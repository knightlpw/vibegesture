import AVFoundation
import XCTest
@testable import VibeGesture

private struct StubPermissionChecker: PermissionChecking {
    let cameraStatus: AVAuthorizationStatus
    let accessibilityTrusted: Bool

    func cameraAuthorizationStatus() -> AVAuthorizationStatus {
        cameraStatus
    }

    func isAccessibilityTrusted() -> Bool {
        accessibilityTrusted
    }
}

final class PermissionStateTests: XCTestCase {
    func testPermissionStateClassification() {
        XCTAssertEqual(PermissionState(cameraAuthorized: true, accessibilityTrusted: true), .ready)
        XCTAssertEqual(PermissionState(cameraAuthorized: false, accessibilityTrusted: true), .missingCamera)
        XCTAssertEqual(PermissionState(cameraAuthorized: true, accessibilityTrusted: false), .missingAccessibility)
        XCTAssertEqual(PermissionState(cameraAuthorized: false, accessibilityTrusted: false), .missingBoth)
    }

    func testPermissionStateMissingKindsMatchState() {
        XCTAssertEqual(PermissionState.missingCamera.missingKinds, [.camera])
        XCTAssertEqual(PermissionState.missingAccessibility.missingKinds, [.accessibility])
        XCTAssertEqual(PermissionState.missingBoth.missingKinds, [.camera, .accessibility])
        XCTAssertTrue(PermissionState.ready.missingKinds.isEmpty)
    }

    func testPermissionStateGuidanceTargetsMissingPermission() {
        XCTAssertEqual(
            PermissionState.missingCamera.guidanceButtonTitle,
            "Grant Camera Access"
        )
        XCTAssertEqual(
            PermissionState.missingCamera.guidanceSettingsURL?.absoluteString,
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera"
        )

        XCTAssertEqual(
            PermissionState.missingAccessibility.guidanceButtonTitle,
            "Grant Accessibility Access"
        )
        XCTAssertEqual(
            PermissionState.missingAccessibility.guidanceSettingsURL?.absoluteString,
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        )
        XCTAssertEqual(
            PermissionState.missingBoth.cameraSettingsURL?.absoluteString,
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera"
        )
        XCTAssertEqual(
            PermissionState.missingBoth.accessibilitySettingsURL?.absoluteString,
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        )
    }

    func testPermissionManagerUsesCheckerOutput() {
        let manager = PermissionManager(
            checker: StubPermissionChecker(
                cameraStatus: .authorized,
                accessibilityTrusted: false
            )
        )

        XCTAssertEqual(manager.refresh(), .missingAccessibility)
    }

    func testAccessibilityPermissionPromptFlowOnlyPromptsAndRefreshes() {
        var promptCount = 0
        var refreshCount = 0
        let flow = AccessibilityPermissionPromptFlow(
            prompt: {
                promptCount += 1
                return false
            },
            refresh: {
                refreshCount += 1
            }
        )

        flow.run()

        XCTAssertEqual(promptCount, 1)
        XCTAssertEqual(refreshCount, 1)
    }
}
