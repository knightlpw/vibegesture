import XCTest
@testable import VibeGesture

final class VibeGestureTests: XCTestCase {
    func testConfigurationRoundTripPreservesShortcutData() throws {
        let original = AppConfiguration.default
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AppConfiguration.self, from: data)

        XCTAssertEqual(decoded, original)
        XCTAssertEqual(decoded.globalRecognitionShortcut.displayName, "⌥⇧G")
        XCTAssertEqual(decoded.recordToggleShortcut.displayName, "Fn")
        XCTAssertEqual(decoded.submitShortcut.displayName, "Enter")
        XCTAssertEqual(decoded.cancelShortcut.displayName, "Esc")
    }
}
