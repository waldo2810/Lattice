import AppKit

/// The user-facing side of the Accessibility permission: the link into System Settings and
/// the messages shown when Lattice cannot do its job.
///
/// `NSAlert` is used deliberately. It needs no entitlement, no authorization prompt and no
/// signed bundle — unlike user notifications, which need all three and would fail silently
/// in exactly the unsigned, first-run situation this is meant to explain.
enum PermissionUI {
    /// Deep link to Privacy & Security > Accessibility. Opening the pane directly is the
    /// whole point: the setting is several clicks deep and easy to miss.
    static let accessibilitySettingsURL = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    )!

    private static var isShowingGuidance = false

    static func openAccessibilitySettings() {
        if !NSWorkspace.shared.open(accessibilitySettingsURL) {
            Log.error("Could not open the Accessibility pane in System Settings.")
        }
    }

    /// Explains the permission and offers to open the pane. Shown when the user presses the
    /// shortcut without permission, so pressing it is never a no-op.
    static func showPermissionGuidance() {
        // The shortcut still works while the alert is up; without this, holding it down
        // would stack modals on top of each other.
        guard !isShowingGuidance else { return }
        isShowingGuidance = true
        defer { isShowingGuidance = false }

        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Lattice needs Accessibility permission"
        alert.informativeText = """
        Lattice moves and resizes other apps' windows, and macOS only allows that with Accessibility permission.

        Open System Settings > Privacy & Security > Accessibility and turn Lattice on. Lattice picks the change up on its own — no restart needed.
        """
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Later")

        if runModal(alert) == .alertFirstButtonReturn {
            openAccessibilitySettings()
        }
    }

    /// Surfaces a placement that failed for a reason other than permission — the log line
    /// alone is invisible to anyone who is not running Console.
    static func showPlacementFailure(_ reason: String) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Lattice could not place the window"
        alert.informativeText = reason
        alert.addButton(withTitle: "OK")
        _ = runModal(alert)
    }

    /// Runs a modal from a menu-bar-only app.
    ///
    /// An `.accessory` app cannot bring a window to the front properly, so the policy is
    /// raised to `.regular` for the duration and put back afterwards — the same dance
    /// `SettingsWindowController` does. The *previous* policy is restored rather than a
    /// hardcoded `.accessory`, so an alert shown while the Settings window is open does not
    /// drop the app back to accessory and hide it.
    private static func runModal(_ alert: NSAlert) -> NSApplication.ModalResponse {
        let previousPolicy = NSApp.activationPolicy()
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        defer { NSApp.setActivationPolicy(previousPolicy) }
        return alert.runModal()
    }
}
