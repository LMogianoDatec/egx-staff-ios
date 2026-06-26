import Foundation

final class EventsRepositoryImpl: EventsRepository {
    private let remote: EventsRemoteDataSource

    init(remote: EventsRemoteDataSource) {
        self.remote = remote
    }

    func fetchAssignedEvents() async throws -> [Event] {
        let dtos = try await remote.fetchAssignedEvents()
        return dtos.map { $0.toDomain() }
    }
}
