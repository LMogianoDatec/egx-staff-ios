import Foundation

enum LoginIntent {
    case deviceNameChanged(String)
    case passwordChanged(String)
    case togglePasswordVisibility
    case submit
    case dismissError
}
