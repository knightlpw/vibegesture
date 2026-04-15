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
            return "Grant Camera access in System Settings > Privacy & Security > Camera to enable recognition."
        case .missingAccessibility:
            return "Grant Accessibility access in System Settings > Privacy & Security > Accessibility to allow keyboard actions later."
        case .missingBoth:
            return "Grant Camera access first, then Accessibility access in System Settings > Privacy & Security before recognition can run."
        }
    }

    var guidanceButtonTitle: String {
        switch self {
        case .ready:
            return "Open System Settings"
        case .missingCamera, .missingBoth:
            return "Open Camera Settings"
        case .missingAccessibility:
            return "Open Accessibility Settings"
        }
    }

    var guidanceSettingsURL: URL? {
        switch self {
        case .ready:
            return URL(string: "x-apple.systempreferences:")
        case .missingCamera, .missingBoth:
            return URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera")
        case .missingAccessibility:
            return URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
        }
    }
}
