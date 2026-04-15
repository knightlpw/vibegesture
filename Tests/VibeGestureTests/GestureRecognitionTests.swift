import Foundation
import XCTest
@testable import VibeGesture

final class GestureRecognitionTests: XCTestCase {
    func testGestureInterpreterEmitsRecordStartAndRearm() {
        let interpreter = GestureInterpreter()
        let baseTime = Date(timeIntervalSinceReferenceDate: 1_000)

        let recordResults = (0..<6).map { index in
            interpreter.interpret(
                frameObservation: makeFrameObservation(
                    pose: .record,
                    timestamp: baseTime.addingTimeInterval(Double(index) * 0.05)
                )
            )
        }

        XCTAssertEqual(recordResults.dropLast().map(\.candidate), Array(repeating: .noAction, count: 5))
        XCTAssertEqual(recordResults.last?.candidate, .recordStarted)

        let releaseResults = (0..<4).map { index in
            interpreter.interpret(
                frameObservation: makeFrameObservation(
                    pose: nil,
                    timestamp: baseTime.addingTimeInterval(0.35 + Double(index) * 0.05)
                )
            )
        }

        XCTAssertEqual(releaseResults.dropLast().map(\.candidate), Array(repeating: .noAction, count: 3))
        XCTAssertEqual(releaseResults.last?.candidate, .recordRearmed)
    }

    func testGestureInterpreterEmitsSubmitAndCancelOnlyOnce() {
        let interpreter = GestureInterpreter()
        let baseTime = Date(timeIntervalSinceReferenceDate: 2_000)

        let submitResults = (0..<4).map { index in
            interpreter.interpret(
                frameObservation: makeFrameObservation(
                    pose: .submit,
                    timestamp: baseTime.addingTimeInterval(Double(index) * 0.05)
                )
            )
        }

        XCTAssertEqual(submitResults.dropLast().map(\.candidate), Array(repeating: .noAction, count: 3))
        XCTAssertEqual(submitResults.last?.candidate, .submitStarted)

        let submitRepeat = interpreter.interpret(
            frameObservation: makeFrameObservation(
                pose: .submit,
                timestamp: baseTime.addingTimeInterval(0.25)
            )
        )
        XCTAssertEqual(submitRepeat.candidate, .noAction)

        let cancelInterpreter = GestureInterpreter()
        let cancelResults = (0..<3).map { index in
            cancelInterpreter.interpret(
                frameObservation: makeFrameObservation(
                    pose: .cancel,
                    timestamp: baseTime.addingTimeInterval(Double(index) * 0.05)
                )
            )
        }

        XCTAssertEqual(cancelResults.dropLast().map(\.candidate), Array(repeating: .noAction, count: 2))
        XCTAssertEqual(cancelResults.last?.candidate, .cancelStarted)

        let cancelRepeat = cancelInterpreter.interpret(
            frameObservation: makeFrameObservation(
                pose: .cancel,
                timestamp: baseTime.addingTimeInterval(0.2)
            )
        )
        XCTAssertEqual(cancelRepeat.candidate, .noAction)
    }

    func testRecognitionStateMachineTransitionsThroughCooldown() {
        var machine = RecognitionStateMachine()
        let baseTime = Date(timeIntervalSinceReferenceDate: 3_000)

        let gateSupported = machine.updateForegroundAppGate(
            true,
            permissionState: .ready,
            timestamp: baseTime
        )
        XCTAssertEqual(gateSupported.state, .disabled)

        let enable = machine.setRecognitionEnabled(true, permissionState: .ready, timestamp: baseTime)
        XCTAssertEqual(enable.state, .idle)
        XCTAssertTrue(enable.shouldStartCamera)
        XCTAssertFalse(enable.shouldStopCamera)

        let recordStarted = machine.process(
            gestureInterpretation: GestureInterpretation(
                timestamp: baseTime.addingTimeInterval(0.1),
                candidate: .recordStarted,
                confidence: 1.0,
                summary: "Record pose stabilized"
            )
        )
        XCTAssertEqual(recordStarted.state, .cooldown)
        XCTAssertEqual(recordStarted.actionIntent, .toggleRecording)
        XCTAssertTrue(recordStarted.recordingActive)
        XCTAssertEqual(machine.latestActionIntent, .toggleRecording)

        let recordCooldownExit = machine.process(
            gestureInterpretation: GestureInterpretation.noAction(
                timestamp: baseTime.addingTimeInterval(0.9),
                summary: "Waiting for a stable gesture"
            )
        )
        XCTAssertEqual(recordCooldownExit.state, .recordingActive)
        XCTAssertEqual(recordCooldownExit.actionIntent, .none)
        XCTAssertTrue(recordCooldownExit.recordingActive)

        let submitStarted = machine.process(
            gestureInterpretation: GestureInterpretation(
                timestamp: baseTime.addingTimeInterval(1.0),
                candidate: .submitStarted,
                confidence: 1.0,
                summary: "Submit pose stabilized"
            )
        )
        XCTAssertEqual(submitStarted.state, .cooldown)
        XCTAssertEqual(
            submitStarted.actionIntent,
            .submit(stopRecordingFirst: true, postStopDelay: 0.3)
        )
        XCTAssertFalse(submitStarted.recordingActive)

        let submitCooldownExit = machine.process(
            gestureInterpretation: GestureInterpretation.noAction(
                timestamp: baseTime.addingTimeInterval(1.8),
                summary: "Waiting for a stable gesture"
            )
        )
        XCTAssertEqual(submitCooldownExit.state, .idle)
        XCTAssertEqual(submitCooldownExit.actionIntent, .none)
        XCTAssertFalse(submitCooldownExit.recordingActive)
    }

    func testRecognitionStateMachineKeepsRecordingStateWhenDisabledDuringCooldown() {
        var machine = RecognitionStateMachine()
        let baseTime = Date(timeIntervalSinceReferenceDate: 3_500)

        let gateSupported = machine.updateForegroundAppGate(
            true,
            permissionState: .ready,
            timestamp: baseTime
        )
        XCTAssertEqual(gateSupported.state, .disabled)

        let enable = machine.setRecognitionEnabled(true, permissionState: .ready, timestamp: baseTime)
        XCTAssertEqual(enable.state, .idle)
        XCTAssertFalse(enable.recordingActive)

        let recordStarted = machine.process(
            gestureInterpretation: GestureInterpretation(
                timestamp: baseTime.addingTimeInterval(0.1),
                candidate: .recordStarted,
                confidence: 1.0,
                summary: "Record pose stabilized"
            )
        )
        XCTAssertEqual(recordStarted.state, .cooldown)
        XCTAssertEqual(recordStarted.actionIntent, .toggleRecording)
        XCTAssertTrue(recordStarted.recordingActive)

        let disableDuringCooldown = machine.setRecognitionEnabled(
            false,
            permissionState: .ready,
            timestamp: baseTime.addingTimeInterval(0.5)
        )
        XCTAssertEqual(disableDuringCooldown.state, .disabled)
        XCTAssertTrue(disableDuringCooldown.recordingActive)
        XCTAssertTrue(disableDuringCooldown.shouldStopCamera)
    }

    func testRecognitionStateMachineHandlesPermissionLossAndRecovery() {
        var machine = RecognitionStateMachine()
        let baseTime = Date(timeIntervalSinceReferenceDate: 4_000)

        let gateSupported = machine.updateForegroundAppGate(
            true,
            permissionState: .ready,
            timestamp: baseTime
        )
        XCTAssertEqual(gateSupported.state, .disabled)

        let enable = machine.setRecognitionEnabled(true, permissionState: .ready, timestamp: baseTime)
        XCTAssertEqual(enable.state, .idle)

        let permissionLost = machine.updatePermissionState(.missingCamera, timestamp: baseTime.addingTimeInterval(0.2))
        XCTAssertEqual(permissionLost.state, .errorPermissionMissing)
        XCTAssertTrue(permissionLost.shouldStopCamera)

        let permissionRecovered = machine.updatePermissionState(.ready, timestamp: baseTime.addingTimeInterval(0.4))
        XCTAssertEqual(permissionRecovered.state, .idle)
        XCTAssertTrue(permissionRecovered.shouldStartCamera)
    }

    func testForegroundAppGatePolicyClassifiesSupportedAndUnsupportedApps() {
        let codex = ForegroundAppGatePolicy.classify(
            bundleIdentifier: "com.openai.codex",
            applicationName: "Codex"
        )
        XCTAssertEqual(
            codex,
            .supported(
                ForegroundAppInfo(
                    applicationName: "Codex",
                    bundleIdentifier: "com.openai.codex"
                )
            )
        )

        let unsupported = ForegroundAppGatePolicy.classify(
            bundleIdentifier: "com.apple.Safari",
            applicationName: "Safari"
        )
        XCTAssertEqual(
            unsupported,
            .unsupported(
                ForegroundAppInfo(
                    applicationName: "Safari",
                    bundleIdentifier: "com.apple.Safari"
                )
            )
        )

        let unknown = ForegroundAppGatePolicy.classify(bundleIdentifier: nil, applicationName: nil)
        XCTAssertEqual(unknown, .unknown)
    }

    func testRecognitionStateMachineSuspendsWhenForegroundAppGateIsLost() {
        var machine = RecognitionStateMachine()
        let baseTime = Date(timeIntervalSinceReferenceDate: 4_500)

        let gateSupported = machine.updateForegroundAppGate(
            true,
            permissionState: .ready,
            timestamp: baseTime
        )
        XCTAssertEqual(gateSupported.state, .disabled)

        let enable = machine.setRecognitionEnabled(true, permissionState: .ready, timestamp: baseTime)
        XCTAssertEqual(enable.state, .idle)

        let recordStarted = machine.process(
            gestureInterpretation: GestureInterpretation(
                timestamp: baseTime.addingTimeInterval(0.1),
                candidate: .recordStarted,
                confidence: 1.0,
                summary: "Record pose stabilized"
            )
        )
        XCTAssertEqual(recordStarted.state, .cooldown)
        XCTAssertTrue(recordStarted.recordingActive)

        let gateLost = machine.updateForegroundAppGate(
            false,
            permissionState: .ready,
            timestamp: baseTime.addingTimeInterval(0.2)
        )
        XCTAssertEqual(gateLost.state, .disabled)
        XCTAssertFalse(gateLost.recordingActive)
        XCTAssertTrue(gateLost.shouldStopCamera)

        let gateRestored = machine.updateForegroundAppGate(
            true,
            permissionState: .ready,
            timestamp: baseTime.addingTimeInterval(0.4)
        )
        XCTAssertEqual(gateRestored.state, .idle)
        XCTAssertTrue(gateRestored.shouldStartCamera)
    }

    private enum SyntheticPose {
        case record
        case submit
        case cancel
    }

    private func makeFrameObservation(
        pose: SyntheticPose?,
        timestamp: Date
    ) -> CameraFrameObservation {
        guard let pose else {
            return CameraFrameObservation(
                timestamp: timestamp,
                status: .noRightHandDetected,
                hands: []
            )
        }

        return CameraFrameObservation(
            timestamp: timestamp,
            status: .rightHandDetected,
            hands: [makeHandPoseObservation(pose: pose)]
        )
    }

    private func makeHandPoseObservation(pose: SyntheticPose) -> HandPoseObservation {
        let wrist = landmark(0.50, 0.20)
        let thumbCMC = landmark(0.38, 0.24)
        let thumbMP = landmark(0.43, 0.30)
        let thumbIP = landmark(0.48, 0.36)

        let indexMCP = landmark(0.55, 0.30)
        let indexPIP = landmark(0.57, 0.44)
        let middleMCP = landmark(0.60, 0.31)
        let middlePIP = landmark(0.62, 0.45)
        let ringMCP = landmark(0.65, 0.30)
        let ringPIP = landmark(0.67, 0.44)
        let littleMCP = landmark(0.70, 0.28)
        let littlePIP = landmark(0.72, 0.42)

        let thumbTip: HandLandmarkObservation
        let indexTip: HandLandmarkObservation
        let middleTip: HandLandmarkObservation
        let ringTip: HandLandmarkObservation
        let littleTip: HandLandmarkObservation

        switch pose {
        case .record:
            thumbTip = landmark(0.565, 0.495)
            indexTip = landmark(0.575, 0.500)
            middleTip = landmark(0.605, 0.355)
            ringTip = landmark(0.655, 0.350)
            littleTip = landmark(0.705, 0.345)
        case .submit:
            thumbTip = landmark(0.360, 0.570)
            indexTip = landmark(0.575, 0.840)
            middleTip = landmark(0.625, 0.860)
            ringTip = landmark(0.675, 0.845)
            littleTip = landmark(0.725, 0.830)
        case .cancel:
            thumbTip = landmark(0.360, 0.570)
            indexTip = landmark(0.575, 0.840)
            middleTip = landmark(0.625, 0.860)
            ringTip = landmark(0.650, 0.350)
            littleTip = landmark(0.700, 0.340)
        }

        return HandPoseObservation(
            laterality: .right,
            confidence: 0.98,
            landmarks: [
                .wrist: wrist,
                .thumbCMC: thumbCMC,
                .thumbMP: thumbMP,
                .thumbIP: thumbIP,
                .thumbTip: thumbTip,
                .indexMCP: indexMCP,
                .indexPIP: indexPIP,
                .indexDIP: landmark(0.58, 0.58),
                .indexTip: indexTip,
                .middleMCP: middleMCP,
                .middlePIP: middlePIP,
                .middleDIP: landmark(0.63, 0.60),
                .middleTip: middleTip,
                .ringMCP: ringMCP,
                .ringPIP: ringPIP,
                .ringDIP: landmark(0.68, 0.59),
                .ringTip: ringTip,
                .littleMCP: littleMCP,
                .littlePIP: littlePIP,
                .littleDIP: landmark(0.73, 0.58),
                .littleTip: littleTip
            ]
        )
    }

    private func landmark(_ x: Double, _ y: Double, confidence: Float = 1) -> HandLandmarkObservation {
        HandLandmarkObservation(
            x: x,
            y: y,
            confidence: confidence
        )
    }
}
