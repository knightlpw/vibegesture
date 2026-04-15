import AppKit
import Observation
import SwiftUI

struct SettingsView: View {
    private enum EditableShortcutField: Hashable {
        case recognition
        case recordToggle
        case submit
        case cancel
    }

    @Bindable var appState: AppState
    let openSystemSettings: (PermissionState) -> Void
    let onConfigurationChange: (AppConfiguration) -> Void

    @State private var activeShortcutField: EditableShortcutField?
    @State private var shortcutValidationMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                shortcutsCard
                permissionCard
                gatingCard
                recognitionCard
                pipelineCard
                scaffoldCard
            }
        }
        .padding(20)
        .frame(minWidth: 520, minHeight: 520)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("VibeGesture")
                .font(.title2.weight(.semibold))
            Text("Shortcut editing, persistence, and lightweight status")
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
                settingRow(title: "Recording state", value: appState.isRecordingActive ? "Active" : "Inactive")
                settingRow(title: "Latest gesture", value: appState.latestGestureInterpretation?.displayText ?? "Waiting for a stable gesture")
                settingRow(title: "Last action", value: appState.latestRecognitionActionIntent.displayName)
                settingRow(title: "Keyboard result", value: appState.latestKeyboardDispatchResult.displayName)
            }
        } label: {
            Text("Recognition")
        }
    }

    private var gatingCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                settingRow(title: "Gate state", value: appState.foregroundAppGateState.displayName)
                Text(appState.foregroundAppGateState.detailMessage)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } label: {
            Text("Foreground app gate")
        }
    }

    private var shortcutsCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                ShortcutEditorRow(
                    title: "Recognition toggle",
                    subtitle: "Global shortcut for enabling or disabling recognition",
                    shortcut: $appState.configuration.globalRecognitionShortcut,
                    isEditing: activeShortcutField == .recognition,
                    validationMessage: activeShortcutField == .recognition ? shortcutValidationMessage : nil,
                    onStartEditing: beginEditing(.recognition),
                    onCancelEditing: cancelEditing,
                    onCaptured: { captured in
                        commitShortcut(captured, field: .recognition)
                    }
                )

                ShortcutEditorRow(
                    title: "Record toggle",
                    subtitle: "Single-key shortcut that starts or stops recording",
                    shortcut: $appState.configuration.recordToggleShortcut,
                    isEditing: activeShortcutField == .recordToggle,
                    validationMessage: activeShortcutField == .recordToggle ? shortcutValidationMessage : nil,
                    onStartEditing: beginEditing(.recordToggle),
                    onCancelEditing: cancelEditing,
                    onCaptured: { captured in
                        commitShortcut(captured, field: .recordToggle)
                    }
                )

                ShortcutEditorRow(
                    title: "Submit",
                    subtitle: "Shortcut used when the recording is submitted",
                    shortcut: $appState.configuration.submitShortcut,
                    isEditing: activeShortcutField == .submit,
                    validationMessage: activeShortcutField == .submit ? shortcutValidationMessage : nil,
                    onStartEditing: beginEditing(.submit),
                    onCancelEditing: cancelEditing,
                    onCaptured: { captured in
                        commitShortcut(captured, field: .submit)
                    }
                )

                ShortcutEditorRow(
                    title: "Cancel",
                    subtitle: "Shortcut used when the recording is cancelled",
                    shortcut: $appState.configuration.cancelShortcut,
                    isEditing: activeShortcutField == .cancel,
                    validationMessage: activeShortcutField == .cancel ? shortcutValidationMessage : nil,
                    onStartEditing: beginEditing(.cancel),
                    onCancelEditing: cancelEditing,
                    onCaptured: { captured in
                        commitShortcut(captured, field: .cancel)
                    }
                )

                Text("Changes save automatically to `config.json`.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } label: {
            Text("Shortcut settings")
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
                        openSystemSettings(appState.permissionState)
                    }
                }
            }
        } label: {
            Text("Permissions")
        }
    }

    private var scaffoldCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                Text("This phase only establishes the shell.")
                    .font(.headline)
                Text("Settings are now editable, persisted, and reloaded at startup. Recognition hotkey changes take effect immediately.")
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

    private func beginEditing(_ field: EditableShortcutField) -> () -> Void {
        {
            activeShortcutField = field
            shortcutValidationMessage = nil
        }
    }

    private func cancelEditing() {
        activeShortcutField = nil
        shortcutValidationMessage = nil
    }

    private func commitShortcut(_ shortcut: Shortcut, field: EditableShortcutField) {
        switch field {
        case .recognition:
            appState.configuration.globalRecognitionShortcut = shortcut
        case .recordToggle:
            guard shortcut.isSingleKey else {
                shortcutValidationMessage = "Record toggle must be a single key."
                NSSound.beep()
                return
            }
            appState.configuration.recordToggleShortcut = shortcut
        case .submit:
            appState.configuration.submitShortcut = shortcut
        case .cancel:
            appState.configuration.cancelShortcut = shortcut
        }

        shortcutValidationMessage = nil
        activeShortcutField = nil
        onConfigurationChange(appState.configuration)
    }
}
