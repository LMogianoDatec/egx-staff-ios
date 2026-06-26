import Foundation

/// Respuesta de Mobile Login (`POST /api/v1/mobile`).
/// `{ "duration": "...", "email": "...", "id": "...", "success": true, "token": "v2.local..." }`
/// `duration` es la expiración del token (~1 semana); no hay refresh token.
struct LoginResponseDTO: Decodable, Sendable {
    let token: String
    let email: String
    let id: String
    let duration: String?
}

extension LoginResponseDTO {
    func toDomain() -> AuthSession {
        AuthSession(
            accessToken: token,
            refreshToken: "",
            expiresAt: LoginResponseDTO.parseDuration(duration),
            user: User(
                id: id,
                email: email,
                fullName: email,
                role: "scanner"
            )
        )
    }

    /// Parsea `duration` (ISO-8601 con offset). Fallback: ahora + 7 días.
    private static func parseDuration(_ raw: String?) -> Date {
        guard let raw, let date = isoFormatter.date(from: raw) else {
            return Date().addingTimeInterval(7 * 24 * 60 * 60)
        }
        return date
    }

    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
}
