import XCTest
@testable import EGX_Staff

final class AccessOutcomeTests: XCTestCase {

    // MARK: - isGranted

    func test_isGranted_grantedCase_returnsTrue() {
        let outcome = AccessOutcome.granted(makeAttendee())
        XCTAssertTrue(outcome.isGranted)
    }

    func test_isGranted_deniedCase_returnsFalse() {
        XCTAssertFalse(AccessOutcome.denied(reason: .notFound).isGranted)
        XCTAssertFalse(AccessOutcome.denied(reason: .invalidQR).isGranted)
        XCTAssertFalse(AccessOutcome.denied(reason: .notAssigned).isGranted)
        XCTAssertFalse(AccessOutcome.denied(reason: .message("err")).isGranted)
    }

    // MARK: - DenialReason.userMessage

    func test_invalidQR_message() {
        XCTAssertEqual(DenialReason.invalidQR.userMessage, "Código QR no válido")
    }

    func test_notFound_message() {
        XCTAssertEqual(DenialReason.notFound.userMessage, "No registrado en esta sesión")
    }

    func test_notAssigned_message() {
        XCTAssertEqual(DenialReason.notAssigned.userMessage, "Escáner no asignado a esta sesión")
    }

    func test_customMessage_message() {
        let msg = "Error personalizado"
        XCTAssertEqual(DenialReason.message(msg).userMessage, msg)
    }
}
