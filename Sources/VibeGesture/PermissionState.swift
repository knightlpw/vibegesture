import Foundation

enum PermissionKind: String, Codable, CaseIterable, Equatable {
    case camera
    case accessibility

    var displayName: String {
        switch self {
        case .camera:
            return "Camera"
        case .accessibility:
            return "Accessibility"
        }
    }
}

enum PermissionState: String, Codable, Equatable {
    case ready
    case missingCamera
    case missingAccessibility
    case missingBoth

    init(cameraAuthorized: Bool, accessibilityTrusted: Bool) {
        switch (cameraAuthorized, accessibilityTrusted) {
        case (true, true):
            self = .ready
        case (false, true):
            self = .missingCamera
        case (true, false):
            self = .missingAccessibility
        case (false, false):
            self = .missingBoth
        }
    }

    var isReady: Bool {
        self == .ready
    }

    var missingKinds: [PermissionKind] {
        switch self {
        case .ready:
            return []
        case .missingCamera:
            return [.camera]
        case .missingAccessibility:
            return [.accessibility]
        case .missingBoth:
            return [.camera, .accessibility]
        }
    }

    var displayName: String {
        switch self {
        case .ready:
            return "Ready"
        case .missingCamera:
            return "Camera permission required"
        case .missingAccessibility:
            return "Accessibility permission required"
        case .missingBoth:
            return "Camera and Accessibility permissions required"
        }
    }

    var guidanceMessage: String {
        switch self {
        case .ready:
            return "All required permissions are available."
        case .missingCamera:
            return "Grant Camera access in System Settings to enable recognition."
        case .missingAccessibility:
            return "Grant Accessibility access in System Settings to allow keyboard actions later."
        case .missingBoth:
            return "Grant Camera and Accessibility access in System Settings before recognition can run."
        }
    }

    var guidanceButtonTitle: String {
        "Open System Settings"
    }
}
