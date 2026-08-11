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

        // A display being plugged in, unplugged, or rearranged invalidates the
        // overlay's frame and every grid cell derived from it, so drop the overlay
        // rather than risk placing a window onto a screen that no longer exists.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func show() {
        // Capture before the overlay steals focus, so we place the window the user was on.
        if let target = frontmostAppTracker.lastApp {
            capturedWindow = accessibility.captureWindow(of: target)
        } else {
            Log.error("No target application to place.")
        }

        let windowFrame = capturedWindow.flatMap { accessibility.frame(of: $0) }
        guard let screen = ScreenResolver.targetScreen(frontmostWindowFrame: windowFrame) else {
            Log.error("No screen available for overlay")
            capturedWindow = nil
            return
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

        // The screen may have gone away between opening the overlay and committing.
        guard NSScreen.screens.contains(screen) else {
            Log.warn("Target screen is gone; skipping placement.")
            return
        }

        // `visibleFrame` excludes the menu bar, the Dock and any notch safe area.
        let rect = OverlayGeometry.rect(
            from: anchor,
            to: opposite,
            in: screen.visibleFrame,
            rows: settings.overlaySettings.rows,
            cols: settings.overlaySettings.cols
        )

        guard let frame = ScreenResolver.accessibilityFrame(for: rect, on: screen) else {
            Log.error("No primary screen to convert coordinates against.")
            return
        }

        accessibility.setFrame(of: capturedWindow, to: frame)
    }

    @objc private func screenParametersChanged() {
        guard overlayWindow != nil else { return }
        Log.info("Display arrangement changed; dismissing the overlay.")
        dismiss()
    }

    private func dismiss() {
        overlayWindow?.close()
        overlayWindow = nil
        capturedWindow = nil
    }
}
