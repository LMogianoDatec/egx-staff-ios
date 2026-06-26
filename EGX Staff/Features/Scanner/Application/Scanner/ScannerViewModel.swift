import Foundation
import Observation
import UIKit
import AVFoundation

@MainActor
@Observable
final class ScannerViewModel {
    private(set) var phase: Phase = .scanning
    private(set) var torchOn: Bool = false
    private(set) var lastResult: ScanResult? = nil
    private(set) var confirm: ConfirmPhase = .idle
    private(set) var cameraPermission: CameraPermission = .notDetermined
    private(set) var scannerAvailable: Bool = true

    enum Phase: Equatable {
        case scanning
        case processing
        case showingResult
    }

    enum ConfirmPhase: Equatable {
        case idle
        case loading
        case done(ConfirmResult)
    }

    enum CameraPermission: Equatable {
        case notDetermined
        case granted
        case denied
    }

    var isProcessing: Bool { phase == .processing }
    var isShowingResult: Bool { phase == .showingResult }
    var isConfirming: Bool { confirm == .loading }

    private let sessionId: String
    private let eventId: String
    private let checkUseCase: CheckAccessUseCase
    private let confirmUseCase: ConfirmAttendanceUseCase
    private let logger: LoggerService
    private let camera: CameraController

    var captureSession: AVCaptureSession { camera.captureSession }

    init(
        sessionId: String,
        eventId: String,
        checkUseCase: CheckAccessUseCase,
        confirmUseCase: ConfirmAttendanceUseCase,
        logger: LoggerService,
        camera: CameraController
    ) {
        self.sessionId = sessionId
        self.eventId = eventId
        self.checkUseCase = checkUseCase
        self.confirmUseCase = confirmUseCase
        self.logger = logger
        self.camera = camera
        self.camera.onQRDetected = { [weak self] payload in
            Task { @MainActor [weak self] in
                self?.handle(.qrDetected(payload))
            }
        }
    }

    deinit {
        let cam = camera
        Task { await cam.stop() }
    }

    func handle(_ intent: ScannerIntent) {
        switch intent {
        case .start:
            Task { await startSession() }
        case .stop:
            Task { await stopSession() }
        case .toggleTorch:
            toggleTorch()
        case .qrDetected(let payload):
            handleQR(payload: payload)
        case .confirmAttendance:
            confirmAttendance()
        case .dismissResult:
            dismissResult()
        }
    }

    // MARK: - Permission

    func refreshCameraPermission() {
        switch camera.authorizationStatus() {
        case .authorized:
            cameraPermission = .granted
        case .notDetermined:
            cameraPermission = .notDetermined
        case .denied, .restricted:
            cameraPermission = .denied
        @unknown default:
            cameraPermission = .denied
        }
    }

    func requestCameraPermission() async {
        let granted = await camera.requestAccess()
        cameraPermission = granted ? .granted : .denied
    }

    func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Session lifecycle

    private func startSession() async {
        refreshCameraPermission()
        guard cameraPermission == .granted else {
            logger.warning("Sin permiso de cámara — no inicio sesión")
            return
        }
        let result = await camera.configure()
        switch result {
        case .success:
            scannerAvailable = true
            await camera.start()
            await camera.setQRDetection(enabled: true)
        case .noCamera:
            logger.error("No se encontró cámara trasera")
            scannerAvailable = false
        case .qrNotSupported:
            logger.error("Detección de QR no soportada en este dispositivo")
            scannerAvailable = false
        }
    }

    private func stopSession() async {
        await camera.setQRDetection(enabled: false)
        await camera.stop()
    }

    // MARK: - Torch

    private func toggleTorch() {
        torchOn.toggle()
        camera.setTorch(on: torchOn)
    }

    // MARK: - QR handling

    private func handleQR(payload: String) {
        guard phase == .scanning else { return }
        phase = .processing
        Task { await camera.setQRDetection(enabled: false) }

        Task {
            let result = await checkUseCase(rawPayload: payload, sessionId: sessionId)
            lastResult = result
            confirm = .idle
            phase = .showingResult
        }
    }

    private func confirmAttendance() {
        guard case .granted(let attendee)? = lastResult?.outcome else { return }
        guard confirm == .idle else { return }
        confirm = .loading

        Task {
            let result = await confirmUseCase(
                userEventId: attendee.userEventId,
                eventId: eventId
            )
            confirm = .done(result)
        }
    }

    private func dismissResult() {
        guard phase == .showingResult else { return }
        lastResult = nil
        confirm = .idle
        phase = .scanning
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            await camera.setQRDetection(enabled: true)
        }
    }
}

#if DEBUG
extension ScannerViewModel {
    func _previewSeed(phase: Phase = .scanning, lastResult: ScanResult? = nil, confirm: ConfirmPhase = .idle) {
        self.phase = phase
        self.lastResult = lastResult
        self.confirm = confirm
    }
}
#endif
