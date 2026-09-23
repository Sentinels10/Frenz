import Foundation

/// Risolve i segnaposto delle carte senza alterare i testi salvati nei JSON.
enum ActionTextRenderer {
    private static let placeholders = try! NSRegularExpression(
        pattern: #"(?i)\{[^{}\n]{1,40}\}|\[[^\[\]\n]{1,40}\]|\((?:player[a-z0-9_]*|opponent)\)|(?<!\[)\bplayer\]|\bplayer(?:[abc]|[0-9]+)\b"#
    )

    static func render(
        _ text: String,
        mainPlayer: String,
        otherPlayers: [String],
        includeMainForAnonymousPlayers: Bool,
        language: String,
        penalty: Int? = nil,
        count: Int? = nil
    ) -> String {
        let anonymousPlayers = includeMainForAnonymousPlayers
            ? [mainPlayer] + otherPlayers
            : otherPlayers + [mainPlayer]
        let secondaryPlayer = otherPlayers.first ?? mainPlayer
        var anonymousIndex = 0

        func nextAnonymousPlayer() -> String {
            guard !anonymousPlayers.isEmpty else { return mainPlayer }
            defer { anonymousIndex += 1 }
            return anonymousPlayers[anonymousIndex % anonymousPlayers.count]
        }

        let matches = placeholders.matches(in: text, range: NSRange(text.startIndex..., in: text))
        var result = ""
        var cursor = text.startIndex
        for match in matches {
            guard let range = Range(match.range, in: text) else { continue }
            result += text[cursor..<range.lowerBound]
            let token = String(text[range])
            let originalKey = token.trimmingCharacters(in: CharacterSet(charactersIn: "{}[]()"))
            let key = originalKey.lowercased()

            let replacement: String
            switch key {
            case "player", "jugador", "joueur", "le joueur", "nome giocatore",
                 "player name", "nombre del jugador", "nom du joueur":
                // {player} indica sempre il giocatore del turno; [player] indica
                // invece una persona scelta per la carta.
                replacement = token.hasPrefix("{") ? mainPlayer : nextAnonymousPlayer()
            case "player's":
                replacement = nextAnonymousPlayer() + "'s"
            case "playera", "tuo nome":
                replacement = mainPlayer
            case "playerb", "player2", "opponent":
                replacement = secondaryPlayer
            case "count":
                replacement = count.map(String.init) ?? token
            case "penalty":
                replacement = penalty.map(String.init) ?? token
            case "regola", "regla", "rule", "régler":
                switch language {
                case "it": replacement = "dire la parola sì"
                case "es": replacement = "decir la palabra sí"
                case "fr": replacement = "dire le mot oui"
                default: replacement = "say the word yes"
                }
            default:
                replacement = key.hasPrefix("player") ? nextAnonymousPlayer() : token
            }

            let shouldUppercasePlayer = key.hasPrefix("player") &&
                originalKey == originalKey.uppercased()
            result += shouldUppercasePlayer ? replacement.uppercased() : replacement
            cursor = range.upperBound
        }
        result += text[cursor...]
        return result
    }
}
