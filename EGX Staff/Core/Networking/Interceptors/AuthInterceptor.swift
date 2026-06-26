import Foundation

final class AuthInterceptor: APIInterceptor, @unchecked Sendable {
    typealias TokenProvider = @Sendable () async -> String?

    private let tokenProvider: TokenProvider

    init(tokenProvider: @escaping TokenProvider) {
        self.tokenProvider = tokenProvider
    }

    func willSend(_ request: inout URLRequest, context: RequestContext) async throws {
        guard context.requiresAuth else { return }
        if let token = await tokenProvider(), !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }
}
