import SwiftUI

struct AppRootView: View {
    @State private var appViewModel: AppViewModel?
    @State private var router = AppRouter()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            Color.egxBackground.ignoresSafeArea()

            if let appViewModel {
                switch appViewModel.phase {
                case .launching:
                    LaunchView()
                case .unauthenticated:
                    LoginView(onAuthenticated: appViewModel.didAuthenticate)
                case .authenticated:
                    CameraPermissionGate {
                        EventsView(
                            onSignOut: { Task { await appViewModel.signOut() } }
                        )
                        .environment(router)
                    }
                }
            } else {
                LaunchView()
            }
        }
        .task {
            if appViewModel == nil {
                let vm = AppViewModel(loadSession: sl(), logout: sl())
                appViewModel = vm
                await vm.bootstrap()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await appViewModel?.revalidateSession() }
            }
        }
        .alert("Sesión expirada", isPresented: Binding(
            get: { appViewModel?.showingSessionExpiredAlert ?? false },
            set: { _ in appViewModel?.confirmSessionExpiredAlert() }
        )) {
            Button("Iniciar sesión") { appViewModel?.confirmSessionExpiredAlert() }
        } message: {
            Text("Tu acceso expiró. Inicia sesión nuevamente para continuar.")
        }
    }
}

private struct LaunchView: View {
    var body: some View {
        VStack(spacing: 18) {
            LogoView(size: 72)
            Text("EGX Staff")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.egxText)
        }
    }
}
