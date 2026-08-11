import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var overlayManager: OverlayManager!
    var hotKeyManager: HotKeyManager = HotKeyManager()
    var accessibility: Accessibility = Accessibility()
    var settings: Settings = Settings()

    private let permissions = PermissionMonitor()
    private var hotKeyBinder: HotKeyBinder!
    private var settingsWindowController: SettingsWindowController?

    /// The permission items live at the top of the menu and are hidden while trusted,
    /// so the menu is built once and only its visibility changes.
    private var permissionStatusMenuItem: NSMenuItem!
    private var openAccessibilitySettingsMenuItem: NSMenuItem!
    private var permissionSeparator: NSMenuItem!

    func applicationDidFinishLaunching(_: Notification) {
        accessibility.requestPermission()
        setupMenuBar()
        setupShortcut()
        setupPermissionMonitoring()
    }

    private func setupShortcut() {
        overlayManager = OverlayManager(settings: settings, accessibility: accessibility)
        overlayManager.onPlacementFailure = { [weak self] reason in
            self?.reportPlacementFailure(reason)
        }
        hotKeyBinder = HotKeyBinder(manager: hotKeyManager, action: { [weak self] in
            self?.handleHotKey()
        })

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

    private func setupPermissionMonitoring() {
        permissions.onChange = { [weak self] _ in
            self?.updatePermissionState()
        }
        permissions.start()
        updatePermissionState()
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        permissionStatusMenuItem = NSMenuItem(title: "Accessibility permission required", action: nil, keyEquivalent: "")
        // A label, not a command: the item below it is the thing to click.
        permissionStatusMenuItem.isEnabled = false
        openAccessibilitySettingsMenuItem = NSMenuItem(
            title: "Open Accessibility Settings…",
            action: #selector(openAccessibilitySettings),
            keyEquivalent: ""
        )
        permissionSeparator = .separator()

        let menu = NSMenu()
        // Not auto-enabled, so the disabled label stays visibly disabled.
        menu.autoenablesItems = false
        menu.addItem(permissionStatusMenuItem)
        menu.addItem(openAccessibilitySettingsMenuItem)
        menu.addItem(permissionSeparator)
        menu.addItem(NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Lattice", action: #selector(quitApp), keyEquivalent: ""))
        statusItem?.menu = menu
    }

    /// Mirrors the trust state in the menu bar: a warning icon plus the permission items,
    /// or the normal icon and nothing extra.
    private func updatePermissionState() {
        let trusted = permissions.isTrusted

        if let button = statusItem?.button {
            let symbol = trusted ? "grid" : "exclamationmark.triangle.fill"
            let description = trusted ? "Lattice" : "Lattice — Accessibility permission required"
            button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: description)
            button.contentTintColor = trusted ? nil : .systemOrange
            button.toolTip = description
        }

        permissionStatusMenuItem?.isHidden = trusted
        openAccessibilitySettingsMenuItem?.isHidden = trusted
        permissionSeparator?.isHidden = trusted
    }

    /// Pressing the shortcut without permission opens the guidance instead of an overlay
    /// that could not place anything anyway.
    private func handleHotKey() {
        guard permissions.refresh() else {
            PermissionUI.showPermissionGuidance()
            return
        }
        overlayManager.show()
    }

    private func reportPlacementFailure(_ reason: String) {
        // A revoked or never-granted permission is by far the likeliest cause, and it has
        // its own actionable message, so check that before the generic failure.
        guard permissions.refresh() else {
            PermissionUI.showPermissionGuidance()
            return
        }
        PermissionUI.showPlacementFailure(reason)
    }

    @objc private func openAccessibilitySettings() {
        PermissionUI.openAccessibilitySettings()
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
