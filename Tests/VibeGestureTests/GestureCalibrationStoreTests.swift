import Foundation
import XCTest
@testable import VibeGesture

final class GestureCalibrationStoreTests: XCTestCase {
    func testCalibrationStorePrefersUserSamplesWhenCalibrationIsComplete() throws {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let fileURL = directoryURL.appendingPathComponent("gesture-calibration.json")
        let store = GestureCalibrationStore(fileURL: fileURL)

        try store.appendSample(GestureTrainingSample(
            label: .record,
            features: makeFeatureVector(pose: .record)
        ))
        try store.appendSample(GestureTrainingSample(
            label: .submit,
            features: makeFeatureVector(pose: .submit)
        ))
        try store.appendSample(GestureTrainingSample(
            label: .cancel,
            features: makeFeatureVector(pose: .cancel)
        ))

        let dataset = store.loadDataset()
        XCTAssertEqual(dataset?.samples.count, 3)

        let loadedClassifier = store.loadClassifierResult()
        XCTAssertEqual(loadedClassifier.source, .calibrated(savedSampleCount: 3))
        XCTAssertNil(loadedClassifier.model.classStatistics[.background])

        let classifier = LearnedGesturePoseClassifier(model: loadedClassifier.model)
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

        try store.reset()
        XCTAssertNil(store.loadDataset())
    }

    func testCalibrationStoreFallsBackToBootstrapWhenCalibrationIsIncomplete() throws {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let fileURL = directoryURL.appendingPathComponent("gesture-calibration.json")
        let store = GestureCalibrationStore(fileURL: fileURL)

        try store.appendSample(GestureTrainingSample(
            label: .record,
            features: makeFeatureVector(pose: .record)
        ))
        try store.appendSample(GestureTrainingSample(
            label: .submit,
            features: makeFeatureVector(pose: .submit)
        ))

        let loadedClassifier = store.loadClassifierResult()
        XCTAssertEqual(loadedClassifier.source, .bootstrap)

        let classifier = LearnedGesturePoseClassifier(model: loadedClassifier.model)
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
    }

    private enum SyntheticPose {
        case record
        case submit
        case cancel
        case recordRelease
    }

    private func makeFeatureVector(pose: SyntheticPose) -> GestureFeatureVector {
        guard let features = GestureFeatureExtractor.extract(from: makeHandPoseObservation(pose: pose)) else {
            fatalError("Failed to extract gesture features")
        }

        return features
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
        case .recordRelease:
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
