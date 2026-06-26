import Foundation

/// Una sesión de un evento asignado. Las ventanas de `access` definen cuándo
/// el escáner puede validar asistentes; `session` es el horario real del bloque.
struct EventSession: Identifiable, Equatable, Hashable, Sendable {
    let id: String
    let name: String
    let start: Date?
    let end: Date?
    let accessStart: Date?
    let accessEnd: Date?

    /// Estado de la ventana de validación respecto a `now`.
    enum AccessState: Equatable {
        case openNow
        case upcoming
        case closed
        /// Sin fechas de acceso → tratamos como abierto (el backend decide).
        case unknown

        var label: String {
            switch self {
            case .openNow:  return "ACCESO ABIERTO AHORA"
            case .upcoming: return "Próxima"
            case .closed:   return "Acceso cerrado"
            case .unknown:  return ""
            }
        }
    }

    func accessState(now: Date = .now) -> AccessState {
        guard let accessStart, let accessEnd else { return .unknown }
        if now < accessStart { return .upcoming }
        if now > accessEnd { return .closed }
        return .openNow
    }

    /// El escáner solo entra cuando la validación está abierta (o sin ventana).
    func isScannable(now: Date = .now) -> Bool {
        switch accessState(now: now) {
        case .openNow, .unknown: return true
        case .upcoming, .closed: return false
        }
    }

    // MARK: - Display

    /// `JUEVES 11 JUN` — fecha del bloque en mayúsculas (locale es).
    var dayLabel: String {
        guard let start else { return "" }
        return EventSession.dayFormatter.string(from: start).uppercased()
    }

    /// `08:30 – 10:00` — horario del bloque.
    var timeRange: String { range(start, end) }

    /// `08:30` — inicio del bloque (para filas compactas).
    var startTime: String { start.map { EventSession.timeFormatter.string(from: $0) } ?? "" }

    /// `10:00` — fin del bloque.
    var endTime: String { end.map { EventSession.timeFormatter.string(from: $0) } ?? "" }

    /// `08:15 – 10:00` — ventana de validación del escáner.
    var accessRange: String { range(accessStart, accessEnd) }

    private func range(_ from: Date?, _ to: Date?) -> String {
        guard let from, let to else { return "" }
        let f = EventSession.timeFormatter
        return "\(f.string(from: from)) – \(f.string(from: to))"
    }

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_ES")
        f.dateFormat = "EEEE d MMM"
        return f
    }()

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_ES")
        f.dateFormat = "HH:mm"
        return f
    }()
}
