import Foundation
import Observation

@MainActor
@Observable
final class LoginViewModel {
    var deviceName: String = ""
    var password: String = ""
    var isPasswordVisible: Bool = false
    private(set) var status: Status = .idle
    private(set) var errorMessage: String? = nil

    enum Status: Equatable {
        case idle
        case loading
        case success(AuthSession)
        case failure
    }

    var isLoading: Bool { status == .loading }

    var canSubmit: Bool {
        !deviceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !password.isEmpty
        && status != .loading
    }

    private let loginUseCase: LoginUseCase

    init(loginUseCase: LoginUseCase) {
        self.loginUseCase = loginUseCase
    }

    func handle(_ intent: LoginIntent) {
        switch intent {
        case .deviceNameChanged(let value):
            deviceName = value
            if errorMessage != nil { errorMessage = nil }
        case .passwordChanged(let value):
            password = value
            if errorMessage != nil { errorMessage = nil }
        case .togglePasswordVisibility:
            isPasswordVisible.toggle()
        case .submit:
            Task { await submit() }
        case .dismissError:
            errorMessage = nil
        }
    }

    private func submit() async {
        guard canSubmit else { return }
        status = .loading
        errorMessage = nil

        do {
            let session = try await loginUseCase(deviceName: deviceName, password: password)
            status = .success(session)
        } catch let error as AuthError {
            status = .failure
            errorMessage = error.userMessage
        } catch {
            status = .failure
            errorMessage = AuthErrorMapper.map(error).userMessage
        }
    }
}
