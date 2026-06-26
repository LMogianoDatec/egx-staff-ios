import XCTest
@testable import EGX_Staff

final class EventActiveSessionTests: XCTestCase {

    private let past  = Date(timeIntervalSince1970: 1_000_000)
    private let open  = Date(timeIntervalSince1970: 2_500_000) // within 2M–3M window
    private let future = Date(timeIntervalSince1970: 5_000_000)

    func test_noSessions_returnsNil() {
        let event = makeEvent(sessions: [])
        XCTAssertNil(event.activeSession(now: open))
    }

    func test_oneOpenSession_returnsIt() {
        let s = makeSession(id: "s_open", accessStart: past, accessEnd: future)
        let event = makeEvent(sessions: [s])
        XCTAssertEqual(event.activeSession(now: open)?.id, "s_open")
    }

    func test_allClosedSessions_returnsNil() {
        let s1 = makeSession(id: "s1", accessStart: past, accessEnd: Date(timeIntervalSince1970: 1_500_000))
        let s2 = makeSession(id: "s2", accessStart: past, accessEnd: Date(timeIntervalSince1970: 2_000_000))
        let event = makeEvent(sessions: [s1, s2])
        XCTAssertNil(event.activeSession(now: open))
    }

    func test_multipleOpenSessions_returnsFirst() {
        let s1 = makeSession(id: "s_first", accessStart: past, accessEnd: future)
        let s2 = makeSession(id: "s_second", accessStart: past, accessEnd: future)
        let event = makeEvent(sessions: [s1, s2])
        XCTAssertEqual(event.activeSession(now: open)?.id, "s_first")
    }

    func test_mixedSessions_returnsOnlyOpenOne() {
        let closed   = makeSession(id: "s_closed",   accessStart: past, accessEnd: Date(timeIntervalSince1970: 1_500_000))
        let upcoming = makeSession(id: "s_upcoming", accessStart: future, accessEnd: Date(timeIntervalSince1970: 6_000_000))
        let openOne  = makeSession(id: "s_open",     accessStart: past, accessEnd: future)
        let event = makeEvent(sessions: [closed, upcoming, openOne])
        XCTAssertEqual(event.activeSession(now: open)?.id, "s_open")
    }

    func test_unknownDates_returnsNil() {
        // activeSession returns only .openNow — .unknown sessions not included
        let s = makeSession(id: "s_unknown", accessStart: nil, accessEnd: nil)
        let event = makeEvent(sessions: [s])
        XCTAssertNil(event.activeSession(now: open))
    }

    // MARK: - Helpers

    private func makeSession(id: String, accessStart: Date?, accessEnd: Date?) -> EventSession {
        EventSession(id: id, name: id, start: nil, end: nil, accessStart: accessStart, accessEnd: accessEnd)
    }

    private func makeEvent(sessions: [EventSession]) -> Event {
        Event(id: "ev1", name: "Test", summary: "", logoURL: nil, status: .assigned, assignedAt: nil, sessions: sessions)
    }
}
