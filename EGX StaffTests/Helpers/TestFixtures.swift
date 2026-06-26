import Foundation
@testable import EGX_Staff

func makeAuthSession(
    accessToken: String = "access_token",
    refreshToken: String = "refresh_token",
    expiresAt: Date = .distantFuture,
    user: User = makeUser()
) -> AuthSession {
    AuthSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAt: expiresAt,
        user: user
    )
}

func makeUser(
    id: String = "op_1",
    email: String = "op@test.com",
    fullName: String = "Test Operator",
    role: String = "scanner"
) -> User {
    User(id: id, email: email, fullName: fullName, role: role)
}

func makeAttendee(
    id: String = "user_1",
    userEventId: String = "ue_1",
    fullName: String = "Juan Perez",
    email: String = "juan@test.com",
    company: String = "ACME",
    idn: String = "idn_abc123",
    approvalStatus: String = "approved",
    sessionName: String? = "Sala A",
    alreadyScanned: Bool = false
) -> Attendee {
    Attendee(
        id: id,
        userEventId: userEventId,
        fullName: fullName,
        email: email,
        company: company,
        idn: idn,
        approvalStatus: approvalStatus,
        sessionName: sessionName,
        alreadyScanned: alreadyScanned
    )
}

func makeEvent(
    id: String = "ev_1",
    name: String = "Tech Summit",
    summary: String = "Descripción del evento",
    logoURL: URL? = nil,
    status: EventStatus = .assigned,
    assignedAt: Date? = Date(timeIntervalSince1970: 1_700_000_000),
    sessions: [EventSession] = []
) -> Event {
    Event(
        id: id,
        name: name,
        summary: summary,
        logoURL: logoURL,
        status: status,
        assignedAt: assignedAt,
        sessions: sessions
    )
}
