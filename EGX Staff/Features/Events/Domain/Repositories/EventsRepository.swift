import Foundation

protocol EventsRepository: Sendable {
    /// Eventos asignados al operador autenticado. Siempre pega a red.
    func fetchAssignedEvents() async throws -> [Event]
}
