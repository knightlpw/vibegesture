import AVFoundation
import Foundation
import Observation

@Observable
@MainActor
final class AppState {
    @ObservationIgnored var onChange: (() -> Void)?

    var recognitionState: RecognitionState {
        didSet { notifyChange() }
    }

    var permissionState: PermissionState {
        didSet { notifyChange() }
    }

    var cameraPipelineState: CameraPipelineState {
        didSet { notifyChange() }
    }

    var latestCameraFrameObservation: CameraFrameObservation? {
        didSet { notifyChange() }
    }

    var latestGestureInterpretation: GestureInterpretation? {
        didSet { notifyChange() }
    }

    var latestRecognitionActionIntent: RecognitionActionIntent {
        didSet { notifyChange() }
    }

    var isRecordingActive: Bool {
        didSet { notifyChange() }
    }

    var foregroundAppGateState: ForegroundAppGateState {
        didSet { notifyChange() }
    }

    var latestKeyboardDispatchResult: KeyboardDispatchResult {
        didSet { notifyChange() }
    }

    var configuration: AppConfiguration {
        didSet { notifyChange() }
    }

    init(configuration: AppConfiguration) {
        self.configuration = configuration
        self.recognitionState = .disabled
        self.permissionState = .missingBoth
        self.cameraPipelineState = .stopped
        self.latestCameraFrameObservation = nil
        self.latestGestureInterpretation = nil
        self.latestRecognitionActionIntent = .none
        self.isRecordingActive = false
        self.foregroundAppGateState = .unknown
        self.latestKeyboardDispatchResult = .idle
    }

    var isRecognitionBlockedByPermission: Bool {
        !permissionState.isReady
    }

    var isForegroundAppSupported: Bool {
        foregroundAppGateState.isSupported
    }

    private func notifyChange() {
        onChange?()
    }
}
