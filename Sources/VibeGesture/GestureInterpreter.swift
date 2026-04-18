import CoreGraphics
import Foundation

protocol GestureInterpreting {
    func interpret(frameObservation: CameraFrameObservation) -> GestureInterpretation
}

final class GestureInterpreter: GestureInterpreting {
    static let recordActivationFrames = 6
    static let recordRearmFrames = 4
    static let submitActivationFrames = 4
    static let cancelActivationFrames = 3

    private var recordActivationCount = 0
    private var recordReleaseCount = 0
    private var submitActivationCount = 0
    private var cancelActivationCount = 0
    private var recordLatched = false
    private var submitLatched = false
    private var cancelLatched = false

    init() {}

    func interpret(frameObservation: CameraFrameObservation) -> GestureInterpretation {
        let timestamp = frameObservation.timestamp

        guard let hand = frameObservation.hands.first else {
            return updateState(
                pose: .background,
                bestEffortSummary: frameObservation.status.detailMessage,
                timestamp: timestamp
            )
        }

        let pose = classifyRulePose(hand: hand)

        return updateState(
            pose: pose,
            bestEffortSummary: summaryText(
                pose: pose,
                frameStatus: frameObservation.status
            ),
            timestamp: timestamp
        )
    }

    private enum RulePose {
        case record
        case submit
        case cancel
        case background
    }

    private func updateState(
        pose: RulePose,
        bestEffortSummary: String,
        timestamp: Date
    ) -> GestureInterpretation {
        var candidate: GestureCandidate = .noAction
        var summary = bestEffortSummary
        var confidence = 0.0

        if pose != .record {
            if recordLatched {
                recordReleaseCount += 1
            } else {
                recordReleaseCount = 0
            }
        } else {
            recordReleaseCount = 0
        }

        switch pose {
        case .cancel:
            cancelActivationCount += 1
            recordActivationCount = 0
            submitActivationCount = 0
            submitLatched = false

            if !cancelLatched, cancelActivationCount >= Self.cancelActivationFrames {
                cancelLatched = true
                cancelActivationCount = 0
                candidate = .cancelStarted
                summary = "Cancel pose stabilized"
                confidence = 1.0
            } else if !cancelLatched {
                summary = "Cancel pose held (\(cancelActivationCount)/\(Self.cancelActivationFrames))"
                confidence = Double(cancelActivationCount) / Double(Self.cancelActivationFrames)
            } else {
                summary = "Cancel pose held"
                confidence = 1.0
            }

        case .submit:
            if !submitLatched {
                submitActivationCount += 1
            }

            recordActivationCount = 0
            cancelActivationCount = 0
            cancelLatched = false

            if !submitLatched, submitActivationCount >= Self.submitActivationFrames {
                submitLatched = true
                submitActivationCount = 0
                candidate = .submitStarted
                summary = "Submit pose stabilized"
                confidence = 1.0
            } else if !submitLatched {
                summary = "Submit pose held (\(submitActivationCount)/\(Self.submitActivationFrames))"
                confidence = Double(submitActivationCount) / Double(Self.submitActivationFrames)
            } else {
                summary = "Submit pose held"
                confidence = 1.0
            }

        case .record:
            cancelActivationCount = 0
            cancelLatched = false
            submitActivationCount = 0
            submitLatched = false

            if !recordLatched {
                recordActivationCount += 1
            } else {
                recordActivationCount = 0
            }

            if !recordLatched, recordActivationCount >= Self.recordActivationFrames {
                recordLatched = true
                recordActivationCount = 0
                candidate = .recordStarted
                summary = "Record pose stabilized"
                confidence = 1.0
            } else if !recordLatched {
                summary = "Record pose held (\(recordActivationCount)/\(Self.recordActivationFrames))"
                confidence = Double(recordActivationCount) / Double(Self.recordActivationFrames)
            } else {
                summary = "Record pose held"
                confidence = 1.0
            }

        case .background:
            cancelActivationCount = 0
            cancelLatched = false
            submitActivationCount = 0
            submitLatched = false
            recordActivationCount = 0

            if recordLatched {
                summary = "Record release held (\(recordReleaseCount)/\(Self.recordRearmFrames))"
                confidence = Double(recordReleaseCount) / Double(Self.recordRearmFrames)
            } else {
                recordReleaseCount = 0
            }
        }

        if pose != .record, recordLatched, recordReleaseCount >= Self.recordRearmFrames {
            recordLatched = false
            recordReleaseCount = 0
            if candidate == .noAction {
                candidate = .recordRearmed
                summary = "Record re-armed"
                confidence = 1.0
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

    private func classifyRulePose(hand: HandPoseObservation) -> RulePose {
        if isCancelPose(hand: hand) {
            return .cancel
        }

        if isSubmitPose(hand: hand) {
            return .submit
        }

        if isRecordPose(hand: hand) {
            return .record
        }

        return .background
    }

    private func summaryText(
        pose: RulePose,
        frameStatus: CameraFrameObservationStatus
    ) -> String {
        switch pose {
        case .record:
            return "Record rule pose observed"
        case .submit:
            return "Submit rule pose observed"
        case .cancel:
            return "Cancel rule pose observed"
        case .background:
            if case .noRightHandDetected = frameStatus {
                return frameStatus.detailMessage
            }
            return "Waiting for a stable gesture"
        }
    }

    private func isRecordPose(hand: HandPoseObservation) -> Bool {
        guard
            let wrist = hand.landmarks[.wrist],
            let thumbTip = hand.landmarks[.thumbTip],
            let indexTip = hand.landmarks[.indexTip],
            let middleTip = hand.landmarks[.middleTip],
            let middlePIP = hand.landmarks[.middlePIP],
            let ringTip = hand.landmarks[.ringTip],
            let ringPIP = hand.landmarks[.ringPIP],
            let littleTip = hand.landmarks[.littleTip],
            let littlePIP = hand.landmarks[.littlePIP]
        else {
            return false
        }

        return isThumbIndexContacted(
            thumbTip: thumbTip,
            indexTip: indexTip,
            hand: hand
        ) && !isExtended(tip: middleTip, joint: middlePIP, wrist: wrist)
            && !isExtended(tip: ringTip, joint: ringPIP, wrist: wrist)
            && !isExtended(tip: littleTip, joint: littlePIP, wrist: wrist)
    }

    private func isSubmitPose(hand: HandPoseObservation) -> Bool {
        guard
            let wrist = hand.landmarks[.wrist],
            let thumbTip = hand.landmarks[.thumbTip],
            let indexTip = hand.landmarks[.indexTip],
            let middleTip = hand.landmarks[.middleTip],
            let middlePIP = hand.landmarks[.middlePIP],
            let ringTip = hand.landmarks[.ringTip],
            let ringPIP = hand.landmarks[.ringPIP],
            let littleTip = hand.landmarks[.littleTip],
            let littlePIP = hand.landmarks[.littlePIP]
        else {
            return false
        }

        return isThumbIndexContacted(
            thumbTip: thumbTip,
            indexTip: indexTip,
            hand: hand
        ) && isExtended(tip: middleTip, joint: middlePIP, wrist: wrist)
            && isExtended(tip: ringTip, joint: ringPIP, wrist: wrist)
            && isExtended(tip: littleTip, joint: littlePIP, wrist: wrist)
    }

    private func isCancelPose(hand: HandPoseObservation) -> Bool {
        guard
            let wrist = hand.landmarks[.wrist],
            let thumbTip = hand.landmarks[.thumbTip],
            let thumbIP = hand.landmarks[.thumbIP],
            let indexTip = hand.landmarks[.indexTip],
            let indexPIP = hand.landmarks[.indexPIP],
            let middleTip = hand.landmarks[.middleTip],
            let middlePIP = hand.landmarks[.middlePIP],
            let ringTip = hand.landmarks[.ringTip],
            let ringPIP = hand.landmarks[.ringPIP],
            let littleTip = hand.landmarks[.littleTip],
            let littlePIP = hand.landmarks[.littlePIP]
        else {
            return false
        }

        return !isThumbIndexContacted(
            thumbTip: thumbTip,
            indexTip: indexTip,
            hand: hand
        ) && isExtended(tip: thumbTip, joint: thumbIP, wrist: wrist)
            && isExtended(tip: indexTip, joint: indexPIP, wrist: wrist)
            && isExtended(tip: middleTip, joint: middlePIP, wrist: wrist)
            && isExtended(tip: ringTip, joint: ringPIP, wrist: wrist)
            && isExtended(tip: littleTip, joint: littlePIP, wrist: wrist)
    }

    private func isThumbIndexContacted(
        thumbTip: HandLandmarkObservation,
        indexTip: HandLandmarkObservation,
        hand: HandPoseObservation
    ) -> Bool {
        guard let wrist = hand.landmarks[.wrist] else {
            return false
        }

        let handSpan = max(
            distance(wrist, hand.landmarks[.indexMCP]),
            distance(wrist, hand.landmarks[.middleMCP]),
            distance(wrist, hand.landmarks[.ringMCP]),
            distance(wrist, hand.landmarks[.littleMCP]),
            0.0001
        )

        let thumbIndexContactDistance = distance(thumbTip, indexTip) / handSpan
        return thumbIndexContactDistance <= 0.22
    }

    private func distance(
        _ lhs: HandLandmarkObservation,
        _ rhs: HandLandmarkObservation?
    ) -> Double {
        guard let rhs else {
            return 0
        }

        return hypot(Double(lhs.x - rhs.x), Double(lhs.y - rhs.y))
    }

    private func isExtended(
        tip: HandLandmarkObservation,
        joint: HandLandmarkObservation,
        wrist: HandLandmarkObservation
    ) -> Bool {
        let tipDistance = distance(tip, wrist)
        let jointDistance = distance(joint, wrist)
        return tipDistance > jointDistance * 1.2
    }
}
