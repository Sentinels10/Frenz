import SwiftUI
import Combine

enum GameState: Equatable {
    case onboardingIntro
    case onboardingWho
    case onboardingMood

    case languageSelection
    case playerSetup
    case roomSelection
    case gameSelection
    case playing
    case gameOver
    case paywall
}

final class GameViewModel: ObservableObject,
    LanguageSelectionRouting, PlayerSetupRouting,
    RoomSelectionRouting, GameSelectionRouting,
    PlayingRouting, PaywallRouting, OnboardingRouting
{
    // ============================================================
    // MARK: Base / Persistenza
    // ============================================================
    @Published var gameState: GameState = .playerSetup

    private let onboardingKey = "onboarding.seen"

    @Published var language: String = UserDefaults.standard.string(forKey: "app.language")
        ?? Locale.current.language.languageCode?.identifier ?? "it" {
        didSet { UserDefaults.standard.set(language, forKey: "app.language") }
    }

    // ============================================================
    // MARK: Player setup
    // ============================================================
    @Published var inputPlayers: [PlayerInput] = [PlayerInput(id: 1, name: "")]

    // Giocatori attivi
    @Published private(set) var players: [String] = []
    private var playerOrder: [Int] = []
    private var playerCursor: Int = 0

    // PlayerB per azione
    private var secondaryByIndex: [Int: Int] = [:]
    private var currentMainPlayerIndex: Int? {
        guard !players.isEmpty, !playerOrder.isEmpty else { return nil }
        return playerOrder[playerCursor % playerOrder.count]
    }
    var currentSecondaryPlayerName: String? {
        guard let sec = secondaryByIndex[currentIndex],
              players.indices.contains(sec) else { return nil }
        return players[sec]
    }

    // ============================================================
    // MARK: Room/Game correnti
    // ============================================================
    @Published var selectedRoom: GameRoom? = nil
    @Published var selectedGame: GameType? = nil
    @Published var currentRoom: GameRoom? = nil
    @Published var currentGame: GameType? = nil

    // Deck
    @Published private var actions: [GameAction] = []
    @Published private(set) var isLoadingActions: Bool = false
    @Published private var currentIndex: Int = 0

    // Limiti e mapping
    let MAX_ACTIONS_PER_MATCH = 50
    private let MIN_SPACING_BETWEEN_SPECIAL = 3

    private var commonSpecialGames: [String] {
        ["truthOrDare", "wouldYouRather", "questoOQuello", "timerChallenge"]
    }
    private var roomSpecificSpecialGames: [GameRoom: [String]] {
        [
            .redRoom:    ["infamata","tuttoHaUnPrezzo","tuttiQuelliChe","penitenzaRandom"],
            .darkRoom:   ["pointFinger","nonHoMai","chiEPiuProbabile"],
            .party:      ["chatDetective","penitenzeGruppo","happyHour","newRule"],
            .partner:    ["oneVsOne"],
            .roulette:   [
                "infamata","pointFinger","chatDetective","tuttoHaUnPrezzo","tuttiQuelliChe",
                "penitenzeGruppo","nonHoMai","chiEPiuProbabile","happyHour","oneVsOne","penitenzaRandom","newRule"
            ],
            .games: []
        ]
    }

    // ============================================================
    // MARK: Init (niente Welcome)
    // ============================================================
    init() {
        if !["it","en","fr","de"].contains(language) { language = "it" }
        if !UserDefaults.standard.bool(forKey: onboardingKey) {
            gameState = .onboardingIntro
        } else {
            gameState = .playerSetup
        }
    }

    // ============================================================
    // MARK: LanguageSelectionRouting
    // ============================================================
    var availableLanguages: [AppLanguage] {
        [.init(id: "it", name: "Italiano", flag: "🇮🇹"),
         .init(id: "en", name: "English",  flag: "🇬🇧"),
         .init(id: "fr", name: "Français", flag: "🇫🇷"),
         .init(id: "de", name: "Deutsch",  flag: "🇩🇪")]
    }
    var title: String      { String(localized: "languageSelectTitle", locale: .init(identifier: language)) }
    var closeTitle: String { String(localized: "close",               locale: .init(identifier: language)) }
    func selectLanguage(_ code: String) { language = code }
    func closeLanguageSelector() { gameState = .playerSetup } // ⬅️ torna al player setup

    // ============================================================
    // MARK: PlayerSetupRouting (con gear → lingua)
    // ============================================================
    var playerInputPlaceholder: String { String(localized: "playerInputPlaceholder", locale: .init(identifier: language)) }
    var addPlayerLabel: String        { String(localized: "addPlayerLabel",        locale: .init(identifier: language)) }
    var backButtonTitle: String       { String(localized: "backButton",            locale: .init(identifier: language)) }

    func addPlayerInput() {
        guard inputPlayers.count < 15 else { return }
        let nextId = (inputPlayers.map(\.id).max() ?? 0) + 1
        inputPlayers.append(.init(id: nextId, name: ""))
    }
    func updatePlayerName(id: Int, name: String) {
        guard let idx = inputPlayers.firstIndex(where: { $0.id == id }) else { return }
        inputPlayers[idx].name = name
    }
    func removePlayerInput(id: Int) {
        guard inputPlayers.count > 1 else { return }
        inputPlayers.removeAll { $0.id == id }
    }
    func startGame() {
        let clean = inputPlayers.map { $0.name.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        guard clean.count >= 2 else { return }
        players = clean
        reseedPlayerOrder()
        gameState = .roomSelection
    }
    func openLanguageSelector() { gameState = .languageSelection } // ⬅️ gear in alto a destra

    // ============================================================
    // MARK: RoomSelectionRouting
    // ============================================================
    var availableRooms: [GameRoom] { [.party, .darkRoom, .partner, .roulette, .redRoom, .games] }
    var roomSelectionTitle: String { String(localized: "roomSelectionTitle", locale: .init(identifier: language)) }
    var continueTitle: String      { String(localized: "continue",           locale: .init(identifier: language)) }

    func displayName(for room: GameRoom) -> String {
        switch room {
        case .party:    return String(localized: "room.party.title",    locale: .init(identifier: language))
        case .redRoom:  return String(localized: "room.red.title",      locale: .init(identifier: language))
        case .darkRoom: return String(localized: "room.dark.title",     locale: .init(identifier: language))
        case .partner:  return String(localized: "room.partner.title",  locale: .init(identifier: language))
        case .roulette: return String(localized: "room.roulette.title", locale: .init(identifier: language))
        case .games:    return String(localized: "room.games.title",    locale: .init(identifier: language))
        }
    }
    func displaySubtitle(for room: GameRoom) -> String {
        switch room {
        case .party:    return String(localized: "room.party.subtitle",    locale: .init(identifier: language))
        case .redRoom:  return String(localized: "room.red.subtitle",      locale: .init(identifier: language))
        case .darkRoom: return String(localized: "room.dark.subtitle",     locale: .init(identifier: language))
        case .partner:  return String(localized: "room.partner.subtitle",  locale: .init(identifier: language))
        case .roulette: return String(localized: "room.roulette.subtitle", locale: .init(identifier: language))
        case .games:    return String(localized: "room.games.subtitle",    locale: .init(identifier: language))
        }
    }
    func select(room: GameRoom) {
        selectedRoom = room
        enterGameSelection()
    }
    func openSettings() { }
    func openPaywall() { gameState = .paywall }
    func addPlayers() { gameState = .playerSetup }
    func isRoomLocked(_ room: GameRoom) -> Bool { room == .darkRoom }
    func showsCrown(_ room: GameRoom) -> Bool { room == .darkRoom || room == .partner || room == .roulette || room == .redRoom }
    func progressForParty() -> (current: Int, total: Int)? { (2, 5) }
    func goBackToPlayerSetup() { gameState = .playerSetup }

    func enterGameSelection() {
        guard let selectedRoom else { return }
        currentRoom = selectedRoom
        currentGame = nil
        resetDeck(with: [])
        reseedPlayerOrder()
        if selectedRoom == .games {
            selectedGame = nil
            gameState = .gameSelection
        } else {
            gameState = .playing
        }
    }

    // ============================================================
    // MARK: GameSelectionRouting
    // ============================================================
    var availableGames: [GameType] { [.truthOrDare, .wouldYouRather, .neverHaveIEver, .priceGame, .miniChallenges] }
    var gameSelectionTitle: String { String(localized: "gameSelectionTitle", locale: .init(identifier: language)) }
    var startMatchTitle: String    { String(localized: "startMatch",         locale: .init(identifier: language)) }

    func displayName(for game: GameType) -> String {
        switch game {
        case .truthOrDare:    return String(localized: "game.truthOrDare.title",   locale: .init(identifier: language))
        case .wouldYouRather: return String(localized: "game.wyr.title",           locale: .init(identifier: language))
        case .neverHaveIEver: return String(localized: "game.nhie.title",          locale: .init(identifier: language))
        case .priceGame:      return String(localized: "game.price.title",         locale: .init(identifier: language))
        case .miniChallenges: return String(localized: "game.minich.title",        locale: .init(identifier: language))
        }
    }
    func displaySubtitle(for game: GameType) -> String {
        switch game {
        case .truthOrDare:    return String(localized: "game.truthOrDare.subtitle",   locale: .init(identifier: language))
        case .wouldYouRather: return String(localized: "game.wyr.subtitle",           locale: .init(identifier: language))
        case .neverHaveIEver: return String(localized: "game.nhie.subtitle",          locale: .init(identifier: language))
        case .priceGame:      return String(localized: "game.price.subtitle",         locale: .init(identifier: language))
        case .miniChallenges: return String(localized: "game.minich.subtitle",        locale: .init(identifier: language))
        }
    }
    func goBackToRoomSelection() { selectedGame = nil; currentGame = nil; gameState = .roomSelection }
    func beginPlaying() {
        guard selectedRoom == .games, let picked = selectedGame else { return }
        currentRoom = .games
        currentGame = picked
        resetDeck(with: [])
        reseedPlayerOrder()
        gameState = .playing
    }

    // ============================================================
    // MARK: PlayingRouting
    // ============================================================
    var playingTitle: String {
        if let game = currentGame { return displayName(for: game) }
        if let room = currentRoom { return displayName(for: room) }
        return String(localized: "playing", locale: .init(identifier: language))
    }
    var nextTitle: String       { String(localized: "next",       locale: .init(identifier: language)) }
    var skipTitle: String       { String(localized: "skip",       locale: .init(identifier: language)) }
    var endTitle: String        { String(localized: "end",        locale: .init(identifier: language)) }
    var startTimerTitle: String { String(localized: "startTimer", locale: .init(identifier: language)) }

    var currentPlayerNameTitle: String? { currentPlayerName }
    private var currentPlayerName: String? {
        guard let idx = currentMainPlayerIndex, players.indices.contains(idx) else { return nil }
        return players[idx]
    }

    var currentSpecialTitle: String? {
        guard currentIndex < actions.count, let gid = actions[currentIndex].game else { return nil }
        return ContentLoader.specialMeta(id: gid)?.title
    }
    var currentSpecialDescription: String? {
        guard currentIndex < actions.count, let gid = actions[currentIndex].game else { return nil }
        return ContentLoader.specialMeta(id: gid)?.description
    }
    var isSpecialCurrent: Bool {
        guard currentIndex < actions.count else { return false }
        return actions[currentIndex].game != nil
    }

    var currentActionText: String? {
        guard currentIndex < actions.count else { return nil }
        return actions[currentIndex].text
    }
    var currentPenalty: Int? {
        guard currentIndex < actions.count else { return nil }
        return actions[currentIndex].penalty
    }

    // testo renderizzato con placeholder
    var currentRenderedActionText: String? {
        guard var s = currentActionText else { return nil }

        ensureSecondaryForCurrentIndexIfNeeded(in: s)

        let main = currentPlayerName ?? ""
        let sec  = currentSecondaryPlayerName ?? otherRandomPlayerName(excluding: main) ?? ""

        s = s.replacingOccurrences(of: "{player}", with: main)
             .replacingOccurrences(of: "{PLAYER}", with: main.uppercased())
             .replacingOccurrences(of: "{playerB}", with: sec)
             .replacingOccurrences(of: "{PLAYERB}", with: sec.uppercased())
             .replacingOccurrences(of: "{player2}", with: sec)
             .replacingOccurrences(of: "{PLAYER2}", with: sec.uppercased())

        if let p = currentPenalty {
            s = s.replacingOccurrences(of: "{penalty}", with: String(p))
        }
        if s.contains("{count}") {
            let random = Int.random(in: 1...5)
            s = s.replacingOccurrences(of: "{count}", with: String(random))
        }
        return s
    }

    var hasMoreActions: Bool { currentIndex < actions.count }

    func onPlayingAppear() {
        guard actions.isEmpty else { return }
        isLoadingActions = true
        let room = self.currentRoom
        let game = self.currentGame

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                var deck: [GameAction] = []
                if let r = room, r != .games {
                    deck = try ContentLoader.loadRoomDeck(room: r)
                    deck = self.injectSpecialGames(into: deck, for: r)
                } else if let g = game {
                    deck = try ContentLoader.loadGameDeck(game: g)
                }
                if deck.count > self.MAX_ACTIONS_PER_MATCH {
                    deck = Array(deck.prefix(self.MAX_ACTIONS_PER_MATCH))
                }
                DispatchQueue.main.async {
                    self.resetDeck(with: deck)
                    self.isLoadingActions = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.resetDeck(with: [])
                    self.isLoadingActions = false
                    print("[ERROR] Content load failed: \(error)")
                }
            }
        }
    }

    func goNext() {
        guard !actions.isEmpty else { return }
        let next = currentIndex + 1
        advancePlayer()
        if next < actions.count && next < MAX_ACTIONS_PER_MATCH {
            currentIndex = next
        } else {
            gameState = .gameOver
        }
    }
    func skip() { goNext() }
    func startTimer() {
        if currentIndex < actions.count {
            let sec = actions[currentIndex].timerSeconds ?? 15
            print("[DEBUG] Start timer: \(sec)s")
        }
    }
    func endMatch() {
        actions.removeAll(); currentIndex = 0
        currentGame = nil; currentRoom = nil
        players.removeAll(); playerOrder.removeAll(); playerCursor = 0
        secondaryByIndex.removeAll()
        gameState = .gameOver
    }

    // Header/counter per PlayingView
    var currentStep: Int { min(currentIndex + 1, MAX_ACTIONS_PER_MATCH) }
    var totalSteps: Int { MAX_ACTIONS_PER_MATCH }
    func backToRooms() { gameState = .roomSelection }

    // ============================================================
    // MARK: PaywallRouting (stub)
    // ============================================================
    @Published var isTrialEnabled: Bool = true
    var paywallTitle: String { "Sblocca Gratis" }
    var paywallBullets: [String] { ["Accesso a tutte le modalità", "Nuovi contenuti regolarmente", "Cancellazione in ogni momento."] }
    var paywallTrialLabel: String { "Dubbi? Attivate la prova gratis" }
    var paywallPriceFooter: String { "Per 3 giorni, poi soli $0,99 a settimana" }
    var paywallContinueTitle: String { "CONTINUA" }
    var paywallRestoreTitle: String { "Ripristina" }
    var paywallTermsTitle: String { "Condizioni" }
    var paywallPrivacyTitle: String { "Privacy" }
    func paywallPurchase() { gameState = .roomSelection }
    func paywallRestore() { }
    func paywallClose() { gameState = .roomSelection }

    // ============================================================
    // MARK: OnboardingRouting
    // ============================================================
    var obIntroTitle: String    { "Sfide, mini giochi, segreti,\ngossip, drama e HOT…" }
    var obIntroSubtitle: String { "Tantissimi giochi a tema e sfide sempre nuove ad ogni partita, senza mai ripetersi." }
    var obStartTitle: String    { "GIOCHIAMO" }

    var obWhoTitle: String { "Chi gioca?" }
    var obWhoOptions: [String] { ["Solo girlz", "Boyz", "Mix"] }

    var obMoodTitle: String { "Siete in vena di…" }
    var obMoodOptions: [String] { ["Serata easy e stupida", "Spaccarci!", "Giochi folli e sexy", "Segreti e confessioni"] }

    func obSkip() { finishOnboarding() }
    func obStart() { gameState = .onboardingWho }
    func obSelectWho(_ index: Int) { gameState = .onboardingMood }
    func obSelectMood(_ index: Int) { finishOnboarding() }

    private func finishOnboarding() {
        UserDefaults.standard.set(true, forKey: onboardingKey)
        gameState = .playerSetup
    }

    // ============================================================
    // MARK: Helpers
    // ============================================================
    private func resetDeck(with new: [GameAction]) {
        actions = new
        currentIndex = 0
        secondaryByIndex.removeAll()
        if !players.isEmpty { reseedPlayerOrder() }
    }

    private func reseedPlayerOrder() {
        let clean = players.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        guard clean.count >= 2 else { return }
        players = clean
        playerOrder = Array(players.indices).shuffled()
        playerCursor = Int.random(in: 0..<playerOrder.count)
    }

    private func advancePlayer() {
        guard !playerOrder.isEmpty else { return }
        playerCursor = (playerCursor + 1) % playerOrder.count
    }

    private func ensureSecondaryForCurrentIndexIfNeeded(in text: String) {
        let needsB = text.localizedCaseInsensitiveContains("{playerb}") ||
                     text.localizedCaseInsensitiveContains("{player2}")
        guard needsB, secondaryByIndex[currentIndex] == nil,
              let mainIdx = currentMainPlayerIndex else { return }
        let candidates = players.indices.filter { $0 != mainIdx }
        guard !candidates.isEmpty else { return }
        secondaryByIndex[currentIndex] = candidates.randomElement()
    }

    private func otherRandomPlayerName(excluding name: String) -> String? {
        let pool = players.filter { $0 != name }
        return pool.randomElement()
    }

    private func injectSpecialGames(into base: [GameAction], for room: GameRoom) -> [GameAction] {
        guard !base.isEmpty else { return base }
        var deck = base
        var valid = commonSpecialGames + (roomSpecificSpecialGames[room] ?? [])
        valid.shuffle()

        let numSpecials = min(10, valid.count)
        let startPos = 5
        let endPos = max(startPos + 1, min(MAX_ACTIONS_PER_MATCH - 2, deck.count - 1))
        let available = max(1, endPos - startPos)
        let interval = max(MIN_SPACING_BETWEEN_SPECIAL, available / max(1, numSpecials))

        var positions: [Int] = []
        for i in 0..<numSpecials {
            let basePos = startPos + i * interval
            let maxOffset = max(0, min(interval - MIN_SPACING_BETWEEN_SPECIAL, 3))
            let randomOffset = (maxOffset > 0) ? Int.random(in: 0...maxOffset) : 0
            positions.append(min(endPos, basePos + randomOffset))
        }

        for (i, pos) in positions.enumerated() {
            let gid = valid[i % valid.count]
            let safeIndex = min(max(0, pos), deck.count)

            if let content = ContentLoader.loadSpecial(id: gid, room: room) {
                deck.insert(GameAction(text: content.action,
                                       room: room.rawValue,
                                       game: gid,
                                       penalty: nil,
                                       timerSeconds: content.timerSeconds),
                            at: safeIndex)
            } else if let mapped = mapSpecialIDToGameType(gid),
                      let one = try? ContentLoader.loadGameDeck(game: mapped).randomElement() {
                deck.insert(GameAction(text: one.text,
                                       room: room.rawValue,
                                       game: gid,
                                       penalty: one.penalty,
                                       timerSeconds: one.timerSeconds),
                            at: safeIndex)
            } else {
                deck.insert(GameAction(text: gid,
                                       room: room.rawValue,
                                       game: gid,
                                       penalty: nil,
                                       timerSeconds: nil),
                            at: safeIndex)
            }
        }

        if deck.count > MAX_ACTIONS_PER_MATCH { deck = Array(deck.prefix(MAX_ACTIONS_PER_MATCH)) }
        return deck
    }

    private func mapSpecialIDToGameType(_ id: String) -> GameType? {
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
