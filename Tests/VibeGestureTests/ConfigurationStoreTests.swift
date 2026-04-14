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
}
