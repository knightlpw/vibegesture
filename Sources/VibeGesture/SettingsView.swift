import Observation
import SwiftUI

struct SettingsView: View {
    @Bindable var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            shortcutsCard
            scaffoldCard

            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(minWidth: 440, minHeight: 300)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("VibeGesture")
                .font(.title2.weight(.semibold))
            Text("Menu bar shell and configuration scaffold")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var shortcutsCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                settingRow(title: "Recognition toggle", value: appState.configuration.globalRecognitionShortcut.displayName)
                settingRow(title: "Record toggle", value: appState.configuration.recordToggleShortcut.displayName)
                settingRow(title: "Submit", value: appState.configuration.submitShortcut.displayName)
                settingRow(title: "Cancel", value: appState.configuration.cancelShortcut.displayName)
                settingRow(title: "Recognition state", value: appState.recognitionState.displayName)
            }
        } label: {
            Text("Current scaffold")
        }
    }

    private var scaffoldCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                Text("This phase only establishes the shell.")
                    .font(.headline)
                Text("Camera capture, Vision hand pose detection, gesture interpretation, app gating, and keyboard dispatch will arrive in later tasks.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } label: {
            Text("What comes later")
        }
    }

    private func settingRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
            Spacer()
            Text(value)
                .monospaced()
                .foregroundStyle(.secondary)
        }
    }
}
