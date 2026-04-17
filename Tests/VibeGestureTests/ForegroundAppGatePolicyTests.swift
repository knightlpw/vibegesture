import XCTest
@testable import VibeGesture

final class ForegroundAppGatePolicyTests: XCTestCase {
    func testCalibrationBypassRequiresSelfFrontmostUnsupportedStateAndVisibleSettings() {
        let selfBundleIdentifier = "com.linpeiwen.vibegesture"
        let selfUnsupported = ForegroundAppGateState.unsupported(
            ForegroundAppInfo(
                applicationName: "VibeGesture",
                bundleIdentifier: selfBundleIdentifier
            )
        )

        XCTAssertTrue(
            ForegroundAppGatePolicy.shouldBypassUnsupportedGateForCalibration(
                gateState: selfUnsupported,
                settingsWindowVisible: true,
                appBundleIdentifier: selfBundleIdentifier
            )
        )
        XCTAssertFalse(
            ForegroundAppGatePolicy.shouldBypassUnsupportedGateForCalibration(
                gateState: selfUnsupported,
                settingsWindowVisible: false,
                appBundleIdentifier: selfBundleIdentifier
            )
        )
    }

    func testCalibrationBypassDoesNotApplyToOtherUnsupportedApps() {
        let selfBundleIdentifier = "com.linpeiwen.vibegesture"
        let safariUnsupported = ForegroundAppGateState.unsupported(
            ForegroundAppInfo(
                applicationName: "Safari",
                bundleIdentifier: "com.apple.Safari"
            )
        )

        XCTAssertFalse(
            ForegroundAppGatePolicy.shouldBypassUnsupportedGateForCalibration(
                gateState: safariUnsupported,
                settingsWindowVisible: true,
                appBundleIdentifier: selfBundleIdentifier
            )
        )
    }
}
