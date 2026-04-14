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

    var configuration: AppConfiguration {
        didSet { notifyChange() }
    }

    init(configuration: AppConfiguration) {
        self.configuration = configuration
        self.recognitionState = .disabled
        self.permissionState = .missingBoth
        self.cameraPipelineState = .stopped
        self.latestCameraFrameObservation = nil
    }

    var isRecognitionBlockedByPermission: Bool {
        !permissionState.isReady
    }

    private func notifyChange() {
        onChange?()
    }
}
