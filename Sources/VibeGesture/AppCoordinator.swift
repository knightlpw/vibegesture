import AppKit

@MainActor
final class AppCoordinator: SafeShutdownHandling {
    private let configurationStore = ConfigurationStore()
    private let permissionManager = PermissionManager()
    private let recognitionCoordinator = RecognitionCoordinator()
    private let keyboardDispatcher = KeyboardDispatcher()
    private let foregroundAppGateMonitor = ForegroundAppGateMonitor()
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
        keyboardDispatcher.onResultChange = { [weak self] result in
            self?.appState.latestKeyboardDispatchResult = result
        }
        foregroundAppGateMonitor.onStateChange = { [weak self] state in
            self?.handleForegroundAppGateChange(state)
        }

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
                    self?.performSafeShutdown(stopRecording: self?.appState.isRecordingActive ?? false)
                }
            }
        }
        cameraPipelineController.onObservation = { [weak self] observation in
            self?.appState.latestCameraFrameObservation = observation
            guard self?.appState.foregroundAppGateState.isSupported == true else {
                return
            }
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

        foregroundAppGateMonitor.startObserving()
        refreshPermissionState()
        activationObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.foregroundAppGateMonitor.refresh()
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

        if !shouldEnable {
            performSafeShutdown(stopRecording: appState.isRecordingActive)
        }
    }

    private func refreshPermissionState() {
        let newState = permissionManager.refresh()
        appState.permissionState = newState

        let transition = recognitionCoordinator.updatePermissionState(newState)
        applyRecognitionTransition(transition)

        if !newState.isReady {
            performSafeShutdown(stopRecording: appState.isRecordingActive)
        }
    }

    private func showSettings() {
        settingsWindowController.showWindow()
    }

    private func terminate() {
        performSafeShutdown(stopRecording: appState.isRecordingActive)
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
        foregroundAppGateMonitor.stopObserving()
        NSApp.terminate(nil)
    }

    func requestSafeShutdown(reason: SafeShutdownReason) {
        print("Safe shutdown requested: \(reason.rawValue)")
        performSafeShutdown(stopRecording: appState.isRecordingActive)
        cameraPipelineController.stop()
    }

    private func applyRecognitionTransition(_ transition: RecognitionTransition) {
        appState.recognitionState = transition.state

        if let gestureInterpretation = transition.gestureInterpretation {
            appState.latestGestureInterpretation = gestureInterpretation
        }

        if transition.actionIntent.isAction {
            appState.latestRecognitionActionIntent = transition.actionIntent
            keyboardDispatcher.dispatch(
                intent: transition.actionIntent,
                configuration: appState.configuration
            )
        } else if transition.gestureInterpretation?.candidate == .cancelStarted,
                  keyboardDispatcher.hasPendingSubmit {
            keyboardDispatcher.dispatch(
                intent: .cancel(stopRecordingFirst: false),
                configuration: appState.configuration
            )
        }

        appState.isRecordingActive = transition.recordingActive

        if transition.shouldStopCamera {
            cameraPipelineController.stop()
        }

        if transition.shouldStartCamera {
            cameraPipelineController.start()
        }
    }

    private func performSafeShutdown(stopRecording: Bool) {
        keyboardDispatcher.performSafeShutdown(
            stopRecording: stopRecording,
            configuration: appState.configuration
        )
        if stopRecording {
            appState.isRecordingActive = false
            recognitionCoordinator.setRecordingActive(false)
        }
    }

    private func handleForegroundAppGateChange(_ state: ForegroundAppGateState) {
        let wasRecordingActive = appState.isRecordingActive
        appState.foregroundAppGateState = state

        let transition = recognitionCoordinator.updateForegroundAppGate(
            state.isSupported,
            permissionState: appState.permissionState
        )
        applyRecognitionTransition(transition)

        if !state.isSupported && wasRecordingActive {
            performSafeShutdown(stopRecording: true)
        }
    }
}
