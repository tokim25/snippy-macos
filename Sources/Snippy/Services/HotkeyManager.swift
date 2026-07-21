import AppKit

/// The global hotkey that opens Quick Search. Stored per-Mac in
/// UserDefaults — deliberately not synced via iCloud, since the same combo
/// might already be taken by something else on a different Mac.
final class HotkeyManager: ObservableObject {
    static let defaultKeyCode: UInt16 = 49 // space
    static let defaultModifiers: NSEvent.ModifierFlags = .option

    private static let keyCodeDefaultsKey = "QuickSearchHotkeyKeyCode"
    private static let modifiersDefaultsKey = "QuickSearchHotkeyModifiers"

    @Published private(set) var keyCode: UInt16
    @Published private(set) var modifiers: NSEvent.ModifierFlags

    init() {
        let defaults = UserDefaults.standard
        if let storedKeyCode = defaults.object(forKey: Self.keyCodeDefaultsKey) as? Int,
           let storedModifiers = defaults.object(forKey: Self.modifiersDefaultsKey) as? Int {
            keyCode = UInt16(storedKeyCode)
            modifiers = NSEvent.ModifierFlags(rawValue: UInt(storedModifiers))
        } else {
            keyCode = Self.defaultKeyCode
            modifiers = Self.defaultModifiers
        }
    }

    var isCustomized: Bool {
        keyCode != Self.defaultKeyCode || modifiers != Self.defaultModifiers
    }

    func set(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) {
        self.keyCode = keyCode
        self.modifiers = modifiers.intersection(.deviceIndependentFlagsMask)
        UserDefaults.standard.set(Int(self.keyCode), forKey: Self.keyCodeDefaultsKey)
        UserDefaults.standard.set(Int(self.modifiers.rawValue), forKey: Self.modifiersDefaultsKey)
    }

    func resetToDefault() {
        UserDefaults.standard.removeObject(forKey: Self.keyCodeDefaultsKey)
        UserDefaults.standard.removeObject(forKey: Self.modifiersDefaultsKey)
        keyCode = Self.defaultKeyCode
        modifiers = Self.defaultModifiers
    }

    func matches(_ event: NSEvent) -> Bool {
        event.keyCode == keyCode
            && event.modifierFlags.intersection(.deviceIndependentFlagsMask) == modifiers
    }

    var displayString: String {
        var text = ""
        if modifiers.contains(.control) { text += "⌃" }
        if modifiers.contains(.option) { text += "⌥" }
        if modifiers.contains(.shift) { text += "⇧" }
        if modifiers.contains(.command) { text += "⌘" }
        text += Self.keyName(for: keyCode)
        return text
    }

    private static let specialKeyNames: [UInt16: String] = [
        49: "Space", 36: "Return", 48: "Tab", 53: "Escape", 51: "Delete",
        123: "←", 124: "→", 125: "↓", 126: "↑"
    ]

    private static func keyName(for keyCode: UInt16) -> String {
        if let name = specialKeyNames[keyCode] {
            return name
        }
        if let cgEvent = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(keyCode), keyDown: true),
           let nsEvent = NSEvent(cgEvent: cgEvent),
           let chars = nsEvent.charactersIgnoringModifiers,
           !chars.isEmpty {
            return chars.uppercased()
        }
        return "Key \(keyCode)"
    }
}
