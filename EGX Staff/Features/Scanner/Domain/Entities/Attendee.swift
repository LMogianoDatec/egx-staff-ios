import Foundation

/// Asistente devuelto por el endpoint `check` (verifica existencia/acceso).
/// `userEventId` es lo que luego confirma la asistencia vía `scan`.
struct Attendee: Equatable, Identifiable, Sendable {
    let id: String              // user_id
    let userEventId: String
    let fullName: String
    let email: String
    let company: String
    let idn: String
    let approvalStatus: String  // approved | pending | rejected
    let sessionName: String?
    let alreadyScanned: Bool

    var isApproved: Bool  { approvalStatus.lowercased() == "approved" }
    var isRejected: Bool  { approvalStatus.lowercased() == "rejected" }
}
