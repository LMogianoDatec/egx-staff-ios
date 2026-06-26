import XCTest
@testable import EGX_Staff

final class LogoutUseCaseTests: XCTestCase {

    private var repo: MockAuthRepository!
    private var sut: LogoutUseCase!

    override func setUp() {
        super.setUp()
        repo = MockAuthRepository()
        sut = LogoutUseCase(repository: repo)
    }

    func test_callsRepositoryLogout() async throws {
        try await sut()
        let called = await repo.logoutCalled
        XCTAssertTrue(called)
    }

    func test_repositoryThrows_propagatesError() async {
        struct LogoutError: Error {}
        // Reemplazamos el mock para que logout lance
        let failingRepo = FailingLogoutRepository()
        let useCase = LogoutUseCase(repository: failingRepo)

        do {
            try await useCase()
            XCTFail("Expected throw")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}

// Repo auxiliar que lanza en logout
private actor FailingLogoutRepository: AuthRepository {
    func login(credentials: Credentials) async throws -> AuthSession { fatalError() }
    func logout() async throws { throw Failure.server(statusCode: 500, message: "Error", domain: nil) }
    func currentSession() async -> AuthSession? { nil }
    func currentAccessToken() async -> String? { nil }
}
