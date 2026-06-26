import Foundation
import Observation

@MainActor
@Observable
final class AppViewModel {
    private(set) var phase: AuthState = .launching
    var showingSessionExpiredAlert = false

    private let loadSession: LoadSessionUseCase
    private let logout: LogoutUseCase

    // @ObservationIgnored + nonisolated(unsafe): plain stored property accessible from deinit
    @ObservationIgnored
    nonisolated(unsafe) private var sessionExpiryObserver: NSObjectProtocol?

    init(loadSession: LoadSessionUseCase, logout: LogoutUseCase) {
        self.loadSession = loadSession
        self.logout = logout
        observeSessionExpiry()
    }

    func bootstrap() async {
        if let session = await loadSession() {
            phase = .authenticated(session)
        } else {
            phase = .unauthenticated
        }
    }

    func didAuthenticate(_ session: AuthSession) {
        phase = .authenticated(session)
    }

    func signOut() async {
        try? await logout()
        NotificationCenter.default.post(name: .egxUserSignedOut, object: nil)
        phase = .unauthenticated
    }

    /// Re-chequea la sesión (token ~1 semana). Si expiró, `loadSession` la limpia
    /// y devuelve nil → forzamos re-login. Llamar al volver a primer plano.
    func revalidateSession() async {
        guard case .authenticated = phase else { return }
        if await loadSession() == nil {
            phase = .unauthenticated
        }
    }

    // MARK: - Session expiry (401 / token vencido)

    private func observeSessionExpiry() {
        sessionExpiryObserver = NotificationCenter.default.addObserver(
            forName: .egxSessionExpired,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            Task { await self?.handleSessionExpired() }
        }
    }

    deinit {
        if let observer = sessionExpiryObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func handleSessionExpired() async {
        guard case .authenticated = phase else { return }
        try? await logout()
        NotificationCenter.default.post(name: .egxUserSignedOut, object: nil)
        showingSessionExpiredAlert = true
    }

    func confirmSessionExpiredAlert() {
        showingSessionExpiredAlert = false
        phase = .unauthenticated
    }
}
