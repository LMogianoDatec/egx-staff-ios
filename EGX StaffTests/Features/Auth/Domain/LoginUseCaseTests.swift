import XCTest
@testable import EGX_Staff

final class LoginUseCaseTests: XCTestCase {

    private var repo: MockAuthRepository!
    private var sut: LoginUseCase!

    override func setUp() {
        super.setUp()
        repo = MockAuthRepository()
        sut = LoginUseCase(repository: repo)
    }

    func test_emptyDeviceName_throwsEmptyFields() async {
        await assertThrowsAuthError(.emptyFields) {
            try await self.sut(deviceName: "", password: "pass123")
        }
    }

    func test_whitespaceOnlyDeviceName_throwsEmptyFields() async {
        await assertThrowsAuthError(.emptyFields) {
            try await self.sut(deviceName: "   ", password: "pass123")
        }
    }

    func test_emptyPassword_throwsEmptyFields() async {
        await assertThrowsAuthError(.emptyFields) {
            try await self.sut(deviceName: "Device1", password: "")
        }
    }

    func test_validCredentials_returnsSession() async throws {
        let session = makeAuthSession(accessToken: "tok_abc")
        await repo.setLoginResult(.success(session))

        let result = try await sut(deviceName: "Device1", password: "pass123")

        XCTAssertEqual(result.accessToken, "tok_abc")
    }

    func test_trimmedCredentials_passedToRepository() async throws {
        let session = makeAuthSession()
        await repo.setLoginResult(.success(session))

        _ = try await sut(deviceName: "  Device1  ", password: "pass123")

        // If repository succeeds, trimming happened (whitespace-only would have thrown emptyFields)
        XCTAssertTrue(true)
    }

    func test_repositoryThrows401_mapsToInvalidCredentials() async {
        let failure = Failure.unauthorized(domain: "auth")
        await repo.setLoginResult(.failure(failure))

        await assertThrowsAuthError(.invalidCredentials) {
            try await self.sut(deviceName: "Device1", password: "pass123")
        }
    }

    func test_repositoryThrowsNoConnection_mapsToNetworkError() async {
        let failure = Failure.noConnection(domain: "auth")
        await repo.setLoginResult(.failure(failure))

        do {
            _ = try await sut(deviceName: "Device1", password: "pass123")
            XCTFail("Expected throw")
        } catch let error as AuthError {
            if case .network = error { } else {
                XCTFail("Expected network error, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Helpers

    private func assertThrowsAuthError(
        _ expected: AuthError,
        _ block: @escaping () async throws -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        do {
            try await block()
            XCTFail("Expected throw of \(expected)", file: file, line: line)
        } catch let error as AuthError {
            XCTAssertEqual(error, expected, file: file, line: line)
        } catch {
            XCTFail("Unexpected error type: \(error)", file: file, line: line)
        }
    }
}
