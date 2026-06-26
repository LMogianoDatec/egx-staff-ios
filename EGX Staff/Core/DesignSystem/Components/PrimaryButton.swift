import SwiftUI

struct PrimaryButton: View {
    let title: String
    var isLoading: Bool = false
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        if #available(iOS 26.0, *), LiquidGlassConfig.enabled {
            modernButton
        } else {
            legacyButton
        }
    }

    private var resolvedTint: Color {
        // Durante la carga el botón se pone gris para diferenciarlo del estado
        // activo (azul). El ProgressView blanco contrasta sobre el gris.
        if isLoading { return Color(uiColor: .systemGray2) }
        return isEnabled ? Color.egxBlue : Color(uiColor: .systemGray2)
    }

    /// El Text siempre define el tamaño del botón. El ProgressView se dibuja
    /// como overlay encima — no afecta el sizing del label.
    private var label: some View {
        Text(title)
            .font(.system(size: 17, weight: .semibold))
            .tracking(-0.2)
            .opacity(isLoading ? 0 : 1)
            .frame(maxWidth: .infinity)
            .overlay {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(Color(uiColor: .systemGray))
                        .scaleEffect(0.80)
                }
            }
    }

    @available(iOS 26.0, *)
    private var modernButton: some View {
        Button {
            Haptics.light()
            action()
        } label: {
            label
        }
        .buttonStyle(.glassProminent)
        .controlSize(.large)
        .tint(resolvedTint)
        .disabled(!isEnabled || isLoading)
    }

    private var legacyButton: some View {
        Button {
            Haptics.light()
            action()
        } label: {
            label
                .foregroundStyle(isEnabled ? Color.white : Color(uiColor: .secondaryLabel))
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(resolvedTint)
                )
                .shadow(
                    color: isEnabled ? Color.egxBlue.opacity(0.25) : .clear,
                    radius: 18,
                    x: 0,
                    y: 10
                )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isLoading)
    }
}

#Preview {
    VStack(spacing: 16) {
        PrimaryButton(title: "Iniciar sesión") {}
        PrimaryButton(title: "Cargando", isLoading: true) {}
        PrimaryButton(title: "Deshabilitado", isEnabled: false) {}
    }
    .padding()
    .background(Color.egxBackground)
}
