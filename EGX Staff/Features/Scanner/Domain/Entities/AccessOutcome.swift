import Foundation

enum AccessOutcome: Equatable, Sendable {
    case granted(Attendee)
    case denied(reason: DenialReason)

    var isGranted: Bool {
        if case .granted = self { return true }
        return false
    }
}

enum DenialReason: Equatable, Sendable {
    case invalidQR
    case expiredQR
    case notFound
    case notAssigned
    case rejectedRegistration
    case pendingApproval
    case message(String)

    var userMessage: String {
        switch self {
        case .invalidQR:              return "Código QR no válido"
        case .expiredQR:              return "Este código QR ha vencido"
        case .notFound:               return "No registrado en esta sesión"
        case .notAssigned:            return "Escáner no asignado a esta sesión"
        case .rejectedRegistration:   return "Lo sentimos, no pudimos reservarte un lugar"
        case .pendingApproval:        return "Inscripción pendiente de aprobación"
        case .message(let m):         return m
        }
    }
}
