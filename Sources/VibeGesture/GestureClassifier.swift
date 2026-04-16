import CoreGraphics
import Foundation

enum GestureTrainingLabel: String, Codable, CaseIterable, Equatable {
    case record
    case submit
    case background

    var displayName: String {
        switch self {
        case .record:
            return "Record"
        case .submit:
            return "Submit"
        case .background:
            return "Background"
        }
    }
}

struct GestureFeatureVector: Codable, Equatable {
    let values: [Double]

    var dimension: Int {
        values.count
    }

    func distance(to other: GestureFeatureVector) -> Double {
        guard values.count == other.values.count else {
            return .infinity
        }

        return zip(values, other.values)
            .reduce(0) { partialResult, pair in
                let delta = pair.0 - pair.1
                return partialResult + delta * delta
            }
            .squareRoot()
    }

    static func average(_ vectors: [GestureFeatureVector]) -> GestureFeatureVector? {
        guard let first = vectors.first else {
            return nil
        }

        guard vectors.allSatisfy({ $0.values.count == first.values.count }) else {
            return nil
        }

        let values = (0..<first.values.count).map { index in
            let total = vectors.reduce(0) { $0 + $1.values[index] }
            return total / Double(vectors.count)
        }
        return GestureFeatureVector(values: values)
    }
}

struct GestureTrainingSample: Codable, Equatable {
    let label: GestureTrainingLabel
    let features: GestureFeatureVector
}

struct GestureClassStatistics: Codable, Equatable {
    let centroid: GestureFeatureVector
    let averageDistance: Double
    let sampleCount: Int
}

struct GestureClassification: Equatable {
    let label: GestureTrainingLabel
    let confidence: Double
    let scores: [GestureTrainingLabel: Double]
}

protocol GesturePoseClassifying {
    func classify(hand: HandPoseObservation) -> GestureClassification?
}

struct GestureFeatureExtractor {
    static let featureLandmarks: [HandLandmark] = HandLandmark.allCases.filter { $0 != .wrist }

    static func extract(from hand: HandPoseObservation) -> GestureFeatureVector? {
        guard let wrist = hand.landmarks[.wrist] else {
            return nil
        }

        let handSpan = max(
            distance(wrist, hand.landmarks[.indexMCP]),
            distance(wrist, hand.landmarks[.middleMCP]),
            distance(wrist, hand.landmarks[.ringMCP]),
            distance(wrist, hand.landmarks[.littleMCP]),
            0.0001
        )

        var values: [Double] = []
        values.reserveCapacity(featureLandmarks.count * 3 + 2)

        for landmark in featureLandmarks {
            guard let point = hand.landmarks[landmark] else {
                values.append(contentsOf: [0, 0, 0])
                continue
            }

            values.append(Double(point.x - wrist.x) / handSpan)
            values.append(Double(point.y - wrist.y) / handSpan)
            values.append(Double(point.confidence))
        }

        values.append(Double(hand.confidence))
        values.append(Double(hand.landmarks.count) / Double(HandLandmark.allCases.count))

        return GestureFeatureVector(values: values)
    }

    private static func distance(
        _ lhs: HandLandmarkObservation,
        _ rhs: HandLandmarkObservation?
    ) -> Double {
        guard let rhs else {
            return 0
        }

        return hypot(Double(lhs.x - rhs.x), Double(lhs.y - rhs.y))
    }
}

struct GestureCalibrationSession {
    private(set) var samples: [GestureTrainingSample] = []

    init(samples: [GestureTrainingSample] = []) {
        self.samples = samples
    }

    mutating func addSample(_ sample: GestureTrainingSample) {
        samples.append(sample)
    }

    mutating func removeSamples(for label: GestureTrainingLabel) {
        samples.removeAll { $0.label == label }
    }

    mutating func clear() {
        samples.removeAll()
    }

    mutating func recordSample(label: GestureTrainingLabel, hand: HandPoseObservation) {
        guard let features = GestureFeatureExtractor.extract(from: hand) else {
            return
        }

        samples.append(GestureTrainingSample(label: label, features: features))
    }

    func train() -> GestureClassifierModel? {
        GestureClassifierTrainer.train(samples: samples)
    }

    func sampleCount(for label: GestureTrainingLabel) -> Int {
        samples.lazy.filter { $0.label == label }.count
    }

    func sampleCounts() -> [GestureTrainingLabel: Int] {
        Dictionary(
            uniqueKeysWithValues: GestureTrainingLabel.allCases.map { label in
                (label, sampleCount(for: label))
            }
        )
    }
}

struct GestureClassifierModel: Codable, Equatable {
    struct ClassificationThresholds: Codable, Equatable {
        let minimumConfidence: Double
        let minimumMargin: Double
        let minimumClassSpread: Double
    }

    let featureCount: Int
    let classStatistics: [GestureTrainingLabel: GestureClassStatistics]
    let thresholds: ClassificationThresholds

    func classify(_ features: GestureFeatureVector) -> GestureClassification {
        guard features.dimension == featureCount else {
            return GestureClassification(label: .background, confidence: 0, scores: [:])
        }

        let scores = classStatistics.mapValues { stats in
            Self.score(features: features, statistics: stats, minimumSpread: thresholds.minimumClassSpread)
        }

        guard let best = scores.max(by: { $0.value < $1.value }) else {
            return GestureClassification(label: .background, confidence: 0, scores: scores)
        }

        let secondBest = scores
            .filter { $0.key != best.key }
            .map(\.value)
            .max() ?? 0

        guard best.key != .background,
              best.value >= thresholds.minimumConfidence,
              best.value - secondBest >= thresholds.minimumMargin else {
            return GestureClassification(label: .background, confidence: best.value, scores: scores)
        }

        return GestureClassification(label: best.key, confidence: best.value, scores: scores)
    }

    static func bootstrap() -> GestureClassifierModel {
        GestureClassifierTrainer.train(samples: GestureBootstrapSamples.defaultSamples()) ?? GestureClassifierModel(
            featureCount: GestureBootstrapSamples.defaultSamples().first?.features.dimension ?? 0,
            classStatistics: [:],
            thresholds: .init(minimumConfidence: 0.55, minimumMargin: 0.08, minimumClassSpread: 0.12)
        )
    }

    private static func score(
        features: GestureFeatureVector,
        statistics: GestureClassStatistics,
        minimumSpread: Double
    ) -> Double {
        let spread = max(statistics.averageDistance, minimumSpread)
        let normalizedDistance = features.distance(to: statistics.centroid) / spread
        return 1.0 / (1.0 + normalizedDistance)
    }
}

enum GestureClassifierTrainer {
    static func train(samples: [GestureTrainingSample]) -> GestureClassifierModel? {
        guard let featureCount = samples.first?.features.dimension else {
            return nil
        }

        guard samples.allSatisfy({ $0.features.dimension == featureCount }) else {
            return nil
        }

        let grouped = Dictionary(grouping: samples, by: \.label)
        guard let recordSamples = grouped[.record], !recordSamples.isEmpty,
              let submitSamples = grouped[.submit], !submitSamples.isEmpty else {
            return nil
        }

        let thresholds = GestureClassifierModel.ClassificationThresholds(
            minimumConfidence: 0.58,
            minimumMargin: 0.07,
            minimumClassSpread: 0.12
        )

        var classStatistics: [GestureTrainingLabel: GestureClassStatistics] = [:]
        for label in GestureTrainingLabel.allCases {
            guard let labelSamples = grouped[label], !labelSamples.isEmpty else {
                continue
            }

            let vectors = labelSamples.map(\.features)
            guard let centroid = GestureFeatureVector.average(vectors) else {
                continue
            }

            let averageDistance = max(
                vectors.map { $0.distance(to: centroid) }.reduce(0, +) / Double(vectors.count),
                thresholds.minimumClassSpread
            )

            classStatistics[label] = GestureClassStatistics(
                centroid: centroid,
                averageDistance: averageDistance,
                sampleCount: labelSamples.count
            )
        }

        guard classStatistics[.record] != nil, classStatistics[.submit] != nil else {
            return nil
        }

        return GestureClassifierModel(
            featureCount: featureCount,
            classStatistics: classStatistics,
            thresholds: thresholds
        )
    }
}

final class LearnedGesturePoseClassifier: GesturePoseClassifying {
    private let model: GestureClassifierModel

    init(model: GestureClassifierModel = .bootstrap()) {
        self.model = model
    }

    func classify(hand: HandPoseObservation) -> GestureClassification? {
        guard let features = GestureFeatureExtractor.extract(from: hand) else {
            return nil
        }

        return model.classify(features)
    }
}

enum GestureBootstrapSamples {
    static func defaultSamples() -> [GestureTrainingSample] {
        var session = GestureCalibrationSession()
        let samples: [(GestureTrainingLabel, HandPoseObservation)] = [
            (.record, makeHandPoseObservation(
                thumbTip: landmark(0.565, 0.495),
                indexTip: landmark(0.575, 0.500),
                middleTip: landmark(0.605, 0.355),
                ringTip: landmark(0.655, 0.350),
                littleTip: landmark(0.705, 0.345)
            )),
            (.record, makeHandPoseObservation(
                thumbTip: landmark(0.555, 0.500),
                indexTip: landmark(0.568, 0.502),
                middleTip: landmark(0.602, 0.360),
                ringTip: landmark(0.652, 0.352),
                littleTip: landmark(0.702, 0.346)
            )),
            (.submit, makeHandPoseObservation(
                thumbTip: landmark(0.565, 0.495),
                indexTip: landmark(0.575, 0.500),
                middleTip: landmark(0.625, 0.860),
                ringTip: landmark(0.675, 0.845),
                littleTip: landmark(0.725, 0.830)
            )),
            (.submit, makeHandPoseObservation(
                thumbTip: landmark(0.560, 0.500),
                indexTip: landmark(0.570, 0.503),
                middleTip: landmark(0.630, 0.850),
                ringTip: landmark(0.680, 0.835),
                littleTip: landmark(0.730, 0.825)
            )),
            (.background, makeHandPoseObservation(
                thumbTip: landmark(0.420, 0.320),
                indexTip: landmark(0.565, 0.870),
                middleTip: landmark(0.625, 0.860),
                ringTip: landmark(0.675, 0.850),
                littleTip: landmark(0.725, 0.835)
            )),
            (.background, makeHandPoseObservation(
                thumbTip: landmark(0.560, 0.495),
                indexTip: landmark(0.610, 0.520),
                middleTip: landmark(0.605, 0.355),
                ringTip: landmark(0.655, 0.350),
                littleTip: landmark(0.705, 0.345)
            )),
            (.background, makeHandPoseObservation(
                thumbTip: landmark(0.565, 0.495),
                indexTip: landmark(0.620, 0.500),
                middleTip: landmark(0.620, 0.500),
                ringTip: landmark(0.670, 0.500),
                littleTip: landmark(0.720, 0.490)
            )),
            (.background, makeHandPoseObservation(
                thumbTip: landmark(0.360, 0.570),
                indexTip: landmark(0.575, 0.840),
                middleTip: landmark(0.625, 0.860),
                ringTip: landmark(0.650, 0.350),
                littleTip: landmark(0.700, 0.340)
            ))
        ]

        for (label, hand) in samples {
            session.recordSample(label: label, hand: hand)
        }

        return session.samples
    }

    private static func makeHandPoseObservation(
        thumbTip: HandLandmarkObservation,
        indexTip: HandLandmarkObservation,
        middleTip: HandLandmarkObservation,
        ringTip: HandLandmarkObservation,
        littleTip: HandLandmarkObservation
    ) -> HandPoseObservation {
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

    private static func landmark(_ x: Double, _ y: Double, confidence: Float = 1) -> HandLandmarkObservation {
        HandLandmarkObservation(
            x: x,
            y: y,
            confidence: confidence
        )
    }
}
