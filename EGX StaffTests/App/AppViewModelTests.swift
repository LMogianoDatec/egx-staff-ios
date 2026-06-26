import XCTest
@testable import EGX_Staff

@MainActor
final class AppViewModelTests: XCTestCase {

    private var repo: MockAuthRepository!
    private var sut: AppViewModel!

    override func setUp() {
        super.setUp()
        repo = MockAuthRepository()
        sut = AppViewModel(
            loadSession: LoadSessionUseCase(repository: repo),
            logout: LogoutUseCase(repository: repo)
        )
    }

    // MARK: - bootstrap

    func test_bootstrap_withValidSession_setsAuthenticated() async {
        let session = makeAuthSession()
        await repo.setCurrentSession(session)

        await sut.bootstrap()

        if case .authenticated(let s) = sut.phase {
            XCTAssertEqual(s.accessToken, session.accessToken)
        } else {
            XCTFail("Expected authenticated, got \(sut.phase)")
        }
    }

    func test_bootstrap_withNoSession_setsUnauthenticated() async {
        await repo.setCurrentSession(nil)

        await sut.bootstrap()

        XCTAssertEqual(sut.phase, .unauthenticated)
    }

    // MARK: - didAuthenticate

    func test_didAuthenticate_setsAuthenticatedPhase() {
        let session = makeAuthSession(accessToken: "tok_new")
        sut.didAuthenticate(session)

        if case .authenticated(let s) = sut.phase {
            XCTAssertEqual(s.accessToken, "tok_new")
        } else {
            XCTFail("Expected authenticated")
        }
    }

    // MARK: - signOut

    func test_signOut_setsUnauthenticated() async {
        let session = makeAuthSession()
        sut.didAuthenticate(session)

        await sut.signOut()

        XCTAssertEqual(sut.phase, .unauthenticated)
    }

    func test_signOut_callsLogout() async {
        sut.didAuthenticate(makeAuthSession())
        await sut.signOut()

        let called = await repo.logoutCalled
        XCTAssertTrue(called)
    }

    // MARK: - revalidateSession

    func test_revalidateSession_sessionStillValid_keepsAuthenticated() async {
        let session = makeAuthSession()
        await repo.setCurrentSession(session)
        sut.didAuthenticate(session)

        await sut.revalidateSession()

        XCTAssertTrue(sut.phase != .unauthenticated)
    }

    func test_revalidateSession_sessionExpired_setsUnauthenticated() async {
        sut.didAuthenticate(makeAuthSession())
        await repo.setCurrentSession(nil)

        await sut.revalidateSession()

        XCTAssertEqual(sut.phase, .unauthenticated)
    }

    func test_revalidateSession_whenUnauthenticated_doesNothing() async {
        XCTAssertEqual(sut.phase, .launching)

        await sut.revalidateSession()

        XCTAssertEqual(sut.phase, .launching)
    }

    // MARK: - Session expiry notification

    func test_sessionExpiredNotification_whenAuthenticated_setsAlert() async {
        sut.didAuthenticate(makeAuthSession())

        NotificationCenter.default.post(name: .egxSessionExpired, object: nil)
        await drainTasks()

        XCTAssertTrue(sut.showingSessionExpiredAlert)
    }

    func test_sessionExpiredNotification_whenUnauthenticated_doesNotSetAlert() async {
        // phase is .launching — not authenticated
        NotificationCenter.default.post(name: .egxSessionExpired, object: nil)
        await drainTasks()

        XCTAssertFalse(sut.showingSessionExpiredAlert)
    }

    // MARK: - confirmSessionExpiredAlert

    func test_confirmSessionExpiredAlert_clearsAlertAndSetsUnauthenticated() async {
        sut.didAuthenticate(makeAuthSession())
        NotificationCenter.default.post(name: .egxSessionExpired, object: nil)
        await drainTasks()

        sut.confirmSessionExpiredAlert()

        XCTAssertFalse(sut.showingSessionExpiredAlert)
        XCTAssertEqual(sut.phase, .unauthenticated)
    }

    // MARK: - Helpers

    private func drainTasks() async {
        for _ in 0..<10 { await Task.yield() }
    }
}
