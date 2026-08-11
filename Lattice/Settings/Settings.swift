import Foundation

struct OverlaySettings: Codable, Equatable {
    /// Cell selection types one letter per cell (see the cell-selection story), and there
    /// are 26 letters, so 26 cells is the hard ceiling. Anything larger would need
    /// multi-key labels, which changes the selection story and is deliberately out of
    /// scope here. Both sides are additionally kept at 1 or more.
    static let maxCells = 26
    static let minSide = 1

    static let `default` = OverlaySettings(rows: 3, cols: 4)

    var rows: Int
    var cols: Int

    var cellCount: Int { rows * cols }

    /// The largest a side may grow to while the other side stays as it is.
    static func maxSide(given otherSide: Int) -> Int {
        max(minSide, maxCells / max(otherSide, minSide))
    }

    /// Clamps a grid that came from outside (a stored value, a hand-edited default) into
    /// the supported range instead of rejecting it.
    func normalized() -> OverlaySettings {
        let cols = min(max(self.cols, Self.minSide), Self.maxCells)
        let rows = min(max(self.rows, Self.minSide), Self.maxSide(given: cols))
        return OverlaySettings(rows: rows, cols: cols)
    }
}

struct HotKeySettings: Codable, Equatable {
    static let `default` = HotKeySettings(current: .default)

    var current: HotKey
}

/// The whole persisted record. Stored and versioned as one unit.
struct SettingsData: Codable, Equatable {
    static let `default` = SettingsData(overlay: .default, hotKey: .default)

    var overlay: OverlaySettings
    var hotKey: HotKeySettings

    func normalized() -> SettingsData {
        SettingsData(overlay: overlay.normalized(), hotKey: hotKey)
    }
}

@Observable
final class Settings {
    private let store: SettingsStore

    /// Mutations go through the methods below so that every change is persisted and
    /// validated in exactly one place.
    private(set) var overlaySettings: OverlaySettings
    private(set) var hotKeySettings: HotKeySettings

    init(store: SettingsStore = SettingsStore()) {
        self.store = store

        let stored = store.load()
        overlaySettings = stored.overlay
        hotKeySettings = stored.hotKey
    }

    func setGrid(rows: Int, cols: Int) {
        overlaySettings = OverlaySettings(rows: rows, cols: cols).normalized()
        persist()
    }

    func setHotKey(_ hotKey: HotKey) {
        hotKeySettings = HotKeySettings(current: hotKey)
        persist()
    }

    func resetToDefaults() {
        overlaySettings = .default
        hotKeySettings = .default
        persist()
    }

    private func persist() {
        store.save(SettingsData(overlay: overlaySettings, hotKey: hotKeySettings))
    }
}
