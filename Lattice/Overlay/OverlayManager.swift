import Cocoa

class OverlayManager {
    var settings: Settings
    private let accessibility: Accessibility
    private let frontmostAppTracker = FrontmostAppTracker()
    private var overlayWindow: OverlayWindow?
    private var capturedWindow: AXUIElement?

    init(settings: Settings, accessibility: Accessibility) {
        self.settings = settings
        self.accessibility = accessibility
        frontmostAppTracker.start()
    }

    func show() {
        let screen = NSScreen.screens.first
        guard let screen else {
            Log.error("No screen available for overlay")
            return
        }

        // Capture before the overlay steals focus, so we place the window the user was on.
        if let target = frontmostAppTracker.lastApp {
            capturedWindow = accessibility.captureWindow(of: target)
        } else {
            Log.error("No target application to place.")
        }

        overlayWindow = OverlayWindow(screen: screen, settings: settings) { [weak self] anchor, opposite in
            self?.place(from: anchor, to: opposite, on: screen)
        }
        overlayWindow?.show()
    }

    private func place(from anchor: GridCell, to opposite: GridCell, on screen: NSScreen) {
        defer { dismiss() }

        guard let capturedWindow else {
            Log.error("No captured window to place. Is accessibility permission granted?")
            return
        }

        let rect = OverlayGeometry.rect(
            from: anchor,
            to: opposite,
            in: screen.visibleFrame,
            rows: settings.overlaySettings.rows,
            cols: settings.overlaySettings.cols
        )

        accessibility.setFrame(of: capturedWindow, to: OverlayGeometry.toAccessibility(rect))
    }

    private func dismiss() {
        overlayWindow?.close()
        overlayWindow = nil
        capturedWindow = nil
    }
}
