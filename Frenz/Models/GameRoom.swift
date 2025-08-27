import Foundation

public enum GameRoom: String, CaseIterable, Identifiable, Codable, Equatable {
    case party = "party"
    case redRoom = "redroom"
    case darkRoom = "darkroom"
    case partner = "partner"
    case roulette = "roulette"
    case games = "games"          // <— NEW

    public var id: String { rawValue }
}
