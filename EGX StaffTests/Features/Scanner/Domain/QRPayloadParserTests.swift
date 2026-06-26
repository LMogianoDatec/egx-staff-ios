import XCTest
@testable import EGX_Staff

final class QRPayloadParserTests: XCTestCase {

    func test_emptyString_returnsNil() {
        XCTAssertNil(QRPayloadParser.extractIdn(from: ""))
    }

    func test_whitespaceOnly_returnsNil() {
        XCTAssertNil(QRPayloadParser.extractIdn(from: "   "))
    }

    func test_rawIdn_returnsItself() {
        let idn = "idn_abc123xyz"
        XCTAssertEqual(QRPayloadParser.extractIdn(from: idn), idn)
    }

    func test_rawIdnWithWhitespace_returnsTrimmed() {
        // Trimming only — "idn_" prefix check is done after trim
        let result = QRPayloadParser.extractIdn(from: "  idn_abc123  ")
        // After trimming: "idn_abc123" which has prefix "idn_"
        XCTAssertEqual(result, "idn_abc123")
    }

    func test_validPasetoToken_extractsIdentityId() {
        // Build a fake PASETO-like token: v2.local.<b64url({"identityId":"idn_test123"})>
        let payload = #"{"identityId":"idn_test123","exp":"2099-01-01"}"#
        let payloadData = payload.data(using: .utf8)!
        let b64 = payloadData.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        let token = "v2.local.\(b64)"

        XCTAssertEqual(QRPayloadParser.extractIdn(from: token), "idn_test123")
    }

    func test_pasetoWithMissingIdentityId_returnsNil() {
        let payload = #"{"userId":"user_1","exp":"2099-01-01"}"#
        let payloadData = payload.data(using: .utf8)!
        let b64 = payloadData.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        let token = "v2.local.\(b64)"

        XCTAssertNil(QRPayloadParser.extractIdn(from: token))
    }

    func test_notEnoughDotParts_returnsNil() {
        XCTAssertNil(QRPayloadParser.extractIdn(from: "v2.local"))
    }

    func test_invalidBase64Payload_returnsNil() {
        XCTAssertNil(QRPayloadParser.extractIdn(from: "v2.local.!!!invalid!!!"))
    }

    func test_pasetoPayloadWithBinaryTrailer_stillExtractsIdn() {
        // Simulates PASETO: JSON followed by binary signature bytes
        let payload = #"{"identityId":"idn_bin_test"}"#
        var data = payload.data(using: .utf8)!
        data.append(contentsOf: [0xFF, 0xFE, 0x00, 0xAB]) // fake signature bytes
        let b64 = data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        let token = "v2.local.\(b64)"

        XCTAssertEqual(QRPayloadParser.extractIdn(from: token), "idn_bin_test")
    }

    // MARK: - extractExpiry

    func test_extractExpiry_pastDate_returnsDate() {
        let token = makePasetoToken(json: #"{"identityId":"idn_x","exp":"2020-01-01T00:00:00.000Z"}"#)
        let expiry = QRPayloadParser.extractExpiry(from: token)
        XCTAssertNotNil(expiry)
        XCTAssertLessThan(expiry!, Date())
    }

    func test_extractExpiry_futureDate_returnsDate() {
        let token = makePasetoToken(json: #"{"identityId":"idn_x","exp":"2099-12-31T23:59:59.000Z"}"#)
        let expiry = QRPayloadParser.extractExpiry(from: token)
        XCTAssertNotNil(expiry)
        XCTAssertGreaterThan(expiry!, Date())
    }

    func test_extractExpiry_missingExpField_returnsNil() {
        let token = makePasetoToken(json: #"{"identityId":"idn_x"}"#)
        XCTAssertNil(QRPayloadParser.extractExpiry(from: token))
    }

    func test_extractExpiry_rawIdn_returnsNil() {
        XCTAssertNil(QRPayloadParser.extractExpiry(from: "idn_abc123"))
    }

    func test_extractExpiry_emptyString_returnsNil() {
        XCTAssertNil(QRPayloadParser.extractExpiry(from: ""))
    }

    // MARK: - Helpers

    private func makePasetoToken(json: String) -> String {
        let data = json.data(using: .utf8)!
        let b64 = data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return "v2.local.\(b64)"
    }
}
