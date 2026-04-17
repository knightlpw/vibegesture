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

    private static let recordActivationConfidenceThreshold = 0.58
    private static let submitActivationConfidenceThreshold = 0.58

    private var classifier: GesturePoseClassifying

    private var recordActivationCount = 0
    private var recordReleaseCount = 0
    private var submitActivationCount = 0
    private var cancelActivationCount = 0
    private var recordLatched = false
    private var submitLatched = false
    private var cancelLatched = false

    init(classifier: GesturePoseClassifying = LearnedGesturePoseClassifier()) {
        self.classifier = classifier
    }

    func updateClassifier(_ classifier: GesturePoseClassifying) {
        self.classifier = classifier
    }

    func interpret(frameObservation: CameraFrameObservation) -> GestureInterpretation {
        let timestamp = frameObservation.timestamp

        guard let hand = frameObservation.hands.first else {
            return updateState(
                classification: nil,
                isCancelPose: false,
                isRecordReleasePose: false,
                bestEffortSummary: frameObservation.status.detailMessage,
                timestamp: timestamp
            )
        }

        let classification = classifier.classify(hand: hand)
        let isCancelPose = isCancelPose(hand: hand)
        let isRecordReleasePose = isRecordReleasePose(hand: hand)

        return updateState(
            classification: classification,
            isCancelPose: isCancelPose,
            isRecordReleasePose: isRecordReleasePose,
            bestEffortSummary: summaryText(
                classification: classification,
                frameStatus: frameObservation.status
            ),
            timestamp: timestamp
        )
    }

    private func updateState(
        classification: GestureClassification?,
        isCancelPose: Bool,
        isRecordReleasePose: Bool,
        bestEffortSummary: String,
        timestamp: Date
    ) -> GestureInterpretation {
        var candidate: GestureCandidate = .noAction
        var summary = bestEffortSummary
        var confidence = classification?.confidence ?? 0

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
            confidence = max(confidence, Double(cancelActivationCount) / Double(Self.cancelActivationFrames))
        }

        if candidate == .noAction {
            switch classification?.label {
            case .submit:
                if (classification?.confidence ?? 0) >= Self.submitActivationConfidenceThreshold {
                    submitActivationCount += 1
                } else {
                    if !submitLatched {
                        submitActivationCount = 0
                    }
                }

                if !submitLatched, submitActivationCount >= Self.submitActivationFrames {
                    submitLatched = true
                    submitActivationCount = 0
                    candidate = .submitStarted
                    summary = "Submit classifier stabilized"
                    confidence = classification?.confidence ?? 0
                } else if candidate == .noAction {
                    summary = "Submit classifier held (\(submitActivationCount)/\(Self.submitActivationFrames))"
                    confidence = classification?.confidence ?? confidence
                }

                recordActivationCount = 0
                recordReleaseCount = 0

            case .record:
                if (classification?.confidence ?? 0) >= Self.recordActivationConfidenceThreshold {
                    recordActivationCount += 1
                    recordReleaseCount = 0
                } else {
                    if !recordLatched {
                        recordActivationCount = 0
                    }
                }

                if !recordLatched, recordActivationCount >= Self.recordActivationFrames {
                    recordLatched = true
                    recordActivationCount = 0
                    if candidate == .noAction {
                        candidate = .recordStarted
                        summary = "Record classifier stabilized"
                        confidence = classification?.confidence ?? 0
                    }
                } else if candidate == .noAction {
                    summary = "Record classifier held (\(recordActivationCount)/\(Self.recordActivationFrames))"
                    confidence = classification?.confidence ?? confidence
                }

                submitActivationCount = 0
                submitLatched = false

            case .cancel:
                recordActivationCount = 0
                recordReleaseCount = 0
                submitActivationCount = 0
                submitLatched = false

            case .background:
                recordActivationCount = 0
                submitActivationCount = 0
                submitLatched = false

                if recordLatched, isRecordReleasePose {
                    recordReleaseCount += 1

                    if recordReleaseCount >= Self.recordRearmFrames {
                        recordLatched = false
                        recordReleaseCount = 0
                        if candidate == .noAction {
                            candidate = .recordRearmed
                            summary = "Record re-armed"
                            confidence = classification?.confidence ?? confidence
                        }
                    } else if candidate == .noAction {
                        summary = "Record release held (\(recordReleaseCount)/\(Self.recordRearmFrames))"
                        confidence = classification?.confidence ?? confidence
                    }
                } else if !recordLatched {
                    recordReleaseCount = 0
                }

            case .none:
                recordActivationCount = 0
                submitActivationCount = 0
                submitLatched = false
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

    private func summaryText(
        classification: GestureClassification?,
        frameStatus: CameraFrameObservationStatus
    ) -> String {
        guard let classification else {
            return frameStatus.detailMessage
        }

        let confidence = Int((classification.confidence * 100).rounded())
        switch classification.label {
        case .record:
            return "Record classifier observed (\(confidence)%)"
        case .submit:
            return "Submit classifier observed (\(confidence)%)"
        case .cancel:
            return "Cancel classifier observed (\(confidence)%)"
        case .background:
            if case .noRightHandDetected = frameStatus {
                return frameStatus.detailMessage
            }
            return "Background classifier observed (\(confidence)%)"
        }
    }

    private func isCancelPose(hand: HandPoseObservation) -> Bool {
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
            return false
        }

        let handSpan = max(
            distance(wrist, indexMCP),
            distance(wrist, middleMCP),
            distance(wrist, ringMCP),
            distance(wrist, littleMCP),
            0.0001
        )

        let thumbIndexContactDistance = distance(thumbTip, indexTip) / handSpan
        let thumbIndexContactThreshold = 0.22
        let thumbIndexContacted = thumbIndexContactDistance <= thumbIndexContactThreshold

        let indexExtended = isExtended(tip: indexTip, joint: indexPIP, wrist: wrist)
        let middleExtended = isExtended(tip: middleTip, joint: middlePIP, wrist: wrist)
        let ringExtended = isExtended(tip: ringTip, joint: ringPIP, wrist: wrist)
        let littleExtended = isExtended(tip: littleTip, joint: littlePIP, wrist: wrist)
        let thumbExtended = isExtended(tip: thumbTip, joint: thumbIP, wrist: wrist)

        return !thumbIndexContacted
            && thumbExtended
            && indexExtended
            && middleExtended
            && ringExtended
            && littleExtended
    }

    private func isRecordReleasePose(hand: HandPoseObservation) -> Bool {
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
            return false
        }

        let handSpan = max(
            distance(wrist, indexMCP),
            distance(wrist, middleMCP),
            distance(wrist, ringMCP),
            distance(wrist, littleMCP),
            0.0001
        )

        let thumbIndexContactDistance = distance(thumbTip, indexTip) / handSpan
        let thumbIndexContactThreshold = 0.22
        let thumbIndexContacted = thumbIndexContactDistance <= thumbIndexContactThreshold

        let indexExtended = isExtended(tip: indexTip, joint: indexPIP, wrist: wrist)
        let middleExtended = isExtended(tip: middleTip, joint: middlePIP, wrist: wrist)
        let ringExtended = isExtended(tip: ringTip, joint: ringPIP, wrist: wrist)
        let littleExtended = isExtended(tip: littleTip, joint: littlePIP, wrist: wrist)
        let thumbOpening = distance(thumbTip, thumbIP) / handSpan

        return !thumbIndexContacted
            && thumbOpening >= 0.08
            && indexExtended
            && middleExtended
            && ringExtended
            && littleExtended
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
        return tipDistance > jointDistance * 1.2
    }
}
