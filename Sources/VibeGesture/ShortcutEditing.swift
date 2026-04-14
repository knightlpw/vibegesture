import AppKit
import Carbon
import SwiftUI

enum ShortcutCaptureFormatter {
    private static let ignoredModifierKeyCodes: Set<UInt16> = [54, 55, 56, 57, 58, 59, 60, 61, 62]

    private static let specialKeyNames: [UInt16: String] = [
        36: "Enter",
        48: "Tab",
        49: "Space",
        51: "Delete",
        53: "Esc",
        63: "Fn",
        96: "F5",
        97: "F6",
        98: "F7",
        99: "F3",
        100: "F8",
        101: "F9",
        103: "F11",
        105: "F13",
        106: "F16",
        107: "F14",
        109: "F10",
        111: "F12",
        113: "F15",
        118: "F4",
        120: "F2",
        122: "F1",
        123: "←",
        124: "→",
        125: "↓",
        126: "↑"
    ]

    static func shortcut(from event: NSEvent) -> Shortcut? {
        let keyCode = event.keyCode
        guard !ignoredModifierKeyCodes.contains(keyCode) else {
            return nil
        }

        let modifiers = CarbonModifierFlags(eventModifierFlags: event.modifierFlags)
        let displayName = displayName(
            keyCode: keyCode,
            characters: event.charactersIgnoringModifiers,
            modifiers: modifiers
        )
        return Shortcut(
            keyCode: keyCode,
            modifiers: modifiers,
            displayName: displayName
        )
    }

    static func displayName(for shortcut: Shortcut) -> String {
        guard let keyCode = shortcut.keyCode else {
            return shortcut.displayName
        }

        return displayName(
            keyCode: keyCode,
            characters: nil,
            modifiers: shortcut.modifiers
        )
    }

    private static func displayName(
        keyCode: UInt16,
        characters: String?,
        modifiers: CarbonModifierFlags
    ) -> String {
        let modifierPrefix = modifierPrefix(for: modifiers)
        let keyName = keyName(for: keyCode, characters: characters)
        return modifierPrefix + keyName
    }

    private static func modifierPrefix(for modifiers: CarbonModifierFlags) -> String {
        var parts: [String] = []

        if modifiers.contains(.command) {
            parts.append("⌘")
        }
        if modifiers.contains(.shift) {
            parts.append("⇧")
        }
        if modifiers.contains(.option) {
            parts.append("⌥")
        }
        if modifiers.contains(.control) {
            parts.append("⌃")
        }

        return parts.joined()
    }

    private static func keyName(for keyCode: UInt16, characters: String?) -> String {
        if let specialKeyName = specialKeyNames[keyCode] {
            return specialKeyName
        }

        if let characters,
           let firstCharacter = characters.first,
           !firstCharacter.isNewline,
           !firstCharacter.isWhitespace {
            return String(firstCharacter).uppercased()
        }

        return "Key \(keyCode)"
    }
}

private extension CarbonModifierFlags {
    init(eventModifierFlags: NSEvent.ModifierFlags) {
        var flags: CarbonModifierFlags = []

        if eventModifierFlags.contains(.command) {
            flags.insert(.command)
        }
        if eventModifierFlags.contains(.shift) {
            flags.insert(.shift)
        }
        if eventModifierFlags.contains(.option) {
            flags.insert(.option)
        }
        if eventModifierFlags.contains(.control) {
            flags.insert(.control)
        }

        self = flags
    }
}

struct ShortcutCaptureHost: NSViewRepresentable {
    var isActive: Bool
    var onCapture: (Shortcut) -> Void

    func makeNSView(context: Context) -> ShortcutCaptureNSView {
        let view = ShortcutCaptureNSView()
        view.onCapture = onCapture
        view.isActive = isActive
        return view
    }

    func updateNSView(_ nsView: ShortcutCaptureNSView, context: Context) {
        nsView.onCapture = onCapture
        nsView.isActive = isActive
        if isActive {
            nsView.requestFocus()
        }
    }
}

final class ShortcutCaptureNSView: NSView {
    var onCapture: ((Shortcut) -> Void)?
    var isActive = false {
        didSet {
            if isActive {
                requestFocus()
            }
        }
    }

    override var acceptsFirstResponder: Bool {
        true
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if isActive {
            requestFocus()
        }
    }

    override func keyDown(with event: NSEvent) {
        guard isActive else {
            super.keyDown(with: event)
            return
        }

        guard !event.isARepeat else {
            return
        }

        guard let shortcut = ShortcutCaptureFormatter.shortcut(from: event) else {
            NSSound.beep()
            return
        }

        onCapture?(shortcut)
    }

    func requestFocus() {
        DispatchQueue.main.async { [weak self] in
            guard let self, self.isActive else {
                return
            }

            self.window?.makeFirstResponder(self)
        }
    }
}

struct ShortcutEditorRow: View {
    let title: String
    let subtitle: String
    let shortcut: Binding<Shortcut>
    let isEditing: Bool
    let validationMessage: String?
    let onStartEditing: () -> Void
    let onCancelEditing: () -> Void
    let onCaptured: (Shortcut) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 12)

                shortcutBadge

                Button(isEditing ? "Cancel" : "Rebind") {
                    if isEditing {
                        onCancelEditing()
                    } else {
                        onStartEditing()
                    }
                }
            }

            if isEditing {
                ShortcutCaptureHost(isActive: true) { captured in
                    onCaptured(captured)
                }
                .frame(width: 1, height: 1)
                .accessibilityHidden(true)

                Text("Press the new shortcut, or click Cancel to stop.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let validationMessage {
                    Text(validationMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.35))
        )
    }

    private var shortcutBadge: some View {
        Text(shortcut.wrappedValue.displayName)
            .font(.callout.weight(.medium))
            .monospaced()
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(Color(nsColor: .windowBackgroundColor))
            )
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(Color.secondary.opacity(0.25), lineWidth: 1)
            )
    }
}
