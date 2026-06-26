import XCTest
@testable import EGX_Staff

final class LoadSessionUseCaseTests: XCTestCase {

    private var repo: MockAuthRepository!
    private var sut: LoadSessionUseCase!

    override func setUp() {
        super.setUp()
        repo = MockAuthRepository()
        sut = LoadSessionUseCase(repository: repo)
    }

    func test_whenSessionExists_returnsSession() async {
        let session = makeAuthSession(accessToken: "tok_valid")
        await repo.setCurrentSession(session)

        let result = await sut()

        XCTAssertEqual(result?.accessToken, "tok_valid")
    }

    func test_whenNoSession_returnsNil() async {
        await repo.setCurrentSession(nil)

        let result = await sut()

        XCTAssertNil(result)
    }
}
