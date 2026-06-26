import Foundation
@preconcurrency import AVFoundation

final class AVCameraController: CameraController, @unchecked Sendable {
    let captureSession: AVCaptureSession
    var onQRDetected: (@Sendable (String) -> Void)?

    private let sessionQueue = DispatchQueue(label: "egx.camera.session", qos: .userInitiated)
    private var metadataOutput: AVCaptureMetadataOutput?
    private var metadataDelegate: MetadataDelegate?
    private var isConfigured = false
    private var configureTask: Task<CameraConfigResult, Never>?

    init(session: AVCaptureSession = AVCaptureSession()) {
        self.captureSession = session
    }

    func configure() async -> CameraConfigResult {
        if isConfigured { return .success }
        if let configureTask { return await configureTask.value }

        let task = Task<CameraConfigResult, Never> { [weak self] in
            guard let self else { return .noCamera }
            return await self.performConfiguration()
        }
        configureTask = task
        let result = await task.value
        if result != .success { configureTask = nil }
        return result
    }

    func start() async {
        await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
            sessionQueue.async { [captureSession] in
                if !captureSession.isRunning { captureSession.startRunning() }
                c.resume()
            }
        }
    }

    func stop() async {
        await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
            sessionQueue.async { [captureSession] in
                if captureSession.isRunning { captureSession.stopRunning() }
                c.resume()
            }
        }
    }

    func setQRDetection(enabled: Bool) async {
        guard let output = metadataOutput else { return }
        await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
            sessionQueue.async {
                let canQR = output.availableMetadataObjectTypes.contains(.qr)
                output.metadataObjectTypes = (enabled && canQR) ? [.qr] : []
                c.resume()
            }
        }
    }

    func setTorch(on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        try? device.lockForConfiguration()
        device.torchMode = on ? .on : .off
        device.unlockForConfiguration()
    }

    func authorizationStatus() -> AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .video)
    }

    func requestAccess() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .video)
    }

    // MARK: - Private

    private func performConfiguration() async -> CameraConfigResult {
        let delegate = MetadataDelegate { [weak self] payload in
            Task { @MainActor [weak self] in
                self?.onQRDetected?(payload)
            }
        }
        self.metadataDelegate = delegate

        let result = await withCheckedContinuation { (c: CheckedContinuation<(Bool, Bool), Never>) in
            sessionQueue.async { [captureSession] in
                captureSession.beginConfiguration()

                if captureSession.canSetSessionPreset(.hd1280x720) {
                    captureSession.sessionPreset = .hd1280x720
                } else if captureSession.canSetSessionPreset(.high) {
                    captureSession.sessionPreset = .high
                }
                captureSession.automaticallyConfiguresCaptureDeviceForWideColor = false

                var inputAdded = false
                if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                   let input = try? AVCaptureDeviceInput(device: device),
                   captureSession.canAddInput(input) {
                    captureSession.addInput(input)
                    inputAdded = true
                }

                var qrSupported = false
                let output = AVCaptureMetadataOutput()
                if captureSession.canAddOutput(output) {
                    captureSession.addOutput(output)
                    let queue = DispatchQueue(label: "egx.camera.metadata", qos: .userInitiated)
                    output.setMetadataObjectsDelegate(delegate, queue: queue)
                    if output.availableMetadataObjectTypes.contains(.qr) {
                        output.metadataObjectTypes = [.qr]
                        qrSupported = true
                    }
                }
                captureSession.commitConfiguration()
                c.resume(returning: (inputAdded, qrSupported))
            }
        }

        guard result.0 else {
            metadataDelegate = nil
            return .noCamera
        }
        guard result.1 else {
            metadataDelegate = nil
            return .qrNotSupported
        }

        self.metadataOutput = await withCheckedContinuation { (c: CheckedContinuation<AVCaptureMetadataOutput?, Never>) in
            sessionQueue.async { [captureSession] in
                c.resume(returning: captureSession.outputs.compactMap { $0 as? AVCaptureMetadataOutput }.first)
            }
        }
        isConfigured = true
        return .success
    }
}

private final class MetadataDelegate: NSObject, AVCaptureMetadataOutputObjectsDelegate, @unchecked Sendable {
    private let onPayload: @Sendable (String) -> Void

    nonisolated init(onPayload: @escaping @Sendable (String) -> Void) {
        self.onPayload = onPayload
        super.init()
    }

    nonisolated func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let payload = obj.stringValue else { return }
        onPayload(payload)
    }
}
