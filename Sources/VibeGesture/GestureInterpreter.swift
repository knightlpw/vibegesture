import CoreGraphics
import Foundation

protocol GestureInterpreting {
    func interpret(frameObservation: CameraFrameObservation) -> GestureInterpretation
}

final class GestureInterpreter: GestureInterpreting {
    static let pinchActivationFrames = 6
    static let pinchRearmFrames = 4
    static let submitActivationFrames = 4
    static let cancelActivationFrames = 3

    private var pinchActivationCount = 0
    private var pinchReleaseCount = 0
    private var submitActivationCount = 0
    private var cancelActivationCount = 0
    private var pinchLatched = false
    private var submitLatched = false
    private var cancelLatched = false

    func interpret(frameObservation: CameraFrameObservation) -> GestureInterpretation {
        let timestamp = frameObservation.timestamp

        guard let hand = frameObservation.hands.first,
              let analysis = analyze(hand: hand, frameStatus: frameObservation.status) else {
            return updateState(
                isPinchPose: false,
                isSubmitPose: false,
                isCancelPose: false,
                bestEffortSummary: frameObservation.status.detailMessage,
                timestamp: timestamp
            )
        }

        return updateState(
            isPinchPose: analysis.isPinchPose,
            isSubmitPose: analysis.isSubmitPose,
            isCancelPose: analysis.isCancelPose,
            bestEffortSummary: analysis.summary,
            timestamp: timestamp
        )
    }

    private func updateState(
        isPinchPose: Bool,
        isSubmitPose: Bool,
        isCancelPose: Bool,
        bestEffortSummary: String,
        timestamp: Date
    ) -> GestureInterpretation {
        var candidate: GestureCandidate = .noAction
        var summary = bestEffortSummary
        var confidence = 0.0

        if isCancelPose {
            cancelActivationCount += 1
        } else {
            cancelActivationCount = 0
            cancelLatched = false
        }

        if !cancelLatched, cancelActivationCount >= Self.cancelActivationFrames {
            cancelLatched = true
            cancelActivationCount = 0
            candidate = .cancelStarted
            summary = "Cancel pose stabilized"
            confidence = 1.0
        } else if isCancelPose {
            candidate = .noAction
            summary = "Cancel pose held (\(cancelActivationCount)/\(Self.cancelActivationFrames))"
            confidence = Double(cancelActivationCount) / Double(Self.cancelActivationFrames)
        }

        if candidate == .noAction {
            if isSubmitPose {
                submitActivationCount += 1
            } else {
                submitActivationCount = 0
                submitLatched = false
            }

            if !submitLatched, submitActivationCount >= Self.submitActivationFrames {
                submitLatched = true
                submitActivationCount = 0
                candidate = .submitStarted
                summary = "Submit pose stabilized"
                confidence = 1.0
            } else if isSubmitPose {
                summary = "Submit pose held (\(submitActivationCount)/\(Self.submitActivationFrames))"
                confidence = Double(submitActivationCount) / Double(Self.submitActivationFrames)
            }
        }

        if isPinchPose {
            pinchActivationCount += 1
            pinchReleaseCount = 0

            if !pinchLatched, pinchActivationCount >= Self.pinchActivationFrames {
                pinchLatched = true
                pinchActivationCount = 0
                if candidate == .noAction {
                    candidate = .pinchStarted
                    summary = "Pinch pose stabilized"
                    confidence = 1.0
                }
            } else if candidate == .noAction {
                summary = "Pinch pose held (\(pinchActivationCount)/\(Self.pinchActivationFrames))"
                confidence = Double(pinchActivationCount) / Double(Self.pinchActivationFrames)
            }
        } else {
            pinchActivationCount = 0

            if pinchLatched {
                pinchReleaseCount += 1

                if pinchReleaseCount >= Self.pinchRearmFrames {
                    pinchLatched = false
                    pinchReleaseCount = 0
                    if candidate == .noAction {
                        candidate = .pinchRearmed
                        summary = "Pinch re-armed"
                        confidence = 1.0
                    }
                } else if candidate == .noAction {
                    summary = "Pinch release held (\(pinchReleaseCount)/\(Self.pinchRearmFrames))"
                    confidence = Double(pinchReleaseCount) / Double(Self.pinchRearmFrames)
                }
            } else {
                pinchReleaseCount = 0
            }
        }

        if candidate == .noAction && summary.isEmpty {
            summary = "Waiting for a stable gesture"
        }

        return GestureInterpretation(
            timestamp: timestamp,
            candidate: candidate,
            confidence: min(max(confidence, 0), 1),
            summary: summary
        )
    }

    private func analyze(
        hand: HandPoseObservation,
        frameStatus: CameraFrameObservationStatus
    ) -> PoseAnalysis? {
        guard
            let wrist = hand.landmarks[.wrist],
            let thumbTip = hand.landmarks[.thumbTip],
            let thumbIP = hand.landmarks[.thumbIP],
            let indexMCP = hand.landmarks[.indexMCP],
            let indexPIP = hand.landmarks[.indexPIP],
            let indexTip = hand.landmarks[.indexTip],
            let middleMCP = hand.landmarks[.middleMCP],
            let middlePIP = hand.landmarks[.middlePIP],
            let middleTip = hand.landmarks[.middleTip],
            let ringMCP = hand.landmarks[.ringMCP],
            let ringPIP = hand.landmarks[.ringPIP],
            let ringTip = hand.landmarks[.ringTip],
            let littleMCP = hand.landmarks[.littleMCP],
            let littlePIP = hand.landmarks[.littlePIP],
            let littleTip = hand.landmarks[.littleTip]
        else {
            return nil
        }

        let handSpan = max(
            distance(wrist, indexMCP),
            distance(wrist, middleMCP),
            distance(wrist, ringMCP),
            distance(wrist, littleMCP),
            0.0001
        )

        let pinchDistance = distance(thumbTip, indexTip) / handSpan
        let pinchThreshold = 0.28
        let isPinchPose = pinchDistance <= pinchThreshold

        let indexExtended = isExtended(tip: indexTip, joint: indexPIP, wrist: wrist)
        let middleExtended = isExtended(tip: middleTip, joint: middlePIP, wrist: wrist)
        let ringExtended = isExtended(tip: ringTip, joint: ringPIP, wrist: wrist)
        let littleExtended = isExtended(tip: littleTip, joint: littlePIP, wrist: wrist)
        let thumbExtended = isExtended(tip: thumbTip, joint: thumbIP, wrist: wrist)

        let extendedFingerCount = [
            indexExtended,
            middleExtended,
            ringExtended,
            littleExtended,
            thumbExtended
        ].filter { $0 }.count

        let isCancelPose = !isPinchPose
            && indexExtended
            && middleExtended
            && !ringExtended
            && !littleExtended

        let isSubmitPose = !isPinchPose && extendedFingerCount >= 4

        let pinchConfidence = min(1, max(0, 1 - (pinchDistance / pinchThreshold)))
        let candidateConfidence = max(
            isCancelPose ? 0.92 : 0,
            isSubmitPose ? Double(extendedFingerCount) / 5.0 : 0
        )
        let confidence = max(pinchConfidence, candidateConfidence)

        var summary: String
        if isCancelPose {
            summary = "Cancel pose observed"
        } else if isSubmitPose {
            summary = "Submit pose observed"
        } else if isPinchPose {
            summary = "Pinch pose observed"
        } else {
            summary = "Waiting for a stable gesture"
            if case .noRightHandDetected = frameStatus {
                summary = frameStatus.detailMessage
            } else if case .pipelineFailed(let message) = frameStatus {
                summary = message
            }
        }

        return PoseAnalysis(
            isPinchPose: isPinchPose,
            isSubmitPose: isSubmitPose,
            isCancelPose: isCancelPose,
            confidence: confidence,
            summary: summary
        )
    }

    private func distance(
        _ lhs: HandLandmarkObservation,
        _ rhs: HandLandmarkObservation
    ) -> Double {
        hypot(Double(lhs.x - rhs.x), Double(lhs.y - rhs.y))
    }

    private func isExtended(
        tip: HandLandmarkObservation,
        joint: HandLandmarkObservation,
        wrist: HandLandmarkObservation
    ) -> Bool {
        let tipDistance = distance(tip, wrist)
        let jointDistance = distance(joint, wrist)
        return tipDistance > jointDistance * 1.08
    }
}

private struct PoseAnalysis {
    let isPinchPose: Bool
    let isSubmitPose: Bool
    let isCancelPose: Bool
    let confidence: Double
    let summary: String
}
