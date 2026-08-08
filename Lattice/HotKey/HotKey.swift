import Carbon.HIToolbox

struct HotKey {
    let carbonKey: Key
    let carbonModifiers: [Modifier]
}

public struct Key {
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
}

struct Modifier {
    public let value: Int
    
    public init(value: Int) {
        self.value = value
    }
    
    static let cmd = Self(value: cmdKey)
    static let option = Self(value: optionKey)
    static let control = Self(value: controlKey)
}
