import SwiftUI

struct LoginView: View {
    @State private var viewModel: LoginViewModel
    let onAuthenticated: (AuthSession) -> Void

    @FocusState private var focusedField: Field?

    private enum Field { case device, password }

    init(onAuthenticated: @escaping (AuthSession) -> Void) {
        self._viewModel = State(initialValue: sl())
        self.onAuthenticated = onAuthenticated
    }

    init(viewModel: LoginViewModel, onAuthenticated: @escaping (AuthSession) -> Void) {
        self._viewModel = State(initialValue: viewModel)
        self.onAuthenticated = onAuthenticated
    }

    var body: some View {
        ZStack {
            Color.egxBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 28) {
                        header
                        formCard
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 56)
                    .padding(.bottom, 24)
                }
                .scrollDismissesKeyboard(.interactively)

                VStack(spacing: 12) {
                    PrimaryButton(
                        title: "Iniciar sesión",
                        isLoading: viewModel.isLoading,
                        isEnabled: viewModel.canSubmit,
                        action: { viewModel.handle(.submit) }
                    )

                    Text("Acceso exclusivo para personal autorizado")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.egxTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
        .onChange(of: viewModel.status) { _, newStatus in
            handleStatusChange(newStatus)
        }
    }

    private func handleStatusChange(_ status: LoginViewModel.Status) {
        switch status {
        case .success(let session):
            Haptics.success()
            onAuthenticated(session)
        case .failure:
            Haptics.error()
        case .idle, .loading:
            break
        }
    }

    private var header: some View {
        VStack(spacing: 14) {
            LogoView(size: 80)
            VStack(spacing: 6) {
                Text("EGX Staff")
                    .font(.system(size: 28, weight: .bold))
                    .tracking(-0.5)
                    .foregroundStyle(Color.egxText)
                Text("Control de acceso")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.egxTextSecondary)
            }
        }
    }

    @ViewBuilder
    private var formCard: some View {
        let deviceBinding = Binding(
            get: { viewModel.deviceName },
            set: { viewModel.handle(.deviceNameChanged($0)) }
        )
        let passwordBinding = Binding(
            get: { viewModel.password },
            set: { viewModel.handle(.passwordChanged($0)) }
        )

        VStack(spacing: 12) {
            GroupedFormView {
                FormFieldRow(
                    label: "Usuario",
                    text: deviceBinding,
                    placeholder: "Tu usuario",
                    keyboardType: .asciiCapable,
                    textContentType: .username
                )
                .focused($focusedField, equals: .device)
                .submitLabel(.next)
                .onSubmit { focusedField = .password }

                FormDivider()

                FormFieldRow(
                    label: "Contraseña",
                    text: passwordBinding,
                    placeholder: "Tu contraseña",
                    isSecure: !viewModel.isPasswordVisible,
                    isToggleable: true,
                    textContentType: .password,
                    returnKeyType: .go,
                    onSubmit: { viewModel.handle(.submit) }
                ) {
                    Button {
                        Haptics.light()
                        viewModel.handle(.togglePasswordVisibility)
                    } label: {
                        Image(systemName: viewModel.isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.egxTextSecondary)
                    }
                    .buttonStyle(.plain)
                }
                .focused($focusedField, equals: .password)
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.egxError)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            HStack {
                Spacer()
                Button("¿Olvidaste tu contraseña?") {
                    Haptics.light()
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.egxBlue)
                .buttonStyle(.plain)
            }
            .padding(.top, 4)
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.errorMessage)
    }
}

#Preview("Login") {
    LoginView(
        viewModel: LoginViewModel(
            loginUseCase: LoginUseCase(repository: PreviewAuthRepository())
        ),
        onAuthenticated: { _ in }
    )
}

private final class PreviewAuthRepository: AuthRepository, @unchecked Sendable {
    func login(credentials: Credentials) async throws -> AuthSession {
        try await Task.sleep(nanoseconds: 500_000_000)
        return AuthSession(
            accessToken: "preview",
            refreshToken: "preview",
            expiresAt: .now.addingTimeInterval(3600),
            user: User(
                id: "p",
                email: credentials.deviceName,
                fullName: "Preview",
                role: "scanner"
            )
        )
    }
    func logout() async throws {}
    func currentSession() async -> AuthSession? { nil }
    func currentAccessToken() async -> String? { nil }
}
