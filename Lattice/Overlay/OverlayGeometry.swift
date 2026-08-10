import Cocoa

struct GridCell: Equatable {
    let row: Int
    let col: Int
}

enum OverlayGeometry {
    /// Rect spanning two grid cells, in AppKit screen coordinates (y grows up).
    /// Corners are normalized, so either cell may be given first.
    static func rect(from a: GridCell, to b: GridCell, in area: CGRect, rows: Int, cols: Int) -> CGRect {
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

    /// Converts an AppKit screen rect (y up, origin bottom-left) into the
    /// Accessibility coordinate space (y down, origin top-left of the primary screen).
    static func toAccessibility(_ rect: CGRect) -> CGRect {
        guard let primary = NSScreen.screens.first else { return rect }
        return CGRect(
            x: rect.minX,
            y: primary.frame.maxY - rect.maxY,
            width: rect.width,
            height: rect.height
        )
    }
}
