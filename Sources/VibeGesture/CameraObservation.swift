import CoreGraphics
import Foundation

enum HandLaterality: String, Codable, Equatable {
    case left
    case right
    case unknown

    var displayName: String {
        switch self {
        case .left:
            return "Left"
        case .right:
            return "Right"
        case .unknown:
            return "Unknown"
        }
    }
}

enum HandLandmark: String, CaseIterable, Codable {
    case wrist
    case thumbCMC
    case thumbMP
    case thumbIP
    case thumbTip
    case indexMCP
    case indexPIP
    case indexDIP
    case indexTip
    case middleMCP
    case middlePIP
    case middleDIP
    case middleTip
    case ringMCP
    case ringPIP
    case ringDIP
    case ringTip
    case littleMCP
    case littlePIP
    case littleDIP
    case littleTip

    var displayName: String {
        switch self {
        case .wrist:
            return "Wrist"
        case .thumbCMC:
            return "Thumb CMC"
        case .thumbMP:
            return "Thumb MP"
        case .thumbIP:
            return "Thumb IP"
        case .thumbTip:
            return "Thumb Tip"
        case .indexMCP:
            return "Index MCP"
        case .indexPIP:
            return "Index PIP"
        case .indexDIP:
            return "Index DIP"
        case .indexTip:
            return "Index Tip"
        case .middleMCP:
            return "Middle MCP"
        case .middlePIP:
            return "Middle PIP"
        case .middleDIP:
            return "Middle DIP"
        case .middleTip:
            return "Middle Tip"
        case .ringMCP:
            return "Ring MCP"
        case .ringPIP:
            return "Ring PIP"
        case .ringDIP:
            return "Ring DIP"
        case .ringTip:
            return "Ring Tip"
        case .littleMCP:
            return "Little MCP"
        case .littlePIP:
            return "Little PIP"
        case .littleDIP:
            return "Little DIP"
        case .littleTip:
            return "Little Tip"
        }
    }
}

struct HandLandmarkObservation: Equatable {
    let x: CGFloat
    let y: CGFloat
    let confidence: Float
}

struct HandPoseObservation: Equatable {
    let laterality: HandLaterality
    let confidence: Float
    let landmarks: [HandLandmark: HandLandmarkObservation]

    var landmarkCount: Int {
        landmarks.count
    }

    var summaryText: String {
        let landmarkText = landmarkCount == 1 ? "1 landmark" : "\(landmarkCount) landmarks"
        return "\(laterality.displayName) hand, \(landmarkText)"
    }
}

enum CameraFrameObservationStatus: Equatable {
    case rightHandDetected
    case noRightHandDetected
    case pipelineFailed(String)

    var displayName: String {
        switch self {
        case .rightHandDetected:
            return "Right hand detected"
        case .noRightHandDetected:
            return "Waiting for right hand"
        case .pipelineFailed:
            return "Pipeline failed"
        }
    }

    var detailMessage: String {
        switch self {
        case .rightHandDetected:
            return "A right-hand observation was produced."
        case .noRightHandDetected:
            return "No right-hand observation was available in this frame."
        case .pipelineFailed(let message):
            return message
        }
    }
}

struct CameraFrameObservation: Equatable {
    let timestamp: Date
    let status: CameraFrameObservationStatus
    let hands: [HandPoseObservation]

    var isRightHandDetected: Bool {
        !hands.isEmpty
    }

    var summaryText: String {
        if let firstHand = hands.first {
            return firstHand.summaryText
        }
        return status.displayName
    }
}

enum CameraPipelineState: Equatable {
    case stopped
    case starting
    case running
    case stopping
    case failed(String)

    var displayName: String {
        switch self {
        case .stopped:
            return "Stopped"
        case .starting:
            return "Starting"
        case .running:
            return "Running"
        case .stopping:
            return "Stopping"
        case .failed:
            return "Failed"
        }
    }

    var detailMessage: String {
        switch self {
        case .stopped:
            return "Camera capture is not active."
        case .starting:
            return "Starting the default camera and Vision pipeline."
        case .running:
            return "Default camera frames are flowing into Vision hand pose detection."
        case .stopping:
            return "Stopping camera capture."
        case .failed(let message):
            return message
        }
    }
}
