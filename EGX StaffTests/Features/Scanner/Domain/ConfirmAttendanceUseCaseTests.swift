import XCTest
@testable import EGX_Staff

final class ConfirmAttendanceUseCaseTests: XCTestCase {

    private var repo: MockScannerRepository!
    private var sut: ConfirmAttendanceUseCase!

    override func setUp() {
        super.setUp()
        repo = MockScannerRepository()
        sut = ConfirmAttendanceUseCase(repository: repo)
    }

    func test_success_returnsRegistered() async {
        await repo.setConfirmScanError(nil)

        let result = await sut(userEventId: "ue_1", eventId: "ev_1")

        XCTAssertEqual(result, .registered)
    }

    func test_409Conflict_returnsAlreadyScanned() async {
        let failure = Failure(code: "conflict", message: "Ya escaneado", type: .server, statusCode: 409, domain: nil)
        await repo.setConfirmScanError(failure)

        let result = await sut(userEventId: "ue_1", eventId: "ev_1")

        XCTAssertEqual(result, .alreadyScanned)
    }

    func test_otherError_returnsFailureWithMessage() async {
        let failure = Failure.server(statusCode: 500, message: "Internal error", domain: nil)
        await repo.setConfirmScanError(failure)

        let result = await sut(userEventId: "ue_1", eventId: "ev_1")

        if case .failure(let msg) = result {
            XCTAssertFalse(msg.isEmpty)
        } else {
            XCTFail("Expected failure result")
        }
    }

    func test_confirmScanIsCalled() async {
        let result = await sut(userEventId: "ue_1", eventId: "ev_1")
        XCTAssertEqual(result, .registered)
        let called = await repo.confirmScanCalled
        XCTAssertTrue(called)
    }
}
