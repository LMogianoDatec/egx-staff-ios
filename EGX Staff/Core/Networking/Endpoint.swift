import Foundation

enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

struct Endpoint<Response: Decodable>: @unchecked Sendable {
    let path: String
    let method: HTTPMethod
    let query: [URLQueryItem]
    let headers: [String: String]
    let body: Data?
    let requiresAuth: Bool

    let domain: String?
    let timeout: RequestTimeout?
    let retryPolicy: RetryPolicy?
    let wrapInBaseResponse: Bool

    let fallback: (@Sendable () -> Response)?
    let mockResult: Result<Response, Failure>?

    init(
        path: String,
        method: HTTPMethod = .get,
        query: [URLQueryItem] = [],
        headers: [String: String] = [:],
        body: Data? = nil,
        requiresAuth: Bool = true,
        domain: String? = nil,
        timeout: RequestTimeout? = nil,
        retryPolicy: RetryPolicy? = nil,
        wrapInBaseResponse: Bool = false,
        fallback: (@Sendable () -> Response)? = nil,
        mockResult: Result<Response, Failure>? = nil
    ) {
        self.path = path
        self.method = method
        self.query = query
        self.headers = headers
        self.body = body
        self.requiresAuth = requiresAuth
        self.domain = domain
        self.timeout = timeout
        self.retryPolicy = retryPolicy
        self.wrapInBaseResponse = wrapInBaseResponse
        self.fallback = fallback
        self.mockResult = mockResult
    }
}

extension Endpoint {
    static func jsonBody<T: Encodable>(_ value: T) -> Data? {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return try? encoder.encode(value)
    }
}
