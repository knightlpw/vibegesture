import Foundation

final class ConfigurationStore {
    private let fileURL: URL
    private let fileManager: FileManager

    init(fileURL: URL? = nil, fileManager: FileManager = .default) {
        self.fileManager = fileManager
        if let fileURL {
            self.fileURL = fileURL
            return
        }

        let baseDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        self.fileURL = baseDirectory
            .appendingPathComponent("VibeGesture", isDirectory: true)
            .appendingPathComponent("config.json")
    }

    var hasStoredConfiguration: Bool {
        fileManager.fileExists(atPath: fileURL.path)
    }

    func load() -> AppConfiguration {
        guard let data = try? Data(contentsOf: fileURL),
              let configuration = try? JSONDecoder().decode(AppConfiguration.self, from: data) else {
            return AppConfiguration.default
        }
        return configuration
    }

    func save(_ configuration: AppConfiguration) throws {
        try ensureParentDirectoryExists()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let data = try encoder.encode(configuration)
        try data.write(to: fileURL, options: [.atomic])
    }

    private func ensureParentDirectoryExists() throws {
        let directory = fileURL.deletingLastPathComponent()
        try fileManager.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }
}
