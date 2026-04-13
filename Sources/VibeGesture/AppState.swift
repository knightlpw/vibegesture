import Foundation
import Observation

@Observable
@MainActor
final class AppState {
    @ObservationIgnored var onChange: (() -> Void)?

    var recognitionState: RecognitionState {
        didSet { notifyChange() }
    }

    var configuration: AppConfiguration {
        didSet { notifyChange() }
    }

    init(configuration: AppConfiguration) {
        self.configuration = configuration
        self.recognitionState = .disabled
    }

    private func notifyChange() {
        onChange?()
    }
}
