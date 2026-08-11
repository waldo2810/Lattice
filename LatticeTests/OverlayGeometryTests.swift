import CoreGraphics
import Testing

@testable import Lattice

/// A 1440x900 screen sitting at the AppKit origin, standing in for the primary display.
private let primary = CGRect(x: 0, y: 0, width: 1440, height: 900)

@Suite("Grid rect math")
struct OverlayGeometryRectTests {
    @Test("A single cell spans exactly one grid step")
    func singleCell() {
        let area = CGRect(x: 0, y: 0, width: 400, height: 300)
        let cell = GridCell(row: 0, col: 0)

        let rect = OverlayGeometry.rect(from: cell, to: cell, in: area, rows: 3, cols: 4)

        // Row 0 is the top row and AppKit's y grows up, so it sits at the top.
        #expect(rect == CGRect(x: 0, y: 200, width: 100, height: 100))
    }

    @Test("The bottom-right cell sits at the bottom-right of the area")
    func bottomRightCell() {
        let area = CGRect(x: 0, y: 0, width: 400, height: 300)
        let cell = GridCell(row: 2, col: 3)

        let rect = OverlayGeometry.rect(from: cell, to: cell, in: area, rows: 3, cols: 4)

        #expect(rect == CGRect(x: 300, y: 0, width: 100, height: 100))
    }

    @Test("Spanning every cell fills the whole area")
    func fullGrid() {
        let area = CGRect(x: 0, y: 0, width: 400, height: 300)

        let rect = OverlayGeometry.rect(
            from: GridCell(row: 0, col: 0),
            to: GridCell(row: 2, col: 3),
            in: area,
            rows: 3,
            cols: 4
        )

        #expect(rect == area)
    }

    @Test("Cells are offset by a non-zero area origin")
    func offsetArea() {
        let area = CGRect(x: 100, y: 50, width: 400, height: 300)

        let rect = OverlayGeometry.rect(
            from: GridCell(row: 0, col: 0),
            to: GridCell(row: 0, col: 0),
            in: area,
            rows: 3,
            cols: 4
        )

        #expect(rect == CGRect(x: 100, y: 250, width: 100, height: 100))
    }

    @Test("Pressing the bottom-right corner first gives the same rect")
    func reversedCornerOrder() {
        let area = CGRect(x: 0, y: 0, width: 400, height: 300)
        let topLeft = GridCell(row: 0, col: 1)
        let bottomRight = GridCell(row: 2, col: 3)

        let forwards = OverlayGeometry.rect(from: topLeft, to: bottomRight, in: area, rows: 3, cols: 4)
        let backwards = OverlayGeometry.rect(from: bottomRight, to: topLeft, in: area, rows: 3, cols: 4)

        #expect(forwards == backwards)
        #expect(forwards == CGRect(x: 100, y: 0, width: 300, height: 300))
    }

    @Test("Top-right and bottom-left corners normalize to the same rect")
    func crossedCornerOrder() {
        let area = CGRect(x: 0, y: 0, width: 400, height: 300)
        let topRight = GridCell(row: 0, col: 3)
        let bottomLeft = GridCell(row: 2, col: 0)

        let a = OverlayGeometry.rect(from: topRight, to: bottomLeft, in: area, rows: 3, cols: 4)
        let b = OverlayGeometry.rect(from: bottomLeft, to: topRight, in: area, rows: 3, cols: 4)

        #expect(a == b)
        #expect(a == area)
    }

    @Test("A tall non-square grid divides rows and columns independently")
    func nonSquareTallGrid() {
        let area = CGRect(x: 0, y: 0, width: 300, height: 800)

        let rect = OverlayGeometry.rect(
            from: GridCell(row: 1, col: 0),
            to: GridCell(row: 1, col: 0),
            in: area,
            rows: 8,
            cols: 3
        )

        #expect(rect == CGRect(x: 0, y: 600, width: 100, height: 100))
    }

    @Test("A wide non-square grid divides rows and columns independently")
    func nonSquareWideGrid() {
        let area = CGRect(x: 0, y: 0, width: 1200, height: 200)

        let rect = OverlayGeometry.rect(
            from: GridCell(row: 0, col: 4),
            to: GridCell(row: 1, col: 5),
            in: area,
            rows: 2,
            cols: 12
        )

        #expect(rect == CGRect(x: 400, y: 0, width: 200, height: 200))
    }

    @Test("A 1x1 grid always yields the whole area")
    func singleCellGrid() {
        let area = CGRect(x: 10, y: 20, width: 400, height: 300)
        let cell = GridCell(row: 0, col: 0)

        #expect(OverlayGeometry.rect(from: cell, to: cell, in: area, rows: 1, cols: 1) == area)
    }

    @Test("A degenerate grid falls back to the whole area instead of dividing by zero",
          arguments: [(0, 4), (3, 0), (-1, 4)])
    func degenerateGrid(rows: Int, cols: Int) {
        let area = CGRect(x: 0, y: 0, width: 400, height: 300)
        let cell = GridCell(row: 0, col: 0)

        let rect = OverlayGeometry.rect(from: cell, to: cell, in: area, rows: rows, cols: cols)

        #expect(rect == area)
        #expect(!rect.width.isNaN)
        #expect(!rect.height.isNaN)
    }
}

@Suite("AppKit <-> Accessibility Y-flip")
struct OverlayGeometryFlipTests {
    @Test("A rect at the top of the primary screen lands at Accessibility y = 0")
    func topOfPrimary() {
        let rect = CGRect(x: 0, y: 800, width: 1440, height: 100)

        let flipped = OverlayGeometry.toAccessibility(rect, primaryFrame: primary)

        #expect(flipped == CGRect(x: 0, y: 0, width: 1440, height: 100))
    }

    @Test("A rect at the bottom of the primary screen lands just above its height")
    func bottomOfPrimary() {
        let rect = CGRect(x: 0, y: 0, width: 1440, height: 100)

        let flipped = OverlayGeometry.toAccessibility(rect, primaryFrame: primary)

        #expect(flipped == CGRect(x: 0, y: 800, width: 1440, height: 100))
    }

    @Test("A rect on a screen to the right keeps its positive x")
    func screenToTheRight() {
        // A 1920x1080 display placed to the right of the 1440x900 primary.
        let rect = CGRect(x: 1440, y: 0, width: 960, height: 540)

        let flipped = OverlayGeometry.toAccessibility(rect, primaryFrame: primary)

        #expect(flipped == CGRect(x: 1440, y: 360, width: 960, height: 540))
    }

    @Test("A display above the primary flips to a negative Accessibility y")
    func displayAbovePrimary() {
        // A 1920x1080 display stacked above the primary: AppKit y runs 900...1980.
        let rect = CGRect(x: 0, y: 900, width: 1920, height: 1080)

        let flipped = OverlayGeometry.toAccessibility(rect, primaryFrame: primary)

        // Its top edge is 1080pt above the Accessibility origin.
        #expect(flipped == CGRect(x: 0, y: -1080, width: 1920, height: 1080))
    }

    @Test("A display left of the primary keeps its negative x through the flip")
    func displayLeftOfPrimary() {
        // A 1920x1080 display to the left: negative x in both spaces.
        let rect = CGRect(x: -1920, y: 0, width: 1920, height: 1080)

        let flipped = OverlayGeometry.toAccessibility(rect, primaryFrame: primary)

        #expect(flipped == CGRect(x: -1920, y: -180, width: 1920, height: 1080))
    }

    @Test("A display both above and left of the primary is negative in x and y")
    func displayAboveAndLeft() {
        let rect = CGRect(x: -1600, y: 900, width: 1600, height: 1200)

        let flipped = OverlayGeometry.toAccessibility(rect, primaryFrame: primary)

        #expect(flipped == CGRect(x: -1600, y: -1200, width: 1600, height: 1200))
    }

    @Test("The flip is measured against the primary frame, not the target screen")
    func flipUsesPrimaryHeight() {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let taller = CGRect(x: 0, y: 0, width: 1920, height: 1080)

        #expect(OverlayGeometry.toAccessibility(rect, primaryFrame: primary).minY == 800)
        #expect(OverlayGeometry.toAccessibility(rect, primaryFrame: taller).minY == 980)
    }

    @Test("Flipping back returns the original rect",
          arguments: [
            CGRect(x: 0, y: 0, width: 1440, height: 900),
            CGRect(x: 120, y: 340, width: 300, height: 200),
            CGRect(x: -1920, y: -540, width: 640, height: 480),
            CGRect(x: 1440, y: 900, width: 1920, height: 1080),
          ])
    func roundTrip(rect: CGRect) {
        let there = OverlayGeometry.toAccessibility(rect, primaryFrame: primary)
        let back = OverlayGeometry.fromAccessibility(there, primaryFrame: primary)

        #expect(back == rect)
    }

    @Test("The flip is its own inverse")
    func flipIsSelfInverse() {
        let rect = CGRect(x: 40, y: 70, width: 300, height: 200)

        let twice = OverlayGeometry.toAccessibility(
            OverlayGeometry.toAccessibility(rect, primaryFrame: primary),
            primaryFrame: primary
        )

        #expect(twice == rect)
    }
}

@Suite("Screen lookup")
struct OverlayGeometryScreenLookupTests {
    /// Primary at the origin, a second display to its right, a third above it.
    private let frames = [
        CGRect(x: 0, y: 0, width: 1440, height: 900),
        CGRect(x: 1440, y: 0, width: 1920, height: 1080),
        CGRect(x: 0, y: 900, width: 1440, height: 900),
    ]

    @Test("A point inside a display finds that display")
    func pointInsideDisplay() {
        #expect(OverlayGeometry.indexOfScreen(containing: CGPoint(x: 10, y: 10), in: frames) == 0)
        #expect(OverlayGeometry.indexOfScreen(containing: CGPoint(x: 2000, y: 500), in: frames) == 1)
        #expect(OverlayGeometry.indexOfScreen(containing: CGPoint(x: 700, y: 1200), in: frames) == 2)
    }

    @Test("A point in a gap between displays finds nothing")
    func pointInGap() {
        #expect(OverlayGeometry.indexOfScreen(containing: CGPoint(x: -50, y: -50), in: frames) == nil)
    }

    @Test("A point looked up against no displays finds nothing")
    func pointWithNoDisplays() {
        #expect(OverlayGeometry.indexOfScreen(containing: .zero, in: []) == nil)
    }

    @Test("A window fully on one display belongs to it")
    func windowOnOneDisplay() {
        let window = CGRect(x: 1600, y: 200, width: 400, height: 300)

        #expect(OverlayGeometry.indexOfScreen(bestMatching: window, in: frames) == 1)
    }

    @Test("A straddling window belongs to whichever display shows more of it")
    func straddlingWindow() {
        // 300pt wide, 100 of it on the primary and 200 on the display to its right.
        let window = CGRect(x: 1340, y: 100, width: 300, height: 300)

        #expect(OverlayGeometry.indexOfScreen(bestMatching: window, in: frames) == 1)

        // Nudged left so the primary shows more of it, the answer flips.
        let nudged = CGRect(x: 1240, y: 100, width: 300, height: 300)

        #expect(OverlayGeometry.indexOfScreen(bestMatching: nudged, in: frames) == 0)
    }

    @Test("An off-screen window falls back to the display with the nearest center")
    func offScreenWindow() {
        // Far below every display: the primary and the right-hand display are the
        // candidates, and the primary's center is closer in x.
        let window = CGRect(x: 200, y: -5000, width: 200, height: 200)

        #expect(OverlayGeometry.indexOfScreen(bestMatching: window, in: frames) == 0)
    }

    @Test("An off-screen window far to the right falls back to the right-hand display")
    func offScreenWindowToTheRight() {
        let window = CGRect(x: 9000, y: 400, width: 200, height: 200)

        #expect(OverlayGeometry.indexOfScreen(bestMatching: window, in: frames) == 1)
    }

    @Test("A window looked up against no displays finds nothing")
    func windowWithNoDisplays() {
        #expect(OverlayGeometry.indexOfScreen(bestMatching: CGRect(x: 0, y: 0, width: 1, height: 1), in: []) == nil)
    }

    @Test("A zero-area window still resolves via the nearest-center fallback")
    func zeroAreaWindow() {
        let window = CGRect(x: 2000, y: 500, width: 0, height: 0)

        #expect(OverlayGeometry.indexOfScreen(bestMatching: window, in: frames) == 1)
    }
}

@Suite("Clamping to a screen")
struct OverlayGeometryClampTests {
    private let bounds = CGRect(x: 0, y: 0, width: 1440, height: 875)

    @Test("A rect already inside the bounds is untouched")
    func insideBounds() {
        let rect = CGRect(x: 100, y: 100, width: 400, height: 300)

        #expect(OverlayGeometry.clamp(rect, to: bounds) == rect)
    }

    @Test("A rect hanging off the right edge is pushed back in")
    func offTheRight() {
        let rect = CGRect(x: 1300, y: 100, width: 400, height: 300)

        #expect(OverlayGeometry.clamp(rect, to: bounds) == CGRect(x: 1040, y: 100, width: 400, height: 300))
    }

    @Test("A rect hanging off the left edge is pushed back in")
    func offTheLeft() {
        let rect = CGRect(x: -200, y: 100, width: 400, height: 300)

        #expect(OverlayGeometry.clamp(rect, to: bounds) == CGRect(x: 0, y: 100, width: 400, height: 300))
    }

    @Test("A rect hanging off the top is pushed back in")
    func offTheTop() {
        let rect = CGRect(x: 0, y: 800, width: 400, height: 300)

        #expect(OverlayGeometry.clamp(rect, to: bounds) == CGRect(x: 0, y: 575, width: 400, height: 300))
    }

    @Test("A rect larger than the bounds is shrunk to fit them exactly")
    func tooLarge() {
        let rect = CGRect(x: -500, y: -500, width: 4000, height: 3000)

        #expect(OverlayGeometry.clamp(rect, to: bounds) == bounds)
    }

    @Test("Clamping respects bounds with a negative origin")
    func negativeOriginBounds() {
        // The visible frame of a display placed left of and below the primary.
        let secondary = CGRect(x: -1920, y: -180, width: 1920, height: 1055)
        let rect = CGRect(x: -2500, y: -900, width: 400, height: 300)

        #expect(OverlayGeometry.clamp(rect, to: secondary) == CGRect(x: -1920, y: -180, width: 400, height: 300))
    }

    @Test("A clamped rect is always contained by the bounds",
          arguments: [
            CGRect(x: 10_000, y: 10_000, width: 100, height: 100),
            CGRect(x: -10_000, y: -10_000, width: 100, height: 100),
            CGRect(x: 0, y: 0, width: 5000, height: 20),
            CGRect(x: 1439, y: 874, width: 1, height: 1),
          ])
    func alwaysContained(rect: CGRect) {
        let clamped = OverlayGeometry.clamp(rect, to: bounds)

        #expect(bounds.contains(clamped))
    }
}
