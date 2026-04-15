import AVFoundation
import Foundation

struct PermissionDiagnostics: Equatable {
    let cameraAuthorizationStatus: AVAuthorizationStatus
    let accessibilityTrusted: Bool

    var cameraAuthorizationStatusDisplayName: String {
        switch cameraAuthorizationStatus {
        case .authorized:
            return "Authorized"
        case .notDetermined:
            return "Not determined"
        case .denied:
            return "Denied"
        case .restricted:
            return "Restricted"
        @unknown default:
            return "Unknown"
        }
    }

    var accessibilityTrustedDisplayName: String {
        accessibilityTrusted ? "Trusted" : "Not trusted"
    }

    var summaryText: String {
        "Camera: \(cameraAuthorizationStatusDisplayName), Accessibility: \(accessibilityTrustedDisplayName)"
    }
}
