import SwiftUI

/// Barrido diagonal de luz que se repite — efecto "skeleton" de carga.
/// Se aplica como overlay sobre cualquier vista (ej. el banner mientras
/// baja la imagen) sin alterar su tamaño.
struct Shimmer: ViewModifier {
    /// Color del destello. Blanco translúcido sobre fondos oscuros.
    var highlight: Color = .white.opacity(0.35)
    /// Duración de un ciclo completo del barrido.
    var duration: Double = 1.2

    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geo in
                    let width = geo.size.width
                    LinearGradient(
                        colors: [.clear, highlight, .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: width * 0.6)
                    .offset(x: phase * width * 1.6)
                    // Animación ligada SOLO a `phase` en esta vista. Evita el
                    // `withAnimation` global que filtraba el repeatForever a
                    // vistas hermanas (ej. el botón del toolbar).
                    .animation(.linear(duration: duration).repeatForever(autoreverses: false), value: phase)
                }
                .allowsHitTesting(false)
            }
            // Aísla el barrido: se recorta a `content` y no sangra sobre vistas
            // hermanas (la imagen real que va encima en el ZStack).
            .compositingGroup()
            .onAppear { phase = 1 }
    }
}

extension View {
    /// Aplica un barrido shimmer cuando `active` es `true`.
    @ViewBuilder
    func shimmering(active: Bool = true, highlight: Color = .white.opacity(0.35)) -> some View {
        if active {
            modifier(Shimmer(highlight: highlight))
        } else {
            self
        }
    }
}
