import SwiftUI

/// Punto "en vivo": núcleo sólido + anillo que late hacia afuera y se desvanece.
struct PulsingDot: View {
    var color: Color = .egxSuccess
    var size: CGFloat = 9

    @State private var animating = false

    var body: some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: size, height: size)
                .scaleEffect(animating ? 2.4 : 1)
                .opacity(animating ? 0 : 0.7)
            Circle()
                .fill(color)
                .frame(width: size, height: size)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.4).repeatForever(autoreverses: false)) {
                animating = true
            }
        }
    }
}
