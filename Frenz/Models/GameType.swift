import Foundation

public enum GameType: String, CaseIterable, Identifiable, Codable, Equatable, Sendable {
    case truthOrDare     = "truthordare"     // Obbligo o Verità
    case wouldYouRather  = "wyr"             // Preferiresti
    case neverHaveIEver  = "nhie"            // Non ho mai
    case priceGame       = "pricegame"       // Tutto ha un prezzo
    case miniChallenges  = "minichallenges"  // Timer / mini-sfide

    public var id: String { rawValue }
}
