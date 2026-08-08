import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var hotKeyManager: HotKeyManager!
    var overlayManager: OverlayManager!
    
    func applicationDidFinishLaunching(_: Notification) {
        setupMenuBar()
        setupDefaultShortcut()
    }
    
    private func setupDefaultShortcut() {
        hotKeyManager = HotKeyManager()
        let hotKey = HotKey(carbonKey: .space, carbonModifiers: [.control, .option])
        overlayManager = OverlayManager()
        hotKeyManager.register(hotKey: hotKey, action: overlayManager.show)
        hotKeyManager.listen()
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "grid", accessibilityDescription: "Lattice")
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Lattice", action: #selector(quitApp), keyEquivalent: "q"))
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
