import AppKit
import ApplicationServices

/// Tracks whether Lattice is trusted for Accessibility and reports changes as they happen.
///
/// The trust state can change at any moment — the user flips the switch in System Settings
/// while Lattice keeps running — and macOS offers no notification for it, so it has to be
/// observed by asking. Two cheap sources are combined:
///
/// - a timer, running *only* while untrusted, so the common case (permission granted long
///   ago) costs nothing and no timer is left burning for the life of the app;
/// - `NSWorkspace.didActivateApplicationNotification`, which fires when the user comes back
///   from System Settings. It also covers the reverse case: if trust is ever revoked while
///   Lattice is trusted — the moment when no timer is running — the next app switch notices
///   and starts the timer again.
final class PermissionMonitor {
    /// Long enough to be invisible in Activity Monitor, short enough that returning from
    /// System Settings feels instant. `AXIsProcessTrusted` is a cheap local check.
    static let defaultPollInterval: TimeInterval = 1.5

    /// Called on the main thread whenever the trust state flips, with the new value.
    var onChange: ((Bool) -> Void)?

    private(set) var isTrusted: Bool
    private let pollInterval: TimeInterval
    private var timer: Timer?
    private var isObserving = false

    init(pollInterval: TimeInterval = PermissionMonitor.defaultPollInterval) {
        self.pollInterval = pollInterval
        isTrusted = AXIsProcessTrusted()
    }

    deinit {
        timer?.invalidate()
        if isObserving {
            NSWorkspace.shared.notificationCenter.removeObserver(self)
        }
    }

    /// Begins observing. Safe to call once; `refresh` decides whether polling is needed.
    func start() {
        if !isObserving {
            NSWorkspace.shared.notificationCenter.addObserver(
                self,
                selector: #selector(applicationDidActivate),
                name: NSWorkspace.didActivateApplicationNotification,
                object: nil
            )
            isObserving = true
        }
        refresh()
    }

    func stop() {
        stopPolling()
        if isObserving {
            NSWorkspace.shared.notificationCenter.removeObserver(self)
            isObserving = false
        }
    }

    /// Re-reads the trust state, notifies on a change, and leaves polling in the right
    /// state (running only while untrusted). Returns the current value, so callers that
    /// are about to act on the permission can use it as an up-to-date guard.
    @discardableResult
    func refresh() -> Bool {
        let trusted = AXIsProcessTrusted()

        if trusted != isTrusted {
            isTrusted = trusted
            Log.info("Accessibility trust changed: \(trusted ? "granted" : "revoked")")
            onChange?(trusted)
        }

        if trusted {
            stopPolling()
        } else {
            startPolling()
        }

        return trusted
    }

    private func startPolling() {
        guard timer == nil else { return }

        let timer = Timer(timeInterval: pollInterval, repeats: true) { [weak self] _ in
            self?.refresh()
        }
        // .common so the poll keeps running while a menu is open or a window is tracking.
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func stopPolling() {
        timer?.invalidate()
        timer = nil
    }

    @objc private func applicationDidActivate(_: Notification) {
        refresh()
    }
}
