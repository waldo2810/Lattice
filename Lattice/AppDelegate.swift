import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var overlayManager: OverlayManager!
    var hotKeyManager: HotKeyManager = HotKeyManager()
    var accessibility: Accessibility = Accessibility()
    var settings: Settings = Settings()

    private var hotKeyBinder: HotKeyBinder!
    private var settingsWindowController: SettingsWindowController?

    func applicationDidFinishLaunching(_: Notification) {
        accessibility.requestPermission()
        setupMenuBar()
        setupShortcut()
    }

    private func setupShortcut() {
        overlayManager = OverlayManager(settings: settings, accessibility: accessibility)
        hotKeyBinder = HotKeyBinder(manager: hotKeyManager, action: overlayManager.show)

        // Settings is the only source for the shortcut: no literal is duplicated here.
        let configured = settings.hotKeySettings.current
        if !hotKeyBinder.bind(configured) {
            Log.error("Could not register \(configured.displayString); trying the default shortcut.")
            // The stored shortcut may have been claimed by another app since it was saved.
            // Falling back keeps the app usable instead of starting with no way to open it.
            if configured != .default, hotKeyBinder.bind(.default) {
                settings.setHotKey(.default)
            }
        }

        hotKeyManager.listen()
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "grid", accessibilityDescription: "Lattice")

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Lattice", action: #selector(quitApp), keyEquivalent: ""))
        statusItem?.menu = menu
    }

    @objc private func openSettings() {
        // Built once and kept, so re-opening refocuses the same window instead of stacking copies.
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController(settings: settings, hotKeyBinder: hotKeyBinder)
        }
        settingsWindowController?.present()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
