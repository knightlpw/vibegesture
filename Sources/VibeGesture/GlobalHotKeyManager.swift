import AppKit
import Carbon

final class GlobalHotKeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var callback: (() -> Void)?

    deinit {
        unregister()
    }

    func register(shortcut: Shortcut, action: @escaping () -> Void) {
        callback = action
        unregister()

        guard let keyCode = shortcut.keyCode else {
            print("Global hot key registration skipped for symbolic shortcut: \(shortcut.displayName)")
            return
        }

        installEventHandlerIfNeeded()

        let hotKeyID = EventHotKeyID(signature: OSType(0x56494745), id: 1)
        let status = RegisterEventHotKey(
            UInt32(keyCode),
            shortcut.modifiers.rawValue,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if status != noErr {
            print("Failed to register global hot key \(shortcut.displayName): \(status)")
        }
    }

    private func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }

    private func installEventHandlerIfNeeded() {
        guard eventHandlerRef == nil else {
            return
        }

        var eventType = EventTypeSpec(
            eventClass: UInt32(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let userData = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        InstallEventHandler(
            GetApplicationEventTarget(),
            hotKeyEventHandler,
            1,
            &eventType,
            userData,
            &eventHandlerRef
        )
    }

    fileprivate func handleHotKeyPress() {
        callback?()
    }
}

private let hotKeyEventHandler: EventHandlerUPP = { _, _, userData in
    guard let userData else {
        return noErr
    }

    let manager = Unmanaged<GlobalHotKeyManager>.fromOpaque(userData).takeUnretainedValue()
    manager.handleHotKeyPress()
    return noErr
}
