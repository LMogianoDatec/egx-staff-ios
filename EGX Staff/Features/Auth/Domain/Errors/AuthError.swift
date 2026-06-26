import Foundation

enum AuthError: Error, Equatable {
    case invalidCredentials
    case emptyFields
    case network(String)
    case unknown(String)

    var userMessage: String {
        switch self {
        case .invalidCredentials: return "Dispositivo o contraseña incorrectos"
        case .emptyFields:        return "Completa todos los campos"
        case .network(let msg):   return msg
        case .unknown(let msg):   return msg
        }
    }
}

enum AuthDomain {
    static let value = "auth"
}

enum AuthErrorMapper {
    static func map(_ error: Error) -> AuthError {
        if let auth = error as? AuthError { return auth }

        let failure = (error as? Failure) ?? Failure.map(error, domain: AuthDomain.value)

        // La API responde 400 "invalid credentials" en login fallido.
        if failure.statusCode == 400 || failure.statusCode == 401 {
            return .invalidCredentials
        }

        switch failure.type {
        case .unauthorized:
            return .invalidCredentials
        case .noConnection, .network, .timeout:
            return .network(failure.message)
        default:
            return .unknown(failure.message)
        }
    }
}
