import XCTest
@testable import EGX_Staff

final class AttendeeTests: XCTestCase {

    func test_isApproved_approvedLowercase_returnsTrue() {
        XCTAssertTrue(makeAttendee(approvalStatus: "approved").isApproved)
    }

    func test_isApproved_approvedUppercase_returnsTrue() {
        XCTAssertTrue(makeAttendee(approvalStatus: "APPROVED").isApproved)
    }

    func test_isApproved_approvedMixedCase_returnsTrue() {
        XCTAssertTrue(makeAttendee(approvalStatus: "Approved").isApproved)
    }

    func test_isApproved_pending_returnsFalse() {
        XCTAssertFalse(makeAttendee(approvalStatus: "pending").isApproved)
    }

    func test_isApproved_rejected_returnsFalse() {
        XCTAssertFalse(makeAttendee(approvalStatus: "rejected").isApproved)
    }

    func test_isApproved_empty_returnsFalse() {
        XCTAssertFalse(makeAttendee(approvalStatus: "").isApproved)
    }
}
