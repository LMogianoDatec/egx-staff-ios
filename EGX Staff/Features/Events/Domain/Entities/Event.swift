import Foundation

/// Estado de un evento asignado al operador.
enum EventStatus: String, Equatable, Sendable {
    case inProgress
    case assigned
    case finished

    /// Etiqueta corta en mayúsculas para el badge de la tarjeta.
    var label: String {
        switch self {
        case .inProgress: return "EN CURSO"
        case .assigned:   return "ASIGNADO"
        case .finished:   return "FINALIZADO"
        }
    }

    /// Mapea el string crudo de la API a un caso conocido (default `.assigned`).
    static func from(raw: String?) -> EventStatus {
        switch raw?.lowercased() {
        case "in_progress", "en_curso", "ongoing": return .inProgress
        case "finished", "finalizado", "ended":    return .finished
        default:                                   return .assigned
        }
    }
}

struct Event: Identifiable, Equatable, Hashable, Sendable {
    let id: String
    let name: String
    let summary: String
    let logoURL: URL?
    let status: EventStatus
    let assignedAt: Date?
    let sessions: [EventSession]

    init(
        id: String,
        name: String,
        summary: String,
        logoURL: URL?,
        status: EventStatus,
        assignedAt: Date?,
        sessions: [EventSession] = []
    ) {
        self.id = id
        self.name = name
        self.summary = summary
        self.logoURL = logoURL
        self.status = status
        self.assignedAt = assignedAt
        self.sessions = sessions
    }

    /// Sesión con validación abierta ahora (la destacada en la pantalla).
    func activeSession(now: Date = .now) -> EventSession? {
        sessions.first { $0.accessState(now: now) == .openNow }
    }

    /// Fecha corta para el badge, p.ej. `2 JUN`. Vacío si no hay fecha.
    var shortDate: String {
        guard let assignedAt else { return "" }
        return Event.badgeFormatter.string(from: assignedAt).uppercased()
    }

    /// `EN CURSO · 2 JUN` — texto completo del badge sobre la imagen.
    var badgeText: String {
        let date = shortDate
        return date.isEmpty ? status.label : "\(status.label) · \(date)"
    }

    private static let badgeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_ES")
        f.dateFormat = "d MMM"
        return f
    }()
}
