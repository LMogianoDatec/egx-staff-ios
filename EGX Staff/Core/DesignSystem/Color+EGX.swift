import SwiftUI
import UIKit

extension Color {
    /// Crea un color dinámico que cambia entre light/dark según el sistema.
    init(light: Color, dark: Color) {
        self = Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}

extension Color {
    // MARK: - Brand (constantes, no cambian con el modo)
    static let egxBlue     = Color(hex: "#0A63FF")
    static let egxBlueDeep = Color(hex: "#0A4FE0")
    static let egxSuccess  = Color(hex: "#34C759")
    static let egxError    = Color(hex: "#FF3B30")

    // MARK: - Surfaces
    /// Fondo principal de la app.
    static let egxBackground = Color(
        light: Color(hex: "#F4F5F7"),
        dark:  Color(hex: "#000A0F")
    )

    /// Fondo de tarjetas agrupadas (form cards).
    static let egxGroupedBG = Color(
        light: .white,
        dark:  Color(hex: "#1C1C1E")
    )

    // MARK: - Text
    /// Texto principal.
    static let egxText = Color(
        light: Color(hex: "#111114"),
        dark:  Color(hex: "#E9EAF0")
    )

    /// Texto secundario (subtítulos, captions).
    static let egxTextSecondary = Color(
        light: Color(hex: "#6B7280"),
        dark:  Color.white.opacity(0.6)
    )

    /// Texto terciario (hints muy sutiles).
    static let egxTextTertiary = Color(
        light: Color(hex: "#9CA3AF"),
        dark:  Color.white.opacity(0.45)
    )

    /// Label de campos de formulario.
    static let egxFormLabel = Color(
        light: Color(hex: "#4B5563"),
        dark:  Color.white.opacity(0.85)
    )

    // MARK: - Dividers
    static let egxFormDivider = Color(
        light: Color.black.opacity(0.08),
        dark:  Color.white.opacity(0.08)
    )
}
