import XCTest
@testable import EGX_Staff

@MainActor
final class LoginViewModelTests: XCTestCase {

    private var repo: MockAuthRepository!
    private var sut: LoginViewModel!

    override func setUp() {
        super.setUp()
        repo = MockAuthRepository()
        sut = LoginViewModel(loginUseCase: LoginUseCase(repository: repo))
    }

    // MARK: - Initial state

    func test_initialState_isIdle() {
        XCTAssertEqual(sut.status, .idle)
        XCTAssertEqual(sut.deviceName, "")
        XCTAssertEqual(sut.password, "")
        XCTAssertFalse(sut.isPasswordVisible)
    }

    // MARK: - canSubmit

    func test_canSubmit_falseWhenBothEmpty() {
        XCTAssertFalse(sut.canSubmit)
    }

    func test_canSubmit_falseWhenOnlyDeviceName() {
        sut.handle(.deviceNameChanged("Device1"))
        XCTAssertFalse(sut.canSubmit)
    }

    func test_canSubmit_falseWhenOnlyPassword() {
        sut.handle(.passwordChanged("pass"))
        XCTAssertFalse(sut.canSubmit)
    }

    func test_canSubmit_trueWhenBothFilled() {
        sut.handle(.deviceNameChanged("Device1"))
        sut.handle(.passwordChanged("pass123"))
        XCTAssertTrue(sut.canSubmit)
    }

    func test_canSubmit_falseWhenWhitespaceDeviceName() {
        sut.handle(.deviceNameChanged("   "))
        sut.handle(.passwordChanged("pass123"))
        XCTAssertFalse(sut.canSubmit)
    }

    // MARK: - Field intents

    func test_deviceNameChanged_updatesField() {
        sut.handle(.deviceNameChanged("NewDevice"))
        XCTAssertEqual(sut.deviceName, "NewDevice")
    }

    func test_passwordChanged_updatesField() {
        sut.handle(.passwordChanged("secret"))
        XCTAssertEqual(sut.password, "secret")
    }

    func test_togglePasswordVisibility_flips() {
        XCTAssertFalse(sut.isPasswordVisible)
        sut.handle(.togglePasswordVisibility)
        XCTAssertTrue(sut.isPasswordVisible)
        sut.handle(.togglePasswordVisibility)
        XCTAssertFalse(sut.isPasswordVisible)
    }

    // MARK: - Error clearing

    func test_deviceNameChange_clearsErrorMessage() async throws {
        // Force an error state via a failed submit
        await repo.setLoginResult(.failure(Failure.unauthorized(domain: nil)))
        sut.handle(.deviceNameChanged("Device1"))
        sut.handle(.passwordChanged("wrong"))
        sut.handle(.submit)
        await drainTasks()

        XCTAssertNotNil(sut.errorMessage)

        sut.handle(.deviceNameChanged("Device2"))
        XCTAssertNil(sut.errorMessage)
    }

    func test_dismissError_clearsMessage() async throws {
        await repo.setLoginResult(.failure(Failure.unauthorized(domain: nil)))
        sut.handle(.deviceNameChanged("Device1"))
        sut.handle(.passwordChanged("wrong"))
        sut.handle(.submit)
        await drainTasks()

        sut.handle(.dismissError)
        XCTAssertNil(sut.errorMessage)
    }

    // MARK: - Submit success

    func test_submit_setsSuccessWithSession() async {
        let session = makeAuthSession(accessToken: "tok_success")
        await repo.setLoginResult(.success(session))
        sut.handle(.deviceNameChanged("Device1"))
        sut.handle(.passwordChanged("pass123"))

        sut.handle(.submit)
        await drainTasks()

        if case .success(let s) = sut.status {
            XCTAssertEqual(s.accessToken, "tok_success")
        } else {
            XCTFail("Expected success status, got \(sut.status)")
        }
    }

    func test_submit_clearsErrorMessageOnSuccess() async {
        let session = makeAuthSession()
        await repo.setLoginResult(.success(session))
        sut.handle(.deviceNameChanged("Device1"))
        sut.handle(.passwordChanged("pass123"))

        sut.handle(.submit)
        await drainTasks()

        XCTAssertNil(sut.errorMessage)
    }

    // MARK: - Submit failure

    func test_submit_invalidCredentials_setsFailureWithMessage() async {
        await repo.setLoginResult(.failure(Failure.unauthorized(domain: nil)))
        sut.handle(.deviceNameChanged("Device1"))
        sut.handle(.passwordChanged("wrong"))

        sut.handle(.submit)
        await drainTasks()

        XCTAssertEqual(sut.status, .failure)
        XCTAssertNotNil(sut.errorMessage)
    }

    func test_submit_emptyFields_doesNotCallRepository() async {
        // canSubmit false — submit intent should be no-op
        sut.handle(.submit)
        await drainTasks()

        XCTAssertEqual(sut.status, .idle)
    }

    // MARK: - isLoading

    func test_isLoading_falseWhenIdle() {
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Helpers

    private func drainTasks() async {
        for _ in 0..<10 { await Task.yield() }
    }
}
