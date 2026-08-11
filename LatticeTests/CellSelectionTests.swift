import CoreGraphics
import Testing

@testable import Lattice

@Suite("Cell labels")
struct CellLabelsTests {
    @Test("A 3x4 grid is labelled A through L in reading order")
    func defaultGridLabels() {
        #expect(CellLabels.labels(rows: 3, cols: 4) == ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L"])
    }

    @Test("Label index maps to row-major row/col")
    func indexToCell() {
        #expect(CellLabels.cell(at: 0, cols: 4) == GridCell(row: 0, col: 0))
        #expect(CellLabels.cell(at: 3, cols: 4) == GridCell(row: 0, col: 3))
        #expect(CellLabels.cell(at: 4, cols: 4) == GridCell(row: 1, col: 0))
        #expect(CellLabels.cell(at: 11, cols: 4) == GridCell(row: 2, col: 3))
    }

    @Test("A negative index or a zero-column grid maps to no cell")
    func invalidIndex() {
        #expect(CellLabels.cell(at: -1, cols: 4) == nil)
        #expect(CellLabels.cell(at: 0, cols: 0) == nil)
    }

    @Test("A pressed letter maps to its cell")
    func letterToCell() {
        #expect(CellLabels.cell(forLabel: "A", rows: 3, cols: 4) == GridCell(row: 0, col: 0))
        #expect(CellLabels.cell(forLabel: "E", rows: 3, cols: 4) == GridCell(row: 1, col: 0))
        #expect(CellLabels.cell(forLabel: "L", rows: 3, cols: 4) == GridCell(row: 2, col: 3))
    }

    @Test("Lowercase keypresses map to the same cell")
    func caseInsensitive() {
        #expect(CellLabels.cell(forLabel: "e", rows: 3, cols: 4) == CellLabels.cell(forLabel: "E", rows: 3, cols: 4))
    }

    @Test("A letter beyond the grid maps to no cell")
    func letterOutsideGrid() {
        // A 3x4 grid stops at L.
        #expect(CellLabels.cell(forLabel: "M", rows: 3, cols: 4) == nil)
        #expect(CellLabels.cell(forLabel: "1", rows: 3, cols: 4) == nil)
        #expect(CellLabels.cell(forLabel: "", rows: 3, cols: 4) == nil)
    }

    @Test("The same letter means different cells in different grid shapes")
    func gridShapeChangesMapping() {
        #expect(CellLabels.cell(forLabel: "E", rows: 3, cols: 4) == GridCell(row: 1, col: 0))
        #expect(CellLabels.cell(forLabel: "E", rows: 4, cols: 2) == GridCell(row: 2, col: 0))
        #expect(CellLabels.cell(forLabel: "E", rows: 2, cols: 6) == GridCell(row: 0, col: 4))
    }

    @Test("A grid needing more than 26 letters has no labels")
    func gridTooLarge() {
        #expect(CellLabels.labels(rows: 6, cols: 6).isEmpty)
        #expect(CellLabels.cell(forLabel: "A", rows: 6, cols: 6) == nil)
    }

    @Test("A 26-cell grid still fits the alphabet")
    func gridExactlyFits() {
        #expect(CellLabels.labels(rows: 2, cols: 13).count == 26)
    }

    @Test("An empty grid has no labels", arguments: [(0, 4), (3, 0)])
    func emptyGrid(rows: Int, cols: Int) {
        #expect(CellLabels.labels(rows: rows, cols: cols).isEmpty)
    }
}

@Suite("Selection state machine")
struct CellSelectionTests {
    private let a = GridCell(row: 0, col: 0)
    private let b = GridCell(row: 2, col: 3)

    @Test("Nothing is anchored before the first keypress")
    func startsEmpty() {
        #expect(CellSelection().anchor == nil)
    }

    @Test("The first keypress sets the anchor and does not commit")
    func firstKeyAnchors() {
        var selection = CellSelection()

        #expect(selection.select(a) == .anchored(a))
        #expect(selection.anchor == a)
    }

    @Test("Pressing the same key twice is a no-op")
    func sameKeyTwiceIsNoOp() {
        var selection = CellSelection()
        _ = selection.select(a)

        #expect(selection.select(a) == .unchanged)
        #expect(selection.anchor == a, "the anchor must survive a repeated keypress")
    }

    @Test("Pressing the same key many times still never commits")
    func sameKeyRepeatedly() {
        var selection = CellSelection()
        _ = selection.select(a)

        for _ in 0..<5 {
            #expect(selection.select(a) == .unchanged)
        }
        #expect(selection.anchor == a)
    }

    @Test("A second, distinct keypress commits both corners in press order")
    func secondDistinctKeyCommits() {
        var selection = CellSelection()
        _ = selection.select(a)

        #expect(selection.select(b) == .committed(anchor: a, opposite: b))
    }

    @Test("Committing keeps the anchor first even when the far corner was pressed first")
    func reversedPressOrderIsPreserved() {
        var selection = CellSelection()
        _ = selection.select(b)

        // Normalization is the geometry's job; the state machine reports press order.
        #expect(selection.select(a) == .committed(anchor: b, opposite: a))
    }

    @Test("A no-op keypress between the two corners does not disturb the commit")
    func noOpBetweenCorners() {
        var selection = CellSelection()
        _ = selection.select(a)
        _ = selection.select(a)

        #expect(selection.select(b) == .committed(anchor: a, opposite: b))
    }

    @Test("Escape before any keypress cancels without committing")
    func escapeBeforeAnchor() {
        var selection = CellSelection()

        #expect(selection.cancel() == .cancelled)
        #expect(selection.anchor == nil)
    }

    @Test("Escape after the anchor clears it without committing")
    func escapeAfterAnchor() {
        var selection = CellSelection()
        _ = selection.select(a)

        #expect(selection.cancel() == .cancelled)
        #expect(selection.anchor == nil)
    }

    @Test("After Escape the next keypress anchors again rather than committing")
    func selectionRestartsAfterEscape() {
        var selection = CellSelection()
        _ = selection.select(a)
        _ = selection.cancel()

        #expect(selection.select(b) == .anchored(b))
        #expect(selection.anchor == b)
    }

    @Test("Cells differing only by row or only by column still commit")
    func adjacentCellsCommit() {
        var byRow = CellSelection()
        _ = byRow.select(GridCell(row: 0, col: 1))
        #expect(byRow.select(GridCell(row: 1, col: 1)) == .committed(anchor: GridCell(row: 0, col: 1),
                                                                    opposite: GridCell(row: 1, col: 1)))

        var byCol = CellSelection()
        _ = byCol.select(GridCell(row: 1, col: 0))
        #expect(byCol.select(GridCell(row: 1, col: 1)) == .committed(anchor: GridCell(row: 1, col: 0),
                                                                    opposite: GridCell(row: 1, col: 1)))
    }
}

@Suite("Selection through to a placed rect")
struct SelectionToRectTests {
    /// The full path a two-keypress sequence takes: letters -> cells -> AppKit rect
    /// -> Accessibility rect, on a 1440x900 primary display.
    @Test("Pressing A then L places the window over the whole visible frame")
    func fullGridSelection() {
        let visibleFrame = CGRect(x: 0, y: 0, width: 1440, height: 875)
        let primaryFrame = CGRect(x: 0, y: 0, width: 1440, height: 900)

        var selection = CellSelection()
        guard let first = CellLabels.cell(forLabel: "A", rows: 3, cols: 4),
              let second = CellLabels.cell(forLabel: "L", rows: 3, cols: 4) else {
            Issue.record("Both letters should map to cells of a 3x4 grid")
            return
        }
        _ = selection.select(first)
        guard case let .committed(anchor, opposite) = selection.select(second) else {
            Issue.record("A second distinct letter should commit")
            return
        }

        let rect = OverlayGeometry.rect(from: anchor, to: opposite, in: visibleFrame, rows: 3, cols: 4)
        let clamped = OverlayGeometry.clamp(rect, to: visibleFrame)
        let accessibility = OverlayGeometry.toAccessibility(clamped, primaryFrame: primaryFrame)

        #expect(rect == visibleFrame)
        // The menu bar takes the top 25pt, so the window starts just below it.
        #expect(accessibility == CGRect(x: 0, y: 25, width: 1440, height: 875))
    }

    @Test("Pressing L then A gives the same placement as A then L")
    func reversedSelectionMatches() {
        let visibleFrame = CGRect(x: 0, y: 0, width: 1440, height: 875)
        let a = CellLabels.cell(forLabel: "A", rows: 3, cols: 4)!
        let l = CellLabels.cell(forLabel: "L", rows: 3, cols: 4)!

        let forwards = OverlayGeometry.rect(from: a, to: l, in: visibleFrame, rows: 3, cols: 4)
        let backwards = OverlayGeometry.rect(from: l, to: a, in: visibleFrame, rows: 3, cols: 4)

        #expect(forwards == backwards)
    }

    @Test("A selection on a display above the primary lands at a negative Accessibility y")
    func selectionOnDisplayAbovePrimary() {
        let primaryFrame = CGRect(x: 0, y: 0, width: 1440, height: 900)
        // A 1920x1080 display stacked above the primary, its own menu bar excluded.
        let visibleFrame = CGRect(x: 0, y: 900, width: 1920, height: 1055)

        let cell = CellLabels.cell(forLabel: "A", rows: 2, cols: 2)!
        let rect = OverlayGeometry.rect(from: cell, to: cell, in: visibleFrame, rows: 2, cols: 2)
        let accessibility = OverlayGeometry.toAccessibility(rect, primaryFrame: primaryFrame)

        #expect(rect == CGRect(x: 0, y: 1427.5, width: 960, height: 527.5))
        #expect(accessibility == CGRect(x: 0, y: -1055, width: 960, height: 527.5))
        #expect(OverlayGeometry.fromAccessibility(accessibility, primaryFrame: primaryFrame) == rect)
    }
}
