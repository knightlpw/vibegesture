import Foundation

@MainActor
final class RecognitionCoordinator {
    private var stateMachine = RecognitionStateMachine()
    private let interpreter: GestureInterpreting

    init(interpreter: GestureInterpreting = GestureInterpreter()) {
        self.interpreter = interpreter
    }

    var currentState: RecognitionState {
        stateMachine.state
    }

    var latestGestureInterpretation: GestureInterpretation? {
        stateMachine.latestGestureInterpretation
    }

    var latestActionIntent: RecognitionActionIntent {
        stateMachine.latestActionIntent
    }

    func setRecognitionEnabled(
        _ enabled: Bool,
        permissionState: PermissionState,
        timestamp: Date = Date()
    ) -> RecognitionTransition {
        stateMachine.setRecognitionEnabled(
            enabled,
            permissionState: permissionState,
            timestamp: timestamp
        )
    }

    func updatePermissionState(
        _ permissionState: PermissionState,
        timestamp: Date = Date()
    ) -> RecognitionTransition {
        stateMachine.updatePermissionState(permissionState, timestamp: timestamp)
    }

    func process(frameObservation: CameraFrameObservation) -> RecognitionTransition {
        let interpretation = interpreter.interpret(frameObservation: frameObservation)
        return stateMachine.process(gestureInterpretation: interpretation, timestamp: interpretation.timestamp)
    }

    func updateForegroundAppGate(
        _ supported: Bool,
        permissionState: PermissionState,
        timestamp: Date = Date()
    ) -> RecognitionTransition {
        stateMachine.updateForegroundAppGate(
            supported,
            permissionState: permissionState,
            timestamp: timestamp
        )
    }

    func setRecordingActive(_ active: Bool) {
        stateMachine.setRecordingActive(active)
    }
}
