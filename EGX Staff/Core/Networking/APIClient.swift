import Foundation

protocol APIClient: Sendable {
    func send<Response: Decodable>(_ endpoint: Endpoint<Response>) async throws -> Response
}

struct APIConfiguration: Sendable {
    let baseURL: URL
    let defaultHeaders: [String: String]
    let defaultTimeout: RequestTimeout
    let defaultRetryPolicy: RetryPolicy
    let useMockData: Bool

    init(
        baseURL: URL,
        defaultHeaders: [String: String] = [:],
        defaultTimeout: RequestTimeout = .default,
        defaultRetryPolicy: RetryPolicy = .default,
        useMockData: Bool = false
    ) {
        self.baseURL = baseURL
        self.defaultHeaders = defaultHeaders
        self.defaultTimeout = defaultTimeout
        self.defaultRetryPolicy = defaultRetryPolicy
        self.useMockData = useMockData
    }

    static let mock = APIConfiguration(
        baseURL: URL(string: "https://mock.egx.local")!,
        useMockData: true
    )

    static let development = APIConfiguration(
        baseURL: AppConfig.apiBaseURL,
        useMockData: false
    )
}

final class DefaultAPIClient: APIClient, @unchecked Sendable {
    private let configuration: APIConfiguration
    private let interceptors: [APIInterceptor]
    private let logger: LoggerService
    private let decoder: JSONDecoder

    // URLSession reutilizada por timeout: mantiene el pool de conexiones (evita
    // re-handshake TLS por request) y no deja sesiones colgadas. Protegida por
    // lock porque send() corre concurrente.
    private let sessionsLock = NSLock()
    private var sessions: [RequestTimeout: URLSession] = [:]

    init(
        configuration: APIConfiguration,
        interceptors: [APIInterceptor] = [],
        logger: LoggerService = SilentLogger()
    ) {
        self.configuration = configuration
        self.interceptors = interceptors
        self.logger = logger
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
    }

    func send<Response: Decodable>(_ endpoint: Endpoint<Response>) async throws -> Response {
        if configuration.useMockData, let mockResult = endpoint.mockResult {
            try await Task.sleep(nanoseconds: 600_000_000)
            switch mockResult {
            case .success(let value):
                return value
            case .failure(let failure):
                throw failure
            }
        }

        let policy = endpoint.retryPolicy ?? configuration.defaultRetryPolicy
        let domain = endpoint.domain
        var attempt = 0
        var lastError: Error?

        while attempt <= policy.maxRetries {
            do {
                return try await performRequest(endpoint, attempt: attempt)
            } catch {
                lastError = error
                let canRetry = attempt < policy.maxRetries && RetryPolicy.isRetryable(error)
                if !canRetry {
                    if let fallback = endpoint.fallback {
                        logger.warning("Using fallback for \(endpoint.path)")
                        return fallback()
                    }
                    throw Failure.map(error, domain: domain)
                }
                let delay = policy.delay(forAttempt: attempt)
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                attempt += 1
            }
        }

        throw Failure.map(lastError ?? Failure.unknown("Retry exhausted", domain: domain), domain: domain)
    }

    private func performRequest<Response: Decodable>(
        _ endpoint: Endpoint<Response>,
        attempt: Int
    ) async throws -> Response {
        let context = RequestContext(
            path: endpoint.path,
            method: endpoint.method,
            domain: endpoint.domain,
            requiresAuth: endpoint.requiresAuth,
            attempt: attempt
        )

        var request = try buildRequest(endpoint)
        for interceptor in interceptors {
            try await interceptor.willSend(&request, context: context)
        }

        let session = session(for: endpoint.timeout ?? configuration.defaultTimeout)
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            for interceptor in interceptors {
                await interceptor.didFail(with: error, context: context)
            }
            throw error
        }

        guard let http = response as? HTTPURLResponse else {
            throw Failure.unknown("No HTTP response", domain: endpoint.domain)
        }

        for interceptor in interceptors {
            try await interceptor.didReceive(data: data, response: http, context: context)
        }

        return try parse(data: data, http: http, endpoint: endpoint)
    }

    private func buildRequest<Response>(_ endpoint: Endpoint<Response>) throws -> URLRequest {
        guard var components = URLComponents(
            url: configuration.baseURL.appendingPathComponent(endpoint.path),
            resolvingAgainstBaseURL: false
        ) else {
            throw Failure.invalidURL(domain: endpoint.domain)
        }
        if !endpoint.query.isEmpty { components.queryItems = endpoint.query }
        guard let url = components.url else { throw Failure.invalidURL(domain: endpoint.domain) }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.body
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if endpoint.body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        for (key, value) in configuration.defaultHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        for (key, value) in endpoint.headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        return request
    }

    /// Devuelve una URLSession reutilizable para ese timeout, creándola la
    /// primera vez. Thread-safe vía lock.
    private func session(for timeout: RequestTimeout) -> URLSession {
        sessionsLock.lock()
        defer { sessionsLock.unlock() }
        if let existing = sessions[timeout] { return existing }
        let session = makeSession(for: timeout)
        sessions[timeout] = session
        return session
    }

    private func makeSession(for timeout: RequestTimeout) -> URLSession {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout.request
        config.timeoutIntervalForResource = timeout.resource
        config.waitsForConnectivity = false
        return URLSession(configuration: config)
    }

    private func parse<Response: Decodable>(
        data: Data,
        http: HTTPURLResponse,
        endpoint: Endpoint<Response>
    ) throws -> Response {
        let domain = endpoint.domain

        switch http.statusCode {
        case 200..<300:
            if data.isEmpty, let empty = EmptyResponse() as? Response {
                return empty
            }
            do {
                if endpoint.wrapInBaseResponse {
                    let wrapped = try decoder.decode(BaseResponse<Response>.self, from: data)
                    return wrapped.data
                }
                return try decoder.decode(Response.self, from: data)
            } catch {
                throw Failure.decoding(error.localizedDescription, domain: domain)
            }
        case 401:
            throw Failure.unauthorized(domain: domain)
        case 403:
            throw Failure.forbidden(domain: domain)
        case 404:
            throw Failure.notFound(domain: domain)
        default:
            let message = decodeErrorMessage(from: data)
            throw Failure.server(statusCode: http.statusCode, message: message, domain: domain)
        }
    }

    private func decodeErrorMessage(from data: Data) -> String? {
        guard !data.isEmpty,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return String(data: data, encoding: .utf8)
        }
        return (json["message"] as? String)
            ?? (json["error"] as? String)
            ?? (json["detail"] as? String)
    }
}

struct EmptyResponse: Decodable, Sendable {}
