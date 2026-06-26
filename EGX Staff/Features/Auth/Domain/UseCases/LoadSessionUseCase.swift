import Foundation

struct LoadSessionUseCase: Sendable {
    let repository: AuthRepository

    func callAsFunction() async -> AuthSession? {
        await repository.currentSession()
    }
}
