import Cocoa

struct OverlaySettings {
    var rows: Int
    var cols: Int
}

struct HotKeySettings {
    var current: HotKey
}

// Deployment floor: `@Observable` (Observation framework) requires macOS 14.0.
// It is one of the APIs that pins MACOSX_DEPLOYMENT_TARGET to 14.0.
// See docs/user-stories/minimum-macos-version.md.
@Observable
final class Settings {
    var overlaySettings: OverlaySettings
    var hotKeySettings: HotKeySettings
    
    init() {
        let overlaySettings = OverlaySettings(rows: 3, cols: 4)
        let hotKeySettings = HotKeySettings(current: HotKey(carbonKey: .space, carbonModifiers: [.control, .option]))
        
        self.overlaySettings = overlaySettings
        self.hotKeySettings = hotKeySettings
    }
}
