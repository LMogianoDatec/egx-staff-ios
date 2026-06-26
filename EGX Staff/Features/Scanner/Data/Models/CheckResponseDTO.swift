import Foundation

/// Objeto `data` de `GET /api/v1/scanner/check/{idn}?event_id=...`.
/// Llaves snake_case resueltas por `convertFromSnakeCase`.
struct CheckResponseDTO: Decodable, Sendable {
    let userId: String
    let userName: String?
    let userLastname: String?
    let userEmail: String?
    let userCompany: String?
    let idn: String?
    let userEventId: String
    let approvalStatus: String?
    let sessionId: String?
    let sessionName: String?
    let alreadyScanned: Bool?
}

extension CheckResponseDTO {
    func toDomain() -> Attendee {
        let full = [userName, userLastname]
            .compactMap { $0?.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return Attendee(
            id: userId,
            userEventId: userEventId,
            fullName: full.isEmpty ? (userEmail ?? "Asistente") : full,
            email: userEmail ?? "",
            company: userCompany ?? "",
            idn: idn ?? "",
            approvalStatus: approvalStatus ?? "",
            sessionName: sessionName,
            alreadyScanned: alreadyScanned ?? false
        )
    }
}
