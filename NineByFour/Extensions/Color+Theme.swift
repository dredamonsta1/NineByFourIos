import SwiftUI

extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }

    enum Theme {
        // Backgrounds
        static let bgBase = Color(hex: 0x0A1420)
        static let bgSurface = Color(hex: 0x0F1A2A)
        static let bgCard = Color(hex: 0x142030)
        static let bgCardElevated = Color(hex: 0x1E3450)
        static let bgInput = Color(hex: 0x080F1A)

        // Accent
        static let accent = Color(hex: 0x0077B6)
        static let accentLight = Color(hex: 0x00B4D8)

        // Text
        static let textBright = Color.white
        static let textPrimary = Color(hex: 0xE0E6ED)
        static let textSecondary = Color(hex: 0x8899AA)

        // Semantic
        static let hot = Color(hex: 0xFF4D4D)
        static let success = Color(hex: 0x00E676)
        static let error = Color(hex: 0xFF6B6B)

        // Border
        static let borderDefault = Color(hex: 0x1E3450)
    }
}
