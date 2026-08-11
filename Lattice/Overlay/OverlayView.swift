import SwiftUI

struct OverlayView: View {
    // Deployment floor: `@Environment(Settings.self)` (Observable-backed environment)
    // and `.onKeyPress` below both require macOS 14.0, which is why
    // MACOSX_DEPLOYMENT_TARGET is 14.0. See docs/user-stories/minimum-macos-version.md.
    @Environment(Settings.self) private var settings
    @FocusState private var isFocused: Bool
    @State private var anchor: GridCell?
    let onSelect: (GridCell, GridCell) -> Void
    let labels = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]

    var body: some View {
        let settingsCols = settings.overlaySettings.cols
        let settingsRows = settings.overlaySettings.rows
        let cols = getCols(colCount: settingsCols)
        let cellLabels = getCellLabels(colCount: settingsCols, rowCount: settingsRows)

        GeometryReader { geometry in
            let cellHeight = geometry.size.height / Double(settingsRows)

            LazyVGrid(columns: cols, spacing: 0) {
                ForEach(Array(cellLabels.enumerated()), id: \.element) { index, label in
                    OverlayCellView(
                        label: label,
                        height: cellHeight,
                        isAnchor: anchor == cell(at: index, colCount: settingsCols)
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .focusable()
        .focused($isFocused)
        .onAppear { isFocused = true }
        .onKeyPress { press in
            if press.key == .escape {
                return .ignored
            }
            guard let index = cellLabels.firstIndex(of: press.characters.uppercased()) else {
                return .ignored
            }
            select(cell(at: index, colCount: settingsCols))
            return .handled
        }
    }

    private func select(_ picked: GridCell) {
        guard let anchor else {
            anchor = picked
            return
        }
        // Same cell twice is not a placement: ignore it, keep the anchor.
        guard picked != anchor else { return }
        onSelect(anchor, picked)
    }

    private func cell(at index: Int, colCount: Int) -> GridCell {
        GridCell(row: index / colCount, col: index % colCount)
    }

    func getCols(colCount: Int) -> [GridItem] {
        return Array(repeating: GridItem(.flexible(), spacing: 0), count: colCount)
    }

    func getCellLabels(colCount: Int, rowCount: Int) -> [String] {
        let totalHints = colCount * rowCount
        guard totalHints <= labels.count else {
            Log.error("Cannot provide too many hints")
            return []
        }
        return Array(labels.prefix(totalHints))
    }
}
