import Observation
import SwiftUI

struct SettingsView: View {
    @Bindable var appState: AppState
    let openSystemSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            permissionCard
            recognitionCard
            pipelineCard
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
            Text("Menu bar shell, configuration scaffold, and permission guidance")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var pipelineCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                settingRow(title: "Pipeline state", value: appState.cameraPipelineState.displayName)

                Text(appState.cameraPipelineState.detailMessage)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if let latestObservation = appState.latestCameraFrameObservation {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Latest observation")
                            .font(.headline)
                        Text(latestObservation.summaryText)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                        Text(latestObservation.status.detailMessage)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } label: {
            Text("Camera pipeline")
        }
    }

    private var recognitionCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                settingRow(title: "Recognition state", value: appState.recognitionState.displayName)
                settingRow(title: "Latest gesture", value: appState.latestGestureInterpretation?.displayText ?? "Waiting for a stable gesture")
                settingRow(title: "Last action", value: appState.latestRecognitionActionIntent.displayName)
            }
        } label: {
            Text("Recognition")
        }
    }

    private var permissionCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                settingRow(title: "Permission state", value: appState.permissionState.displayName)

                if appState.permissionState.isReady {
                    Text(appState.permissionState.guidanceMessage)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(appState.permissionState.missingKinds, id: \.self) { kind in
                            Text("Missing \(kind.displayName)")
                                .font(.callout)
                        }
                    }
                    Text(appState.permissionState.guidanceMessage)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Button(appState.permissionState.guidanceButtonTitle) {
                        openSystemSettings()
                    }
                }
            }
        } label: {
            Text("Permissions")
        }
    }

    private var shortcutsCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                settingRow(title: "Recognition toggle", value: appState.configuration.globalRecognitionShortcut.displayName)
                settingRow(title: "Record toggle", value: appState.configuration.recordToggleShortcut.displayName)
                settingRow(title: "Submit", value: appState.configuration.submitShortcut.displayName)
                settingRow(title: "Cancel", value: appState.configuration.cancelShortcut.displayName)
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
                Text("Camera capture, Vision hand pose detection, gesture interpretation, app gating, and keyboard dispatch will arrive in later tasks. Safe shutdown is only reserved as an interface for later stages.")
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
