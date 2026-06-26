import Foundation

struct User: Equatable, Identifiable, Sendable {
    let id: String
    let email: String
    let fullName: String
    let role: String
}
