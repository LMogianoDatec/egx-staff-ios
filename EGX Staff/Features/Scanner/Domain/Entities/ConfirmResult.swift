import Foundation

/// Resultado de confirmar asistencia (`POST /api/v1/scanner/scan`).
enum ConfirmResult: Equatable, Sendable {
    case registered
    case alreadyScanned
    case failure(String)
}
