import Foundation

enum FailureType: String, Sendable, Equatable {
    case validation
    case unauthorized
    case forbidden
    case notFound
    case server
    case decoding
    case parsing
    case network
    case noConnection
    case timeout
    case cancelled
    case unknown
}

struct Failure: Error, Equatable, Sendable {
    let code: String
    let message: String
    let type: FailureType
    let statusCode: Int?
    let domain: String?

    init(
        code: String,
        message: String,
        type: FailureType,
        statusCode: Int? = nil,
        domain: String? = nil
    ) {
        self.code = code
        self.message = message
        self.type = type
        self.statusCode = statusCode
        self.domain = domain
    }
}

extension Failure {
    static func invalidURL(domain: String?) -> Failure {
        Failure(code: "invalid_url", message: "URL inválida", type: .unknown, domain: domain)
    }

    static func unauthorized(domain: String?, message: String = "Credenciales incorrectas") -> Failure {
        Failure(code: "unauthorized", message: message, type: .unauthorized, statusCode: 401, domain: domain)
    }

    static func forbidden(domain: String?) -> Failure {
        Failure(code: "forbidden", message: "No tienes permisos para esta acción", type: .forbidden, statusCode: 403, domain: domain)
    }

    static func notFound(domain: String?) -> Failure {
        Failure(code: "not_found", message: "Recurso no encontrado", type: .notFound, statusCode: 404, domain: domain)
    }

    static func server(statusCode: Int, message: String?, domain: String?) -> Failure {
        Failure(
            code: "server_error",
            message: message ?? "Error del servidor",
            type: .server,
            statusCode: statusCode,
            domain: domain
        )
    }

    static func decoding(_ description: String, domain: String?) -> Failure {
        Failure(code: "decoding_error", message: "Respuesta inválida del servidor", type: .decoding, domain: domain)
    }

    static func parsing(_ description: String, domain: String?) -> Failure {
        Failure(code: "parsing_error", message: "Error al procesar la respuesta", type: .parsing, domain: domain)
    }

    static func noConnection(domain: String?) -> Failure {
        Failure(code: "no_connection", message: "Sin conexión a internet", type: .noConnection, domain: domain)
    }

    static func timeout(domain: String?) -> Failure {
        Failure(code: "timeout", message: "La conexión tardó demasiado", type: .timeout, domain: domain)
    }

    static func cancelled(domain: String?) -> Failure {
        Failure(code: "cancelled", message: "Solicitud cancelada", type: .cancelled, domain: domain)
    }

    static func network(_ description: String, domain: String?) -> Failure {
        Failure(code: "network_error", message: "Problema de conexión", type: .network, domain: domain)
    }

    static func unknown(_ description: String, domain: String?) -> Failure {
        Failure(code: "unknown", message: description.isEmpty ? "Ocurrió un error inesperado" : description, type: .unknown, domain: domain)
    }
}

extension Failure {
    static func map(_ error: Error, domain: String?) -> Failure {
        if let failure = error as? Failure { return failure }
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .dataNotAllowed:
                return .noConnection(domain: domain)
            case .timedOut:
                return .timeout(domain: domain)
            case .cancelled:
                return .cancelled(domain: domain)
            case .networkConnectionLost, .dnsLookupFailed, .cannotFindHost, .cannotConnectToHost:
                return .network(urlError.localizedDescription, domain: domain)
            default:
                return .network(urlError.localizedDescription, domain: domain)
            }
        }
        if error is DecodingError {
            return .decoding(String(describing: error), domain: domain)
        }
        return .unknown(error.localizedDescription, domain: domain)
    }
}
