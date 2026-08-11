import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var overlayManager: OverlayManager!
    var hotKeyManager: HotKeyManager = HotKeyManager()
    var accessibility: Accessibility = Accessibility()
    var settings: Settings = Settings()
    
    func applicationDidFinishLaunching(_: Notification) {
        accessibility.requestPermission()
        setupMenuBar()
        setupDefaultShortcut()
    }
    
    private func setupDefaultShortcut() {
        let hotKey = HotKey(carbonKey: .space, carbonModifiers: [.control, .option])
        overlayManager = OverlayManager(settings: settings, accessibility: accessibility)
        hotKeyManager.register(hotKey: hotKey, action: overlayManager.show)
        hotKeyManager.listen()
    }
    
    /// SF Symbol used for the menu bar item.
    ///
    /// `grid` has been available since SF Symbols 1.0 (macOS 10.15), which is
    /// comfortably below our 14.0 deployment target. Symbol names are resolved
    /// at runtime, so `applyStatusItemIcon` still handles a nil image rather
    /// than leaving an invisible, unfindable status item behind.
    private static let statusItemSymbolName = "grid"

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        applyStatusItemIcon()

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "About Lattice", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Lattice", action: #selector(quitApp), keyEquivalent: ""))
        statusItem?.menu = menu
    }

    private func applyStatusItemIcon() {
        guard let button = statusItem.button else { return }

        let image = NSImage(
            systemSymbolName: Self.statusItemSymbolName,
            accessibilityDescription: "Lattice"
        )
        // A template image picks up light/dark menu bars and menu bar tinting.
        image?.isTemplate = true
        button.image = image

        if image == nil {
            // The symbol is missing on this OS. Fall back to text so the item
            // is still visible and findable instead of a blank menu bar slot.
            assertionFailure("SF Symbol '\(Self.statusItemSymbolName)' is unavailable on this system")
            button.title = "Lattice"
            button.setAccessibilityLabel("Lattice")
        }
    }

    @objc private func showAbout() {
        let info = Bundle.main.infoDictionary
        let shortVersion = info?["CFBundleShortVersionString"] as? String ?? "unknown"
        let build = info?["CFBundleVersion"] as? String ?? "unknown"

        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationVersion: shortVersion,
            .version: build,
        ])
    }

    @objc private func openSettings() {
        // Show a dock
        NSApp.setActivationPolicy(.regular)
        // Go back to accessory once closed
        NSApp.activate(ignoringOtherApps: true)
        
        print("Open Settings!")
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
