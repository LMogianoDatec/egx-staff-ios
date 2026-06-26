import Foundation

protocol APIInterceptor: Sendable {
    func willSend(_ request: inout URLRequest, context: RequestContext) async throws
    func didReceive(data: Data, response: HTTPURLResponse, context: RequestContext) async throws
    func didFail(with error: Error, context: RequestContext) async
}

extension APIInterceptor {
    func willSend(_ request: inout URLRequest, context: RequestContext) async throws {}
    func didReceive(data: Data, response: HTTPURLResponse, context: RequestContext) async throws {}
    func didFail(with error: Error, context: RequestContext) async {}
}

struct RequestContext: Sendable {
    let path: String
    let method: HTTPMethod
    let domain: String?
    let requiresAuth: Bool
    let attempt: Int
}
