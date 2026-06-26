import SwiftUI

struct QRTargetFrameView: View {
    /// Controla si el láser anima. Cuando es `false`, el láser desaparece y la
    /// animación se detiene — ahorra batería/GPU mientras se muestra el resultado.
    let isAnimating: Bool

    @State private var laserOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height) * 0.68

            ZStack {
                // 1) Cutout overlay — un solo Path con eoFill (sin offscreen pass)
                CutoutOverlayShape(cutoutSize: side, cornerRadius: 32)
                    .fill(Color.black.opacity(0.55), style: FillStyle(eoFill: true))

                // 2) Corner brackets — Liquid Glass aplicado directamente a la shape stroked,
                //    así Liquid Glass samplea el fondo bajo cada bracket en vez del cuadrado entero.
                bracketsView(side: side)
                    .opacity(0.85)

                // 4) Láser — solo se renderiza si está animando
                if isAnimating {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, .white.opacity(0.9), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: side - 40, height: 2)
                        .offset(y: laserOffset)
                        .mask(
                            RoundedRectangle(cornerRadius: 32, style: .continuous)
                                .frame(width: side, height: side)
                        )
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .onAppear {
                if isAnimating { startLaserAnimation(side: side) }
            }
            .onChange(of: isAnimating) { _, newValue in
                if newValue {
                    startLaserAnimation(side: side)
                } else {
                    laserOffset = 0
                }
            }
        }
        .ignoresSafeArea()
    }

    private func bracketsView(side: CGFloat) -> some View {
        CornerBracketsShape(cornerRadius: 32, bracketLength: 32)
            .stroke(Color.white.opacity(0.8), style: StrokeStyle(lineWidth: 4, lineCap: .round))
            .frame(width: side, height: side)
    }

    private func startLaserAnimation(side: CGFloat) {
        let maxOffset = (side / 2) - 24
        laserOffset = -maxOffset
        withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
            laserOffset = maxOffset
        }
    }
}

/// Overlay oscuro con un cutout rounded en el centro.
/// Usa una sola Path con eoFill — evita el offscreen rendering pass de `.mask`.
private struct CutoutOverlayShape: Shape {
    let cutoutSize: CGFloat
    let cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(rect)

        let cutoutRect = CGRect(
            x: (rect.width - cutoutSize) / 2,
            y: (rect.height - cutoutSize) / 2,
            width: cutoutSize,
            height: cutoutSize
        )
        path.addPath(
            Path(
                roundedRect: cutoutRect,
                cornerSize: CGSize(width: cornerRadius, height: cornerRadius)
            )
        )
        return path
    }
}

/// 4 brackets en forma de "L" en las esquinas de un rectángulo redondeado.
private struct CornerBracketsShape: Shape {
    let cornerRadius: CGFloat
    let bracketLength: CGFloat
    var inset: CGFloat = 0

    func path(in originalRect: CGRect) -> Path {
        let rect = originalRect.insetBy(dx: inset, dy: inset)
        var path = Path()
        let r = cornerRadius
        let L = bracketLength

        // Top-left
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + r + L))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
        path.addArc(
            center: CGPoint(x: rect.minX + r, y: rect.minY + r),
            radius: r,
            startAngle: .degrees(180),
            endAngle: .degrees(270),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.minX + r + L, y: rect.minY))

        // Top-right
        path.move(to: CGPoint(x: rect.maxX - r - L, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        path.addArc(
            center: CGPoint(x: rect.maxX - r, y: rect.minY + r),
            radius: r,
            startAngle: .degrees(270),
            endAngle: .degrees(0),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + r + L))

        // Bottom-right
        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - r - L))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
        path.addArc(
            center: CGPoint(x: rect.maxX - r, y: rect.maxY - r),
            radius: r,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.maxX - r - L, y: rect.maxY))

        // Bottom-left
        path.move(to: CGPoint(x: rect.minX + r + L, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
        path.addArc(
            center: CGPoint(x: rect.minX + r, y: rect.maxY - r),
            radius: r,
            startAngle: .degrees(90),
            endAngle: .degrees(180),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - r - L))

        return path
    }
}
