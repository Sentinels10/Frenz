import SwiftUI

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self = Color(red: r, green: g, blue: b).opacity(alpha)
    }
    
    init(hex: String, alpha: Double = 1.0) {
        let cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
            .lowercased()
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        self.init(hex: UInt(value), alpha: alpha)
    }
}

// Colori condivisi dell’arcobaleno Frenz (corretti e normalizzati)
enum Palette {
    static let rainbow: [Color] = [
        Color(hex: "ff1919"), // rosso
        Color(hex: "ff58ef"), // rosa
        Color(hex: "ffe252"), // giallo
        Color(hex: "57e5ff")  // azzurro (corretto)
    ]
}

// Comodità per costruire gradienti coerenti
extension LinearGradient {
    static func frenzRainbow(start: UnitPoint = .leading,
                             end: UnitPoint = .trailing) -> LinearGradient {
        LinearGradient(colors: Palette.rainbow, startPoint: start, endPoint: end)
    }
}
