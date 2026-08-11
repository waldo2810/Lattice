import Cocoa

class OverlayManager {
    var settings: Settings

    /// Called with a human-readable reason when a selection could not be turned into a
    /// placed window. The manager does not present anything itself: who owns the user
    /// -visible channel is the app delegate's decision, not the overlay's.
    var onPlacementFailure: ((String) -> Void)?

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
        let failure = attemptPlacement(from: anchor, to: opposite, on: screen)
        // Take the overlay down first: the failure message is a modal, and it should not
        // appear behind a full-screen overlay that is on its way out.
        dismiss()

        if let failure {
            onPlacementFailure?(failure)
        }
    }

    /// Returns `nil` on success, or the reason the placement did not happen.
    private func attemptPlacement(from anchor: GridCell, to opposite: GridCell, on screen: NSScreen) -> String? {
        guard let capturedWindow else {
            Log.error("No captured window to place. Is accessibility permission granted?")
            return "Lattice could not read the window of the app you were using. Make sure the app has a normal, unminimized window and try again."
        }

        let rect = OverlayGeometry.rect(
            from: anchor,
            to: opposite,
            in: screen.visibleFrame,
            rows: settings.overlaySettings.rows,
            cols: settings.overlaySettings.cols
        )

        guard accessibility.setFrame(of: capturedWindow, to: OverlayGeometry.toAccessibility(rect)) else {
            return "The window refused to move or resize. Some windows — full-screen windows and some dialogs — cannot be placed."
        }

        return nil
    }

    private func dismiss() {
        overlayWindow?.close()
        overlayWindow = nil
        capturedWindow = nil
    }
}
