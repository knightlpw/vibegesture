import AVFoundation
import Foundation

protocol CameraCapturing: AnyObject {
    var onFrame: ((CMSampleBuffer) -> Void)? { get set }

    func start(completion: @escaping @Sendable (Result<Void, CameraCaptureError>) -> Void)
    func stop(completion: (@Sendable () -> Void)?)
}

enum CameraCaptureError: Error, Equatable {
    case cameraUnavailable
    case unableToCreateInput
    case unableToAddInput
    case unableToAddOutput

    var displayMessage: String {
        switch self {
        case .cameraUnavailable:
            return "The default camera is unavailable."
        case .unableToCreateInput:
            return "Unable to create an input from the default camera."
        case .unableToAddInput:
            return "Unable to attach the camera input to the capture session."
        case .unableToAddOutput:
            return "Unable to attach the video output to the capture session."
        }
    }
}

final class CameraCaptureManager: NSObject, CameraCapturing, @unchecked Sendable {
    var onFrame: ((CMSampleBuffer) -> Void)?

    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "VibeGesture.CameraCaptureManager.session")
    private let outputQueue = DispatchQueue(label: "VibeGesture.CameraCaptureManager.output")
    private let videoOutput = AVCaptureVideoDataOutput()

    private var isConfigured = false
    private var isRunning = false

    func start(completion: @escaping @Sendable (Result<Void, CameraCaptureError>) -> Void) {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            if self.isRunning {
                completion(.success(()))
                return
            }

            do {
                if !self.isConfigured {
                    try self.configureSessionIfNeeded()
                }

                self.session.startRunning()
                self.isRunning = true
                completion(.success(()))
            } catch let error as CameraCaptureError {
                completion(.failure(error))
            } catch {
                completion(.failure(.cameraUnavailable))
            }
        }
    }

    func stop(completion: (@Sendable () -> Void)? = nil) {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            if self.isRunning {
                self.session.stopRunning()
                self.isRunning = false
            }

            completion?()
        }
    }

    private func configureSessionIfNeeded() throws {
        guard let camera = AVCaptureDevice.default(for: .video) else {
            throw CameraCaptureError.cameraUnavailable
        }

        let input: AVCaptureDeviceInput
        do {
            input = try AVCaptureDeviceInput(device: camera)
        } catch {
            throw CameraCaptureError.unableToCreateInput
        }

        session.beginConfiguration()
        defer {
            session.commitConfiguration()
            isConfigured = true
        }

        session.sessionPreset = .high

        guard session.canAddInput(input) else {
            throw CameraCaptureError.unableToAddInput
        }
        session.addInput(input)

        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: outputQueue)

        guard session.canAddOutput(videoOutput) else {
            throw CameraCaptureError.unableToAddOutput
        }
        session.addOutput(videoOutput)
    }
}

extension CameraCaptureManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        onFrame?(sampleBuffer)
    }
}
