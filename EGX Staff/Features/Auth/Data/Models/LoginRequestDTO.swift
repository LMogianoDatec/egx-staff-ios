import Foundation

/// Cuerpo de Mobile Login (`POST /api/v1/mobile`).
/// `deviceName` se serializa a `device_name` vía `convertToSnakeCase`.
struct LoginRequestDTO: Encodable {
    let deviceName: String
    let password: String
}
