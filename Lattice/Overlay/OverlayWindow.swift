import AppKit

class OverlayWindow: NSWindow {
    init(screen: NSScreen) {
        super.init(
            contentRect: screen.visibleFrame,
            styleMask: [.fullSizeContentView],
            backing: .buffered,
            defer: false
        )
    }
    
    func show() {
        orderFrontRegardless()
        makeKey()
    }
}
