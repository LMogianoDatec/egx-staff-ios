import AVFoundation
@testable import EGX_Staff

final class MockCameraController: CameraController, @unchecked Sendable {
    let captureSession: AVCaptureSession = AVCaptureSession()
    var onQRDetected: (@Sendable (String) -> Void)?

    var configureResult: CameraConfigResult = .success
    var authStatus: AVAuthorizationStatus = .authorized
    var requestAccessResult: Bool = true

    private(set) var startCalled = false
    private(set) var stopCalled = false
    private(set) var setQRDetectionCalls: [Bool] = []
    private(set) var setTorchCalls: [Bool] = []

    func configure() async -> CameraConfigResult { configureResult }
    func start() async { startCalled = true }
    func stop() async { stopCalled = true }
    func setQRDetection(enabled: Bool) async { setQRDetectionCalls.append(enabled) }
    func setTorch(on: Bool) { setTorchCalls.append(on) }
    func authorizationStatus() -> AVAuthorizationStatus { authStatus }
    func requestAccess() async -> Bool { requestAccessResult }

    func simulateQRDetected(_ payload: String) {
        onQRDetected?(payload)
    }
}
