import Foundation

/// Paso 1: del QR escaneado extrae el `idn` y consulta `check`.
/// No confirma asistencia — solo verifica que el asistente exista/tenga acceso.
struct CheckAccessUseCase: Sendable {
    let repository: ScannerRepository

    func callAsFunction(rawPayload: String, sessionId: String) async -> ScanResult {
        let now = Date()

        if let expiry = QRPayloadParser.extractExpiry(from: rawPayload), expiry < now {
            return ScanResult(outcome: .denied(reason: .expiredQR), scannedAt: now, rawPayload: rawPayload)
        }

        guard let idn = QRPayloadParser.extractIdn(from: rawPayload) else {
            return ScanResult(outcome: .denied(reason: .invalidQR), scannedAt: now, rawPayload: rawPayload)
        }

        do {
            let attendee = try await repository.check(idn: idn, sessionId: sessionId)
            if attendee.isRejected {
                return ScanResult(outcome: .denied(reason: .rejectedRegistration), scannedAt: now, rawPayload: rawPayload)
            }
            guard attendee.isApproved else {
                return ScanResult(outcome: .denied(reason: .pendingApproval), scannedAt: now, rawPayload: rawPayload)
            }
            return ScanResult(outcome: .granted(attendee), scannedAt: now, rawPayload: rawPayload)
        } catch {
            return ScanResult(outcome: .denied(reason: Self.reason(for: error)), scannedAt: now, rawPayload: rawPayload)
        }
    }

    private static func reason(for error: Error) -> DenialReason {
        let failure = (error as? Failure) ?? Failure.map(error, domain: ScannerDomain.value)
        switch failure.statusCode {
        case 403: return .notAssigned
        case 404: return .notFound
        default:
            switch failure.type {
            case .noConnection, .network, .timeout:
                return .message(failure.message)
            default:
                return .notFound
            }
        }
    }
}
