import SwiftUI

/// Colori dei minigiochi durante la partita, indipendenti dalla stanza.
enum SpecialGamePalette {
    static func colors(for id: String) -> [Color]? {
        guard let game = SpecialGameID(rawValue: id) else { return nil }
        let shades: (UInt, UInt)
        switch game {
        case .truthOrDare:      return nil
        case .chatDetective:     shades = (0x00B654, 0x00934C)
        case .tuttoHaUnPrezzo:  shades = (0xFEBB00, 0xF89B00)
        case .penitenzeGruppo:  shades = (0xFC4145, 0xEE283F)
        case .questoOQuello:    shades = (0x0099FC, 0x007BFC)
        case .newRule:          shades = (0xFE8500, 0xFD5800)
        case .wouldYouRather:   shades = (0x1B6BFC, 0x035AF8)
        case .happyHour:        shades = (0x8FE100, 0x6AC600)
        case .nonHoMai:         shades = (0xF734A4, 0xE52B90)
        case .chiEPiuProbabile: shades = (0xFC778D, 0xFB5680)
        case .tuttiQuelliChe:   shades = (0x00DFDE, 0x00C9D0)

        case .penitenzaRandom:  shades = (0x49627F, 0x233A59)
        case .infamata:         shades = (0xAD295B, 0x6A124C)
        case .pointFinger:      shades = (0x8F69E5, 0x5132AF)
        case .oneVsOne:         shades = (0x168E83, 0x005F62)
        case .timerChallenge:   shades = (0x897899, 0x4F416F)
        }

        return [Color(hex: shades.0), Color(hex: shades.1)]
    }

    static func colors(for game: GameType) -> [Color]? {
        let id: SpecialGameID
        switch game {
        case .truthOrDare:    return nil
        case .wouldYouRather: id = .wouldYouRather
        case .neverHaveIEver: id = .nonHoMai
        case .priceGame:      id = .tuttoHaUnPrezzo
        case .miniChallenges: id = .timerChallenge
        }
        return colors(for: id.rawValue)
    }
}
