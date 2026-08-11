import Foundation
import ServiceManagement

/// The "Launch at Login" state, backed entirely by `SMAppService`.
///
/// Deliberately *not* persisted alongside the other settings: the login item lives in the
/// system's registry, and the user can remove it at any time from System Settings →
/// General → Login Items without the app running. A copy in `UserDefaults` would go stale
/// the moment that happens, so `SMAppService.mainApp.status` is the single source of
/// truth and is re-read every time the UI is shown.
@MainActor
@Observable
final class LaunchAtLogin {
    /// Whether the app is currently registered *and* allowed to launch. Only `.enabled`
    /// counts: a registration that macOS is holding back is not a login item that works,
    /// and showing the toggle on would be a lie.
    private(set) var isEnabled = false

    /// Why the last `register()` / `unregister()` failed, in words a user can act on.
    /// `nil` once a later attempt (or a refresh) succeeds.
    private(set) var failure: String?

    /// Set when the app is registered but macOS is not launching it — typically because
    /// the item was switched off in System Settings rather than through this toggle.
    private(set) var approvalNotice: String?

    /// A permanent warning about *where* the app is installed, computed once at startup.
    /// Registering from a build folder or a random directory "succeeds" and then behaves
    /// unpredictably after the path changes, which is worth saying up front.
    let locationWarning: String?

    private let service: SMAppService

    init(service: SMAppService = .mainApp, bundleURL: URL = Bundle.main.bundleURL) {
        self.service = service
        locationWarning = Self.locationWarning(bundleURL: bundleURL)
        refresh()
    }

    /// Re-reads the system state. Called when Settings appears and whenever its window
    /// becomes key again, so a change made in System Settings shows up here.
    func refresh() {
        let status = service.status
        isEnabled = status == .enabled

        switch status {
        case .requiresApproval:
            approvalNotice = "macOS is holding Lattice's login item back. Turn Lattice on under System Settings → General → Login Items."
        default:
            approvalNotice = nil
        }
    }

    /// Registers or unregisters the login item, then re-reads the status so the toggle
    /// always shows what the system actually did rather than what was asked for.
    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try service.register()
            } else {
                try service.unregister()
            }
            failure = nil
        } catch {
            Log.error("Launch at login \(enabled ? "registration" : "removal") failed: \(error)")
            failure = Self.explanation(for: error, enabling: enabled)
        }

        refresh()
    }

    private static func explanation(for error: Error, enabling: Bool) -> String {
        let reason = (error as NSError).localizedFailureReason ?? error.localizedDescription

        guard enabling else {
            return "Could not remove Lattice from your login items: \(reason) You can remove it under System Settings → General → Login Items."
        }

        return "Could not add Lattice to your login items: \(reason) This usually means the app is not code signed, or is not installed in your Applications folder — move Lattice to /Applications and try again."
    }

    /// `/Applications` and `~/Applications` are the two locations a login item can be
    /// expected to survive in; anything else (Downloads, a Desktop copy, Xcode's
    /// DerivedData) either moves or gets rebuilt out from under the registration.
    private static func locationWarning(bundleURL: URL) -> String? {
        let path = bundleURL.resolvingSymlinksInPath().path
        let userApplications = FileManager.default
            .homeDirectoryForCurrentUser
            .appendingPathComponent("Applications")
            .resolvingSymlinksInPath()
            .path

        if path.hasPrefix("/Applications/") || path.hasPrefix(userApplications + "/") {
            return nil
        }

        if path.contains("/DerivedData/") {
            return "Lattice is running from Xcode's build folder, so launching at login will not work reliably. Install it in /Applications to use this."
        }

        return "Lattice is running from \(bundleURL.deletingLastPathComponent().path), not /Applications. Launching at login is unreliable outside the Applications folder, and breaks entirely if the app is moved."
    }
}
