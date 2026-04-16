import Foundation

enum GestureCalibrationAction: Equatable {
    case capture(GestureTrainingLabel)
    case clear(GestureTrainingLabel)
    case save
    case reset
}

struct GestureCalibrationStatus: Equatable {
    var sampleCounts: [GestureTrainingLabel: Int]
    var persistedSampleCount: Int
    var isDirty: Bool
    var canSave: Bool
    var classifierSourceDescription: String
    var statusMessage: String

    static func bootstrap() -> GestureCalibrationStatus {
        GestureCalibrationStatus(
            sampleCounts: Dictionary(
                uniqueKeysWithValues: GestureTrainingLabel.allCases.map { ($0, 0) }
            ),
            persistedSampleCount: 0,
            isDirty: false,
            canSave: false,
            classifierSourceDescription: "Bootstrap classifier",
            statusMessage: "Ready to calibrate"
        )
    }
}

enum GestureCalibrationControllerError: Error, Equatable, LocalizedError {
    case missingRequiredSamples

    var errorDescription: String? {
        switch self {
        case .missingRequiredSamples:
            return "Record and submit samples are required before saving."
        }
    }
}

@MainActor
final class GestureCalibrationController {
    private let store: GestureCalibrationStore
    private var session: GestureCalibrationSession

    var onStatusChange: ((GestureCalibrationStatus) -> Void)?
    var onClassifierReload: ((GestureClassifierModel) -> Void)?

    private(set) var status: GestureCalibrationStatus {
        didSet { onStatusChange?(status) }
    }

    init(store: GestureCalibrationStore = GestureCalibrationStore()) {
        self.store = store
        let persistedSamples = store.loadDataset()?.samples ?? []
        self.session = GestureCalibrationSession(samples: persistedSamples)
        self.status = GestureCalibrationStatus(
            sampleCounts: session.sampleCounts(),
            persistedSampleCount: persistedSamples.count,
            isDirty: false,
            canSave: Self.canSave(session: session),
            classifierSourceDescription: persistedSamples.isEmpty
                ? "Bootstrap classifier"
                : "Loaded \(persistedSamples.count) saved samples",
            statusMessage: persistedSamples.isEmpty
                ? "Ready to calibrate"
                : "Loaded \(persistedSamples.count) saved samples"
        )
    }

    func captureSample(label: GestureTrainingLabel, observation: CameraFrameObservation?) {
        guard let observation, let hand = observation.hands.first else {
            updateStatus(
                message: "No usable right-hand observation available",
                isDirty: status.isDirty
            )
            return
        }

        let beforeCount = session.sampleCount(for: label)
        session.recordSample(label: label, hand: hand)
        let afterCount = session.sampleCount(for: label)

        guard afterCount > beforeCount else {
            updateStatus(
                message: "Unable to extract calibration features for \(label.displayName)",
                isDirty: status.isDirty
            )
            return
        }

        updateStatus(
            message: "Captured \(label.displayName) sample (\(afterCount) total)",
            isDirty: true
        )
    }

    func clearSamples(for label: GestureTrainingLabel) {
        session.removeSamples(for: label)
        updateStatus(
            message: "Cleared \(label.displayName) samples",
            isDirty: true
        )
    }

    func saveCalibration() throws -> GestureClassifierModel {
        guard session.train() != nil else {
            updateStatus(
                message: "Need at least one Record and one Submit sample before saving",
                isDirty: true
            )
            throw GestureCalibrationControllerError.missingRequiredSamples
        }

        try store.saveDataset(GestureCalibrationDataset(samples: session.samples))
        let savedModel = store.loadClassifier()

        status = GestureCalibrationStatus(
            sampleCounts: session.sampleCounts(),
            persistedSampleCount: session.samples.count,
            isDirty: false,
            canSave: Self.canSave(session: session),
            classifierSourceDescription: "Calibrated classifier loaded",
            statusMessage: "Saved \(session.samples.count) samples and reloaded classifier"
        )
        onClassifierReload?(savedModel)
        return savedModel
    }

    func resetCalibration() throws -> GestureClassifierModel {
        session.clear()
        try store.reset()
        let model = store.loadClassifier()

        status = GestureCalibrationStatus(
            sampleCounts: session.sampleCounts(),
            persistedSampleCount: 0,
            isDirty: false,
            canSave: false,
            classifierSourceDescription: "Bootstrap classifier",
            statusMessage: "Calibration data cleared and bootstrap classifier reloaded"
        )
        onClassifierReload?(model)
        return model
    }

    private static func canSave(session: GestureCalibrationSession) -> Bool {
        session.sampleCount(for: .record) > 0 && session.sampleCount(for: .submit) > 0
    }

    private func updateStatus(message: String, isDirty: Bool) {
        status = GestureCalibrationStatus(
            sampleCounts: session.sampleCounts(),
            persistedSampleCount: status.persistedSampleCount,
            isDirty: isDirty,
            canSave: Self.canSave(session: session),
            classifierSourceDescription: status.classifierSourceDescription,
            statusMessage: message
        )
    }
}
