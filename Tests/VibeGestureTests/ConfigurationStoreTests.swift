import Foundation
import XCTest
@testable import VibeGesture

final class ConfigurationStoreTests: XCTestCase {
    func testConfigurationStorePersistsEditedShortcuts() throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("config.json")

        let store = ConfigurationStore(fileURL: fileURL)
        let configuration = AppConfiguration(
            globalRecognitionShortcut: Shortcut(
                keyCode: 1,
                modifiers: [.command, .shift],
                displayName: "⌘⇧S"
            ),
            recordToggleShortcut: Shortcut(
                keyCode: 63,
                modifiers: [],
                displayName: "Fn"
            ),
            submitShortcut: Shortcut(
                keyCode: 36,
                modifiers: [],
                displayName: "Enter"
            ),
            cancelShortcut: Shortcut(
                keyCode: 53,
                modifiers: [],
                displayName: "Esc"
            )
        )

        try store.save(configuration)

        XCTAssertTrue(store.hasStoredConfiguration)
        XCTAssertEqual(store.load(), configuration)
    }

    func testRecordToggleShortcutMustRemainSingleKey() {
        XCTAssertTrue(AppConfiguration.default.recordToggleShortcut.isSingleKey)

        let invalidShortcut = Shortcut(
            keyCode: 1,
            modifiers: [.command],
            displayName: "⌘S"
        )

        XCTAssertFalse(invalidShortcut.isSingleKey)
    }

    func testConfigurationStoreNormalizesMissingRecordToggleKeyCode() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let fileURL = directory.appendingPathComponent("config.json")
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        let badJSON = """
        {
          "cancelShortcut" : {
            "displayName" : "Esc",
            "keyCode" : 53,
            "modifiers" : 0
          },
          "globalRecognitionShortcut" : {
            "displayName" : "⌥⇧G",
            "keyCode" : 5,
            "modifiers" : 2560
          },
          "recordToggleShortcut" : {
            "displayName" : "Fn",
            "modifiers" : 0
          },
          "submitShortcut" : {
            "displayName" : "Enter",
            "keyCode" : 36,
            "modifiers" : 0
          }
        }
        """

        try badJSON.data(using: .utf8)?.write(to: fileURL)

        let store = ConfigurationStore(fileURL: fileURL)
        let loaded = store.load()

        XCTAssertEqual(loaded.recordToggleShortcut, AppConfiguration.default.recordToggleShortcut)
        let persisted = try Data(contentsOf: fileURL)
        let reloaded = try JSONDecoder().decode(AppConfiguration.self, from: persisted)
        XCTAssertEqual(reloaded.recordToggleShortcut, AppConfiguration.default.recordToggleShortcut)
    }
}
