import Foundation
@testable import EGX_Staff

actor MockAuthRepository: AuthRepository {
    var loginResult: Result<AuthSession, Error> = .success(makeAuthSession())
    var currentSessionResult: AuthSession? = nil
    var logoutCalled = false

    func setLoginResult(_ result: Result<AuthSession, Error>) {
        loginResult = result
    }

    func setCurrentSession(_ session: AuthSession?) {
        currentSessionResult = session
    }

    func login(credentials: Credentials) async throws -> AuthSession {
        try loginResult.get()
    }

    func logout() async throws {
        logoutCalled = true
    }

    func currentSession() async -> AuthSession? {
        currentSessionResult
    }

    func currentAccessToken() async -> String? {
        currentSessionResult?.accessToken
    }
}
