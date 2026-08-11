import CoreGraphics

struct GridCell: Equatable {
    let row: Int
    let col: Int
}

/// Pure geometry for the overlay grid and for moving between the two coordinate
/// spaces Lattice has to deal with:
///
/// - **AppKit screen space**: y grows *up*, the origin is the bottom-left corner
///   of the *primary* screen (`NSScreen.screens.first`). Screens placed left of
///   or below the primary therefore have negative coordinates.
/// - **Accessibility space** (what `kAXPositionAttribute` expects): y grows
///   *down*, the origin is the *top-left* corner of the primary screen. Screens
///   placed left of or above the primary have negative coordinates here.
///
/// The flip between the two is always done against the **primary** screen's
/// frame height — never the target screen's. Flipping against the target screen
/// is the classic multi-monitor bug: it happens to be correct on the primary
/// display and silently wrong everywhere else.
///
/// Everything here is deliberately free of `NSScreen` so it can be unit tested
/// with synthetic display arrangements. `ScreenResolver` does the AppKit lookups.
enum OverlayGeometry {
    /// Rect spanning two grid cells, in AppKit screen coordinates (y grows up).
    /// Corners are normalized, so either cell may be given first.
    static func rect(from a: GridCell, to b: GridCell, in area: CGRect, rows: Int, cols: Int) -> CGRect {
        guard rows > 0, cols > 0 else { return area }

        let minRow = min(a.row, b.row)
        let maxRow = max(a.row, b.row)
        let minCol = min(a.col, b.col)
        let maxCol = max(a.col, b.col)

        let cellWidth = area.width / Double(cols)
        let cellHeight = area.height / Double(rows)

        let width = Double(maxCol - minCol + 1) * cellWidth
        let height = Double(maxRow - minRow + 1) * cellHeight

        let x = area.minX + Double(minCol) * cellWidth
        // Row 0 is the top row, AppKit's y grows upwards.
        let top = area.maxY - Double(minRow) * cellHeight

        return CGRect(x: x, y: top - height, width: width, height: height)
    }

    /// Converts an AppKit screen rect (y up, origin bottom-left of the primary
    /// screen) into Accessibility coordinates (y down, origin top-left of the
    /// primary screen).
    ///
    /// - Parameter primaryFrame: the *primary* screen's `frame`, i.e.
    ///   `NSScreen.screens.first!.frame`. Passing the target screen's frame here
    ///   is what produces off-by-a-screen-height placements on secondary displays.
    static func toAccessibility(_ rect: CGRect, primaryFrame: CGRect) -> CGRect {
        flipVertically(rect, about: primaryFrame)
    }

    /// Converts an Accessibility rect (y down, origin top-left of the primary
    /// screen) back into AppKit screen coordinates. Inverse of `toAccessibility`.
    static func fromAccessibility(_ rect: CGRect, primaryFrame: CGRect) -> CGRect {
        flipVertically(rect, about: primaryFrame)
    }

    /// The flip is its own inverse: `y' = primary.maxY - (y + height)`.
    /// `primaryFrame.maxY` is the primary screen's height, since the primary
    /// screen sits at the AppKit origin by definition.
    private static func flipVertically(_ rect: CGRect, about primaryFrame: CGRect) -> CGRect {
        CGRect(
            x: rect.minX,
            y: primaryFrame.maxY - rect.maxY,
            width: rect.width,
            height: rect.height
        )
    }

    /// Index of the display whose frame contains `point`, or `nil` if the point
    /// falls in a gap between displays. Coordinates must all be in the same space.
    static func indexOfScreen(containing point: CGPoint, in frames: [CGRect]) -> Int? {
        frames.firstIndex { $0.contains(point) }
    }

    /// Index of the display that a window belongs to: the one it overlaps most.
    /// A window straddling two displays is owned by whichever shows more of it,
    /// which matches how macOS itself assigns windows to screens. If the window
    /// overlaps nothing (it is off-screen, e.g. after a display was unplugged),
    /// the display with the nearest center wins so we still place it somewhere
    /// visible. Coordinates must all be in the same space.
    static func indexOfScreen(bestMatching rect: CGRect, in frames: [CGRect]) -> Int? {
        guard !frames.isEmpty else { return nil }

        var bestIndex: Int?
        var bestArea = 0.0
        for (index, frame) in frames.enumerated() {
            let intersection = frame.intersection(rect)
            guard !intersection.isNull else { continue }
            let area = intersection.width * intersection.height
            if area > bestArea {
                bestArea = area
                bestIndex = index
            }
        }
        if let bestIndex { return bestIndex }

        return frames.indices.min { lhs, rhs in
            squaredDistance(from: rect.center, to: frames[lhs].center)
                < squaredDistance(from: rect.center, to: frames[rhs].center)
        }
    }

    /// Keeps `rect` inside `bounds`, shrinking it first if it is simply too big.
    /// Used as a last line of defence so a stale grid selection or a display
    /// arrangement change can never push a window off-screen.
    static func clamp(_ rect: CGRect, to bounds: CGRect) -> CGRect {
        let width = min(rect.width, bounds.width)
        let height = min(rect.height, bounds.height)
        let x = min(max(rect.minX, bounds.minX), bounds.maxX - width)
        let y = min(max(rect.minY, bounds.minY), bounds.maxY - height)
        return CGRect(x: x, y: y, width: width, height: height)
    }

    private static func squaredDistance(from a: CGPoint, to b: CGPoint) -> Double {
        let dx = a.x - b.x
        let dy = a.y - b.y
        return dx * dx + dy * dy
    }
}

private extension CGRect {
    var center: CGPoint { CGPoint(x: midX, y: midY) }
}
