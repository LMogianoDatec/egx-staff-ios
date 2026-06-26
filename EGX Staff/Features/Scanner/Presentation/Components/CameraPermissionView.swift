import SwiftUI

struct CameraPermissionView: View {
    let isDenied: Bool
    let onRequest: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        ZStack {
            Color.egxBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 36) {
                        header
                        bullets
                        Text("Puedes cambiar este permiso en Ajustes en cualquier momento.")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.egxTextSecondary)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 64)
                    .padding(.bottom, 32)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                PrimaryButton(
                    title: isDenied ? "Abrir Ajustes" : "Continuar",
                    action: isDenied ? onOpenSettings : onRequest
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 20) {
            iconBadge(systemName: "camera.fill")

            Text("Activa la cámara para\nescanear códigos QR")
                .font(.system(size: 30, weight: .bold))
                .tracking(-0.5)
                .foregroundStyle(Color.egxText)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var bullets: some View {
        VStack(alignment: .leading, spacing: 26) {
            bullet(
                icon: "qrcode.viewfinder",
                title: "Validar acceso de invitados",
                description: "Escanea el QR personal generado desde EGX One."
            )
            bullet(
                icon: "bolt.fill",
                title: "Verificación instantánea",
                description: "Confirma el ingreso en milisegundos, sin contacto."
            )
            bullet(
                icon: "lock.shield.fill",
                title: "Privacidad protegida",
                description: "Las imágenes no se guardan, solo se procesa el QR."
            )
        }
    }

    private func iconBadge(systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 30, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 68, height: 68)
            .background(Color.egxBlue, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color.egxBlue.opacity(0.3), radius: 16, x: 0, y: 8)
    }

    private func bullet(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 18) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Color.egxBlue)
                .frame(width: 40, height: 40, alignment: .center)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.egxText)
                Text(description)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.egxTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview("Not Determined") {
    CameraPermissionView(
        isDenied: false,
        onRequest: {},
        onOpenSettings: {}
    )
}

#Preview("Denied") {
    CameraPermissionView(
        isDenied: true,
        onRequest: {},
        onOpenSettings: {}
    )
}
