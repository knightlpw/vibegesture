import Foundation
import XCTest
@testable import VibeGesture

final class GestureRecognitionTests: XCTestCase {
    func testGestureInterpreterEmitsRecordStartAndRearm() {
        let interpreter = makeTrainedGestureInterpreter()
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
                    pose: .recordRelease,
                    timestamp: baseTime.addingTimeInterval(0.35 + Double(index) * 0.05)
                )
            )
        }

        XCTAssertEqual(releaseResults.dropLast().map(\.candidate), Array(repeating: .noAction, count: 3))
        XCTAssertEqual(releaseResults.last?.candidate, .recordRearmed)
    }

    func testGestureInterpreterKeepsRecordLatchedAcrossBorderlineReleaseFrames() {
        let interpreter = makeTrainedGestureInterpreter()
        let baseTime = Date(timeIntervalSinceReferenceDate: 1_400)

        let recordResults = (0..<6).map { index in
            interpreter.interpret(
                frameObservation: makeFrameObservation(
                    pose: .record,
                    timestamp: baseTime.addingTimeInterval(Double(index) * 0.05)
                )
            )
        }

        XCTAssertEqual(recordResults.last?.candidate, .recordStarted)

        let borderlineFrames = (0..<4).map { index in
            interpreter.interpret(
                frameObservation: makeFrameObservation(
                    pose: .borderlineRecord,
                    timestamp: baseTime.addingTimeInterval(0.35 + Double(index) * 0.05)
                )
            )
        }

        XCTAssertEqual(borderlineFrames.dropLast().map(\.candidate), Array(repeating: .noAction, count: 3))
        XCTAssertEqual(borderlineFrames.last?.candidate, .recordRearmed)

        let continuedRecordFrames = (0..<6).map { index in
            interpreter.interpret(
                frameObservation: makeFrameObservation(
                    pose: .record,
                    timestamp: baseTime.addingTimeInterval(0.60 + Double(index) * 0.05)
                )
            )
        }

        XCTAssertEqual(continuedRecordFrames.dropLast().map(\.candidate), Array(repeating: .noAction, count: 5))
        XCTAssertEqual(continuedRecordFrames.last?.candidate, .recordStarted)
    }

    func testGestureInterpreterEmitsSubmitAndCancelOnlyOnce() {
        let interpreter = makeTrainedGestureInterpreter()
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

        let cancelInterpreter = makeTrainedGestureInterpreter()
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

    func testGestureInterpreterRejectsBorderlineRecordLikePose() {
        let interpreter = makeTrainedGestureInterpreter()
        let baseTime = Date(timeIntervalSinceReferenceDate: 2_250)

        let borderlineResults = (0..<6).map { index in
            interpreter.interpret(
                frameObservation: makeFrameObservation(
                    pose: .borderlineRecord,
                    timestamp: baseTime.addingTimeInterval(Double(index) * 0.05)
                )
            )
        }

        XCTAssertEqual(borderlineResults.map(\.candidate), Array(repeating: .noAction, count: 6))
    }

    func testGestureInterpreterAcceptsCalibratedRecordConfidenceAtRuntimeThreshold() {
        let interpreter = GestureInterpreter(classifier: StubGesturePoseClassifier(
            classification: GestureClassification(
                label: .record,
                confidence: 0.55,
                scores: [
                    .record: 0.55,
                    .submit: 0.20,
                    .cancel: 0.15,
                    .background: 0.10
                ]
            )
        ))
        let baseTime = Date(timeIntervalSinceReferenceDate: 2_300)

        let results = (0..<6).map { index in
            interpreter.interpret(
                frameObservation: makeFrameObservation(
                    pose: .record,
                    timestamp: baseTime.addingTimeInterval(Double(index) * 0.05)
                )
            )
        }

        XCTAssertEqual(results.dropLast().map(\.candidate), Array(repeating: .noAction, count: 5))
        XCTAssertEqual(results.last?.candidate, .recordStarted)
    }

    func testGestureInterpreterRejectsHalfCurledSubmitLikePose() {
        let interpreter = makeTrainedGestureInterpreter()
        let baseTime = Date(timeIntervalSinceReferenceDate: 2_375)

        let misfireResults = (0..<4).map { index in
            interpreter.interpret(
                frameObservation: makeFrameObservation(
                    pose: .halfCurledSubmit,
                    timestamp: baseTime.addingTimeInterval(Double(index) * 0.05)
                )
            )
        }

        XCTAssertEqual(misfireResults.map(\.candidate), Array(repeating: .noAction, count: 4))
    }

    func testGestureInterpreterRejectsLegacyCancelLikePose() {
        let interpreter = makeTrainedGestureInterpreter()
        let baseTime = Date(timeIntervalSinceReferenceDate: 2_500)

        let legacyCancelResults = (0..<3).map { index in
            interpreter.interpret(
                frameObservation: makeFrameObservation(
                    pose: .legacyCancel,
                    timestamp: baseTime.addingTimeInterval(Double(index) * 0.05)
                )
            )
        }

        XCTAssertEqual(legacyCancelResults.map(\.candidate), Array(repeating: .noAction, count: 3))
    }

    func testGestureCalibrationSessionTrainsClassifierFromSamples() {
        let model = makeTrainedClassifierModel()
        let classifier = LearnedGesturePoseClassifier(model: model)

        XCTAssertEqual(
            classifier.classify(hand: makeHandPoseObservation(pose: .record))?.label,
            .record
        )
        XCTAssertEqual(
            classifier.classify(hand: makeHandPoseObservation(pose: .submit))?.label,
            .submit
        )
        XCTAssertEqual(
            classifier.classify(hand: makeHandPoseObservation(pose: .cancel))?.label,
            .cancel
        )
        XCTAssertEqual(
            classifier.classify(hand: makeHandPoseObservation(pose: .halfCurledSubmit))?.label,
            .background
        )
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

    func testRecognitionStateMachineEmitsDirectCancelAndStopsRecordingInternally() {
        var machine = RecognitionStateMachine()
        let baseTime = Date(timeIntervalSinceReferenceDate: 4_250)

        let gateSupported = machine.updateForegroundAppGate(
            true,
            permissionState: .ready,
            timestamp: baseTime
        )
        XCTAssertEqual(gateSupported.state, .disabled)

        let enable = machine.setRecognitionEnabled(true, permissionState: .ready, timestamp: baseTime)
        XCTAssertEqual(enable.state, .idle)

        machine.setRecordingActive(true)

        let cancelStarted = machine.process(
            gestureInterpretation: GestureInterpretation(
                timestamp: baseTime.addingTimeInterval(0.1),
                candidate: .cancelStarted,
                confidence: 1.0,
                summary: "Cancel pose stabilized"
            )
        )

        XCTAssertEqual(cancelStarted.state, .cooldown)
        XCTAssertEqual(cancelStarted.actionIntent, .cancel)
        XCTAssertFalse(cancelStarted.recordingActive)
        XCTAssertEqual(machine.latestActionIntent, .cancel)
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
        case legacyCancel
        case borderlineRecord
        case recordRelease
        case halfCurledSubmit
    }

    private struct StubGesturePoseClassifier: GesturePoseClassifying {
        let classification: GestureClassification?

        func classify(hand: HandPoseObservation) -> GestureClassification? {
            classification
        }
    }

    private func makeTrainedGestureInterpreter() -> GestureInterpreter {
        GestureInterpreter(classifier: LearnedGesturePoseClassifier(model: makeTrainedClassifierModel()))
    }

    private func makeTrainedClassifierModel() -> GestureClassifierModel {
        var session = GestureCalibrationSession()

        session.recordSample(
            label: .record,
            hand: makeHandPoseObservation(pose: .record)
        )
        session.recordSample(
            label: .record,
            hand: makeHandPoseObservation(pose: .record)
        )
        session.recordSample(
            label: .submit,
            hand: makeHandPoseObservation(pose: .submit)
        )
        session.recordSample(
            label: .submit,
            hand: makeHandPoseObservation(pose: .submit)
        )
        session.recordSample(
            label: .cancel,
            hand: makeHandPoseObservation(pose: .cancel)
        )
        session.recordSample(
            label: .cancel,
            hand: makeHandPoseObservation(pose: .cancel)
        )
        session.recordSample(
            label: .background,
            hand: makeHandPoseObservation(pose: .recordRelease)
        )
        session.recordSample(
            label: .background,
            hand: makeHandPoseObservation(pose: .borderlineRecord)
        )
        session.recordSample(
            label: .background,
            hand: makeHandPoseObservation(pose: .halfCurledSubmit)
        )
        session.recordSample(
            label: .background,
            hand: makeHandPoseObservation(pose: .legacyCancel)
        )

        guard let model = session.train() else {
            fatalError("Failed to train gesture classifier model")
        }

        return model
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
            thumbTip = landmark(0.565, 0.495)
            indexTip = landmark(0.575, 0.500)
            middleTip = landmark(0.625, 0.860)
            ringTip = landmark(0.675, 0.845)
            littleTip = landmark(0.725, 0.830)
        case .cancel:
            thumbTip = landmark(0.315, 0.615)
            indexTip = landmark(0.520, 0.870)
            middleTip = landmark(0.620, 0.880)
            ringTip = landmark(0.720, 0.865)
            littleTip = landmark(0.815, 0.840)
        case .legacyCancel:
            thumbTip = landmark(0.360, 0.570)
            indexTip = landmark(0.575, 0.840)
            middleTip = landmark(0.625, 0.860)
            ringTip = landmark(0.650, 0.350)
            littleTip = landmark(0.700, 0.340)
        case .borderlineRecord:
            thumbTip = landmark(0.420, 0.320)
            indexTip = landmark(0.610, 0.520)
            middleTip = landmark(0.625, 0.860)
            ringTip = landmark(0.675, 0.850)
            littleTip = landmark(0.725, 0.835)
        case .recordRelease:
            thumbTip = landmark(0.420, 0.320)
            indexTip = landmark(0.585, 0.430)
            middleTip = landmark(0.625, 0.410)
            ringTip = landmark(0.675, 0.405)
            littleTip = landmark(0.725, 0.395)
        case .halfCurledSubmit:
            thumbTip = landmark(0.565, 0.495)
            indexTip = landmark(0.575, 0.500)
            middleTip = landmark(0.620, 0.500)
            ringTip = landmark(0.670, 0.500)
            littleTip = landmark(0.720, 0.490)
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
