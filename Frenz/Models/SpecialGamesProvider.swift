import Foundation

enum SpecialGameID: String, CaseIterable {
    case truthOrDare, wouldYouRather, questoOQuello, timerChallenge
    case tuttoHaUnPrezzo, tuttiQuelliChe, penitenzaRandom
    case nonHoMai, chiEPiuProbabile, penitenzeGruppo, happyHour
    // extra
    case infamata, pointFinger, chatDetective, newRule, oneVsOne
}

struct SpecialGamesProvider {
    static let common: [String] = [
        "truthOrDare","wouldYouRather","questoOQuello","timerChallenge",
        "tuttoHaUnPrezzo","tuttiQuelliChe","penitenzaRandom",
        "nonHoMai","chiEPiuProbabile","penitenzeGruppo","happyHour"
    ]

    static let byRoom: [GameRoom: [String]] = [
        .redRoom:  ["infamata"],
        .darkRoom: ["pointFinger"],
        .party:    ["chatDetective","newRule"],
        .partner:  ["oneVsOne"],
        .roulette: ["infamata","pointFinger","chatDetective","newRule","oneVsOne"],
        .games:    []
    ]

    static func allFor(room: GameRoom) -> [String] {
        common + (byRoom[room] ?? [])
    }

    static func mapToGameType(_ id: String) -> GameType? {
        switch id {
        case "truthOrDare":     return .truthOrDare
        case "wouldYouRather":  return .wouldYouRather
        case "nonHoMai":        return .neverHaveIEver
        case "tuttoHaUnPrezzo": return .priceGame
        case "timerChallenge":  return .miniChallenges
        default:                return nil
        }
    }
}
