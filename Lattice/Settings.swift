import Cocoa

struct OverlaySettings {
    var rows: Int
    var cols: Int
}

struct HotKeySettings {
    var current: HotKey
}

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
