import Foundation
import XCTest
@testable import VibeGesture

@MainActor
final class StatusItemControllerTests: XCTestCase {
    func testMenuSnapshotReflectsLiveStateAndHidesDiagnosticsFromTopLevelMenu() {
        let appState = AppState(configuration: .default)
        let controller = StatusItemController(appState: appState)

        let timestamp = Date(timeIntervalSinceReferenceDate: 5_000)
        appState.recognitionState = .idle
        appState.isRecordingActive = true
        appState.foregroundAppGateState = .supported(
            ForegroundAppInfo(
                applicationName: "Codex",
                bundleIdentifier: "com.openai.codex"
            )
        )
        appState.permissionState = .ready
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
        appState.cameraPipelineState = .running

        let snapshot = controller.menuSnapshot()
        XCTAssertEqual(
            snapshot,
            [
                "State: Idle",
                "Recording: Active",
                "Gate: Codex · supported",
                "Permissions: Ready",
                "Disable Recognition",
                "Diagnostics",
                "Settings…",
                "Quit VibeGesture"
            ]
        )
        XCTAssertFalse(snapshot.contains("Gesture candidate: Submit started"))
        XCTAssertFalse(snapshot.contains("Recent action: Submit"))
        XCTAssertFalse(snapshot.contains("Keyboard: Sent submit"))
    }
}
