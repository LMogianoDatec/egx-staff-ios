import XCTest
@testable import EGX_Staff

final class EventStatusTests: XCTestCase {

    func test_inProgress_variants() {
        XCTAssertEqual(EventStatus.from(raw: "in_progress"), .inProgress)
        XCTAssertEqual(EventStatus.from(raw: "en_curso"),    .inProgress)
        XCTAssertEqual(EventStatus.from(raw: "ongoing"),     .inProgress)
        XCTAssertEqual(EventStatus.from(raw: "IN_PROGRESS"), .inProgress)
    }

    func test_finished_variants() {
        XCTAssertEqual(EventStatus.from(raw: "finished"),   .finished)
        XCTAssertEqual(EventStatus.from(raw: "finalizado"), .finished)
        XCTAssertEqual(EventStatus.from(raw: "ended"),      .finished)
        XCTAssertEqual(EventStatus.from(raw: "FINISHED"),   .finished)
    }

    func test_unknown_raw_defaultsToAssigned() {
        XCTAssertEqual(EventStatus.from(raw: "pending"),     .assigned)
        XCTAssertEqual(EventStatus.from(raw: ""),            .assigned)
        XCTAssertEqual(EventStatus.from(raw: "gibberish"),   .assigned)
        XCTAssertEqual(EventStatus.from(raw: nil),           .assigned)
    }
}
