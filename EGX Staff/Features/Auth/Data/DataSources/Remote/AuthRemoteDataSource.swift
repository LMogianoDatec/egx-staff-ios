import Foundation

protocol AuthRemoteDataSource: Sendable {
    func login(deviceName: String, password: String) async throws -> LoginResponseDTO
}

final class AuthRemoteDataSourceImpl: AuthRemoteDataSource, @unchecked Sendable {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func login(deviceName: String, password: String) async throws -> LoginResponseDTO {
        let body = Endpoint<LoginResponseDTO>.jsonBody(
            LoginRequestDTO(deviceName: deviceName, password: password)
        )

        let endpoint = Endpoint<LoginResponseDTO>(
            path: "/api/v1/mobile",
            method: .post,
            body: body,
            requiresAuth: false,
            domain: AuthDomain.value,
            timeout: .short,
            retryPolicy: RetryPolicy.none
        )

        return try await client.send(endpoint)
    }
}
