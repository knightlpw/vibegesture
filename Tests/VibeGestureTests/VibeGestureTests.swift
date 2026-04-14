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

    func testCameraPipelineStateDisplayNames() {
        XCTAssertEqual(CameraPipelineState.stopped.displayName, "Stopped")
        XCTAssertEqual(CameraPipelineState.starting.displayName, "Starting")
        XCTAssertEqual(CameraPipelineState.running.displayName, "Running")
        XCTAssertEqual(CameraPipelineState.stopping.displayName, "Stopping")
        XCTAssertEqual(CameraPipelineState.failed("boom").displayName, "Failed")
    }

    func testHandObservationSummaryUsesRightHand() {
        let observation = HandPoseObservation(
            laterality: .right,
            confidence: 0.9,
            landmarks: [
                .wrist: HandLandmarkObservation(x: 0.2, y: 0.8, confidence: 0.9),
                .indexTip: HandLandmarkObservation(x: 0.4, y: 0.5, confidence: 0.8)
            ]
        )

        XCTAssertEqual(observation.landmarkCount, 2)
        XCTAssertEqual(observation.summaryText, "Right hand, 2 landmarks")
    }
}
