import Foundation

struct AppConfiguration: Codable, Equatable {
    var globalRecognitionShortcut: Shortcut
    var recordToggleShortcut: Shortcut
    var submitShortcut: Shortcut
    var cancelShortcut: Shortcut

    static let `default` = AppConfiguration(
        globalRecognitionShortcut: Shortcut(
            keyCode: 5,
            modifiers: [.option, .shift],
            displayName: "⌥⇧G"
        ),
        recordToggleShortcut: Shortcut.symbolic(displayName: "Fn"),
        submitShortcut: Shortcut(
            keyCode: 36,
            modifiers: [],
            displayName: "Enter"
        ),
        cancelShortcut: Shortcut(
            keyCode: 53,
            modifiers: [],
            displayName: "Esc"
        )
    )
}

struct Shortcut: Codable, Equatable {
    var keyCode: UInt16?
    var modifiers: CarbonModifierFlags
    var displayName: String

    init(keyCode: UInt16?, modifiers: CarbonModifierFlags, displayName: String) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.displayName = displayName
    }

    static func symbolic(displayName: String) -> Shortcut {
        Shortcut(keyCode: nil, modifiers: [], displayName: displayName)
    }
}

struct CarbonModifierFlags: OptionSet, Codable, Equatable {
    let rawValue: UInt32

    static let command = CarbonModifierFlags(rawValue: 1 << 8)
    static let shift = CarbonModifierFlags(rawValue: 1 << 9)
    static let option = CarbonModifierFlags(rawValue: 1 << 11)
    static let control = CarbonModifierFlags(rawValue: 1 << 12)

    init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        rawValue = try container.decode(UInt32.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
