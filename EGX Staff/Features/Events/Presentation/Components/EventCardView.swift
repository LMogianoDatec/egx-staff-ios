import SwiftUI

/// Tarjeta de evento como un único componente: banner con imagen + badge/título
/// superpuestos arriba, sección blanca con descripción y botón "Ir" abajo.
/// Todo recortado a un solo `RoundedRectangle`.
struct EventCardView: View {
    let event: Event
    let onOpen: () -> Void

    private let bannerHeight: CGFloat = 220
    private let corner: CGFloat = 26

    var body: some View {
        VStack(spacing: 0) {
            banner
            infoSection
        }
        .background(Color.egxGroupedBG)
        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        .shadow(color: .black.opacity(0.10), radius: 16, x: 0, y: 8)
        .contentShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        .onTapGesture {
            Haptics.light()
            onOpen()
        }
    }

    // MARK: - Banner

    private var banner: some View {
        ZStack(alignment: .bottomLeading) {
            background
            legibilityGradient
            VStack(alignment: .leading, spacing: 4) {
                Text(event.badgeText)
                    .font(.system(size: 12, weight: .bold))
                    .tracking(0.8)
                    .foregroundStyle(.white.opacity(0.9))
                Text(event.name)
                    .font(.system(size: 26, weight: .bold))
                    .tracking(-0.3)
                    .foregroundStyle(.white)
                    .lineLimit(2)
            }
            .shadow(color: .black.opacity(0.35), radius: 6, x: 0, y: 2)
            .padding(20)
        }
        .frame(height: bannerHeight)
        .frame(maxWidth: .infinity)
        .clipped()
    }

    /// `Color.clear` fija el tamaño del banner; la imagen va en `overlay` con
    /// `scaledToFill` + `clipped`, así su tamaño natural no expande la tarjeta.
    private var background: some View {
        Color.clear
            .overlay {
                if let url = event.logoURL {
                    CachedAsyncImage(url: url) { phase in
                        ZStack {
                            // Base/skeleton: siempre debajo, nunca tapa la imagen.
                            fallbackGradient
                                .shimmering(active: phase.isLoading)
                            // La imagen real entra por encima con fade.
                            if case .success(let image) = phase {
                                image.resizable().scaledToFill()
                                    .transition(.opacity)
                            }
                        }
                    }
                } else {
                    fallbackGradient
                }
            }
            .clipped()
    }

    /// Oscurece el tercio inferior para que el texto blanco siempre se lea.
    private var legibilityGradient: some View {
        LinearGradient(
            colors: [.clear, .black.opacity(0.55)],
            startPoint: .center,
            endPoint: .bottom
        )
    }

    /// Gradiente de relleno cuando no hay imagen o mientras carga.
    /// Determinista por `id` para que cada evento mantenga su color.
    private var fallbackGradient: LinearGradient {
        let palettes: [[Color]] = [
            [Color(hex: "#F5A623"), Color(hex: "#B5179E")],
            [Color(hex: "#1565FF"), Color(hex: "#0A1F66")],
            [Color(hex: "#16BFA6"), Color(hex: "#0A4FE0")],
            [Color(hex: "#FF6B6B"), Color(hex: "#6A0572")]
        ]
        let index = abs(event.id.hashValue) % palettes.count
        return LinearGradient(
            colors: palettes[index],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Info section

    private var infoSection: some View {
        Text(event.summary)
            .font(.system(size: 15))
            .foregroundStyle(Color.egxTextSecondary)
            .lineLimit(2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
    }
}

#Preview {
    let formatter = ISO8601DateFormatter()
    return ScrollView {
        VStack(spacing: 20) {
            EventCardView(
                event: Event(
                    id: "1",
                    name: "Breakfast & Security",
                    summary: "Te invitamos a un desayuno donde exploraremos las últimas innovaciones…",
                    logoURL: nil,
                    status: .inProgress,
                    assignedAt: formatter.date(from: "2026-06-02T07:53:47Z")
                ),
                onOpen: {}
            )
            EventCardView(
                event: Event(
                    id: "2",
                    name: "Tech Summit 2025",
                    summary: "Conferencias y demos sobre las tendencias tecnológicas del año.",
                    logoURL: nil,
                    status: .assigned,
                    assignedAt: formatter.date(from: "2025-05-27T09:00:00Z")
                ),
                onOpen: {}
            )
        }
        .padding()
    }
    .background(Color.egxBackground)
}
