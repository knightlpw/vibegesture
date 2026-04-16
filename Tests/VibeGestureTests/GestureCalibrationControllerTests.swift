import Foundation
import XCTest
@testable import VibeGesture

@MainActor
final class GestureCalibrationControllerTests: XCTestCase {
    func testCalibrationControllerCapturesSavesAndReloadsClassifier() throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("gesture-calibration.json")
        let controller = GestureCalibrationController(
            store: GestureCalibrationStore(fileURL: fileURL)
        )

        var reloadedModels: [GestureClassifierModel] = []
        controller.onClassifierReload = { model in
            reloadedModels.append(model)
        }

        controller.captureSample(
            label: .record,
            observation: makeFrameObservation(pose: .record)
        )
        controller.captureSample(
            label: .submit,
            observation: makeFrameObservation(pose: .submit)
        )
        controller.captureSample(
            label: .background,
            observation: makeFrameObservation(pose: .background)
        )
        controller.clearSamples(for: .background)
        controller.captureSample(
            label: .background,
            observation: makeFrameObservation(pose: .background)
        )

        XCTAssertEqual(controller.status.sampleCounts[.record], 1)
        XCTAssertEqual(controller.status.sampleCounts[.submit], 1)
        XCTAssertEqual(controller.status.sampleCounts[.background], 1)
        XCTAssertTrue(controller.status.isDirty)
        XCTAssertTrue(controller.status.canSave)

        let savedModel = try controller.saveCalibration()

        XCTAssertEqual(reloadedModels.count, 1)
        XCTAssertEqual(savedModel.classify(makeFeatures(pose: .record)).label, .record)
        XCTAssertEqual(savedModel.classify(makeFeatures(pose: .submit)).label, .submit)
        XCTAssertEqual(savedModel.classify(makeFeatures(pose: .background)).label, .background)
        XCTAssertEqual(controller.status.persistedSampleCount, 3)
        XCTAssertFalse(controller.status.isDirty)
        XCTAssertEqual(controller.status.classifierSourceDescription, "Calibrated classifier loaded")

        let storedDataset = GestureCalibrationStore(fileURL: fileURL).loadDataset()
        XCTAssertEqual(storedDataset?.samples.count, 3)
    }

    func testCalibrationControllerResetsCalibrationDataAndReloadsBootstrapClassifier() throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("gesture-calibration.json")
        let controller = GestureCalibrationController(
            store: GestureCalibrationStore(fileURL: fileURL)
        )

        var reloadCount = 0
        controller.onClassifierReload = { _ in
            reloadCount += 1
        }

        controller.captureSample(
            label: .record,
            observation: makeFrameObservation(pose: .record)
        )
        controller.captureSample(
            label: .submit,
            observation: makeFrameObservation(pose: .submit)
        )
        _ = try controller.saveCalibration()

        let resetModel = try controller.resetCalibration()

        XCTAssertEqual(reloadCount, 2)
        XCTAssertNil(GestureCalibrationStore(fileURL: fileURL).loadDataset())
        XCTAssertEqual(controller.status.sampleCounts.values.reduce(0, +), 0)
        XCTAssertEqual(controller.status.persistedSampleCount, 0)
        XCTAssertFalse(controller.status.isDirty)
        XCTAssertEqual(controller.status.classifierSourceDescription, "Bootstrap classifier")
        XCTAssertEqual(resetModel.classify(makeFeatures(pose: .record)).label, .record)
        XCTAssertEqual(resetModel.classify(makeFeatures(pose: .submit)).label, .submit)
    }

    private enum SyntheticPose {
        case record
        case submit
        case background
    }

    private func makeFeatures(pose: SyntheticPose) -> GestureFeatureVector {
        guard let features = GestureFeatureExtractor.extract(from: makeHandPoseObservation(pose: pose)) else {
            fatalError("Failed to extract calibration features")
        }

        return features
    }

    private func makeFrameObservation(pose: SyntheticPose) -> CameraFrameObservation {
        CameraFrameObservation(
            timestamp: Date(timeIntervalSinceReferenceDate: 7_500),
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
        case .background:
            thumbTip = landmark(0.420, 0.320)
            indexTip = landmark(0.565, 0.870)
            middleTip = landmark(0.625, 0.860)
            ringTip = landmark(0.675, 0.850)
            littleTip = landmark(0.725, 0.835)
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
        HandLandmarkObservation(x: x, y: y, confidence: confidence)
    }
}
