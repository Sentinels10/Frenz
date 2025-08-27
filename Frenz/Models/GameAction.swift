import Foundation

public struct GameAction: Identifiable, Codable, Equatable {
    public var id: UUID = UUID()
    public let text: String
    public let room: String?          // "party", "redroom", "darkroom", "partner", "roulette" (se presente nel JSON)
    public let game: String?          // usato solo quando arrivi da .games (es. "truthordare", "wyr", ecc.)
    public let penalty: Int?          // opzionale
    public let timerSeconds: Int?     // opzionale (per mini-sfide a tempo)

    // Decoder tollerante a chiavi diverse
    enum CodingKeys: String, CodingKey {
        case text, room, game, penalty
        case timerSeconds = "timer_seconds"
    }
}
