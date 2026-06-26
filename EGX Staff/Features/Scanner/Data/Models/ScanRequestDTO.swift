import Foundation

/// Cuerpo de `POST /api/v1/scanner/scan`.
/// `userEventId`/`eventId`/`scanMethod`/`deviceId` → snake_case vía `convertToSnakeCase`.
struct ScanRequestDTO: Encodable {
    let userEventId: String
    let eventId: String
    let scanMethod: String
    let deviceId: String
    let notes: String
}
