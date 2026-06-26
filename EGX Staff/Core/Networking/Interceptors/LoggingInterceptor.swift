import Foundation

final class LoggingInterceptor: APIInterceptor, @unchecked Sendable {
    private let logger: LoggerService
    private let logBody: Bool

    init(logger: LoggerService, logBody: Bool = false) {
        self.logger = logger
        self.logBody = logBody
    }

    func willSend(_ request: inout URLRequest, context: RequestContext) async throws {
        let url = request.url?.absoluteString ?? "?"
        let prefix = context.attempt > 0 ? "↻[\(context.attempt)] " : "→ "
        logger.debug("\(prefix)\(context.method.rawValue) \(url)")
        if logBody, let body = request.httpBody, let str = String(data: body, encoding: .utf8) {
            logger.debug("   body: \(str)")
        }
    }

    func didReceive(data: Data, response: HTTPURLResponse, context: RequestContext) async throws {
        let url = response.url?.absoluteString ?? "?"
        logger.debug("← \(response.statusCode) \(context.method.rawValue) \(url) (\(data.count)B)")
        // En errores siempre mostramos el body; en éxito solo si logBody.
        if (response.statusCode >= 400 || logBody), !data.isEmpty,
           let str = String(data: data, encoding: .utf8) {
            logger.debug("   body: \(str)")
        }
    }

    func didFail(with error: Error, context: RequestContext) async {
        let domain = context.domain.map { "[\($0)] " } ?? ""
        logger.error("✗ \(domain)\(context.method.rawValue) \(context.path) — \(error.localizedDescription)")
    }
}
