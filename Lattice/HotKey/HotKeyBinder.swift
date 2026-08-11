import Foundation

/// Owns the single global shortcut that opens the overlay.
///
/// Everything that changes the shortcut goes through `bind`, which releases the previous
/// registration before claiming the new one — `RegisterEventHotKey` refuses a combination
/// that is still held, including one we hold ourselves. If the new combination is refused
/// the previous one is put back, so the app is never left with no shortcut at all.
final class HotKeyBinder {
    private let manager: HotKeyManager
    private let action: () -> Void
    private var currentId: UInt32?

    /// The shortcut currently registered with the system, or `nil` if none is.
    private(set) var current: HotKey?

    init(manager: HotKeyManager, action: @escaping () -> Void) {
        self.manager = manager
        self.action = action
    }

    /// Returns `true` when `hotKey` is live. On `false` the previous shortcut (if any)
    /// is still live and `current` is unchanged.
    @discardableResult
    func bind(_ hotKey: HotKey) -> Bool {
        let previous = current

        if let currentId {
            manager.unregister(id: currentId)
            self.currentId = nil
            current = nil
        }

        if let id = manager.register(hotKey: hotKey, action: action) {
            currentId = id
            current = hotKey
            return true
        }

        if let previous, let id = manager.register(hotKey: previous, action: action) {
            currentId = id
            current = previous
        } else if previous != nil {
            Log.error("Lost the previous shortcut while restoring it; no shortcut is registered.")
        }

        return false
    }
}
