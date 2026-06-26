import XCTest
@testable import EGX_Staff

final class EventSessionTests: XCTestCase {

    // MARK: - accessState

    func test_noDates_returnsUnknown() {
        let session = makeSession(accessStart: nil, accessEnd: nil)
        XCTAssertEqual(session.accessState(now: .now), .unknown)
    }

    func test_onlyAccessStart_returnsUnknown() {
        let session = makeSession(accessStart: .distantPast, accessEnd: nil)
        XCTAssertEqual(session.accessState(now: .now), .unknown)
    }

    func test_nowBeforeAccessStart_returnsUpcoming() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let session = makeSession(
            accessStart: Date(timeIntervalSince1970: 2_000_000),
            accessEnd:   Date(timeIntervalSince1970: 3_000_000)
        )
        XCTAssertEqual(session.accessState(now: now), .upcoming)
    }

    func test_nowWithinWindow_returnsOpenNow() {
        let now = Date(timeIntervalSince1970: 2_500_000)
        let session = makeSession(
            accessStart: Date(timeIntervalSince1970: 2_000_000),
            accessEnd:   Date(timeIntervalSince1970: 3_000_000)
        )
        XCTAssertEqual(session.accessState(now: now), .openNow)
    }

    func test_nowAfterAccessEnd_returnsClosed() {
        let now = Date(timeIntervalSince1970: 4_000_000)
        let session = makeSession(
            accessStart: Date(timeIntervalSince1970: 2_000_000),
            accessEnd:   Date(timeIntervalSince1970: 3_000_000)
        )
        XCTAssertEqual(session.accessState(now: now), .closed)
    }

    func test_nowExactlyAtAccessStart_returnsOpenNow() {
        let t = Date(timeIntervalSince1970: 2_000_000)
        let session = makeSession(
            accessStart: t,
            accessEnd:   Date(timeIntervalSince1970: 3_000_000)
        )
        XCTAssertEqual(session.accessState(now: t), .openNow)
    }

    // MARK: - isScannable

    func test_isScannable_openNow_returnsTrue() {
        let now = Date(timeIntervalSince1970: 2_500_000)
        let session = makeSession(
            accessStart: Date(timeIntervalSince1970: 2_000_000),
            accessEnd:   Date(timeIntervalSince1970: 3_000_000)
        )
        XCTAssertTrue(session.isScannable(now: now))
    }

    func test_isScannable_unknown_returnsTrue() {
        let session = makeSession(accessStart: nil, accessEnd: nil)
        XCTAssertTrue(session.isScannable(now: .now))
    }

    func test_isScannable_upcoming_returnsFalse() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let session = makeSession(
            accessStart: Date(timeIntervalSince1970: 2_000_000),
            accessEnd:   Date(timeIntervalSince1970: 3_000_000)
        )
        XCTAssertFalse(session.isScannable(now: now))
    }

    func test_isScannable_closed_returnsFalse() {
        let now = Date(timeIntervalSince1970: 4_000_000)
        let session = makeSession(
            accessStart: Date(timeIntervalSince1970: 2_000_000),
            accessEnd:   Date(timeIntervalSince1970: 3_000_000)
        )
        XCTAssertFalse(session.isScannable(now: now))
    }

    // MARK: - Helpers

    private func makeSession(
        accessStart: Date?,
        accessEnd: Date?,
        id: String = "s1"
    ) -> EventSession {
        EventSession(
            id: id,
            name: "Test Session",
            start: nil,
            end: nil,
            accessStart: accessStart,
            accessEnd: accessEnd
        )
    }
}
