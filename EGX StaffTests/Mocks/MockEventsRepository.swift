import Foundation
@testable import EGX_Staff

actor MockEventsRepository: EventsRepository {
    var fetchResult: Result<[Event], Error> = .success([])

    func setFetchResult(_ result: Result<[Event], Error>) {
        fetchResult = result
    }

    func fetchAssignedEvents() async throws -> [Event] {
        try fetchResult.get()
    }
}
