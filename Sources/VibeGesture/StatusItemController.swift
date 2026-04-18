import AppKit

@MainActor
final class StatusItemController: NSObject {
    var onToggleRecognition: (() -> Void)?
    var onOpenSettings: (() -> Void)?
    var onQuit: (() -> Void)?

    private let appState: AppState
    private var statusItem: NSStatusItem?
    private let menu = NSMenu(title: "VibeGesture")
    private let stateItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let gestureCandidateItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let gesturePoseItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let actionItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let runtimeModeItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let recordingItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let gateItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let keyboardItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let permissionItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let pipelineItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let toggleItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let settingsItem = NSMenuItem(title: "", action: nil, keyEquivalent: ",")
    private let quitItem = NSMenuItem(title: "", action: nil, keyEquivalent: "q")
    private var menuConfigured = false

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

        configureMenuIfNeeded()
        item.menu = menu
        refresh()
    }

    func menuSnapshot() -> [String] {
        [
            "State: \(appState.recognitionState.displayName)",
            "Gesture candidate: \(gestureCandidateTitle())",
            "Gesture pose: \(gesturePoseTitle())",
            "Recent action: \(appState.latestRecognitionActionIntent.displayName)",
            "Runtime: Rules mode",
            "Recording: \(appState.isRecordingActive ? "Active" : "Inactive")",
            "Gate: \(appState.foregroundAppGateState.displayName)",
            "Keyboard: \(appState.latestKeyboardDispatchResult.displayName)",
            "Permissions: \(appState.permissionState.displayName)",
            "Camera: \(appState.cameraPipelineState.displayName)",
            recognitionToggleTitle(),
            "Settings…",
            "Quit VibeGesture"
        ]
    }

    private func refresh() {
        guard let statusItem else { return }

        configureMenuIfNeeded()
        updateMenuTitles()
        statusItem.button?.image = statusImage()
    }

    private func configureMenuIfNeeded() {
        guard !menuConfigured else { return }

        menu.autoenablesItems = false

        stateItem.isEnabled = false
        gestureCandidateItem.isEnabled = false
        gesturePoseItem.isEnabled = false
        actionItem.isEnabled = false
        runtimeModeItem.isEnabled = false
        recordingItem.isEnabled = false
        gateItem.isEnabled = false
        keyboardItem.isEnabled = false
        permissionItem.isEnabled = false
        pipelineItem.isEnabled = false

        toggleItem.action = #selector(handleToggleRecognition(_:))
        toggleItem.target = self
        settingsItem.action = #selector(handleOpenSettings(_:))
        settingsItem.target = self
        quitItem.action = #selector(handleQuit(_:))
        quitItem.target = self

        menu.addItem(stateItem)
        menu.addItem(gestureCandidateItem)
        menu.addItem(gesturePoseItem)
        menu.addItem(actionItem)
        menu.addItem(runtimeModeItem)
        menu.addItem(recordingItem)
        menu.addItem(gateItem)
        menu.addItem(keyboardItem)
        menu.addItem(permissionItem)
        menu.addItem(pipelineItem)
        menu.addItem(toggleItem)
        menu.addItem(.separator())
        menu.addItem(settingsItem)
        menu.addItem(.separator())
        menu.addItem(quitItem)

        menuConfigured = true
    }

    private func updateMenuTitles() {
        stateItem.title = "State: \(appState.recognitionState.displayName)"
        gestureCandidateItem.title = "Gesture candidate: \(gestureCandidateTitle())"
        gesturePoseItem.title = "Gesture pose: \(gesturePoseTitle())"
        actionItem.title = "Recent action: \(appState.latestRecognitionActionIntent.displayName)"
        runtimeModeItem.title = "Runtime: Rules mode"
        recordingItem.title = "Recording: \(appState.isRecordingActive ? "Active" : "Inactive")"
        gateItem.title = "Gate: \(appState.foregroundAppGateState.displayName)"
        keyboardItem.title = "Keyboard: \(appState.latestKeyboardDispatchResult.displayName)"
        permissionItem.title = "Permissions: \(appState.permissionState.displayName)"
        pipelineItem.title = "Camera: \(appState.cameraPipelineState.displayName)"
        toggleItem.title = recognitionToggleTitle()
        settingsItem.title = "Settings…"
        quitItem.title = "Quit VibeGesture"
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

    private func gestureCandidateTitle() -> String {
        appState.latestGestureInterpretation?.candidateDisplayName ?? "Waiting for a stable gesture"
    }

    private func gesturePoseTitle() -> String {
        appState.latestGestureInterpretation?.poseSummary ?? "Waiting for a stable gesture"
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
