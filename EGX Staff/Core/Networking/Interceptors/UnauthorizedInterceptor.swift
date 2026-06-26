import Foundation

extension Notification.Name {
    /// El token fue rechazado por el servidor (401) en un request autenticado,
    /// o la sesión expiró. La app debe forzar re-login.
    static let egxSessionExpired = Notification.Name("egx.session.expired")
    /// Usuario hizo sign out explícito o por expiración: limpiar estados de UI.
    static let egxUserSignedOut = Notification.Name("egx.user.signed_out")
}

/// Convierte un 401 del backend en una señal global de sesión expirada.
/// Solo dispara para requests que requieren auth (ignora el login).
final class UnauthorizedInterceptor: APIInterceptor, @unchecked Sendable {
    func didReceive(data: Data, response: HTTPURLResponse, context: RequestContext) async throws {
        if response.statusCode == 401 && context.requiresAuth {
            NotificationCenter.default.post(name: .egxSessionExpired, object: nil)
        }
    }
}
