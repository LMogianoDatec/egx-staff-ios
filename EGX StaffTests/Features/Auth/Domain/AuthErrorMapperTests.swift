import XCTest
@testable import EGX_Staff

final class AuthErrorMapperTests: XCTestCase {

    // MARK: - AuthError passthrough

    func test_authError_returnedAsIs() {
        let error = AuthError.invalidCredentials
        XCTAssertEqual(AuthErrorMapper.map(error), .invalidCredentials)
    }

    // MARK: - HTTP status codes

    func test_400_mapsToInvalidCredentials() {
        let failure = Failure(code: "bad_request", message: "Invalid credentials", type: .validation, statusCode: 400)
        XCTAssertEqual(AuthErrorMapper.map(failure), .invalidCredentials)
    }

    func test_401_mapsToInvalidCredentials() {
        let failure = Failure.unauthorized(domain: "auth")
        XCTAssertEqual(AuthErrorMapper.map(failure), .invalidCredentials)
    }

    // MARK: - Failure type

    func test_unauthorizedType_mapsToInvalidCredentials() {
        let failure = Failure(code: "x", message: "x", type: .unauthorized)
        XCTAssertEqual(AuthErrorMapper.map(failure), .invalidCredentials)
    }

    func test_noConnectionType_mapsToNetwork() {
        let failure = Failure.noConnection(domain: "auth")
        if case .network = AuthErrorMapper.map(failure) { }
        else { XCTFail("Expected network") }
    }

    func test_timeoutType_mapsToNetwork() {
        let failure = Failure.timeout(domain: "auth")
        if case .network = AuthErrorMapper.map(failure) { }
        else { XCTFail("Expected network") }
    }

    func test_networkType_mapsToNetwork() {
        let failure = Failure.network("desc", domain: "auth")
        if case .network = AuthErrorMapper.map(failure) { }
        else { XCTFail("Expected network") }
    }

    func test_serverType_mapsToUnknown() {
        let failure = Failure.server(statusCode: 500, message: "Internal", domain: "auth")
        if case .unknown = AuthErrorMapper.map(failure) { }
        else { XCTFail("Expected unknown") }
    }

    func test_decodingType_mapsToUnknown() {
        let failure = Failure.decoding("bad json", domain: "auth")
        if case .unknown = AuthErrorMapper.map(failure) { }
        else { XCTFail("Expected unknown") }
    }

    // MARK: - Raw Error passthrough

    func test_urlErrorNoConnection_mapsToNetwork() {
        let error = URLError(.notConnectedToInternet)
        if case .network = AuthErrorMapper.map(error) { }
        else { XCTFail("Expected network") }
    }

    func test_urlErrorTimeout_mapsToNetwork() {
        let error = URLError(.timedOut)
        if case .network = AuthErrorMapper.map(error) { }
        else { XCTFail("Expected network") }
    }
}
