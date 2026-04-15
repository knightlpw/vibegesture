import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController {
    private let appState: AppState
    private let onOpenSystemSettings: (PermissionState) -> Void
    var onConfigurationChange: (AppConfiguration) -> Void = { _ in }
    private var window: NSWindow?

    init(appState: AppState, onOpenSystemSettings: @escaping (PermissionState) -> Void) {
        self.appState = appState
        self.onOpenSystemSettings = onOpenSystemSettings
    }

    func showWindow() {
        if window == nil {
            let contentView = SettingsView(
                appState: appState,
                openSystemSettings: onOpenSystemSettings,
                onConfigurationChange: onConfigurationChange
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
