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
