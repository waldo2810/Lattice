import Cocoa

/// AppKit glue around `OverlayGeometry`: picks the display the overlay targets
/// and owns the coordinate conversion, so no caller has to remember which
/// screen the vertical flip is measured against.
enum ScreenResolver {
    /// The primary screen: the one at the AppKit origin, whose top-left corner is
    /// also the Accessibility origin. `NSScreen.screens` is documented to list it
    /// first; `NSScreen.main` is *not* the same thing (it follows the key window).
    static var primary: NSScreen? { NSScreen.screens.first }

    /// Which screen the overlay opens on, in priority order:
    ///
    /// 1. **The screen showing most of the frontmost window** — the window the
    ///    user is about to move. If it straddles two displays, the one showing
    ///    more of it wins, matching how macOS assigns windows to screens.
    /// 2. **The screen under the mouse cursor** — used when there is no captured
    ///    window, or its position could not be read (some apps deny it).
    /// 3. **`NSScreen.main`** — the screen with the active menu bar.
    /// 4. **The primary screen** — last resort.
    ///
    /// - Parameter windowFrame: the frontmost window's frame in *Accessibility*
    ///   coordinates, as read from `kAXPositionAttribute`/`kAXSizeAttribute`.
    static func targetScreen(frontmostWindowFrame windowFrame: CGRect?) -> NSScreen? {
        let screens = NSScreen.screens
        guard let primary = screens.first else { return nil }

        if let windowFrame {
            let appKitFrame = OverlayGeometry.fromAccessibility(windowFrame, primaryFrame: primary.frame)
            if let index = OverlayGeometry.indexOfScreen(bestMatching: appKitFrame, in: screens.map(\.frame)) {
                return screens[index]
            }
        }

        // `NSEvent.mouseLocation` is already in AppKit screen coordinates.
        if let index = OverlayGeometry.indexOfScreen(containing: NSEvent.mouseLocation, in: screens.map(\.frame)) {
            return screens[index]
        }

        return NSScreen.main ?? primary
    }

    /// Converts a rect in AppKit screen coordinates into the Accessibility space,
    /// clamped to `screen.visibleFrame` so nothing ever lands under the menu bar,
    /// under the Dock, behind a notch, or off-screen entirely.
    static func accessibilityFrame(for rect: CGRect, on screen: NSScreen) -> CGRect? {
        guard let primary else { return nil }
        let clamped = OverlayGeometry.clamp(rect, to: screen.visibleFrame)
        return OverlayGeometry.toAccessibility(clamped, primaryFrame: primary.frame)
    }
}
