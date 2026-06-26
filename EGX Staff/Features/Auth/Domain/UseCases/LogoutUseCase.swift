import Foundation

struct LogoutUseCase: Sendable {
    let repository: AuthRepository

    func callAsFunction() async throws {
        try await repository.logout()
    }
}
