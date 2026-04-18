import Foundation

struct GestureCalibrationDataset: Codable, Equatable {
    var samples: [GestureTrainingSample] = []
}

final class GestureCalibrationStore {
    private let fileManager: FileManager
    private let fileURL: URL

    init(
        fileManager: FileManager = .default,
        fileURL: URL? = nil
    ) {
        self.fileManager = fileManager

        if let fileURL {
            self.fileURL = fileURL
        } else {
            let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? fileManager.temporaryDirectory
            self.fileURL = appSupport
                .appendingPathComponent("com.linpeiwen.vibegesture", isDirectory: true)
                .appendingPathComponent("gesture-calibration.json")
        }
    }

    func loadDataset() -> GestureCalibrationDataset? {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(GestureCalibrationDataset.self, from: data)
        } catch {
            return nil
        }
    }

    func saveDataset(_ dataset: GestureCalibrationDataset) throws {
        try ensureDirectoryExists()

        let data = try JSONEncoder().encode(dataset)
        try data.write(to: fileURL, options: [.atomic])
    }

    func appendSample(_ sample: GestureTrainingSample) throws {
        var dataset = loadDataset() ?? GestureCalibrationDataset()
        dataset.samples.append(sample)
        try saveDataset(dataset)
    }

    func loadClassifierResult() -> LoadedGestureClassifier {
        if let dataset = loadDataset(), !dataset.samples.isEmpty,
           let model = GestureClassifierTrainer.train(
            samples: dataset.samples,
            profile: .calibrated
           ) {
            return LoadedGestureClassifier(
                model: model,
                source: .calibrated(savedSampleCount: dataset.samples.count)
            )
        }

        return LoadedGestureClassifier(
            model: GestureClassifierModel.bootstrap(),
            source: .bootstrap
        )
    }

    func loadClassifier() -> GestureClassifierModel {
        loadClassifierResult().model
    }

    func reset() throws {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return
        }

        try fileManager.removeItem(at: fileURL)
    }

    private func ensureDirectoryExists() throws {
        let directoryURL = fileURL.deletingLastPathComponent()
        try fileManager.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }
}
