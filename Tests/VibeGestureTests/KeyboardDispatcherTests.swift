import XCTest
@testable import VibeGesture

@MainActor
final class KeyboardDispatcherTests: XCTestCase {
    func testRecordToggleDispatchSendsSingleKeyTap() {
        let poster = RecordingKeyboardEventPoster()
        let dispatcher = KeyboardDispatcher(eventPoster: poster, submitStopDelay: 0.01)

        dispatcher.dispatch(intent: .toggleRecording, configuration: .default)

        XCTAssertEqual(poster.tappedShortcuts.map(\.displayName), ["Fn"])
        XCTAssertEqual(poster.tappedShortcuts.first?.keyCode, 63)
        XCTAssertEqual(dispatcher.latestResult.displayName, "Sent record toggle")
    }

    func testSubmitWhileRecordingSchedulesDelayedSubmit() async throws {
        let poster = RecordingKeyboardEventPoster()
        let dispatcher = KeyboardDispatcher(eventPoster: poster, submitStopDelay: 0.05)

        dispatcher.dispatch(
            intent: .submit(stopRecordingFirst: true, postStopDelay: 0.05),
            configuration: .default
        )

        XCTAssertEqual(poster.tappedShortcuts.map(\.displayName), ["Fn"])
        XCTAssertEqual(dispatcher.latestResult.displayName, "Waiting 50 ms for submit")

        try await Task.sleep(nanoseconds: 90_000_000)

        XCTAssertEqual(poster.tappedShortcuts.map(\.displayName), ["Fn", "Enter"])
        XCTAssertEqual(dispatcher.latestResult.displayName, "Sent submit")
    }

    func testCancelInterruptsPendingSubmitBeforeEnter() async throws {
        let poster = RecordingKeyboardEventPoster()
        let dispatcher = KeyboardDispatcher(eventPoster: poster, submitStopDelay: 0.05)

        dispatcher.dispatch(
            intent: .submit(stopRecordingFirst: true, postStopDelay: 0.05),
            configuration: .default
        )

        XCTAssertTrue(dispatcher.hasPendingSubmit)

        dispatcher.dispatch(
            intent: .cancel,
            configuration: .default
        )

        XCTAssertEqual(poster.tappedShortcuts.map(\.displayName), ["Fn", "Esc"])
        XCTAssertEqual(dispatcher.latestResult.displayName, "Sent cancel")

        try await Task.sleep(nanoseconds: 90_000_000)

        XCTAssertEqual(poster.tappedShortcuts.map(\.displayName), ["Fn", "Esc"])
    }

    func testSafeShutdownCancelsPendingSubmitWithoutSendingEnter() async throws {
        let poster = RecordingKeyboardEventPoster()
        let dispatcher = KeyboardDispatcher(eventPoster: poster, submitStopDelay: 0.05)

        dispatcher.dispatch(
            intent: .submit(stopRecordingFirst: true, postStopDelay: 0.05),
            configuration: .default
        )

        dispatcher.performSafeShutdown(stopRecording: false, configuration: .default)

        XCTAssertEqual(poster.tappedShortcuts.map(\.displayName), ["Fn"])
        XCTAssertEqual(dispatcher.latestResult.displayName, "Cancelled pending submit")

        try await Task.sleep(nanoseconds: 90_000_000)

        XCTAssertEqual(poster.tappedShortcuts.map(\.displayName), ["Fn"])
    }

    func testCancelPendingSubmitWithoutStoppingRecording() async throws {
        let poster = RecordingKeyboardEventPoster()
        let dispatcher = KeyboardDispatcher(eventPoster: poster, submitStopDelay: 0.05)

        dispatcher.dispatch(
            intent: .submit(stopRecordingFirst: true, postStopDelay: 0.05),
            configuration: .default
        )

        dispatcher.cancelPendingSubmit()

        XCTAssertEqual(poster.tappedShortcuts.map(\.displayName), ["Fn"])
        XCTAssertEqual(dispatcher.latestResult.displayName, "Cancelled pending submit")

        try await Task.sleep(nanoseconds: 90_000_000)

        XCTAssertEqual(poster.tappedShortcuts.map(\.displayName), ["Fn"])
    }
}

@MainActor
final class RecordingKeyboardEventPoster: KeyboardEventPosting {
    private(set) var tappedShortcuts: [Shortcut] = []

    func tap(shortcut: Shortcut) throws {
        tappedShortcuts.append(shortcut)
    }
}
