import AVFoundation
import CoreGraphics
import Foundation
import ImageIO
import Vision

protocol HandPoseProcessing {
    func process(sampleBuffer: CMSampleBuffer) -> CameraFrameObservation
}

final class VisionHandPoseProcessor: HandPoseProcessing {
    private let sequenceRequestHandler = VNSequenceRequestHandler()
    private let request = VNDetectHumanHandPoseRequest()

    init() {
        request.maximumHandCount = 1
    }

    func process(sampleBuffer: CMSampleBuffer) -> CameraFrameObservation {
        let timestamp = Date()

        do {
            try sequenceRequestHandler.perform([request], on: sampleBuffer, orientation: .up)
            let hands = (request.results ?? [])
                .filter { $0.chirality == .right }
                .compactMap { convert(observation: $0) }

            let status: CameraFrameObservationStatus = hands.isEmpty
                ? .noRightHandDetected
                : .rightHandDetected

            return CameraFrameObservation(
                timestamp: timestamp,
                status: status,
                hands: hands
            )
        } catch {
            return CameraFrameObservation(
                timestamp: timestamp,
                status: .pipelineFailed(error.localizedDescription),
                hands: []
            )
        }
    }

    private func convert(observation: VNHumanHandPoseObservation) -> HandPoseObservation? {
        var landmarks: [HandLandmark: HandLandmarkObservation] = [:]

        for landmark in HandLandmark.allCases {
            guard let point = try? observation.recognizedPoint(landmark.visionJointName) else {
                continue
            }

            landmarks[landmark] = HandLandmarkObservation(
                x: point.location.x,
                y: point.location.y,
                confidence: point.confidence
            )
        }

        guard !landmarks.isEmpty else {
            return nil
        }

        return HandPoseObservation(
            laterality: observation.chirality.handLaterality,
            confidence: observation.confidence,
            landmarks: landmarks
        )
    }
}

private extension HandLandmark {
    var visionJointName: VNHumanHandPoseObservation.JointName {
        switch self {
        case .wrist:
            return .wrist
        case .thumbCMC:
            return .thumbCMC
        case .thumbMP:
            return .thumbMP
        case .thumbIP:
            return .thumbIP
        case .thumbTip:
            return .thumbTip
        case .indexMCP:
            return .indexMCP
        case .indexPIP:
            return .indexPIP
        case .indexDIP:
            return .indexDIP
        case .indexTip:
            return .indexTip
        case .middleMCP:
            return .middleMCP
        case .middlePIP:
            return .middlePIP
        case .middleDIP:
            return .middleDIP
        case .middleTip:
            return .middleTip
        case .ringMCP:
            return .ringMCP
        case .ringPIP:
            return .ringPIP
        case .ringDIP:
            return .ringDIP
        case .ringTip:
            return .ringTip
        case .littleMCP:
            return .littleMCP
        case .littlePIP:
            return .littlePIP
        case .littleDIP:
            return .littleDIP
        case .littleTip:
            return .littleTip
        }
    }
}

    private extension VNChirality {
    var handLaterality: HandLaterality {
        switch self {
        case .left:
            return .left
        case .right:
            return .right
        case .unknown:
            return .unknown
        @unknown default:
            return .unknown
        }
    }
}
