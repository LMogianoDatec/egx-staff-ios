import XCTest
@testable import EGX_Staff

final class FetchAssignedEventsUseCaseTests: XCTestCase {

    private var repo: MockEventsRepository!
    private var sut: FetchAssignedEventsUseCase!

    override func setUp() {
        super.setUp()
        repo = MockEventsRepository()
        sut = FetchAssignedEventsUseCase(repository: repo)
    }

    func test_success_returnsEvents() async throws {
        let events = [makeEvent(id: "ev_1"), makeEvent(id: "ev_2")]
        await repo.setFetchResult(.success(events))

        let result = try await sut()

        XCTAssertEqual(result.map(\.id), ["ev_1", "ev_2"])
    }

    func test_emptyList_returnsEmpty() async throws {
        await repo.setFetchResult(.success([]))

        let result = try await sut()

        XCTAssertTrue(result.isEmpty)
    }

    func test_repositoryThrows_propagatesError() async {
        let failure = Failure.noConnection(domain: "events")
        await repo.setFetchResult(.failure(failure))

        do {
            _ = try await sut()
            XCTFail("Expected throw")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}
