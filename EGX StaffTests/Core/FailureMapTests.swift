import XCTest
@testable import EGX_Staff

final class FailureMapTests: XCTestCase {

    // MARK: - Failure passthrough

    func test_failureError_returnedAsIs() {
        let failure = Failure.noConnection(domain: "test")
        let result = Failure.map(failure, domain: "other")
        XCTAssertEqual(result, failure)
    }

    // MARK: - URLError mapping

    func test_notConnectedToInternet_mapsToNoConnection() {
        let result = Failure.map(URLError(.notConnectedToInternet), domain: nil)
        XCTAssertEqual(result.type, .noConnection)
    }

    func test_dataNotAllowed_mapsToNoConnection() {
        let result = Failure.map(URLError(.dataNotAllowed), domain: nil)
        XCTAssertEqual(result.type, .noConnection)
    }

    func test_timedOut_mapsToTimeout() {
        let result = Failure.map(URLError(.timedOut), domain: nil)
        XCTAssertEqual(result.type, .timeout)
    }

    func test_cancelled_mapsToCancelled() {
        let result = Failure.map(URLError(.cancelled), domain: nil)
        XCTAssertEqual(result.type, .cancelled)
    }

    func test_networkConnectionLost_mapsToNetwork() {
        let result = Failure.map(URLError(.networkConnectionLost), domain: nil)
        XCTAssertEqual(result.type, .network)
    }

    func test_cannotFindHost_mapsToNetwork() {
        let result = Failure.map(URLError(.cannotFindHost), domain: nil)
        XCTAssertEqual(result.type, .network)
    }

    // MARK: - DecodingError

    func test_decodingError_mapsToDecoding() {
        let decodingError = DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "bad"))
        let result = Failure.map(decodingError, domain: nil)
        XCTAssertEqual(result.type, .decoding)
    }

    // MARK: - Unknown error

    func test_genericError_mapsToUnknown() {
        struct RandomError: Error, LocalizedError {
            var errorDescription: String? { "random" }
        }
        let result = Failure.map(RandomError(), domain: nil)
        XCTAssertEqual(result.type, .unknown)
    }

    // MARK: - Domain preserved

    func test_domain_preserved() {
        let result = Failure.map(URLError(.timedOut), domain: "auth")
        XCTAssertEqual(result.domain, "auth")
    }
}
