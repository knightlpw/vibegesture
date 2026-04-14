import AppKit

@MainActor
final class AppCoordinator: SafeShutdownHandling {
    private let configurationStore = ConfigurationStore()
    private let permissionManager = PermissionManager()
    private let recognitionCoordinator = RecognitionCoordinator()
    private let cameraPipelineController: CameraPipelineControlling
    private let appState: AppState
    private let statusItemController: StatusItemController
    private let settingsWindowController: SettingsWindowController
    private let hotKeyManager = GlobalHotKeyManager()
    private var activationObserver: NSObjectProtocol?

    init() {
        let configuration = configurationStore.load()
        let appState = AppState(configuration: configuration)
        self.appState = appState
        self.cameraPipelineController = CameraPipelineController()
        self.statusItemController = StatusItemController(appState: appState)
        self.settingsWindowController = SettingsWindowController(
            appState: appState,
            onOpenSystemSettings: {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:")!)
            }
        )

        cameraPipelineController.onStateChange = { [weak self] state in
            self?.appState.cameraPipelineState = state

            if case .failed = state,
               let currentRecognitionState = self?.appState.recognitionState,
               currentRecognitionState != .disabled,
               currentRecognitionState != .errorPermissionMissing {
                if let transition = self?.recognitionCoordinator.setRecognitionEnabled(
                    false,
                    permissionState: self?.appState.permissionState ?? .missingBoth
                ) {
                    self?.applyRecognitionTransition(transition)
                }
            }
        }
        cameraPipelineController.onObservation = { [weak self] observation in
            self?.appState.latestCameraFrameObservation = observation
            if let transition = self?.recognitionCoordinator.process(frameObservation: observation) {
                self?.applyRecognitionTransition(transition)
            }
        }

        statusItemController.onToggleRecognition = { [weak self] in
            self?.toggleRecognition()
        }
        statusItemController.onOpenSettings = { [weak self] in
            self?.showSettings()
        }
        statusItemController.onQuit = { [weak self] in
            self?.terminate()
        }
    }

    func start() {
        if !configurationStore.hasStoredConfiguration {
            do {
                try configurationStore.save(appState.configuration)
            } catch {
                print("Failed to create initial configuration file: \(error)")
            }
        }

        refreshPermissionState()
        activationObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshPermissionState()
            }
        }

        statusItemController.install()
        registerRecognitionHotKey()
    }

    private func registerRecognitionHotKey() {
        let shortcut = appState.configuration.globalRecognitionShortcut
        hotKeyManager.register(shortcut: shortcut) { [weak self] in
            self?.toggleRecognition()
        }
    }

    private func toggleRecognition() {
        let shouldEnable = appState.recognitionState == .disabled || appState.recognitionState == .errorPermissionMissing
        let transition = recognitionCoordinator.setRecognitionEnabled(
            shouldEnable,
            permissionState: appState.permissionState
        )
        applyRecognitionTransition(transition)
    }

    private func refreshPermissionState() {
        let newState = permissionManager.refresh()
        appState.permissionState = newState

        let transition = recognitionCoordinator.updatePermissionState(newState)
        applyRecognitionTransition(transition)
    }

    private func showSettings() {
        settingsWindowController.showWindow()
    }

    private func terminate() {
        cameraPipelineController.stop()
        do {
            try configurationStore.save(appState.configuration)
        } catch {
            print("Failed to save configuration before quit: \(error)")
        }
        if let activationObserver {
            NotificationCenter.default.removeObserver(activationObserver)
            self.activationObserver = nil
        }
        NSApp.terminate(nil)
    }

    func requestSafeShutdown(reason: SafeShutdownReason) {
        print("Safe shutdown requested: \(reason.rawValue)")
        cameraPipelineController.stop()
    }

    private func applyRecognitionTransition(_ transition: RecognitionTransition) {
        appState.recognitionState = transition.state

        if let gestureInterpretation = transition.gestureInterpretation {
            appState.latestGestureInterpretation = gestureInterpretation
        }

        if transition.actionIntent.isAction {
            appState.latestRecognitionActionIntent = transition.actionIntent
        }

        if transition.shouldStopCamera {
            cameraPipelineController.stop()
        }

        if transition.shouldStartCamera {
            cameraPipelineController.start()
        }
    }
}
