import AppKit

@MainActor
final class AppCoordinator: SafeShutdownHandling {
    private let configurationStore: ConfigurationStore
    private let permissionManager = PermissionManager()
    private let recognitionCoordinator: RecognitionCoordinator
    private let calibrationController: GestureCalibrationController
    private let keyboardDispatcher = KeyboardDispatcher()
    private let foregroundAppGateMonitor = ForegroundAppGateMonitor()
    private let cameraPipelineController: CameraPipelineControlling
    private let appState: AppState
    private let statusItemController: StatusItemController
    private var calibrationModeActive = false
    private lazy var settingsWindowController: SettingsWindowController = {
        let controller = SettingsWindowController(
            appState: appState,
            onPermissionAction: { [weak self] in
                self?.handlePermissionGuidanceAction()
            }
        )
        controller.onVisibilityChange = { [weak self] isVisible in
            self?.handleCalibrationModeVisibilityChange(isVisible)
        }
        return controller
    }()
    private let hotKeyManager: GlobalHotKeyManaging
    private var activationObserver: NSObjectProtocol?

    init(
        configurationStore: ConfigurationStore = ConfigurationStore(),
        calibrationStore: GestureCalibrationStore = GestureCalibrationStore(),
        hotKeyManager: GlobalHotKeyManaging = GlobalHotKeyManager()
    ) {
        self.configurationStore = configurationStore
        self.hotKeyManager = hotKeyManager
        let configuration = configurationStore.load()
        let recognitionCoordinator = RecognitionCoordinator()
        self.recognitionCoordinator = recognitionCoordinator
        let calibrationController = GestureCalibrationController(store: calibrationStore)
        self.calibrationController = calibrationController
        let appState = AppState(configuration: configuration)
        self.appState = appState
        self.cameraPipelineController = CameraPipelineController()
        self.statusItemController = StatusItemController(appState: appState)
        calibrationController.onStatusChange = { [weak self] status in
            self?.appState.calibrationStatus = status
        }
        appState.calibrationStatus = calibrationController.status
        keyboardDispatcher.onResultChange = { [weak self] result in
            self?.appState.latestKeyboardDispatchResult = result
        }
        foregroundAppGateMonitor.onStateChange = { [weak self] state in
            self?.handleForegroundAppGateChange(state)
        }
        settingsWindowController.onConfigurationChange = { [weak self] configuration in
            self?.updateConfiguration(configuration)
        }
        settingsWindowController.onCalibrationAction = { [weak self] action in
            self?.handleCalibrationAction(action)
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

    func updateConfiguration(_ configuration: AppConfiguration) {
        guard configuration.recordToggleShortcut.isSingleKey else {
            print("Rejected configuration update: record toggle must be a single key")
            return
        }

        appState.configuration = configuration
        registerRecognitionHotKey()

        do {
            try configurationStore.save(configuration)
        } catch {
            print("Failed to save updated configuration: \(error)")
        }
    }

    private func refreshPermissionState() {
        let cameraStatus = permissionManager.cameraAuthorizationStatus()
        let accessibilityTrusted = permissionManager.isAccessibilityTrusted()

        let newState = PermissionState(
            cameraAuthorized: cameraStatus == .authorized,
            accessibilityTrusted: accessibilityTrusted
        )
        appState.permissionState = newState

        let transition = recognitionCoordinator.updatePermissionState(newState)
        applyRecognitionTransition(transition)

        if !newState.isReady {
            performSafeShutdown(stopRecording: appState.isRecordingActive)
        } else if calibrationModeActive {
            startCalibrationCameraIfNeeded()
        }
    }

    private func showSettings() {
        settingsWindowController.showWindow()
    }

    private func handleCalibrationAction(_ action: GestureCalibrationAction) {
        switch action {
        case .capture(let label):
            calibrationController.captureSample(
                label: label,
                observation: appState.latestCameraFrameObservation
            )
        case .clear(let label):
            calibrationController.clearSamples(for: label)
        case .save:
            do {
                _ = try calibrationController.saveCalibration()
            } catch {
                print("Failed to save calibration: \(error)")
            }
        case .reset:
            do {
                _ = try calibrationController.resetCalibration()
            } catch {
                print("Failed to reset calibration: \(error)")
            }
        }
    }

    private func handlePermissionGuidanceAction() {
        let permissionState = appState.permissionState

        switch permissionState {
        case .ready:
            openSystemSettings()

        case .missingCamera:
            requestCameraPermissionThenRefresh()

        case .missingAccessibility:
            requestAccessibilityPermissionThenRefresh()

        case .missingBoth:
            switch permissionManager.cameraAuthorizationStatus() {
            case .notDetermined:
                requestCameraPermissionThenRefresh(promptAccessibilityIfNeeded: true)
            case .denied, .restricted:
                openCameraSettings()
            case .authorized:
                requestAccessibilityPermissionThenRefresh()
            @unknown default:
                openCameraSettings()
            }
        }
    }

    private func requestCameraPermissionThenRefresh(promptAccessibilityIfNeeded: Bool = false) {
        permissionManager.requestCameraAccess { [weak self] granted in
            Task { @MainActor [weak self] in
                guard let self else { return }

                self.refreshPermissionState()

                guard granted else {
                    self.openCameraSettings()
                    return
                }

                if promptAccessibilityIfNeeded, !self.appState.permissionState.isReady {
                    self.requestAccessibilityPermissionThenRefresh()
                }
            }
        }
    }

    private func requestAccessibilityPermissionThenRefresh() {
        AccessibilityPermissionPromptFlow(
            prompt: { [permissionManager] in
                permissionManager.promptAccessibilityAccess()
            },
            refresh: { [weak self] in
                self?.refreshPermissionState()
            }
        ).run()
    }

    private func openSystemSettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:")!)
    }

    private func openCameraSettings() {
        guard let url = appState.permissionState.cameraSettingsURL else {
            return
        }

        NSWorkspace.shared.open(url)
    }

    private func openAccessibilitySettings() {
        guard let url = appState.permissionState.accessibilitySettingsURL else {
            return
        }

        NSWorkspace.shared.open(url)
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
        applyRecognitionTransition(transition, suppressCameraStop: false)
    }

    private func applyRecognitionTransition(
        _ transition: RecognitionTransition,
        suppressCameraStop: Bool
    ) {
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
        }

        appState.isRecordingActive = transition.recordingActive

        if transition.shouldStopCamera, !suppressCameraStop {
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
        let hadPendingSubmit = keyboardDispatcher.hasPendingSubmit
        let calibrationBypass = ForegroundAppGatePolicy.shouldBypassUnsupportedGateForCalibration(
            gateState: state,
            settingsWindowVisible: calibrationModeActive,
            appBundleIdentifier: Bundle.main.bundleIdentifier
        )
        appState.foregroundAppGateState = state

        let transition = recognitionCoordinator.updateForegroundAppGate(
            state.isSupported,
            permissionState: appState.permissionState
        )
        applyRecognitionTransition(transition, suppressCameraStop: calibrationBypass)

        if !state.isSupported {
            if wasRecordingActive {
                performSafeShutdown(stopRecording: true)
            } else if hadPendingSubmit {
                keyboardDispatcher.cancelPendingSubmit()
            }

            if calibrationBypass {
                startCalibrationCameraIfNeeded()
            }
        }
    }

    private func handleCalibrationModeVisibilityChange(_ isVisible: Bool) {
        calibrationModeActive = isVisible

        if isVisible {
            startCalibrationCameraIfNeeded()
            return
        }

        if !appState.foregroundAppGateState.isSupported {
            if appState.isRecordingActive {
                performSafeShutdown(stopRecording: true)
            }
            cameraPipelineController.stop()
        }
    }

    private func startCalibrationCameraIfNeeded() {
        guard appState.permissionState.isReady else {
            return
        }

        guard ForegroundAppGatePolicy.shouldBypassUnsupportedGateForCalibration(
            gateState: appState.foregroundAppGateState,
            settingsWindowVisible: calibrationModeActive,
            appBundleIdentifier: Bundle.main.bundleIdentifier
        ) else {
            return
        }

        guard appState.cameraPipelineState != .running,
              appState.cameraPipelineState != .starting else {
            return
        }

        cameraPipelineController.start()
    }
}

struct AccessibilityPermissionPromptFlow {
    let prompt: () -> Bool
    let refresh: () -> Void

    func run() {
        _ = prompt()
        refresh()
    }
}
