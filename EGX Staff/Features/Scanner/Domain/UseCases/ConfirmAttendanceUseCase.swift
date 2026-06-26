import Foundation

/// Paso 2: confirma la asistencia vía `scan`. 409 → ya escaneado.
struct ConfirmAttendanceUseCase: Sendable {
    let repository: ScannerRepository

    func callAsFunction(userEventId: String, eventId: String) async -> ConfirmResult {
        do {
            try await repository.confirmScan(userEventId: userEventId, eventId: eventId)
            return .registered
        } catch {
            let failure = (error as? Failure) ?? Failure.map(error, domain: ScannerDomain.value)
            if failure.statusCode == 409 {
                return .alreadyScanned
            }
            return .failure(failure.message)
        }
    }
}
