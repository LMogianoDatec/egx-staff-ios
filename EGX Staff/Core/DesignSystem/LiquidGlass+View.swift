import SwiftUI

enum LiquidGlassConfig {
    /// Pon en false para forzar el fallback (sin liquid glass) en TODAS las vistas.
    static let enabled = true
}

extension View {
    @ViewBuilder
    func glassSurface<S: Shape>(in shape: S, tint: Color? = nil) -> some View {
        if #available(iOS 26.0, *), LiquidGlassConfig.enabled {
            self.glassEffect(
                tint.map { Glass.regular.tint($0) } ?? .regular,
                in: shape
            )
        } else {
            self
                .background(.ultraThinMaterial, in: shape)
                .background(tint.map { $0.opacity(0.3) } ?? Color.clear, in: shape)
                .overlay(shape.stroke(Color.white.opacity(0.18), lineWidth: 0.5))
        }
    }

    @ViewBuilder
    func glassSurfaceInteractive<S: Shape>(in shape: S, tint: Color? = nil) -> some View {
        if #available(iOS 26.0, *), LiquidGlassConfig.enabled {
            let base: Glass = tint.map { Glass.regular.tint($0).interactive() } ?? Glass.regular.interactive()
            self.glassEffect(base, in: shape)
        } else {
            self
                .background(.ultraThinMaterial, in: shape)
                .background(tint.map { $0.opacity(0.3) } ?? Color.clear, in: shape)
                .overlay(shape.stroke(Color.white.opacity(0.22), lineWidth: 0.5))
        }
    }

    @ViewBuilder
    func clearGlass<S: Shape>(in shape: S) -> some View {
        if #available(iOS 26.0, *), LiquidGlassConfig.enabled {
            self.glassEffect(.clear, in: shape)
        } else {
            self
                .background(.ultraThinMaterial, in: shape)
                .overlay(shape.stroke(Color.white.opacity(0.18), lineWidth: 0.5))
        }
    }

    @ViewBuilder
    func clearGlassInteractive<S: Shape>(in shape: S) -> some View {
        if #available(iOS 26.0, *), LiquidGlassConfig.enabled {
            self.glassEffect(.clear.interactive(), in: shape)
        } else {
            self
                .background(.ultraThinMaterial, in: shape)
                .overlay(shape.stroke(Color.white.opacity(0.22), lineWidth: 0.5))
        }
    }
}
