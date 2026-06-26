import Foundation

protocol AuthRepository: Sendable {
    func login(credentials: Credentials) async throws -> AuthSession
    func logout() async throws
    func currentSession() async -> AuthSession?
    func currentAccessToken() async -> String?
}
