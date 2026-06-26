import XCTest
@testable import EGX_Staff

final class AuthErrorTests: XCTestCase {

    func test_invalidCredentials_userMessage() {
        XCTAssertEqual(AuthError.invalidCredentials.userMessage, "Dispositivo o contraseña incorrectos")
    }

    func test_emptyFields_userMessage() {
        XCTAssertEqual(AuthError.emptyFields.userMessage, "Completa todos los campos")
    }

    func test_network_userMessage_containsProvidedMessage() {
        let msg = "Sin conexión a internet"
        XCTAssertEqual(AuthError.network(msg).userMessage, msg)
    }

    func test_unknown_userMessage_containsProvidedMessage() {
        let msg = "Error inesperado del servidor"
        XCTAssertEqual(AuthError.unknown(msg).userMessage, msg)
    }
}
