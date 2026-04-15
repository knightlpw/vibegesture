import Foundation

enum GestureCandidate: String, Codable, Equatable {
    case noAction
    case recordStarted
    case recordRearmed
    case submitStarted
    case cancelStarted

    var displayName: String {
        switch self {
        case .noAction:
            return "No action"
        case .recordStarted:
            return "Record started"
        case .recordRearmed:
            return "Record re-armed"
        case .submitStarted:
            return "Submit started"
        case .cancelStarted:
            return "Cancel started"
        }
    }

    var isActionCandidate: Bool {
        switch self {
        case .noAction, .recordRearmed:
            return false
        case .recordStarted, .submitStarted, .cancelStarted:
            return true
        }
    }
}

struct GestureInterpretation: Equatable {
    let timestamp: Date
    let candidate: GestureCandidate
    let confidence: Double
    let summary: String

    static func noAction(timestamp: Date, summary: String = "Waiting for a stable gesture") -> GestureInterpretation {
        GestureInterpretation(
            timestamp: timestamp,
            candidate: .noAction,
            confidence: 0,
            summary: summary
        )
    }

    var displayText: String {
        "\(candidate.displayName) · \(summary)"
    }

    var candidateDisplayName: String {
        candidate.displayName
    }

    var poseSummary: String {
        summary
    }
}

enum RecognitionActionIntent: Equatable {
    case none
    case toggleRecording
    case submit(stopRecordingFirst: Bool, postStopDelay: TimeInterval)
    case cancel

    var displayName: String {
        switch self {
        case .none:
            return "No action"
        case .toggleRecording:
            return "Toggle recording"
        case .submit(let stopRecordingFirst, let postStopDelay):
            if stopRecordingFirst {
                let delayMillis = Int((postStopDelay * 1000).rounded())
                return "Submit · stop first · \(delayMillis) ms delay"
            }
            return "Submit"
        case .cancel:
            return "Cancel"
        }
    }

    var isAction: Bool {
        self != .none
    }
}

struct RecognitionTransition: Equatable {
    let state: RecognitionState
    let recordingActive: Bool
    let gestureInterpretation: GestureInterpretation?
    let actionIntent: RecognitionActionIntent
    let shouldStartCamera: Bool
    let shouldStopCamera: Bool
}
