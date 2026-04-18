import Foundation
import XCTest
@testable import VibeGesture

@MainActor
final class StatusItemControllerTests: XCTestCase {
    func testMenuSnapshotReflectsLiveStateAndSeparatesGestureCandidateFromPose() {
        let appState = AppState(configuration: .default)
        let controller = StatusItemController(appState: appState)

        XCTAssertEqual(
            controller.menuSnapshot().prefix(4),
            [
                "State: Disabled",
                "Gesture candidate: Waiting for a stable gesture",
                "Gesture pose: Waiting for a stable gesture",
                "Recent action: No action"
            ]
        )

        let timestamp = Date(timeIntervalSinceReferenceDate: 5_000)
        appState.recognitionState = .idle
        appState.latestGestureInterpretation = GestureInterpretation(
            timestamp: timestamp,
            candidate: .submitStarted,
            confidence: 1,
            summary: "Submit pose stabilized"
        )
        appState.latestRecognitionActionIntent = .submit(
            stopRecordingFirst: false,
            postStopDelay: 0
        )
        appState.latestKeyboardDispatchResult = .sent(action: .submit, timestamp: timestamp)
        appState.isRecordingActive = true
        appState.foregroundAppGateState = .supported(
            ForegroundAppInfo(
                applicationName: "Codex",
                bundleIdentifier: "com.openai.codex"
            )
        )
        appState.permissionState = .ready
        appState.cameraPipelineState = .running

        let snapshot = controller.menuSnapshot()
        XCTAssertEqual(snapshot[0], "State: Idle")
        XCTAssertEqual(snapshot[1], "Gesture candidate: Submit started")
        XCTAssertEqual(snapshot[2], "Gesture pose: Submit pose stabilized")
        XCTAssertEqual(snapshot[3], "Recent action: Submit")
        XCTAssertEqual(snapshot[4], "Runtime: Rules mode")
        XCTAssertEqual(snapshot[5], "Recording: Active")
        XCTAssertEqual(snapshot[6], "Gate: Codex · supported")
        XCTAssertEqual(snapshot[7], "Keyboard: Sent submit")
        XCTAssertEqual(snapshot[8], "Permissions: Ready")
        XCTAssertEqual(snapshot[9], "Camera: Running")
        XCTAssertEqual(snapshot[10], "Disable Recognition")
    }
}
