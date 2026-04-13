import AppKit

@MainActor
final class AppCoordinator {
    private let configurationStore = ConfigurationStore()
    private let appState: AppState
    private let statusItemController: StatusItemController
    private let settingsWindowController: SettingsWindowController
    private let hotKeyManager = GlobalHotKeyManager()

    init() {
        let configuration = configurationStore.load()
        let appState = AppState(configuration: configuration)
        self.appState = appState
        self.statusItemController = StatusItemController(appState: appState)
        self.settingsWindowController = SettingsWindowController(appState: appState)

        statusItemController.onToggleRecognition = { [weak self] in
            self?.toggleRecognition()
        }
        statusItemController.onOpenSettings = { [weak self] in
            self?.showSettings()
        }
        statusItemController.onQuit = { [weak self] in
            self?.terminate()
        }
    }

    func start() {
        if !configurationStore.hasStoredConfiguration {
            do {
                try configurationStore.save(appState.configuration)
            } catch {
                print("Failed to create initial configuration file: \(error)")
            }
        }
        statusItemController.install()
        registerRecognitionHotKey()
    }

    private func registerRecognitionHotKey() {
        let shortcut = appState.configuration.globalRecognitionShortcut
        hotKeyManager.register(shortcut: shortcut) { [weak self] in
            self?.toggleRecognition()
        }
    }

    private func toggleRecognition() {
        switch appState.recognitionState {
        case .disabled, .errorPermissionMissing:
            appState.recognitionState = .idle
        default:
            appState.recognitionState = .disabled
        }
    }

    private func showSettings() {
        settingsWindowController.showWindow()
    }

    private func terminate() {
        do {
            try configurationStore.save(appState.configuration)
        } catch {
            print("Failed to save configuration before quit: \(error)")
        }
        NSApp.terminate(nil)
    }
}
