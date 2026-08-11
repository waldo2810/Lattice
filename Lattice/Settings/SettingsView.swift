import SwiftUI

struct SettingsView: View {
    let settings: Settings
    let hotKeyBinder: HotKeyBinder

    @State private var hotKeyError: String?

    var body: some View {
        let grid = settings.overlaySettings

        Form {
            Section("Grid") {
                Stepper(value: rowsBinding, in: OverlaySettings.minSide...OverlaySettings.maxSide(given: grid.cols)) {
                    LabeledContent("Rows", value: "\(grid.rows)")
                }
                Stepper(value: colsBinding, in: OverlaySettings.minSide...OverlaySettings.maxSide(given: grid.rows)) {
                    LabeledContent("Columns", value: "\(grid.cols)")
                }
                Text("\(grid.rows) × \(grid.cols) = \(grid.cellCount) cells. Up to \(OverlaySettings.maxCells): each cell is picked by its own letter, A–Z. The overlay uses the new grid the next time it opens.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Shortcut") {
                HotKeyRecorder(hotKey: settings.hotKeySettings.current, onRecord: apply)

                if let hotKeyError {
                    Text(hotKeyError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section {
                Button("Reset to Defaults", action: resetToDefaults)
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
    }

    private var rowsBinding: Binding<Int> {
        Binding(
            get: { settings.overlaySettings.rows },
            set: { settings.setGrid(rows: $0, cols: settings.overlaySettings.cols) }
        )
    }

    private var colsBinding: Binding<Int> {
        Binding(
            get: { settings.overlaySettings.cols },
            set: { settings.setGrid(rows: settings.overlaySettings.rows, cols: $0) }
        )
    }

    /// Only stores a shortcut that the system actually accepted, so what Settings shows
    /// and what is registered can never drift apart.
    private func apply(_ hotKey: HotKey) {
        guard hotKeyBinder.bind(hotKey) else {
            hotKeyError = "\(hotKey.displayString) is already used by macOS or another app. Keeping \(settings.hotKeySettings.current.displayString)."
            if let kept = hotKeyBinder.current {
                settings.setHotKey(kept)
            }
            return
        }

        hotKeyError = nil
        settings.setHotKey(hotKey)
    }

    private func resetToDefaults() {
        settings.resetToDefaults()
        apply(.default)
    }
}
