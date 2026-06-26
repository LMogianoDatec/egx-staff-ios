import Foundation

/// Payload de un evento asignado tal como llega de la API.
/// Las llaves snake_case (`event_id`, `logo_url`, `assigned_at`) las resuelve
/// `keyDecodingStrategy = .convertFromSnakeCase` del decoder compartido.
struct EventDTO: Decodable, Sendable {
    let eventId: String
    let eventName: String
    let eventDescription: String?
    let logoUrl: String?
    let status: String?
    /// ISO-8601 con fracción de segundos; se parsea a `Date` en `toDomain`.
    let assignedAt: String?
    /// Sesiones anidadas (formato nuevo de `GET /scanner/events`). Opcional por
    /// compatibilidad con respuestas viejas/planas.
    let sessions: [SessionDTO]?
}

/// Sesión anidada dentro de `EventDTO.sessions`.
struct SessionDTO: Decodable, Sendable {
    let sessionId: String
    let sessionName: String
    let sessionStart: String?
    let sessionEnd: String?
    let accessStart: String?
    let accessEnd: String?
}

extension EventDTO {
    func toDomain() -> Event {
        let mapped = (sessions ?? [])
            .map { $0.toDomain() }
            .sorted { ($0.start ?? .distantFuture) < ($1.start ?? .distantFuture) }

        return Event(
            id: eventId,
            name: eventName,
            summary: eventDescription ?? "",
            logoURL: logoUrl.flatMap(URL.init(string:)),
            status: EventStatus.from(raw: status),
            assignedAt: assignedAt.flatMap(EventDTO.parseDate),
            sessions: mapped
        )
    }

    /// Parser tolerante: prueba ISO-8601 con y sin fracción de segundos.
    nonisolated static func parseDate(_ raw: String) -> Date? {
        if let date = isoWithFraction.date(from: raw) { return date }
        return isoPlain.date(from: raw)
    }

    nonisolated(unsafe) private static let isoWithFraction: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    nonisolated(unsafe) private static let isoPlain: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
}

extension SessionDTO {
    func toDomain() -> EventSession {
        EventSession(
            id: sessionId,
            name: sessionName,
            start: sessionStart.flatMap(EventDTO.parseDate),
            end: sessionEnd.flatMap(EventDTO.parseDate),
            accessStart: accessStart.flatMap(EventDTO.parseDate),
            accessEnd: accessEnd.flatMap(EventDTO.parseDate)
        )
    }
}
