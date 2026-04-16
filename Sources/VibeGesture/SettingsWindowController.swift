import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController {
    private let appState: AppState
    private let onPermissionAction: () -> Void
    var onConfigurationChange: (AppConfiguration) -> Void = { _ in }
    var onCalibrationAction: (GestureCalibrationAction) -> Void = { _ in }
    private var window: NSWindow?

    init(appState: AppState, onPermissionAction: @escaping () -> Void) {
        self.appState = appState
        self.onPermissionAction = onPermissionAction
    }

    func showWindow() {
        if window == nil {
            let contentView = SettingsView(
                appState: appState,
                onPermissionAction: onPermissionAction,
                onConfigurationChange: onConfigurationChange,
                onCalibrationAction: onCalibrationAction
            )
            let hostingController = NSHostingController(rootView: contentView)
            let newWindow = NSWindow(contentViewController: hostingController)
            newWindow.title = "VibeGesture Settings"
            newWindow.styleMask = [.titled, .closable, .miniaturizable]
            newWindow.setContentSize(NSSize(width: 560, height: 580))
            newWindow.isReleasedWhenClosed = false
            newWindow.center()
            newWindow.level = .normal
            window = newWindow
        }

        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
