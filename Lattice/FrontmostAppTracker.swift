import Cocoa

/// Remembers the last activated application that is not Lattice itself.
/// Needed because opening the overlay makes Lattice frontmost, so by the second
/// hotkey press `NSWorkspace.frontmostApplication` would be Lattice.
final class FrontmostAppTracker {
    private(set) var lastApp: NSRunningApplication?

    private let ownPid = ProcessInfo.processInfo.processIdentifier

    func start() {
        if let current = NSWorkspace.shared.frontmostApplication, current.processIdentifier != ownPid {
            lastApp = current
        }

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appActivated(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }

    @objc private func appActivated(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              app.processIdentifier != ownPid else {
            return
        }
        lastApp = app
    }
}
