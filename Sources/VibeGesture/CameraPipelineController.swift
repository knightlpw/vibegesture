import AVFoundation
import Foundation

protocol CameraPipelineControlling: AnyObject {
    var onObservation: ((CameraFrameObservation) -> Void)? { get set }
    var onStateChange: ((CameraPipelineState) -> Void)? { get set }

    func start()
    func stop()
}

final class CameraPipelineController: CameraPipelineControlling, @unchecked Sendable {
    var onObservation: ((CameraFrameObservation) -> Void)?
    var onStateChange: ((CameraPipelineState) -> Void)?

    private let captureManager: CameraCapturing
    private let processor: HandPoseProcessing
    private var state: CameraPipelineState = .stopped {
        didSet {
            let callback = onStateChange
            let currentState = state
            DispatchQueue.main.async {
                callback?(currentState)
            }
        }
    }

    init(
        captureManager: CameraCapturing = CameraCaptureManager(),
        processor: HandPoseProcessing = VisionHandPoseProcessor()
    ) {
        self.captureManager = captureManager
        self.processor = processor

        self.captureManager.onFrame = { [weak self] sampleBuffer in
            self?.handleFrame(sampleBuffer)
        }
    }

    func start() {
        guard state != .starting, state != .running else {
            return
        }

        state = .starting
        captureManager.start { [weak self] result in
            guard let self else { return }

            switch result {
            case .success:
                self.state = .running
            case .failure(let error):
                self.state = .failed(error.displayMessage)
            }
        }
    }

    func stop() {
        guard state != .stopping, state != .stopped else {
            return
        }

        state = .stopping
        captureManager.stop { [weak self] in
            self?.state = .stopped
        }
    }

    private func handleFrame(_ sampleBuffer: CMSampleBuffer) {
        let observation = processor.process(sampleBuffer: sampleBuffer)
        let callback = onObservation
        DispatchQueue.main.async {
            callback?(observation)
        }
    }
}
