import AppKit

class OverlayManager {

    func show() {
        let screen = NSScreen.screens.first
        guard let screen else {
            Log.error("No screen available for overlay")
            return
        }
        let overlayWindow = OverlayWindow(screen: screen)
        overlayWindow.show()
    }
}
