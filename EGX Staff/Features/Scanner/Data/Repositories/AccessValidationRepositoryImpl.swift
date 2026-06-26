import Foundation

final class ScannerRepositoryImpl: ScannerRepository, @unchecked Sendable {
    private let remote: ScannerRemoteDataSource

    init(remote: ScannerRemoteDataSource) {
        self.remote = remote
    }

    func check(idn: String, sessionId: String) async throws -> Attendee {
        let dto = try await remote.check(idn: idn, sessionId: sessionId)
        return dto.toDomain()
    }

    func confirmScan(userEventId: String, eventId: String) async throws {
        try await remote.confirmScan(userEventId: userEventId, eventId: eventId)
    }
}
