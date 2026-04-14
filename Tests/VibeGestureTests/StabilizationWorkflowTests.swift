import Foundation
import XCTest
@testable import VibeGesture

@MainActor
final class StabilizationWorkflowTests: XCTestCase {
    func testUpdateConfigurationRebindsRecognitionHotkeyAndRejectsInvalidRecordToggle() throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("config.json")

        let store = ConfigurationStore(fileURL: fileURL)
        let hotKeyManager = RecordingGlobalHotKeyManager()
        let coordinator = AppCoordinator(
            configurationStore: store,
            hotKeyManager: hotKeyManager
        )

        let updatedConfiguration = AppConfiguration(
            globalRecognitionShortcut: Shortcut(
                keyCode: 6,
                modifiers: [.command, .shift],
                displayName: "⌘⇧Z"
            ),
            recordToggleShortcut: Shortcut(
                keyCode: 63,
                modifiers: [],
                displayName: "Fn"
            ),
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

        coordinator.updateConfiguration(updatedConfiguration)

        XCTAssertEqual(hotKeyManager.registeredShortcuts, [updatedConfiguration.globalRecognitionShortcut])
        XCTAssertEqual(store.load(), updatedConfiguration)

        let invalidConfiguration = AppConfiguration(
            globalRecognitionShortcut: Shortcut(
                keyCode: 7,
                modifiers: [.command],
                displayName: "⌘D"
            ),
            recordToggleShortcut: Shortcut(
                keyCode: 7,
                modifiers: [.command],
                displayName: "⌘D"
            ),
            submitShortcut: updatedConfiguration.submitShortcut,
            cancelShortcut: updatedConfiguration.cancelShortcut
        )

        coordinator.updateConfiguration(invalidConfiguration)

        XCTAssertEqual(hotKeyManager.registeredShortcuts, [updatedConfiguration.globalRecognitionShortcut])
        XCTAssertEqual(store.load(), updatedConfiguration)
    }

    func testWorkflowCancelsPendingSubmitWhenForegroundGateLosesSupport() async throws {
        let harness = StabilizationWorkflowHarness(submitStopDelay: 0.05)
        let baseTime = Date(timeIntervalSinceReferenceDate: 10_000)

        harness.setForegroundApp(
            supported: true,
            applicationName: "Codex",
            bundleIdentifier: "com.openai.codex",
            timestamp: baseTime
        )
        harness.setPermission(.ready, timestamp: baseTime)
        harness.enableRecognition(true, timestamp: baseTime)

        for index in 0..<6 {
            harness.feed(pose: .pinch, timestamp: baseTime.addingTimeInterval(Double(index) * 0.05))
        }

        XCTAssertEqual(harness.tappedShortcutNames, ["Fn"])
        XCTAssertEqual(harness.appState.recognitionState, .cooldown)
        XCTAssertTrue(harness.appState.isRecordingActive)

        for index in 0..<4 {
            harness.feed(
                pose: .submit,
                timestamp: baseTime.addingTimeInterval(1.0 + Double(index) * 0.05)
            )
        }

        XCTAssertEqual(harness.tappedShortcutNames, ["Fn", "Fn"])
        XCTAssertEqual(harness.appState.latestKeyboardDispatchResult.displayName, "Waiting 300 ms for submit")
        XCTAssertFalse(harness.appState.isRecordingActive)

        harness.setForegroundApp(
            supported: false,
            applicationName: "Safari",
            bundleIdentifier: "com.apple.Safari",
            timestamp: baseTime.addingTimeInterval(1.2)
        )

        XCTAssertEqual(harness.tappedShortcutNames, ["Fn", "Fn"])
        XCTAssertEqual(harness.appState.recognitionState, .disabled)
        XCTAssertEqual(harness.appState.latestKeyboardDispatchResult.displayName, "Cancelled pending submit")

        try await Task.sleep(nanoseconds: 90_000_000)

        XCTAssertEqual(harness.tappedShortcutNames, ["Fn", "Fn"])
        XCTAssertEqual(harness.appState.latestKeyboardDispatchResult.displayName, "Cancelled pending submit")

        harness.setForegroundApp(
            supported: true,
            applicationName: "Codex",
            bundleIdentifier: "com.openai.codex",
            timestamp: baseTime.addingTimeInterval(1.4)
        )

        XCTAssertEqual(harness.appState.recognitionState, .idle)
        XCTAssertTrue(harness.appState.isForegroundAppSupported)
    }

    func testWorkflowStopsRecordingImmediatelyWhenForegroundGateLosesSupportDuringRecording() async throws {
        let harness = StabilizationWorkflowHarness(submitStopDelay: 0.05)
        let baseTime = Date(timeIntervalSinceReferenceDate: 20_000)

        harness.setForegroundApp(
            supported: true,
            applicationName: "Codex",
            bundleIdentifier: "com.openai.codex",
            timestamp: baseTime
        )
        harness.setPermission(.ready, timestamp: baseTime)
        harness.enableRecognition(true, timestamp: baseTime)

        for index in 0..<6 {
            harness.feed(pose: .pinch, timestamp: baseTime.addingTimeInterval(Double(index) * 0.05))
        }

        XCTAssertEqual(harness.tappedShortcutNames, ["Fn"])
        XCTAssertTrue(harness.appState.isRecordingActive)

        harness.setForegroundApp(
            supported: false,
            applicationName: "Safari",
            bundleIdentifier: "com.apple.Safari",
            timestamp: baseTime.addingTimeInterval(0.5)
        )

        XCTAssertEqual(harness.tappedShortcutNames, ["Fn", "Fn"])
        XCTAssertEqual(harness.appState.recognitionState, .disabled)
        XCTAssertFalse(harness.appState.isRecordingActive)
        XCTAssertEqual(harness.appState.latestKeyboardDispatchResult.displayName, "Safe shutdown · stopped recording")

        try await Task.sleep(nanoseconds: 90_000_000)

        XCTAssertEqual(harness.tappedShortcutNames, ["Fn", "Fn"])
        XCTAssertEqual(harness.appState.latestKeyboardDispatchResult.displayName, "Safe shutdown · stopped recording")
    }
}

@MainActor
private final class StabilizationWorkflowHarness {
    let appState: AppState
    let recognitionCoordinator = RecognitionCoordinator()
    let keyboardDispatcher: KeyboardDispatcher
    private let keyboardPoster = RecordingKeyboardEventPoster()

    init(configuration: AppConfiguration = .default, submitStopDelay: TimeInterval = 0.05) {
        self.appState = AppState(configuration: configuration)
        self.keyboardDispatcher = KeyboardDispatcher(
            eventPoster: keyboardPoster,
            submitStopDelay: submitStopDelay
        )

        keyboardDispatcher.onResultChange = { [weak self] result in
            self?.appState.latestKeyboardDispatchResult = result
        }
    }

    var tappedShortcutNames: [String] {
        keyboardPoster.tappedShortcuts.map(\.displayName)
    }

    func setPermission(_ state: PermissionState, timestamp: Date) {
        appState.permissionState = state
        let transition = recognitionCoordinator.updatePermissionState(state, timestamp: timestamp)
        apply(transition)

        if !state.isReady {
            performSafeShutdown(stopRecording: appState.isRecordingActive)
        }
    }

    func setForegroundApp(
        supported: Bool,
        applicationName: String?,
        bundleIdentifier: String?,
        timestamp: Date
    ) {
        let appGateState = supported
            ? ForegroundAppGatePolicy.classify(
                bundleIdentifier: bundleIdentifier,
                applicationName: applicationName
            )
            : .unsupported(
                ForegroundAppInfo(
                    applicationName: applicationName,
                    bundleIdentifier: bundleIdentifier
                )
            )

        let wasRecordingActive = appState.isRecordingActive
        let hadPendingSubmit = keyboardDispatcher.hasPendingSubmit
        appState.foregroundAppGateState = appGateState

        let transition = recognitionCoordinator.updateForegroundAppGate(
            supported,
            permissionState: appState.permissionState,
            timestamp: timestamp
        )
        apply(transition)

        if !supported {
            if wasRecordingActive {
                performSafeShutdown(stopRecording: true)
            } else if hadPendingSubmit {
                keyboardDispatcher.cancelPendingSubmit()
            }
        }
    }

    func enableRecognition(_ enabled: Bool, timestamp: Date) {
        let transition = recognitionCoordinator.setRecognitionEnabled(
            enabled,
            permissionState: appState.permissionState,
            timestamp: timestamp
        )
        apply(transition)

        if !enabled {
            performSafeShutdown(stopRecording: appState.isRecordingActive)
        }
    }

    func feed(pose: SyntheticPose, timestamp: Date) {
        let observation = makeFrameObservation(pose: pose, timestamp: timestamp)
        appState.latestCameraFrameObservation = observation

        guard appState.foregroundAppGateState.isSupported else {
            return
        }

        let transition = recognitionCoordinator.process(frameObservation: observation)
        apply(transition)
    }

    private func apply(_ transition: RecognitionTransition) {
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

    enum SyntheticPose {
        case pinch
        case submit
        case cancel
    }

    private func makeFrameObservation(
        pose: SyntheticPose,
        timestamp: Date
    ) -> CameraFrameObservation {
        CameraFrameObservation(
            timestamp: timestamp,
            status: .rightHandDetected,
            hands: [makeHandPoseObservation(pose: pose)]
        )
    }

    private func makeHandPoseObservation(pose: SyntheticPose) -> HandPoseObservation {
        let wrist = landmark(0.50, 0.20)
        let thumbCMC = landmark(0.38, 0.24)
        let thumbMP = landmark(0.43, 0.30)
        let thumbIP = landmark(0.48, 0.36)

        let indexMCP = landmark(0.55, 0.30)
        let indexPIP = landmark(0.57, 0.44)
        let middleMCP = landmark(0.60, 0.31)
        let middlePIP = landmark(0.62, 0.45)
        let ringMCP = landmark(0.65, 0.30)
        let ringPIP = landmark(0.67, 0.44)
        let littleMCP = landmark(0.70, 0.28)
        let littlePIP = landmark(0.72, 0.42)

        let thumbTip: HandLandmarkObservation
        let indexTip: HandLandmarkObservation
        let middleTip: HandLandmarkObservation
        let ringTip: HandLandmarkObservation
        let littleTip: HandLandmarkObservation

        switch pose {
        case .pinch:
            thumbTip = landmark(0.565, 0.495)
            indexTip = landmark(0.575, 0.500)
            middleTip = landmark(0.605, 0.355)
            ringTip = landmark(0.655, 0.350)
            littleTip = landmark(0.705, 0.345)
        case .submit:
            thumbTip = landmark(0.360, 0.570)
            indexTip = landmark(0.575, 0.840)
            middleTip = landmark(0.625, 0.860)
            ringTip = landmark(0.675, 0.845)
            littleTip = landmark(0.725, 0.830)
        case .cancel:
            thumbTip = landmark(0.360, 0.570)
            indexTip = landmark(0.575, 0.840)
            middleTip = landmark(0.625, 0.860)
            ringTip = landmark(0.650, 0.350)
            littleTip = landmark(0.700, 0.340)
        }

        return HandPoseObservation(
            laterality: .right,
            confidence: 0.98,
            landmarks: [
                .wrist: wrist,
                .thumbCMC: thumbCMC,
                .thumbMP: thumbMP,
                .thumbIP: thumbIP,
                .thumbTip: thumbTip,
                .indexMCP: indexMCP,
                .indexPIP: indexPIP,
                .indexDIP: landmark(0.58, 0.58),
                .indexTip: indexTip,
                .middleMCP: middleMCP,
                .middlePIP: middlePIP,
                .middleDIP: landmark(0.63, 0.60),
                .middleTip: middleTip,
                .ringMCP: ringMCP,
                .ringPIP: ringPIP,
                .ringDIP: landmark(0.68, 0.59),
                .ringTip: ringTip,
                .littleMCP: littleMCP,
                .littlePIP: littlePIP,
                .littleDIP: landmark(0.73, 0.58),
                .littleTip: littleTip
            ]
        )
    }

    private func landmark(_ x: Double, _ y: Double, confidence: Float = 1) -> HandLandmarkObservation {
        HandLandmarkObservation(
            x: x,
            y: y,
            confidence: confidence
        )
    }
}

@MainActor
private final class RecordingGlobalHotKeyManager: GlobalHotKeyManaging {
    private(set) var registeredShortcuts: [Shortcut] = []

    func register(shortcut: Shortcut, action: @escaping () -> Void) {
        registeredShortcuts.append(shortcut)
        _ = action
    }
}
