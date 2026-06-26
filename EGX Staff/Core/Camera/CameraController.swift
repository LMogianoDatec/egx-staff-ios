import Foundation
import AVFoundation

enum CameraConfigResult {
    case success
    case noCamera
    case qrNotSupported
}

protocol CameraController: AnyObject, Sendable {
    var captureSession: AVCaptureSession { get }
    var onQRDetected: (@Sendable (String) -> Void)? { get set }

    func configure() async -> CameraConfigResult
    func start() async
    func stop() async
    func setQRDetection(enabled: Bool) async
    func setTorch(on: Bool)
    func authorizationStatus() -> AVAuthorizationStatus
    func requestAccess() async -> Bool
}
