import Foundation

enum RecognitionState: String, Codable, Equatable {
    case disabled
    case idle
    case recordingActive
    case cooldown
    case errorPermissionMissing

    var displayName: String {
        switch self {
        case .disabled:
            return "Disabled"
        case .idle:
            return "Idle"
        case .recordingActive:
            return "Recording Active"
        case .cooldown:
            return "Cooldown"
        case .errorPermissionMissing:
            return "Permission Missing"
        }
    }

    var menuBarSymbolName: String {
        switch self {
        case .disabled:
            return "hand.raised"
        case .idle:
            return "hand.raised.fill"
        case .recordingActive:
            return "mic.fill"
        case .cooldown:
            return "hourglass"
        case .errorPermissionMissing:
            return "exclamationmark.triangle.fill"
        }
    }

    var toggleMenuTitle: String {
        switch self {
        case .disabled, .errorPermissionMissing:
            return "Enable Recognition"
        default:
            return "Disable Recognition"
        }
    }
}
