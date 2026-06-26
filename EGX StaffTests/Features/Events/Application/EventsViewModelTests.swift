import XCTest
@testable import EGX_Staff

@MainActor
final class EventsViewModelTests: XCTestCase {

    private var repo: MockEventsRepository!
    private var sut: EventsViewModel!

    override func setUp() {
        super.setUp()
        repo = MockEventsRepository()
        sut = EventsViewModel(
            fetchEvents: FetchAssignedEventsUseCase(repository: repo),
            logger: SilentLogger()
        )
    }

    // MARK: - Initial state

    func test_initialState_isIdle() {
        XCTAssertEqual(sut.status, .idle)
        XCTAssertTrue(sut.events.isEmpty)
        XCTAssertEqual(sut.query, "")
        XCTAssertNil(sut.selectedEventId)
    }

    // MARK: - Load

    func test_appeared_whenIdle_triggersLoad() async {
        let events = [makeEvent(id: "ev_1"), makeEvent(id: "ev_2")]
        await repo.setFetchResult(.success(events))

        sut.handle(.appeared)
        await drainTasks()

        XCTAssertEqual(sut.status, .loaded)
        XCTAssertEqual(sut.events.count, 2)
    }

    func test_appeared_whenAlreadyLoaded_doesNotReload() async {
        let events = [makeEvent(id: "ev_1")]
        await repo.setFetchResult(.success(events))
        sut.handle(.appeared)
        await drainTasks()

        // Change what repo would return — appeared again should not re-fetch
        await repo.setFetchResult(.success([makeEvent(id: "ev_new")]))
        sut.handle(.appeared)
        await drainTasks()

        XCTAssertEqual(sut.events.map(\.id), ["ev_1"])
    }

    func test_refresh_reloadsEvenWhenLoaded() async {
        let initial = [makeEvent(id: "ev_1")]
        await repo.setFetchResult(.success(initial))
        sut.handle(.appeared)
        await drainTasks()

        let updated = [makeEvent(id: "ev_2"), makeEvent(id: "ev_3")]
        await repo.setFetchResult(.success(updated))
        sut.handle(.refresh)
        await drainTasks()

        XCTAssertEqual(sut.events.map(\.id), ["ev_2", "ev_3"])
    }

    func test_retry_reloadsOnFailure() async {
        await repo.setFetchResult(.failure(Failure.noConnection(domain: nil)))
        sut.handle(.appeared)
        await drainTasks()
        XCTAssertEqual(sut.status, .failure("Sin conexión a internet"))

        let events = [makeEvent(id: "ev_1")]
        await repo.setFetchResult(.success(events))
        sut.handle(.retry)
        await drainTasks()

        XCTAssertEqual(sut.status, .loaded)
    }

    func test_fetchFailure_setsFailureStatus() async {
        await repo.setFetchResult(.failure(Failure.server(statusCode: 500, message: "Server error", domain: nil)))
        sut.handle(.appeared)
        await drainTasks()

        if case .failure = sut.status { } else {
            XCTFail("Expected failure status, got \(sut.status)")
        }
    }

    // MARK: - Query filtering

    func test_queryChanged_updatesQuery() {
        sut.handle(.queryChanged("Tech"))
        XCTAssertEqual(sut.query, "Tech")
    }

    func test_filteredEvents_emptyQuery_returnsAll() async {
        let events = [makeEvent(id: "ev_1", name: "Tech Summit"), makeEvent(id: "ev_2", name: "Art Fair")]
        await repo.setFetchResult(.success(events))
        sut.handle(.appeared)
        await drainTasks()

        sut.handle(.queryChanged(""))
        XCTAssertEqual(sut.filteredEvents.count, 2)
    }

    func test_filteredEvents_matchingQuery_returnsSubset() async {
        let events = [makeEvent(id: "ev_1", name: "Tech Summit"), makeEvent(id: "ev_2", name: "Art Fair")]
        await repo.setFetchResult(.success(events))
        sut.handle(.appeared)
        await drainTasks()

        sut.handle(.queryChanged("tech"))
        XCTAssertEqual(sut.filteredEvents.map(\.id), ["ev_1"])
    }

    func test_filteredEvents_noMatch_returnsEmpty() async {
        let events = [makeEvent(name: "Tech Summit")]
        await repo.setFetchResult(.success(events))
        sut.handle(.appeared)
        await drainTasks()

        sut.handle(.queryChanged("zzznomatch"))
        XCTAssertTrue(sut.filteredEvents.isEmpty)
    }

    func test_hasNoSearchResults_trueWhenQueryMatchesNothing() async {
        let events = [makeEvent(name: "Tech Summit")]
        await repo.setFetchResult(.success(events))
        sut.handle(.appeared)
        await drainTasks()

        sut.handle(.queryChanged("zzznomatch"))
        XCTAssertTrue(sut.hasNoSearchResults)
    }

    func test_hasNoSearchResults_falseWhenResultsExist() async {
        let events = [makeEvent(name: "Tech Summit")]
        await repo.setFetchResult(.success(events))
        sut.handle(.appeared)
        await drainTasks()

        sut.handle(.queryChanged("Tech"))
        XCTAssertFalse(sut.hasNoSearchResults)
    }

    // MARK: - selectEvent

    func test_selectEvent_setsSelectedEventId() async {
        let events = [makeEvent(id: "ev_1")]
        await repo.setFetchResult(.success(events))
        sut.handle(.appeared)
        await drainTasks()

        sut.handle(.selectEvent("ev_1"))
        XCTAssertEqual(sut.selectedEventId, "ev_1")
    }

    func test_selectedEvent_returnsMatchingEvent() async {
        let events = [makeEvent(id: "ev_target", name: "Target Event")]
        await repo.setFetchResult(.success(events))
        sut.handle(.appeared)
        await drainTasks()

        sut.handle(.selectEvent("ev_target"))
        XCTAssertEqual(sut.selectedEvent?.name, "Target Event")
    }

    func test_selectedEvent_nilWhenIdNotFound() async {
        let events = [makeEvent(id: "ev_1")]
        await repo.setFetchResult(.success(events))
        sut.handle(.appeared)
        await drainTasks()

        sut.handle(.selectEvent("ev_nonexistent"))
        XCTAssertNil(sut.selectedEvent)
    }

    // MARK: - Helpers

    private func drainTasks() async {
        for _ in 0..<10 { await Task.yield() }
    }
}
