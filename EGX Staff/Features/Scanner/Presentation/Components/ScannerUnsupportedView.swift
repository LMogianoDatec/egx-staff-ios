import SwiftUI

/// Pantalla mostrada cuando el dispositivo (o el simulador) no soporta
/// la detección de códigos QR. Evita arrancar la cámara y crashear.
struct ScannerUnsupportedView: View {
    let onBack: () -> Void

    var body: some View {
        ZStack {
            Color.egxBackground.ignoresSafeArea()

            VStack(spacing: 16) {
                Image("GeniousSad")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)

                Text("Escaneo no disponible")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.egxText)

                Text("Lo sentimos, este dispositivo no puede leer códigos QR. Usa un equipo con cámara compatible.")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.egxTextSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 32)
            }
            .padding(.bottom, 40)

            VStack {
                HStack {
                    Button {
                        Haptics.light()
                        onBack()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.egxText)
                            .frame(width: 44, height: 44)
                            .contentShape(Circle())
                            .glassSurfaceInteractive(in: Circle())
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
    }
}

#Preview {
    ScannerUnsupportedView(onBack: {})
}
