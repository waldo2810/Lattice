import Cocoa
import SwiftUI

class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    
    init(screen: NSScreen, settings: Settings) {
        super.init(
            contentRect: screen.visibleFrame,
            styleMask: [.fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        let view = NSHostingView(rootView: OverlayView().environment(settings))
        self.contentView = view
        self.isOpaque = false
        self.hasShadow = false
        self.backgroundColor = .blue.withAlphaComponent(0.2)
        self.isReleasedWhenClosed = false
    }
    
    func show() {
        NSApp.activate(ignoringOtherApps: true)
        orderFrontRegardless()
        makeKey()
    }
    
    override func cancelOperation(_ sender: Any?) {
        self.close()
    }
}
