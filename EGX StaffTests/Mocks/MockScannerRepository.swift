import Foundation
@testable import EGX_Staff

actor MockScannerRepository: ScannerRepository {
    var checkResult: Result<Attendee, Error> = .success(makeAttendee())
    var confirmScanError: Error? = nil
    var confirmScanCalled = false
    var checkCalled = false

    func setCheckResult(_ result: Result<Attendee, Error>) {
        checkResult = result
    }

    func setConfirmScanError(_ error: Error?) {
        confirmScanError = error
    }

    func check(idn: String, sessionId: String) async throws -> Attendee {
        checkCalled = true
        return try checkResult.get()
    }

    func confirmScan(userEventId: String, eventId: String) async throws {
        confirmScanCalled = true
        if let error = confirmScanError { throw error }
    }
}
