import Foundation

final class AuthRepositoryImpl: AuthRepository {
    private let remote: AuthRemoteDataSource
    private let local: AuthLocalDataSource
    private var cachedSession: AuthSession?

    init(remote: AuthRemoteDataSource, local: AuthLocalDataSource) {
        self.remote = remote
        self.local = local
    }

    func login(credentials: Credentials) async throws -> AuthSession {
        let dto = try await remote.login(deviceName: credentials.deviceName, password: credentials.password)
        let session = dto.toDomain()
        try local.saveSession(session)
        cachedSession = session
        return session
    }

    func logout() async throws {
        try local.clearSession()
        cachedSession = nil
    }

    func currentSession() async -> AuthSession? {
        let session = cachedSession ?? (try? local.loadSession())

        // Token de Mobile Login vive ~1 semana. Expirado → limpiar y forzar re-login.
        if let session, session.expiresAt <= Date() {
            try? local.clearSession()
            cachedSession = nil
            return nil
        }

        cachedSession = session
        return session
    }

    func currentAccessToken() async -> String? {
        await currentSession()?.accessToken
    }
}
