import SwiftUI
import AVFoundation
import UIKit

/// Bloquea su contenido hasta que el permiso de cámara esté concedido.
/// Primera pantalla post-login: pedimos cámara antes de mostrar Eventos.
struct CameraPermissionGate<Content: View>: View {
    @ViewBuilder let content: () -> Content

    @State private var status: Status
    @Environment(\.scenePhase) private var scenePhase

    private enum Status { case checking, granted, notDetermined, denied }

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
        // Estado síncrono en el primer frame: evita el flash `.checking` y el
        // slide-in del toolbar cuando el permiso ya está concedido.
        _status = State(initialValue: Self.status(for: AVCaptureDevice.authorizationStatus(for: .video)))
    }

    var body: some View {
        Group {
            switch status {
            case .checking:
                Color.egxBackground.ignoresSafeArea()
            case .granted:
                content()
            case .notDetermined, .denied:
                CameraPermissionView(
                    isDenied: status == .denied,
                    onRequest: { Task { await request() } },
                    onOpenSettings: openSettings
                )
            }
        }
        .task { refresh() }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active { refresh() }
        }
    }

    private func refresh() {
        status = Self.status(for: AVCaptureDevice.authorizationStatus(for: .video))
    }

    private static func status(for auth: AVAuthorizationStatus) -> Status {
        switch auth {
        case .authorized:          return .granted
        case .notDetermined:       return .notDetermined
        case .denied, .restricted: return .denied
        @unknown default:          return .denied
        }
    }

    private func request() async {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        status = granted ? .granted : .denied
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
