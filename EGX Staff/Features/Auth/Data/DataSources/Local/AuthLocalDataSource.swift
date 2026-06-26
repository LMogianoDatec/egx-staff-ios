import Foundation

protocol AuthLocalDataSource: Sendable {
    func saveSession(_ session: AuthSession) throws
    func loadSession() throws -> AuthSession?
    func clearSession() throws
}

final class AuthLocalDataSourceImpl: AuthLocalDataSource, @unchecked Sendable {
    private let keychain: KeychainStorage
    private let defaults: UserDefaults

    private enum DefaultsKey {
        static let email    = "egx.auth.email"
        static let fullName = "egx.auth.full_name"
        static let role     = "egx.auth.role"
        static let expires  = "egx.auth.expires_at"
    }

    init(keychain: KeychainStorage, defaults: UserDefaults = .standard) {
        self.keychain = keychain
        self.defaults = defaults
    }

    func saveSession(_ session: AuthSession) throws {
        try keychain.write(key: KeychainStorage.accessToken,  value: session.accessToken)
        try keychain.write(key: KeychainStorage.refreshToken, value: session.refreshToken)
        try keychain.write(key: KeychainStorage.userId,       value: session.user.id)

        defaults.set(session.user.email,        forKey: DefaultsKey.email)
        defaults.set(session.user.fullName,     forKey: DefaultsKey.fullName)
        defaults.set(session.user.role,         forKey: DefaultsKey.role)
        defaults.set(session.expiresAt.timeIntervalSince1970, forKey: DefaultsKey.expires)
    }

    func loadSession() throws -> AuthSession? {
        guard
            let accessToken  = try keychain.read(key: KeychainStorage.accessToken),
            let refreshToken = try keychain.read(key: KeychainStorage.refreshToken),
            let userId       = try keychain.read(key: KeychainStorage.userId),
            let email        = defaults.string(forKey: DefaultsKey.email),
            let fullName     = defaults.string(forKey: DefaultsKey.fullName),
            let role         = defaults.string(forKey: DefaultsKey.role)
        else {
            return nil
        }
        let expires = defaults.double(forKey: DefaultsKey.expires)
        return AuthSession(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: Date(timeIntervalSince1970: expires),
            user: User(id: userId, email: email, fullName: fullName, role: role)
        )
    }

    func clearSession() throws {
        try keychain.delete(key: KeychainStorage.accessToken)
        try keychain.delete(key: KeychainStorage.refreshToken)
        try keychain.delete(key: KeychainStorage.userId)
        defaults.removeObject(forKey: DefaultsKey.email)
        defaults.removeObject(forKey: DefaultsKey.fullName)
        defaults.removeObject(forKey: DefaultsKey.role)
        defaults.removeObject(forKey: DefaultsKey.expires)
    }
}
