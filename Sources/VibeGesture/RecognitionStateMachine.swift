import Foundation

struct RecognitionStateMachine {
    private(set) var state: RecognitionState = .disabled
    private(set) var recordingActive = false
    private(set) var latestGestureInterpretation: GestureInterpretation?
    private(set) var latestActionIntent: RecognitionActionIntent = .none

    private var recognitionEnabled = false
    private var permissionState: PermissionState = .missingBoth
    private var foregroundAppSupported = false
    private var cooldownDeadline: Date?
    private var cooldownReturnState: RecognitionState = .idle

    mutating func setRecognitionEnabled(
        _ enabled: Bool,
        permissionState: PermissionState,
        timestamp: Date = Date()
    ) -> RecognitionTransition {
        _ = timestamp
        recognitionEnabled = enabled
        self.permissionState = permissionState
        cooldownDeadline = nil
        cooldownReturnState = .idle

        let previousState = state

        if !enabled {
            state = .disabled
        } else if !foregroundAppSupported {
            state = .disabled
        } else if permissionState.isReady {
            state = .idle
        } else {
            state = .errorPermissionMissing
        }

        return makeTransition(
            gestureInterpretation: nil,
            actionIntent: .none,
            shouldStartCamera: state == .idle && previousState != .idle,
            shouldStopCamera: previousState != .disabled && previousState != .errorPermissionMissing && state == .disabled
        )
    }

    mutating func updatePermissionState(
        _ permissionState: PermissionState,
        timestamp: Date = Date()
    ) -> RecognitionTransition {
        _ = timestamp
        self.permissionState = permissionState
        cooldownDeadline = nil
        cooldownReturnState = .idle

        let previousState = state

        if !permissionState.isReady {
            state = .errorPermissionMissing
        } else if !foregroundAppSupported {
            state = .disabled
        } else if recognitionEnabled {
            state = .idle
        } else {
            state = .disabled
        }

        return makeTransition(
            gestureInterpretation: nil,
            actionIntent: .none,
            shouldStartCamera: previousState != .idle && state == .idle,
            shouldStopCamera: previousState != .disabled && previousState != .errorPermissionMissing && state == .errorPermissionMissing
        )
    }

    mutating func process(
        gestureInterpretation: GestureInterpretation,
        timestamp: Date = Date()
    ) -> RecognitionTransition {
        _ = timestamp
        latestGestureInterpretation = gestureInterpretation
        resolveCooldownIfNeeded(at: gestureInterpretation.timestamp)

        guard recognitionEnabled, permissionState.isReady, foregroundAppSupported else {
            return makeTransition(
                gestureInterpretation: gestureInterpretation,
                actionIntent: .none,
                shouldStartCamera: false,
                shouldStopCamera: false
            )
        }

        guard state != .disabled, state != .errorPermissionMissing else {
            return makeTransition(
                gestureInterpretation: gestureInterpretation,
                actionIntent: .none,
                shouldStartCamera: false,
                shouldStopCamera: false
            )
        }

        guard state != .cooldown else {
            return makeTransition(
                gestureInterpretation: gestureInterpretation,
                actionIntent: .none,
                shouldStartCamera: false,
                shouldStopCamera: false
            )
        }

        let actionIntent: RecognitionActionIntent

        switch gestureInterpretation.candidate {
        case .noAction, .recordRearmed:
            actionIntent = .none
        case .recordStarted:
            actionIntent = .toggleRecording
            recordingActive.toggle()
            cooldownDeadline = gestureInterpretation.timestamp.addingTimeInterval(Self.cooldownDuration)
            cooldownReturnState = (state == .recordingActive) ? .idle : .recordingActive
            state = .cooldown
        case .submitStarted:
            let stopRecordingFirst = recordingActive
            actionIntent = .submit(
                stopRecordingFirst: stopRecordingFirst,
                postStopDelay: stopRecordingFirst ? Self.submitStopDelay : 0
            )
            recordingActive = false
            cooldownDeadline = gestureInterpretation.timestamp.addingTimeInterval(Self.cooldownDuration)
            cooldownReturnState = .idle
            state = .cooldown
        case .cancelStarted:
            actionIntent = .cancel
            recordingActive = false
            cooldownDeadline = gestureInterpretation.timestamp.addingTimeInterval(Self.cooldownDuration)
            cooldownReturnState = .idle
            state = .cooldown
        }

        if actionIntent.isAction {
            latestActionIntent = actionIntent
        }

        return makeTransition(
            gestureInterpretation: gestureInterpretation,
            actionIntent: actionIntent,
            shouldStartCamera: false,
            shouldStopCamera: false
        )
    }

    mutating func updateForegroundAppGate(
        _ supported: Bool,
        permissionState: PermissionState,
        timestamp: Date = Date()
    ) -> RecognitionTransition {
        _ = timestamp
        guard supported != foregroundAppSupported else {
            return makeTransition(
                gestureInterpretation: nil,
                actionIntent: .none,
                shouldStartCamera: false,
                shouldStopCamera: false
            )
        }

        foregroundAppSupported = supported
        self.permissionState = permissionState
        cooldownDeadline = nil
        cooldownReturnState = .idle

        let previousState = state

        if !supported {
            recordingActive = false
            state = .disabled
        } else if !recognitionEnabled {
            state = .disabled
        } else if permissionState.isReady {
            state = .idle
        } else {
            state = .errorPermissionMissing
        }

        return makeTransition(
            gestureInterpretation: nil,
            actionIntent: .none,
            shouldStartCamera: previousState != .idle && state == .idle,
            shouldStopCamera: previousState != .disabled && state == .disabled
        )
    }

    mutating func setRecordingActive(_ active: Bool) {
        recordingActive = active
    }

    private mutating func resolveCooldownIfNeeded(at timestamp: Date) {
        guard state == .cooldown, let cooldownDeadline, timestamp >= cooldownDeadline else {
            return
        }

        state = cooldownReturnState
        cooldownReturnState = .idle
        self.cooldownDeadline = nil
    }

    private func makeTransition(
        gestureInterpretation: GestureInterpretation?,
        actionIntent: RecognitionActionIntent,
        shouldStartCamera: Bool,
        shouldStopCamera: Bool
    ) -> RecognitionTransition {
        return RecognitionTransition(
            state: state,
            recordingActive: recordingActive,
            gestureInterpretation: gestureInterpretation,
            actionIntent: actionIntent,
            shouldStartCamera: shouldStartCamera,
            shouldStopCamera: shouldStopCamera
        )
    }

    private static let cooldownDuration: TimeInterval = 0.7
    private static let submitStopDelay: TimeInterval = 0.3
}
