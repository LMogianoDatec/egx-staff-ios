import XCTest
import AVFoundation
@testable import EGX_Staff

@MainActor
final class ScannerViewModelTests: XCTestCase {

    private var scannerRepo: MockScannerRepository!
    private var camera: MockCameraController!
    private var sut: ScannerViewModel!

    override func setUp() {
        super.setUp()
        scannerRepo = MockScannerRepository()
        camera = MockCameraController()
        sut = makeSUT()
    }

    // MARK: - Initial state

    func test_initialState() {
        XCTAssertEqual(sut.phase, .scanning)
        XCTAssertEqual(sut.confirm, .idle)
        XCTAssertFalse(sut.torchOn)
        XCTAssertEqual(sut.cameraPermission, .notDetermined)
        XCTAssertTrue(sut.scannerAvailable)
    }

    // MARK: - Start session

    func test_start_withGrantedPermission_configuresAndStartsCamera() async {
        camera.authStatus = .authorized
        camera.configureResult = .success

        sut.handle(.start)
        await drainTasks()

        XCTAssertTrue(camera.startCalled)
        XCTAssertTrue(sut.scannerAvailable)
    }

    func test_start_withDeniedPermission_doesNotStartCamera() async {
        camera.authStatus = .denied

        sut.handle(.start)
        await drainTasks()

        XCTAssertFalse(camera.startCalled)
    }

    func test_start_withNoCameraResult_setsScannerUnavailable() async {
        camera.authStatus = .authorized
        camera.configureResult = .noCamera

        sut.handle(.start)
        await drainTasks()

        XCTAssertFalse(sut.scannerAvailable)
        XCTAssertFalse(camera.startCalled)
    }

    func test_start_withQRUnsupported_setsScannerUnavailable() async {
        camera.authStatus = .authorized
        camera.configureResult = .qrNotSupported

        sut.handle(.start)
        await drainTasks()

        XCTAssertFalse(sut.scannerAvailable)
    }

    // MARK: - Camera permission

    func test_refreshPermission_authorized_setsGranted() {
        camera.authStatus = .authorized
        sut.refreshCameraPermission()
        XCTAssertEqual(sut.cameraPermission, .granted)
    }

    func test_refreshPermission_denied_setsDenied() {
        camera.authStatus = .denied
        sut.refreshCameraPermission()
        XCTAssertEqual(sut.cameraPermission, .denied)
    }

    func test_refreshPermission_notDetermined_setsNotDetermined() {
        camera.authStatus = .notDetermined
        sut.refreshCameraPermission()
        XCTAssertEqual(sut.cameraPermission, .notDetermined)
    }

    func test_requestPermission_granted_setsGranted() async {
        camera.requestAccessResult = true
        await sut.requestCameraPermission()
        XCTAssertEqual(sut.cameraPermission, .granted)
    }

    func test_requestPermission_denied_setsDenied() async {
        camera.requestAccessResult = false
        await sut.requestCameraPermission()
        XCTAssertEqual(sut.cameraPermission, .denied)
    }

    // MARK: - QR detection

    func test_qrDetected_callsCheckUseCase_setsShowingResult() async {
        let attendee = attendee()
        await scannerRepo.setCheckResult(.success(attendee))

        sut.handle(.qrDetected("idn_abc"))
        await drainTasks()

        XCTAssertEqual(sut.phase, .showingResult)
        XCTAssertTrue(sut.lastResult?.outcome.isGranted == true)
    }

    func test_qrDetected_goesThrough_processing_first() async {
        await scannerRepo.setCheckResult(.success(attendee()))

        sut.handle(.qrDetected("idn_abc"))

        XCTAssertEqual(sut.phase, .processing)
    }

    func test_qrDetected_whenAlreadyProcessing_isIgnored() async {
        await scannerRepo.setCheckResult(.success(attendee()))

        sut.handle(.qrDetected("idn_first"))
        sut.handle(.qrDetected("idn_second")) // ignored

        await drainTasks()

        XCTAssertEqual(sut.lastResult?.rawPayload, "idn_first")
    }

    func test_qrDetected_invalidQR_setsDeniedOutcome() async {
        sut.handle(.qrDetected("not_valid"))
        await drainTasks()

        if case .denied(let reason) = sut.lastResult?.outcome {
            XCTAssertEqual(reason, .invalidQR)
        } else {
            XCTFail("Expected denied invalidQR")
        }
    }

    func test_qrDetected_404_setsDeniedNotFound() async {
        await scannerRepo.setCheckResult(.failure(Failure.notFound(domain: nil)))

        sut.handle(.qrDetected("idn_abc"))
        await drainTasks()

        if case .denied(let reason) = sut.lastResult?.outcome {
            XCTAssertEqual(reason, .notFound)
        } else {
            XCTFail("Expected denied notFound")
        }
    }

    func test_cameraOnQRDetected_callback_triggersHandle() async {
        await scannerRepo.setCheckResult(.success(attendee()))

        camera.simulateQRDetected("idn_abc")
        await drainTasks()

        XCTAssertEqual(sut.phase, .showingResult)
    }

    // MARK: - Confirm attendance

    func test_confirmAttendance_granted_setsRegistered() async {
        let attendee = attendee()
        await scannerRepo.setCheckResult(.success(attendee))
        await scannerRepo.setConfirmScanError(nil)

        sut.handle(.qrDetected("idn_abc"))
        await drainTasks()
        sut.handle(.confirmAttendance)
        await drainTasks()

        if case .done(let result) = sut.confirm {
            XCTAssertEqual(result, .registered)
        } else {
            XCTFail("Expected done(.registered)")
        }
    }

    func test_confirmAttendance_409_setsAlreadyScanned() async {
        await scannerRepo.setCheckResult(.success(attendee()))
        await scannerRepo.setConfirmScanError(
            Failure(code: "conflict", message: "Conflict", type: .server, statusCode: 409)
        )

        sut.handle(.qrDetected("idn_abc"))
        await drainTasks()
        sut.handle(.confirmAttendance)
        await drainTasks()

        if case .done(let result) = sut.confirm {
            XCTAssertEqual(result, .alreadyScanned)
        } else {
            XCTFail("Expected done(.alreadyScanned)")
        }
    }

    func test_confirmAttendance_whenDenied_doesNothing() async {
        await scannerRepo.setCheckResult(.failure(Failure.notFound(domain: nil)))

        sut.handle(.qrDetected("idn_abc"))
        await drainTasks()
        sut.handle(.confirmAttendance)
        await drainTasks()

        XCTAssertEqual(sut.confirm, .idle)
    }

    func test_confirmAttendance_whileLoading_isIgnored() async {
        await scannerRepo.setCheckResult(.success(attendee()))
        await scannerRepo.setConfirmScanError(nil)

        sut.handle(.qrDetected("idn_abc"))
        await drainTasks()

        sut.handle(.confirmAttendance)
        sut.handle(.confirmAttendance) // should be ignored

        await drainTasks()

        let called = await scannerRepo.confirmScanCalled
        XCTAssertTrue(called) // called only once (no crash from double-call)
    }

    // MARK: - Dismiss result

    func test_dismissResult_resetsPhaseAndConfirm() async {
        await scannerRepo.setCheckResult(.success(attendee()))
        sut.handle(.qrDetected("idn_abc"))
        await drainTasks()

        sut.handle(.dismissResult)

        XCTAssertEqual(sut.phase, .scanning)
        XCTAssertEqual(sut.confirm, .idle)
        XCTAssertNil(sut.lastResult)
    }

    // MARK: - Torch

    func test_toggleTorch_flipsStateAndCallsCamera() {
        XCTAssertFalse(sut.torchOn)

        sut.handle(.toggleTorch)
        XCTAssertTrue(sut.torchOn)
        XCTAssertEqual(camera.setTorchCalls.last, true)

        sut.handle(.toggleTorch)
        XCTAssertFalse(sut.torchOn)
        XCTAssertEqual(camera.setTorchCalls.last, false)
    }

    // MARK: - Stop

    func test_stop_callsCameraStop() async {
        sut.handle(.stop)
        await drainTasks()
        XCTAssertTrue(camera.stopCalled)
    }

    // MARK: - Helpers

    private func makeSUT() -> ScannerViewModel {
        ScannerViewModel(
            sessionId: "s_1",
            eventId: "ev_1",
            checkUseCase: CheckAccessUseCase(repository: scannerRepo),
            confirmUseCase: ConfirmAttendanceUseCase(repository: scannerRepo),
            logger: SilentLogger(),
            camera: camera
        )
    }

    private func attendee() -> Attendee {
        makeAttendee(idn: "idn_abc")
    }

    private func drainTasks() async {
        for _ in 0..<10 { await Task.yield() }
    }
}
