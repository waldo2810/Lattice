import Foundation

/// The lettered labels the overlay draws on its cells, and the mapping back from
/// a pressed letter to a `GridCell`.
///
/// Kept free of SwiftUI so the label → row/col mapping — which changes the moment
/// the grid size becomes configurable — can be unit tested on its own.
enum CellLabels {
    /// Labels in reading order: left to right, then top to bottom.
    static let alphabet = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
                           "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]

    /// The labels for a `rows` × `cols` grid, or `[]` if the grid needs more
    /// letters than the alphabet has.
    static func labels(rows: Int, cols: Int) -> [String] {
        guard rows > 0, cols > 0 else { return [] }
        let total = rows * cols
        guard total <= alphabet.count else { return [] }
        return Array(alphabet.prefix(total))
    }

    /// The cell a label index refers to. Index 0 is the top-left cell.
    static func cell(at index: Int, cols: Int) -> GridCell? {
        guard cols > 0, index >= 0 else { return nil }
        return GridCell(row: index / cols, col: index % cols)
    }

    /// The cell a pressed key refers to, or `nil` if the key is not a cell label
    /// of this grid. Matching is case-insensitive.
    static func cell(forLabel label: String, rows: Int, cols: Int) -> GridCell? {
        let wanted = label.uppercased()
        guard let index = labels(rows: rows, cols: cols).firstIndex(of: wanted) else { return nil }
        return cell(at: index, cols: cols)
    }
}

/// The two-keypress selection state machine, extracted from `OverlayView` so it
/// can be tested without a window, a key handler, or a running app.
///
/// The rules ([[cell-selection-window-placement]] AC 2/3/8): the first cell sets
/// the anchor, pressing the anchor again is a no-op, a second *distinct* cell
/// commits, and Escape clears everything.
struct CellSelection: Equatable {
    /// What the caller should do after feeding an event in.
    enum Outcome: Equatable {
        /// The anchor corner was set; keep the overlay open and highlight it.
        case anchored(GridCell)
        /// Nothing changed — the same cell was pressed twice.
        case unchanged
        /// Both corners are known; place the window and dismiss.
        case committed(anchor: GridCell, opposite: GridCell)
        /// The selection was cancelled; dismiss without placing anything.
        case cancelled
    }

    /// The first picked cell, or `nil` before anything has been pressed.
    private(set) var anchor: GridCell?

    init(anchor: GridCell? = nil) {
        self.anchor = anchor
    }

    /// Feeds a picked cell into the machine.
    mutating func select(_ picked: GridCell) -> Outcome {
        guard let anchor else {
            self.anchor = picked
            return .anchored(picked)
        }
        // The same cell twice is not a placement: ignore it and keep the anchor.
        guard picked != anchor else { return .unchanged }
        return .committed(anchor: anchor, opposite: picked)
    }

    /// Escape: forget the anchor. Never commits a partial placement.
    mutating func cancel() -> Outcome {
        anchor = nil
        return .cancelled
    }
}
