import Foundation

struct FetchAssignedEventsUseCase: Sendable {
    let repository: EventsRepository

    func callAsFunction() async throws -> [Event] {
        try await repository.fetchAssignedEvents()
    }
}
