import Foundation

struct UserDTO: Decodable, Sendable {
    let id: String
    let email: String
    let fullName: String
    let role: String
}

extension UserDTO {
    func toDomain() -> User {
        User(id: id, email: email, fullName: fullName, role: role)
    }
}
