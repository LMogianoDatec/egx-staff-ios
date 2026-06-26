import Foundation

enum AuthState: Equatable {
    case launching
    case unauthenticated
    case authenticated(AuthSession)
}
