import XCTest
@testable import EGX_Staff

final class FailureFactoryTests: XCTestCase {

    func test_unauthorized_type_and_statusCode() {
        let f = Failure.unauthorized(domain: "auth")
        XCTAssertEqual(f.type, .unauthorized)
        XCTAssertEqual(f.statusCode, 401)
    }

    func test_forbidden_type_and_statusCode() {
        let f = Failure.forbidden(domain: nil)
        XCTAssertEqual(f.type, .forbidden)
        XCTAssertEqual(f.statusCode, 403)
    }

    func test_notFound_type_and_statusCode() {
        let f = Failure.notFound(domain: nil)
        XCTAssertEqual(f.type, .notFound)
        XCTAssertEqual(f.statusCode, 404)
    }

    func test_server_type_and_statusCode() {
        let f = Failure.server(statusCode: 500, message: "Internal error", domain: nil)
        XCTAssertEqual(f.type, .server)
        XCTAssertEqual(f.statusCode, 500)
    }

    func test_noConnection_type() {
        let f = Failure.noConnection(domain: nil)
        XCTAssertEqual(f.type, .noConnection)
        XCTAssertNil(f.statusCode)
    }

    func test_timeout_type() {
        let f = Failure.timeout(domain: nil)
        XCTAssertEqual(f.type, .timeout)
    }

    func test_cancelled_type() {
        let f = Failure.cancelled(domain: nil)
        XCTAssertEqual(f.type, .cancelled)
    }

    func test_network_type() {
        let f = Failure.network("desc", domain: nil)
        XCTAssertEqual(f.type, .network)
    }

    func test_decoding_type() {
        let f = Failure.decoding("bad json", domain: nil)
        XCTAssertEqual(f.type, .decoding)
    }

    func test_unknown_type() {
        let f = Failure.unknown("?", domain: nil)
        XCTAssertEqual(f.type, .unknown)
    }

    func test_domain_assigned() {
        let f = Failure.noConnection(domain: "scanner")
        XCTAssertEqual(f.domain, "scanner")
    }

    func test_server_message_default() {
        let f = Failure.server(statusCode: 503, message: nil, domain: nil)
        XCTAssertFalse(f.message.isEmpty)
    }
}
