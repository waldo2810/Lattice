import AppKit
import Carbon.HIToolbox
import SwiftUI

/// Captures a shortcut by listening with a *local* `NSEvent` monitor while recording.
///
/// A local monitor only sees events already delivered to this app's key window, so it
/// needs no Input Monitoring permission — that is only required for the global monitor
/// variant, which we do not use. The monitor returns `nil` while recording so the keys
/// being recorded do not also trigger menu items or text editing.
struct HotKeyRecorder: View {
    let hotKey: HotKey
    let onRecord: (HotKey) -> Void

    @State private var monitor: Any?
    @State private var hint: String?

    private var isRecording: Bool { monitor != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            LabeledContent("Shortcut") {
                Button(isRecording ? "Press a shortcut…" : hotKey.displayString) {
                    isRecording ? stop() : start()
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Record shortcut, currently \(hotKey.displayString)")
            }

            if let hint {
                Text(hint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .onDisappear(perform: stop)
    }

    private func start() {
        guard monitor == nil else { return }

        hint = "Hold at least one modifier (⌃ ⌥ ⇧ ⌘) and press a key. Escape cancels."
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            handle(event)
            return nil
        }
    }

    private func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
        hint = nil
    }

    private func handle(_ event: NSEvent) {
        guard event.keyCode != UInt16(kVK_Escape) else {
            stop()
            return
        }

        let recorded = HotKey(
            carbonKey: Key(value: Int(event.keyCode)),
            carbonModifiers: Modifier.from(event.modifierFlags)
        )

        // Keep listening until the user produces something registrable.
        guard recorded.isValid else {
            hint = "\(recorded.carbonKey.displayName) on its own would capture that key everywhere. Add ⌃, ⌥, ⇧ or ⌘."
            return
        }

        stop()
        onRecord(recorded)
    }
}
