import Foundation

enum EventsDomain {
    static let value = "events"
}

protocol EventsRemoteDataSource: Sendable {
    func fetchAssignedEvents() async throws -> [EventDTO]
}

final class EventsRemoteDataSourceImpl: EventsRemoteDataSource, @unchecked Sendable {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func fetchAssignedEvents() async throws -> [EventDTO] {
        // GET /api/v1/scanner/events → { "data": [...], "success": true }
        // Requiere scanner_token (lo inyecta AuthInterceptor).
        let endpoint = Endpoint<[EventDTO]>(
            path: "/api/v1/scanner/events",
            method: .get,
            requiresAuth: true,
            domain: EventsDomain.value,
            timeout: .default,
            wrapInBaseResponse: true
        )

        return try await client.send(endpoint)
    }
}

enum EventsMockData {
    static let assignedEvents: [EventDTO] = [
        EventDTO(
            eventId: "20cc2601-893e-4f09-b597-6b0ef0af6042",
            eventName: "Breakfast & Security",
            eventDescription: "Te invitamos a un desayuno donde exploraremos las últimas innovaciones en seguridad de red y cómo la inteligencia artificial.",
            logoUrl: "https://www.datec.com.bo/wp-content/uploads/2026/03/Evento-desayuno-DACAS-1700-x-590-1024x355.jpg",
            status: "in_progress",
            assignedAt: "2026-06-02T07:53:47.971135Z",
            sessions: [
                SessionDTO(
                    sessionId: "523e4567-e89b-12d3-a456-426614174001",
                    sessionName: "Acreditación y registro",
                    sessionStart: "2026-06-11T11:30:00Z",
                    sessionEnd: "2026-06-11T12:30:00Z",
                    accessStart: "2026-06-11T11:15:00Z",
                    accessEnd: "2026-06-11T12:30:00Z"
                ),
                SessionDTO(
                    sessionId: "523e4567-e89b-12d3-a456-426614174002",
                    sessionName: "Desayuno & Keynote de apertura",
                    sessionStart: "2026-06-11T12:30:00Z",
                    sessionEnd: "2026-06-11T14:00:00Z",
                    accessStart: "2026-06-11T12:15:00Z",
                    accessEnd: "2026-06-11T14:00:00Z"
                ),
                SessionDTO(
                    sessionId: "523e4567-e89b-12d3-a456-426614174003",
                    sessionName: "Panel de cierre & Networking",
                    sessionStart: "2026-06-11T15:00:00Z",
                    sessionEnd: "2026-06-11T16:30:00Z",
                    accessStart: "2026-06-11T14:45:00Z",
                    accessEnd: "2026-06-11T16:30:00Z"
                )
            ]
        ),
        EventDTO(
            eventId: "8f1c9d22-77ab-4e10-9d3a-2b5e0c4477aa",
            eventName: "Tech Summit 2025",
            eventDescription: "Conferencias y demos sobre las tendencias tecnológicas del año.",
            logoUrl: nil,
            status: "assigned",
            assignedAt: "2025-05-27T09:00:00Z",
            sessions: []
        )
    ]
}
