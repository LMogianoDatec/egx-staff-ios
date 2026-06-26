import SwiftUI

struct ScannerHeaderView: View {
    let onBack: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            glassIconButton(systemName: "chevron.left") {
                onBack()
            }

            Spacer()

            VStack(spacing: 2) {
                Text("Escanear QR")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                Text("Apunta al código QR")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.75))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .clearGlass(in: Capsule())

            Spacer()

            // Espacio invisible para mantener el título centrado
            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func glassIconButton(
        systemName: String,
        foreground: Color = .white,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            Haptics.light()
            action()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(foreground)
                .frame(width: 44, height: 44)
                .contentShape(Circle())
                .clearGlassInteractive(in: Circle())
        }
        .buttonStyle(.plain)
    }
}
