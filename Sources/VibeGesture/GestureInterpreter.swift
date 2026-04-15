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

    func interpret(frameObservation: CameraFrameObservation) -> GestureInterpretation {
        let timestamp = frameObservation.timestamp

        guard let hand = frameObservation.hands.first,
              let analysis = analyze(hand: hand, frameStatus: frameObservation.status) else {
            return updateState(
                isRecordPose: false,
                isSubmitPose: false,
                isCancelPose: false,
                bestEffortSummary: frameObservation.status.detailMessage,
                timestamp: timestamp
            )
        }

        return updateState(
            isRecordPose: analysis.isRecordPose,
            isSubmitPose: analysis.isSubmitPose,
            isCancelPose: analysis.isCancelPose,
            bestEffortSummary: analysis.summary,
            timestamp: timestamp
        )
    }

    private func updateState(
        isRecordPose: Bool,
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

        if isRecordPose {
            recordActivationCount += 1
            recordReleaseCount = 0

            if !recordLatched, recordActivationCount >= Self.recordActivationFrames {
                recordLatched = true
                recordActivationCount = 0
                if candidate == .noAction {
                    candidate = .recordStarted
                    summary = "Record pose stabilized"
                    confidence = 1.0
                }
            } else if candidate == .noAction {
                summary = "Record pose held (\(recordActivationCount)/\(Self.recordActivationFrames))"
                confidence = Double(recordActivationCount) / Double(Self.recordActivationFrames)
            }
        } else {
            recordActivationCount = 0

            if recordLatched {
                recordReleaseCount += 1

                if recordReleaseCount >= Self.recordRearmFrames {
                    recordLatched = false
                    recordReleaseCount = 0
                    if candidate == .noAction {
                        candidate = .recordRearmed
                        summary = "Record re-armed"
                        confidence = 1.0
                    }
                } else if candidate == .noAction {
                    summary = "Record release held (\(recordReleaseCount)/\(Self.recordRearmFrames))"
                    confidence = Double(recordReleaseCount) / Double(Self.recordRearmFrames)
                }
            } else {
                recordReleaseCount = 0
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

        let thumbIndexContactDistance = distance(thumbTip, indexTip) / handSpan
        let thumbIndexContactThreshold = 0.28
        let thumbIndexContacted = thumbIndexContactDistance <= thumbIndexContactThreshold

        let indexExtended = isExtended(tip: indexTip, joint: indexPIP, wrist: wrist)
        let middleExtended = isExtended(tip: middleTip, joint: middlePIP, wrist: wrist)
        let ringExtended = isExtended(tip: ringTip, joint: ringPIP, wrist: wrist)
        let littleExtended = isExtended(tip: littleTip, joint: littlePIP, wrist: wrist)
        let thumbExtended = isExtended(tip: thumbTip, joint: thumbIP, wrist: wrist)

        let isRecordPose = thumbIndexContacted
            && !middleExtended
            && !ringExtended
            && !littleExtended

        let isSubmitPose = thumbIndexContacted
            && middleExtended
            && ringExtended
            && littleExtended

        let isCancelPose = !thumbIndexContacted
            && thumbExtended
            && indexExtended
            && middleExtended
            && ringExtended
            && littleExtended

        let thumbIndexContactScore = min(1, max(0, 1 - (thumbIndexContactDistance / thumbIndexContactThreshold)))
        let curledScore = average([
            middleExtended ? 0 : 1,
            ringExtended ? 0 : 1,
            littleExtended ? 0 : 1
        ])
        let recordConfidence = average([thumbIndexContactScore, curledScore])
        let submitConfidence = average([
            thumbIndexContactScore,
            middleExtended ? 1 : 0,
            ringExtended ? 1 : 0,
            littleExtended ? 1 : 0
        ])
        let cancelConfidence = average([
            thumbExtended ? 1 : 0,
            indexExtended ? 1 : 0,
            middleExtended ? 1 : 0,
            ringExtended ? 1 : 0,
            littleExtended ? 1 : 0,
            thumbIndexContacted ? 0 : 1
        ])
        let confidence = max(recordConfidence, submitConfidence, cancelConfidence)

        var summary: String
        if isCancelPose {
            summary = "Cancel pose observed"
        } else if isSubmitPose {
            summary = "Submit pose observed"
        } else if isRecordPose {
            summary = "Record pose observed"
        } else {
            summary = "Waiting for a stable gesture"
            if case .noRightHandDetected = frameStatus {
                summary = frameStatus.detailMessage
            } else if case .pipelineFailed(let message) = frameStatus {
                summary = message
            }
        }

        return PoseAnalysis(
            isRecordPose: isRecordPose,
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

    private func average(_ values: [Double]) -> Double {
        guard !values.isEmpty else {
            return 0
        }
        return values.reduce(0, +) / Double(values.count)
    }
}

private struct PoseAnalysis {
    let isRecordPose: Bool
    let isSubmitPose: Bool
    let isCancelPose: Bool
    let confidence: Double
    let summary: String
}
