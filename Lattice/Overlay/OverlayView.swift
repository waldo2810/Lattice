import SwiftUI

struct OverlayView: View {
    @Environment(Settings.self) var settings
    let labels = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
    
    var body: some View {
        let settingsCols = settings.overlaySettings.cols
        let settingsRows = settings.overlaySettings.rows
        let cols = getCols(colCount: settingsCols)
        let cellLabels = getCellLabels(colCount: settingsCols, rowCount: settingsRows)
        
        GeometryReader { geometry in
            let cellHeight = geometry.size.height / Double(settingsRows)
            
            LazyVGrid(columns: cols) {
                ForEach(cellLabels, id: \.self) { label in
                    OverlayCellView(label: label, height: cellHeight)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    func getCols(colCount: Int) -> [GridItem] {
        return Array(repeating: GridItem(), count: colCount)
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
