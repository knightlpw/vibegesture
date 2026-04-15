import AppKit

@MainActor
final class StatusItemController: NSObject {
    var onToggleRecognition: (() -> Void)?
    var onOpenSettings: (() -> Void)?
    var onQuit: (() -> Void)?

    private let appState: AppState
    private var statusItem: NSStatusItem?

    init(appState: AppState) {
        self.appState = appState
        super.init()
        appState.onChange = { [weak self] in
            self?.refresh()
        }
    }

    func install() {
        guard statusItem == nil else {
            refresh()
            return
        }

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = statusImage()
        item.button?.imagePosition = .imageOnly
        item.button?.toolTip = "VibeGesture"
        statusItem = item
        refresh()
    }

    private func refresh() {
        guard let statusItem else { return }

        statusItem.button?.image = statusImage()
        statusItem.menu = buildMenu()
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu(title: "VibeGesture")

        let stateItem = NSMenuItem(
            title: "State: \(appState.recognitionState.displayName)",
            action: nil,
            keyEquivalent: ""
        )
        stateItem.isEnabled = false
        menu.addItem(stateItem)

        let gestureItem = NSMenuItem(
            title: "Gesture: \(latestGestureTitle())",
            action: nil,
            keyEquivalent: ""
        )
        gestureItem.isEnabled = false
        menu.addItem(gestureItem)

        let actionItem = NSMenuItem(
            title: "Action: \(appState.latestRecognitionActionIntent.displayName)",
            action: nil,
            keyEquivalent: ""
        )
        actionItem.isEnabled = false
        menu.addItem(actionItem)

        let recordingItem = NSMenuItem(
            title: "Recording: \(appState.isRecordingActive ? "Active" : "Inactive")",
            action: nil,
            keyEquivalent: ""
        )
        recordingItem.isEnabled = false
        menu.addItem(recordingItem)

        let gateItem = NSMenuItem(
            title: "Gate: \(appState.foregroundAppGateState.displayName)",
            action: nil,
            keyEquivalent: ""
        )
        gateItem.isEnabled = false
        menu.addItem(gateItem)

        let keyboardItem = NSMenuItem(
            title: "Keyboard: \(appState.latestKeyboardDispatchResult.displayName)",
            action: nil,
            keyEquivalent: ""
        )
        keyboardItem.isEnabled = false
        menu.addItem(keyboardItem)

        let permissionItem = NSMenuItem(
            title: "Permissions: \(appState.permissionState.displayName)",
            action: nil,
            keyEquivalent: ""
        )
        permissionItem.isEnabled = false
        menu.addItem(permissionItem)

        let liveCameraItem = NSMenuItem(
            title: "Live Camera: \(appState.permissionDiagnostics.cameraAuthorizationStatusDisplayName)",
            action: nil,
            keyEquivalent: ""
        )
        liveCameraItem.isEnabled = false
        menu.addItem(liveCameraItem)

        let liveAccessibilityItem = NSMenuItem(
            title: "Live AX: \(appState.permissionDiagnostics.accessibilityTrustedDisplayName)",
            action: nil,
            keyEquivalent: ""
        )
        liveAccessibilityItem.isEnabled = false
        menu.addItem(liveAccessibilityItem)

        let pipelineItem = NSMenuItem(
            title: "Camera: \(appState.cameraPipelineState.displayName)",
            action: nil,
            keyEquivalent: ""
        )
        pipelineItem.isEnabled = false
        menu.addItem(pipelineItem)

        let toggleItem = NSMenuItem(
            title: recognitionToggleTitle(),
            action: #selector(handleToggleRecognition(_:)),
            keyEquivalent: ""
        )
        toggleItem.target = self
        menu.addItem(toggleItem)

        menu.addItem(.separator())

        let settingsItem = NSMenuItem(
            title: "Settings…",
            action: #selector(handleOpenSettings(_:)),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit VibeGesture",
            action: #selector(handleQuit(_:)),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    private func statusImage() -> NSImage? {
        let symbolName = !appState.permissionState.isReady || !appState.foregroundAppGateState.isSupported
            ? "exclamationmark.triangle.fill"
            : appState.recognitionState.menuBarSymbolName
        let image = NSImage(
            systemSymbolName: symbolName,
            accessibilityDescription: "VibeGesture"
        )
        image?.isTemplate = true
        let configuration = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        return image?.withSymbolConfiguration(configuration) ?? image
    }

    private func recognitionToggleTitle() -> String {
        guard appState.permissionState.isReady else {
            return "Recognition Locked"
        }

        return appState.recognitionState.toggleMenuTitle
    }

    private func latestGestureTitle() -> String {
        appState.latestGestureInterpretation?.displayText ?? "Waiting for a stable gesture"
    }

    @objc private func handleToggleRecognition(_ sender: Any?) {
        onToggleRecognition?()
    }

    @objc private func handleOpenSettings(_ sender: Any?) {
        onOpenSettings?()
    }

    @objc private func handleQuit(_ sender: Any?) {
        onQuit?()
    }
}
