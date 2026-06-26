import Foundation

protocol ScannerRepository: Sendable {
    /// Verifica si el asistente existe / tiene acceso a la sesión.
    func check(idn: String, sessionId: String) async throws -> Attendee
    /// Confirma la asistencia. Lanza `Failure` (409 = ya escaneado).
    func confirmScan(userEventId: String, eventId: String) async throws
}
