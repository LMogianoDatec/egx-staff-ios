import Foundation

protocol ScannerRemoteDataSource: Sendable {
    func check(idn: String, sessionId: String) async throws -> CheckResponseDTO
    func confirmScan(userEventId: String, eventId: String) async throws
}

final class ScannerRemoteDataSourceImpl: ScannerRemoteDataSource, @unchecked Sendable {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func check(idn: String, sessionId: String) async throws -> CheckResponseDTO {
        // v2: valida acceso por sesión (no por evento). Devuelve el user_event_id
        // específico de esa sesión, que luego usa confirmScan.
        let endpoint = Endpoint<CheckResponseDTO>(
            path: "/api/v1/scanner/v2/check/\(idn)",
            method: .get,
            query: [URLQueryItem(name: "session_id", value: sessionId)],
            requiresAuth: true,
            domain: ScannerDomain.value,
            timeout: .short,
            retryPolicy: RetryPolicy.none,
            wrapInBaseResponse: true
        )
        return try await client.send(endpoint)
    }

    func confirmScan(userEventId: String, eventId: String) async throws {
        // TODO: valores hardcodeados — aún no se define qué mandar aquí.
        // Reemplazar device_id / notes con datos reales del dispositivo.
        let body = Endpoint<EmptyResponse>.jsonBody(
            ScanRequestDTO(
                userEventId: userEventId,
                eventId: eventId,
                scanMethod: "qr",
                deviceId: "scanner-11",
                notes: "test"
            )
        )
        let endpoint = Endpoint<EmptyResponse>(
            path: "/api/v1/scanner/scan",
            method: .post,
            body: body,
            requiresAuth: true,
            domain: ScannerDomain.value,
            timeout: .short,
            retryPolicy: RetryPolicy.none
        )
        _ = try await client.send(endpoint)
    }
}
