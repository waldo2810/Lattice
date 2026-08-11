import AppKit
import SwiftUI

struct SettingsView: View {
    let settings: Settings
    let hotKeyBinder: HotKeyBinder

    @State private var hotKeyError: String?
    /// Owned by the view because it holds no persisted state of its own — it is a live
    /// window onto `SMAppService`, re-read every time this form is shown.
    @State private var launchAtLogin = LaunchAtLogin()

    var body: some View {
        let grid = settings.overlaySettings

        Form {
            Section("Startup") {
                Toggle("Launch at Login", isOn: launchAtLoginBinding)

                if let warning = launchAtLogin.locationWarning {
                    notice(warning, color: .orange)
                }

                if let failure = launchAtLogin.failure {
                    notice(failure, color: .red)
                }

                if let approvalNotice = launchAtLogin.approvalNotice {
                    notice(approvalNotice, color: .orange)
                }
            }

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
        .onAppear(perform: launchAtLogin.refresh)
        // The login item can be removed in System Settings while this window sits open,
        // so re-read the real status every time the window comes back to the front.
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            launchAtLogin.refresh()
        }
    }

    private func notice(_ message: String, color: Color) -> some View {
        Text(message)
            .font(.caption)
            .foregroundStyle(color)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { launchAtLogin.isEnabled },
            // `setEnabled` re-reads the system status, so a failed registration puts the
            // toggle straight back where it was instead of showing a state that is not real.
            set: { launchAtLogin.setEnabled($0) }
        )
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
