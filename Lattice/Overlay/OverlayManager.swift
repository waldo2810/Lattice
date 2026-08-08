import Cocoa

class OverlayManager {
    var settings: Settings
    
    init(settings: Settings) {
        self.settings = settings
    }
    
    func show() {
        let screen = NSScreen.screens.first
        guard let screen else {
            Log.error("No screen available for overlay")
            return
        }
        let overlayWindow = OverlayWindow(screen: screen, settings: settings)
        overlayWindow.show()
    }
}
