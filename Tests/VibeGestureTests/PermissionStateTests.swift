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
            "Open Camera Settings"
        )
        XCTAssertEqual(
            PermissionState.missingCamera.guidanceSettingsURL?.absoluteString,
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera"
        )

        XCTAssertEqual(
            PermissionState.missingAccessibility.guidanceButtonTitle,
            "Open Accessibility Settings"
        )
        XCTAssertEqual(
            PermissionState.missingAccessibility.guidanceSettingsURL?.absoluteString,
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
}
