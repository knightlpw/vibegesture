import CoreGraphics
import Foundation

enum KeyboardAction: Equatable {
    case recordToggle
    case submit
    case cancel

    var displayName: String {
        switch self {
        case .recordToggle:
            return "Record toggle"
        case .submit:
            return "Submit"
        case .cancel:
            return "Cancel"
        }
    }
}

enum KeyboardDispatchResult: Equatable {
    case idle
    case sent(action: KeyboardAction, timestamp: Date)
    case waitingForSubmit(delay: TimeInterval, fireAt: Date)
    case cancelledPendingSubmit(timestamp: Date)
    case interruptedPendingSubmitWithCancel(timestamp: Date)
    case safeShutdown(stopRecording: Bool, timestamp: Date)
    case failed(action: KeyboardAction, reason: String, timestamp: Date)

    var displayName: String {
        switch self {
        case .idle:
            return "Idle"
        case .sent(let action, _):
            return "Sent \(action.displayName.lowercased())"
        case .waitingForSubmit(let delay, _):
            let delayMillis = Int((delay * 1000).rounded())
            return "Waiting \(delayMillis) ms for submit"
        case .cancelledPendingSubmit:
            return "Cancelled pending submit"
        case .interruptedPendingSubmitWithCancel:
            return "Cancelled pending submit · Sent cancel"
        case .safeShutdown(let stopRecording, _):
            return stopRecording ? "Safe shutdown · stopped recording" : "Safe shutdown"
        case .failed(let action, let reason, _):
            return "Failed \(action.displayName.lowercased()): \(reason)"
        }
    }
}

@MainActor
protocol KeyboardEventPosting {
    func tap(shortcut: Shortcut) throws
}

enum KeyboardEventPostingError: Error, Equatable, LocalizedError {
    case missingKeyCode
    case unableToCreateEvent
    case unableToCreateEventSource

    var errorDescription: String? {
        switch self {
        case .missingKeyCode:
            return "Shortcut is missing a key code."
        case .unableToCreateEvent:
            return "Unable to create keyboard event."
        case .unableToCreateEventSource:
            return "Unable to create keyboard event source."
        }
    }
}

final class SystemKeyboardEventPoster: KeyboardEventPosting {
    func tap(shortcut: Shortcut) throws {
        guard let keyCode = shortcut.keyCode else {
            throw KeyboardEventPostingError.missingKeyCode
        }

        guard let source = CGEventSource(stateID: .hidSystemState) else {
            throw KeyboardEventPostingError.unableToCreateEventSource
        }

        guard let keyDown = CGEvent(
            keyboardEventSource: source,
            virtualKey: keyCode,
            keyDown: true
        ),
        let keyUp = CGEvent(
            keyboardEventSource: source,
            virtualKey: keyCode,
            keyDown: false
        ) else {
            throw KeyboardEventPostingError.unableToCreateEvent
        }

        if !shortcut.modifiers.isEmpty {
            let flags = shortcut.modifiers.cgEventFlags
            keyDown.flags = flags
            keyUp.flags = flags
        }

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}

@MainActor
final class KeyboardDispatcher {
    var onResultChange: ((KeyboardDispatchResult) -> Void)?

    private let eventPoster: KeyboardEventPosting
    private let submitStopDelay: TimeInterval
    private var pendingSubmitTask: Task<Void, Never>?
    private var pendingSubmitToken: UUID?

    private(set) var latestResult: KeyboardDispatchResult = .idle {
        didSet {
            onResultChange?(latestResult)
        }
    }

    init(
        eventPoster: KeyboardEventPosting = SystemKeyboardEventPoster(),
        submitStopDelay: TimeInterval = 0.3
    ) {
        self.eventPoster = eventPoster
        self.submitStopDelay = submitStopDelay
    }

    var hasPendingSubmit: Bool {
        pendingSubmitTask != nil
    }

    func dispatch(intent: RecognitionActionIntent, configuration: AppConfiguration) {
        switch intent {
        case .none:
            return
        case .toggleRecording:
            discardPendingSubmit()
            sendTap(shortcut: configuration.recordToggleShortcut, action: .recordToggle)
        case .submit(let stopRecordingFirst, let postStopDelay):
            discardPendingSubmit()

            if stopRecordingFirst {
                guard sendTap(shortcut: configuration.recordToggleShortcut, action: .recordToggle) else {
                    return
                }
                scheduleSubmit(
                    after: postStopDelay > 0 ? postStopDelay : submitStopDelay,
                    shortcut: configuration.submitShortcut
                )
            } else {
                sendTap(shortcut: configuration.submitShortcut, action: .submit)
            }
        case .cancel(let stopRecordingFirst):
            let hadPendingSubmit = discardPendingSubmit()

            if stopRecordingFirst {
                guard sendTap(shortcut: configuration.recordToggleShortcut, action: .recordToggle) else {
                    return
                }
            }

            if hadPendingSubmit {
                guard sendTap(shortcut: configuration.cancelShortcut, action: .cancel) else {
                    return
                }
                latestResult = .interruptedPendingSubmitWithCancel(timestamp: Date())
            } else {
                sendTap(shortcut: configuration.cancelShortcut, action: .cancel)
            }
        }
    }

    func performSafeShutdown(stopRecording: Bool, configuration: AppConfiguration) {
        let hadPendingSubmit = discardPendingSubmit()

        if stopRecording {
            guard sendTap(shortcut: configuration.recordToggleShortcut, action: .recordToggle) else {
                return
            }
            latestResult = .safeShutdown(stopRecording: true, timestamp: Date())
            return
        }

        if hadPendingSubmit {
            latestResult = .cancelledPendingSubmit(timestamp: Date())
        } else {
            latestResult = .safeShutdown(stopRecording: false, timestamp: Date())
        }
    }

    private func scheduleSubmit(after delay: TimeInterval, shortcut: Shortcut) {
        let token = UUID()
        pendingSubmitToken = token
        latestResult = .waitingForSubmit(delay: delay, fireAt: Date().addingTimeInterval(delay))

        pendingSubmitTask = Task { [weak self] in
            let nanoseconds = UInt64(max(delay, 0) * 1_000_000_000)

            do {
                try await Task.sleep(nanoseconds: nanoseconds)
            } catch {
                return
            }

            guard let self else { return }
            await self.completePendingSubmit(token: token, shortcut: shortcut)
        }
    }

    private func completePendingSubmit(token: UUID, shortcut: Shortcut) async {
        guard pendingSubmitToken == token, pendingSubmitTask != nil else {
            return
        }

        pendingSubmitTask = nil
        pendingSubmitToken = nil
        sendTap(shortcut: shortcut, action: .submit)
    }

    @discardableResult
    private func discardPendingSubmit() -> Bool {
        guard let pendingSubmitTask else {
            return false
        }

        pendingSubmitTask.cancel()
        self.pendingSubmitTask = nil
        pendingSubmitToken = nil
        return true
    }

    @discardableResult
    private func sendTap(shortcut: Shortcut, action: KeyboardAction) -> Bool {
        do {
            try eventPoster.tap(shortcut: shortcut)
            latestResult = .sent(action: action, timestamp: Date())
            return true
        } catch {
            latestResult = .failed(action: action, reason: error.localizedDescription, timestamp: Date())
            return false
        }
    }
}
