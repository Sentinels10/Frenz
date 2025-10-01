import Foundation

public enum GameRoom: String, CaseIterable, Identifiable, Codable, Equatable, Sendable {
    case party    = "party"
    case redRoom  = "redroom"
    case darkRoom = "darkroom"
    case partner  = "partner"
    case roulette = "roulette"
    case games    = "games"

    public var id: String { rawValue }
}
