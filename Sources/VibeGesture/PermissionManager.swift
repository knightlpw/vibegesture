import ApplicationServices
import AVFoundation
import Foundation

protocol PermissionChecking {
    func cameraAuthorizationStatus() -> AVAuthorizationStatus
    func isAccessibilityTrusted() -> Bool
}

protocol PermissionRequesting {
    func requestCameraAccess(completion: @escaping @Sendable (Bool) -> Void)
    func promptAccessibilityAccess() -> Bool
}

struct SystemPermissionChecker: PermissionChecking {
    func cameraAuthorizationStatus() -> AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .video)
    }

    func isAccessibilityTrusted() -> Bool {
        AXIsProcessTrusted()
    }
}

struct SystemPermissionRequester: PermissionRequesting {
    func requestCameraAccess(completion: @escaping @Sendable (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            completion(granted)
        }
    }

    func promptAccessibilityAccess() -> Bool {
        let promptKey = "AXTrustedCheckOptionPrompt" as CFString
        return AXIsProcessTrustedWithOptions([promptKey: true] as CFDictionary)
    }
}

final class PermissionManager {
    private let checker: PermissionChecking
    private let requester: PermissionRequesting

    init(
        checker: PermissionChecking = SystemPermissionChecker(),
        requester: PermissionRequesting = SystemPermissionRequester()
    ) {
        self.checker = checker
        self.requester = requester
    }

    func refresh() -> PermissionState {
        let cameraAuthorized = checker.cameraAuthorizationStatus() == .authorized
        let accessibilityTrusted = checker.isAccessibilityTrusted()
        return PermissionState(
            cameraAuthorized: cameraAuthorized,
            accessibilityTrusted: accessibilityTrusted
        )
    }

    func cameraAuthorizationStatus() -> AVAuthorizationStatus {
        checker.cameraAuthorizationStatus()
    }

    func isAccessibilityTrusted() -> Bool {
        checker.isAccessibilityTrusted()
    }

    func requestCameraAccess(completion: @escaping @Sendable (Bool) -> Void) {
        requester.requestCameraAccess(completion: completion)
    }

    func promptAccessibilityAccess() -> Bool {
        requester.promptAccessibilityAccess()
    }
}
