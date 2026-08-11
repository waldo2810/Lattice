import AppKit
import SwiftUI

/// Hosts the SwiftUI settings form in a real AppKit window.
///
/// SwiftUI's `Settings` scene is not an option here: the app has no SwiftUI `App` entry
/// point — `main.swift` drives `NSApplication` directly — so there is no `Scene` builder
/// to put it in. An `NSWindowController` wrapping an `NSHostingController` gives the same
/// result without restructuring the app's startup.
final class SettingsWindowController: NSWindowController, NSWindowDelegate {
    init(settings: Settings, hotKeyBinder: HotKeyBinder) {
        let hostingController = NSHostingController(
            rootView: SettingsView(settings: settings, hotKeyBinder: hotKeyBinder)
        )
        // Let the window follow the form's height, which grows when an error is shown.
        hostingController.sizingOptions = [.preferredContentSize]

        let window = NSWindow(contentViewController: hostingController)
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.title = "Lattice Settings"
        // The controller keeps the window alive across closes so re-opening refocuses it.
        window.isReleasedWhenClosed = false

        super.init(window: window)

        window.delegate = self
        window.center()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    /// Shows the window, giving the app a Dock icon and a menu bar for as long as it is
    /// open — an `.accessory` app cannot properly focus a normal window.
    func present() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_: Notification) {
        // Back to a menu-bar-only app: the Dock icon goes away again.
        NSApp.setActivationPolicy(.accessory)
    }
}
