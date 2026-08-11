import AppKit
import Carbon.HIToolbox

struct HotKey: Codable, Equatable, Hashable {
    let carbonKey: Key
    let carbonModifiers: [Modifier]

    init(carbonKey: Key, carbonModifiers: [Modifier]) {
        self.carbonKey = carbonKey
        // Canonical order and no duplicates, so two equal shortcuts always compare equal
        // and always render their symbols in the order macOS uses.
        self.carbonModifiers = Modifier.displayOrder.filter { carbonModifiers.contains($0) }
    }

    static let `default` = HotKey(carbonKey: .space, carbonModifiers: [.control, .option])

    /// A shortcut with no modifier would swallow a plain keystroke system-wide.
    var isValid: Bool { !carbonModifiers.isEmpty }

    /// The shortcut as macOS writes it, e.g. `⌃⌥Space`.
    var displayString: String {
        carbonModifiers.map(\.symbol).joined() + carbonKey.displayName
    }
}

public struct Key: Codable, Equatable, Hashable {
    public let value: Int

    public init(value: Int) {
        self.value = value
    }

    private init(_ value: Int) {
        self.init(value: value)
    }

    static let a = Self(kVK_ANSI_A)
    static let t = Self(kVK_ANSI_T)
    static let space = Self(kVK_Space)

    var displayName: String { Self.names[value] ?? "Key \(value)" }

    private static let names: [Int: String] = [
        kVK_ANSI_A: "A", kVK_ANSI_B: "B", kVK_ANSI_C: "C", kVK_ANSI_D: "D",
        kVK_ANSI_E: "E", kVK_ANSI_F: "F", kVK_ANSI_G: "G", kVK_ANSI_H: "H",
        kVK_ANSI_I: "I", kVK_ANSI_J: "J", kVK_ANSI_K: "K", kVK_ANSI_L: "L",
        kVK_ANSI_M: "M", kVK_ANSI_N: "N", kVK_ANSI_O: "O", kVK_ANSI_P: "P",
        kVK_ANSI_Q: "Q", kVK_ANSI_R: "R", kVK_ANSI_S: "S", kVK_ANSI_T: "T",
        kVK_ANSI_U: "U", kVK_ANSI_V: "V", kVK_ANSI_W: "W", kVK_ANSI_X: "X",
        kVK_ANSI_Y: "Y", kVK_ANSI_Z: "Z",
        kVK_ANSI_0: "0", kVK_ANSI_1: "1", kVK_ANSI_2: "2", kVK_ANSI_3: "3",
        kVK_ANSI_4: "4", kVK_ANSI_5: "5", kVK_ANSI_6: "6", kVK_ANSI_7: "7",
        kVK_ANSI_8: "8", kVK_ANSI_9: "9",
        kVK_ANSI_Minus: "-", kVK_ANSI_Equal: "=",
        kVK_ANSI_LeftBracket: "[", kVK_ANSI_RightBracket: "]",
        kVK_ANSI_Backslash: "\\", kVK_ANSI_Semicolon: ";", kVK_ANSI_Quote: "'",
        kVK_ANSI_Comma: ",", kVK_ANSI_Period: ".", kVK_ANSI_Slash: "/",
        kVK_ANSI_Grave: "`",
        kVK_Space: "Space", kVK_Return: "↩", kVK_Tab: "⇥", kVK_Delete: "⌫",
        kVK_ForwardDelete: "⌦", kVK_Escape: "⎋", kVK_Home: "↖", kVK_End: "↘",
        kVK_PageUp: "⇞", kVK_PageDown: "⇟",
        kVK_LeftArrow: "←", kVK_RightArrow: "→", kVK_UpArrow: "↑", kVK_DownArrow: "↓",
        kVK_F1: "F1", kVK_F2: "F2", kVK_F3: "F3", kVK_F4: "F4", kVK_F5: "F5",
        kVK_F6: "F6", kVK_F7: "F7", kVK_F8: "F8", kVK_F9: "F9", kVK_F10: "F10",
        kVK_F11: "F11", kVK_F12: "F12",
    ]
}

struct Modifier: Codable, Equatable, Hashable {
    public let value: Int

    public init(value: Int) {
        self.value = value
    }

    static let cmd = Self(value: cmdKey)
    static let option = Self(value: optionKey)
    static let control = Self(value: controlKey)
    static let shift = Self(value: shiftKey)

    /// The order macOS renders modifier symbols in.
    static let displayOrder: [Modifier] = [.control, .option, .shift, .cmd]

    var symbol: String {
        switch value {
        case controlKey: "⌃"
        case optionKey: "⌥"
        case shiftKey: "⇧"
        case cmdKey: "⌘"
        default: ""
        }
    }

    /// Translates the AppKit modifier flags of a recorded event into Carbon modifiers.
    static func from(_ flags: NSEvent.ModifierFlags) -> [Modifier] {
        var modifiers: [Modifier] = []
        if flags.contains(.control) { modifiers.append(.control) }
        if flags.contains(.option) { modifiers.append(.option) }
        if flags.contains(.shift) { modifiers.append(.shift) }
        if flags.contains(.command) { modifiers.append(.cmd) }
        return modifiers
    }
}
