import XCTest
@testable import EGX_Staff

final class CheckAccessUseCaseTests: XCTestCase {

    private var repo: MockScannerRepository!
    private var sut: CheckAccessUseCase!

    override func setUp() {
        super.setUp()
        repo = MockScannerRepository()
        sut = CheckAccessUseCase(repository: repo)
    }

    func test_emptyPayload_returnsDeniedInvalidQR() async {
        let result = await sut(rawPayload: "", sessionId: "s1")
        assertDenied(result, reason: .invalidQR)
    }

    func test_nonPasetoNonIdnPayload_returnsDeniedInvalidQR() async {
        let result = await sut(rawPayload: "random_garbage", sessionId: "s1")
        assertDenied(result, reason: .invalidQR)
    }

    func test_rawIdnPayload_callsRepositoryAndGrantsAccess() async {
        let attendee = makeAttendee(idn: "idn_abc")
        await repo.setCheckResult(.success(attendee))

        let result = await sut(rawPayload: "idn_abc", sessionId: "s1")

        XCTAssertTrue(result.outcome.isGranted)
        if case .granted(let a) = result.outcome {
            XCTAssertEqual(a.idn, "idn_abc")
        } else {
            XCTFail("Expected granted")
        }
    }

    func test_repositoryThrows403_returnsNotAssigned() async {
        let failure = Failure.forbidden(domain: "scanner")
        await repo.setCheckResult(.failure(failure))

        let result = await sut(rawPayload: "idn_abc", sessionId: "s1")
        assertDenied(result, reason: .notAssigned)
    }

    func test_repositoryThrows404_returnsNotFound() async {
        let failure = Failure.notFound(domain: "scanner")
        await repo.setCheckResult(.failure(failure))

        let result = await sut(rawPayload: "idn_abc", sessionId: "s1")
        assertDenied(result, reason: .notFound)
    }

    func test_repositoryThrowsNoConnection_returnsDeniedWithMessage() async {
        let failure = Failure.noConnection(domain: "scanner")
        await repo.setCheckResult(.failure(failure))

        let result = await sut(rawPayload: "idn_abc", sessionId: "s1")

        XCTAssertFalse(result.outcome.isGranted)
        if case .denied(let reason) = result.outcome, case .message = reason { }
        else { XCTFail("Expected denied with message") }
    }

    func test_rawPayloadPreserved() async {
        await repo.setCheckResult(.failure(Failure.notFound(domain: nil)))

        let result = await sut(rawPayload: "idn_abc", sessionId: "s1")
        XCTAssertEqual(result.rawPayload, "idn_abc")
    }

    // MARK: - Approval status

    func test_rejectedAttendee_returnsDeniedRejectedRegistration() async {
        let attendee = makeAttendee(approvalStatus: "rejected")
        await repo.setCheckResult(.success(attendee))

        let result = await sut(rawPayload: "idn_abc", sessionId: "s1")
        assertDenied(result, reason: .rejectedRegistration)
    }

    func test_pendingAttendee_returnsDeniedPendingApproval() async {
        let attendee = makeAttendee(approvalStatus: "pending")
        await repo.setCheckResult(.success(attendee))

        let result = await sut(rawPayload: "idn_abc", sessionId: "s1")
        assertDenied(result, reason: .pendingApproval)
    }

    func test_approvedAttendee_returnsGranted() async {
        let attendee = makeAttendee(approvalStatus: "approved")
        await repo.setCheckResult(.success(attendee))

        let result = await sut(rawPayload: "idn_abc", sessionId: "s1")
        XCTAssertTrue(result.outcome.isGranted)
    }

    // MARK: - QR expiry

    func test_expiredPasetoToken_returnsDeniedExpiredQR_withoutCallingRepo() async {
        let token = makePasetoToken(json: #"{"identityId":"idn_x","exp":"2020-01-01T00:00:00.000Z"}"#)

        let result = await sut(rawPayload: token, sessionId: "s1")

        assertDenied(result, reason: .expiredQR)
        let called = await repo.checkCalled
        XCTAssertFalse(called, "Repo should not be called for expired QR")
    }

    func test_validPasetoToken_withFutureExp_callsRepoAndGrantsAccess() async {
        let attendee = makeAttendee(idn: "idn_x")
        await repo.setCheckResult(.success(attendee))
        let token = makePasetoToken(json: #"{"identityId":"idn_x","exp":"2099-12-31T23:59:59.000Z"}"#)

        let result = await sut(rawPayload: token, sessionId: "s1")

        XCTAssertTrue(result.outcome.isGranted)
    }

    // MARK: - Helpers

    private func makePasetoToken(json: String) -> String {
        let data = json.data(using: .utf8)!
        let b64 = data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return "v2.local.\(b64)"
    }

    private func assertDenied(_ result: ScanResult, reason: DenialReason, file: StaticString = #file, line: UInt = #line) {
        XCTAssertFalse(result.outcome.isGranted, file: file, line: line)
        if case .denied(let r) = result.outcome {
            XCTAssertEqual(r, reason, file: file, line: line)
        } else {
            XCTFail("Expected denied outcome", file: file, line: line)
        }
    }
}
