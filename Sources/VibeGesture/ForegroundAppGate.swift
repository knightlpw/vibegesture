import AppKit
import Foundation

struct ForegroundAppInfo: Equatable {
    let applicationName: String?
    let bundleIdentifier: String?
}

enum ForegroundAppGateState: Equatable {
    case unknown
    case supported(ForegroundAppInfo)
    case unsupported(ForegroundAppInfo)

    var isSupported: Bool {
        switch self {
        case .supported:
            return true
        case .unknown, .unsupported:
            return false
        }
    }

    var displayName: String {
        switch self {
        case .unknown:
            return "Unknown"
        case .supported(let info):
            return "\(info.applicationName ?? "Supported app") · supported"
        case .unsupported(let info):
            return "\(info.applicationName ?? "Unsupported app") · unsupported"
        }
    }

    var detailMessage: String {
        switch self {
        case .unknown:
            return "Waiting for the current frontmost application."
        case .supported(let info):
            if let bundleIdentifier = info.bundleIdentifier {
                return "Frontmost app \(info.applicationName ?? "Supported app") is allowed (\(bundleIdentifier))."
            }
            return "Frontmost supported app is allowed."
        case .unsupported(let info):
            let frontmost = info.applicationName ?? "Frontmost app"
            if let bundleIdentifier = info.bundleIdentifier {
                return "\(frontmost) (\(bundleIdentifier)) is not in the supported app list."
            }
            return "Frontmost app is not in the supported app list."
        }
    }
}

enum ForegroundAppGatePolicy {
    static let supportedApps: [String: String] = [
        "com.openai.codex": "Codex",
        "com.anthropic.claudefordesktop": "Claude Code",
        "com.todesktop.230313mzl4w4u92": "Cursor"
    ]

    static func classify(frontmostApplication: NSRunningApplication?) -> ForegroundAppGateState {
        classify(
            bundleIdentifier: frontmostApplication?.bundleIdentifier,
            applicationName: frontmostApplication?.localizedName
        )
    }

    static func classify(
        bundleIdentifier: String?,
        applicationName: String?
    ) -> ForegroundAppGateState {
        guard let bundleIdentifier else {
            return .unknown
        }

        guard let supportedName = supportedApps[bundleIdentifier] else {
            return .unsupported(
                ForegroundAppInfo(
                    applicationName: applicationName,
                    bundleIdentifier: bundleIdentifier
                )
            )
        }

        return .supported(
            ForegroundAppInfo(
                applicationName: applicationName ?? supportedName,
                bundleIdentifier: bundleIdentifier
            )
        )
    }
}

@MainActor
final class ForegroundAppGateMonitor {
    var onStateChange: ((ForegroundAppGateState) -> Void)?

    private var observationToken: NSObjectProtocol?
    private(set) var state: ForegroundAppGateState = .unknown {
        didSet {
            guard state != oldValue else {
                return
            }
            onStateChange?(state)
        }
    }

    func startObserving() {
        guard observationToken == nil else {
            refresh()
            return
        }

        observationToken = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refresh()
            }
        }

        refresh()
    }

    func stopObserving() {
        if let observationToken {
            NSWorkspace.shared.notificationCenter.removeObserver(observationToken)
            self.observationToken = nil
        }
    }

    func refresh() {
        state = ForegroundAppGatePolicy.classify(frontmostApplication: NSWorkspace.shared.frontmostApplication)
    }
}
