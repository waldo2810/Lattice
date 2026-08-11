import Foundation

/// Settings are persisted in `UserDefaults` rather than a JSON file in Application Support.
///
/// Why `UserDefaults`: the record is tiny (two grid dimensions, one key code, one modifier
/// list), it is rewritten from the main thread on every edit, and `UserDefaults` already
/// gives us atomic writes, no half-written files, no directory creation and no I/O error
/// paths of our own to invent. A file would only start paying for itself once users are
/// expected to inspect, diff or hand-edit it, which is not the case for four values. The
/// record is stored as a single JSON blob under one key so the whole thing can be
/// versioned and migrated as a unit if the shape ever changes.
///
/// A missing key (first run) or a blob that no longer decodes (corrupt store, a shape
/// from a future build) both fall back to `SettingsData.default` rather than failing;
/// a store that decodes but holds out-of-range values is clamped by `normalized()`.
struct SettingsStore {
    static let key = "co.waasabi.Lattice.settings"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> SettingsData {
        guard let data = defaults.data(forKey: Self.key) else {
            return .default
        }

        do {
            return try JSONDecoder().decode(SettingsData.self, from: data).normalized()
        } catch {
            Log.error("Stored settings could not be read, falling back to defaults: \(error)")
            return .default
        }
    }

    func save(_ settings: SettingsData) {
        do {
            defaults.set(try JSONEncoder().encode(settings), forKey: Self.key)
        } catch {
            Log.error("Settings could not be saved: \(error)")
        }
    }
}
