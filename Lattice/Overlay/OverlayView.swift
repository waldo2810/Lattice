import SwiftUI

struct OverlayView: View {
    @Environment(Settings.self) private var settings
    @FocusState private var isFocused: Bool
    @State private var selection = CellSelection()
    let onSelect: (GridCell, GridCell) -> Void

    var body: some View {
        let settingsCols = settings.overlaySettings.cols
        let settingsRows = settings.overlaySettings.rows
        let cols = getCols(colCount: settingsCols)
        let cellLabels = CellLabels.labels(rows: settingsRows, cols: settingsCols)

        GeometryReader { geometry in
            let cellHeight = geometry.size.height / Double(settingsRows)

            LazyVGrid(columns: cols, spacing: 0) {
                ForEach(Array(cellLabels.enumerated()), id: \.element) { index, label in
                    OverlayCellView(
                        label: label,
                        height: cellHeight,
                        isAnchor: selection.anchor == CellLabels.cell(at: index, cols: settingsCols)
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
                // The window itself closes on Escape (`cancelOperation`); just make
                // sure no half-finished selection survives.
                _ = selection.cancel()
                return .ignored
            }
            guard let picked = CellLabels.cell(
                forLabel: press.characters,
                rows: settingsRows,
                cols: settingsCols
            ) else {
                return .ignored
            }
            if case let .committed(anchor, opposite) = selection.select(picked) {
                onSelect(anchor, opposite)
            }
            return .handled
        }
    }

    func getCols(colCount: Int) -> [GridItem] {
        return Array(repeating: GridItem(.flexible(), spacing: 0), count: colCount)
    }
}
