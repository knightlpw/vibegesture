import ApplicationServices
import AVFoundation

protocol PermissionChecking {
    func cameraAuthorizationStatus() -> AVAuthorizationStatus
    func isAccessibilityTrusted() -> Bool
}

struct SystemPermissionChecker: PermissionChecking {
    func cameraAuthorizationStatus() -> AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .video)
    }

    func isAccessibilityTrusted() -> Bool {
        AXIsProcessTrusted()
    }
}

final class PermissionManager {
    private let checker: PermissionChecking

    init(checker: PermissionChecking = SystemPermissionChecker()) {
        self.checker = checker
    }

    func refresh() -> PermissionState {
        let cameraAuthorized = checker.cameraAuthorizationStatus() == .authorized
        let accessibilityTrusted = checker.isAccessibilityTrusted()
        return PermissionState(
            cameraAuthorized: cameraAuthorized,
            accessibilityTrusted: accessibilityTrusted
        )
    }
}
