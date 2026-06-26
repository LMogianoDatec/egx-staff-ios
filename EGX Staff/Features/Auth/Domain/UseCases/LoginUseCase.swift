import Foundation

struct LoginUseCase: Sendable {
    let repository: AuthRepository

    func callAsFunction(deviceName: String, password: String) async throws -> AuthSession {
        let trimmedDevice = deviceName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedDevice.isEmpty, !trimmedPassword.isEmpty else {
            throw AuthError.emptyFields
        }

        do {
            return try await repository.login(
                credentials: Credentials(deviceName: trimmedDevice, password: trimmedPassword)
            )
        } catch {
            throw AuthErrorMapper.map(error)
        }
    }
}
