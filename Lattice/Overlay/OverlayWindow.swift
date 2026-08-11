import Cocoa
import SwiftUI

class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool { true }

    private let targetScreen: NSScreen

    init(screen: NSScreen, settings: Settings, onSelect: @escaping (GridCell, GridCell) -> Void) {
        self.targetScreen = screen
        super.init(
            contentRect: screen.visibleFrame,
            styleMask: [.fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        let view = NSHostingView(rootView: OverlayView(onSelect: onSelect).environment(settings))
        self.contentView = view
        self.isOpaque = false
        self.hasShadow = false
        self.backgroundColor = .blue.withAlphaComponent(0.2)
        self.isReleasedWhenClosed = false
        // Follow the user onto whichever Space they are on, on any display.
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }

    func show() {
        // `contentRect` is only a hint; AppKit may have constrained the window to
        // another screen. Re-apply the target screen's visible frame explicitly so
        // the overlay lands on the display it was computed for.
        setFrame(targetScreen.visibleFrame, display: false)
        NSApp.activate(ignoringOtherApps: true)
        orderFrontRegardless()
        makeKey()
    }

    override func cancelOperation(_ sender: Any?) {
        self.close()
    }
}
