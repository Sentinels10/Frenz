import SwiftUI
import Combine

// MARK: - Stato app (senza .welcome)
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
    case loading
}

final class GameViewModel: ObservableObject,
    // Routing (NO WelcomeRouting)
    LanguageSelectionRouting, PlayerSetupRouting,
    RoomSelectionRouting, GameSelectionRouting,
    PlayingRouting, PaywallRouting, OnboardingRouting,
    TruthOrDareRouting
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
    
    func togglePremium() {
        premiumUnlocked.toggle()
    }
    
    // MARK: Loading (splash tra stanza e partita)
    @Published var loadingProgress: Double = 0        // 0...1
    @Published var loadingSnippets: [String] = []     // frasi che ruotano
    @Published var carouselIndex: Int = 0

    private var loadingTimerCancellable: AnyCancellable?
    private var carouselTimerCancellable: AnyCancellable?

    // ============================================================
    // MARK: Player setup
    // ============================================================
    @Published var inputPlayers: [PlayerInput] = [PlayerInput(id: 1, name: "")]

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
    @Published private var currentIndex: Int = 0 {
        didSet {
            // Se abbiamo lasciato una carta ToD, resetta lo stato ToD
            if todActive && !isTruthOrDareRound {
                todActive = false
                todText = nil
                todPhase = .choose
                todOrder.removeAll()
                todCursor = 0
            }
        }
    }

    // Limiti e mapping
    let MAX_ACTIONS_PER_MATCH = 50
    private let MIN_SPACING_BETWEEN_SPECIAL = 3


    // ============================================================
    // MARK: Truth or Dare (round per tutti)
    // ============================================================
    private enum TODPhase { case choose, truth, dare }
    @Published private var todActive: Bool = false
    @Published private var todPhase: TODPhase = .choose
    private var todOrder: [Int] = []   // indici dei giocatori per il giro
    private var todCursor: Int = 0
    @Published private var todText: String? = nil
    private var todTruths: [String] = []
    private var todDares:  [String] = []

    // ============================================================
    // MARK: Premium
    // ============================================================
    private let premiumKey = "premium.unlocked"

    @Published var premiumUnlocked: Bool {
        didSet { UserDefaults.standard.set(premiumUnlocked, forKey: premiumKey) }
    }
    private var pendingRoomSelection: GameRoom?

    // ============================================================
    // MARK: Init
    // ============================================================
    init() {
        self.premiumUnlocked = UserDefaults.standard.bool(forKey: premiumKey)
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
    func closeLanguageSelector() { gameState = .playerSetup }

    // Bootstrap opzionale per Truth or Dare
    func todChoosePhaseBootstrapIfNeeded() {
        guard isTruthOrDareRound else { return }
        ensureTodPrepared()
    }

    // ============================================================
    // MARK: PlayerSetupRouting
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
    func openLanguageSelector() { gameState = .languageSelection }

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

    // 🔁 RINOMINATO: era `isPremium(_:)`
    func isRoomPremium(_ room: GameRoom) -> Bool { room != .party }
    
    // MARK: - RoomSelectionRouting shims (per compatibilità con la View/protocollo attuale)
    func isPremium(_ room: GameRoom) -> Bool {    // il protocollo si aspetta questo nome
        return isRoomPremium(room)                 // reindirizza al metodo nuovo
    }

    func goBack() {                                // richiesto dal protocollo
        gameState = .playerSetup                   // stesso comportamento di goBackToPlayerSetup()
    }

    func openPlayerSetup() {                       // richiesto dal protocollo
        gameState = .playerSetup
    }

    func select(room: GameRoom) {
        // paywall se serve
        if isRoomPremium(room) && !premiumUnlocked {
            pendingRoomSelection = room
            gameState = .paywall
            return
        }
        // altrimenti avvia schermata di loading
        startLoadingAndEnter(room: room)
    }
    
    // Avvia schermata di loading e prepara deck/snippets
    func startLoadingAndEnter(room: GameRoom) {
        currentRoom = room
        currentGame = nil

        // reset stato loading
        loadingProgress = 0
        loadingSnippets = []
        carouselIndex = 0
        gameState = .loading

        // Pre-carica 3-4 frasi casuali della stanza per il carosello
        DispatchQueue.global(qos: .userInitiated).async {
            let deck = (try? ContentLoader.loadRoomDeck(room: room)) ?? []
            let texts = deck.map { $0.text }.shuffled().prefix(4)
            DispatchQueue.main.async {
                self.loadingSnippets = Array(texts)
            }
        }

        // Timer progress bar (~4s)
        loadingTimerCancellable?.cancel()
        loadingTimerCancellable = Timer.publish(every: 0.04, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.loadingProgress += 0.01            // 0.04s * 100 step ≈ 4s
                if self.loadingProgress >= 1.0 {
                    self.loadingTimerCancellable?.cancel()
                    self.finishLoadingAndStartMatch()
                }
            }

        // Timer carosello (cambia frase ogni ~1.2s)
        carouselTimerCancellable?.cancel()
        carouselTimerCancellable = Timer.publish(every: 1.2, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, !self.loadingSnippets.isEmpty else { return }
                self.carouselIndex = (self.carouselIndex + 1) % self.loadingSnippets.count
            }
    }

    // Quando il loading termina, prepara il deck e vai in playing
    private func finishLoadingAndStartMatch() {
        carouselTimerCancellable?.cancel()

        DispatchQueue.global(qos: .userInitiated).async {
            var deck: [GameAction] = []
            if let r = self.currentRoom, r != .games {
                deck = (try? ContentLoader.loadRoomDeck(room: r)) ?? []
                deck = self.injectSpecialGames(into: deck, for: r)
            } else if let g = self.currentGame {
                deck = (try? ContentLoader.loadGameDeck(game: g)) ?? []
            }
            if deck.count > self.MAX_ACTIONS_PER_MATCH {
                deck = Array(deck.prefix(self.MAX_ACTIONS_PER_MATCH))
            }
            DispatchQueue.main.async {
                self.resetDeck(with: deck)
                self.gameState = .playing
            }
        }
    }

    // Paywall flow
    func completePremiumPurchase() {
        premiumUnlocked = true
        if let r = pendingRoomSelection {
            pendingRoomSelection = nil
            select(room: r)
        } else {
            gameState = .roomSelection
        }
    }
    func cancelPremiumFlow() {
        pendingRoomSelection = nil
        gameState = .roomSelection
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
            s = s.replacingOccurrences(of: "{count}", with: String(Int.random(in: 1...5)))
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

        // Blocca l'avanzamento solo se siamo su una carta TruthOrDare *e* il round ToD è attivo
        if todActive && isTruthOrDareRound { return }

        let next = currentIndex + 1
        advancePlayer()

        if next < actions.count && next < MAX_ACTIONS_PER_MATCH {
            currentIndex = next
            // Failsafe: se la prossima non è ToD, spegni qualsiasi stato residuo di ToD
            if !isTruthOrDareRound {
                todActive = false
                todText = nil
                todPhase = .choose
            }
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
        todActive = false; todText = nil; todTruths.removeAll(); todDares.removeAll()
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
    var paywallTitle: String { String(localized: "paywall.title", locale: .init(identifier: language)) }
    var paywallBullets: [String] {
        [
            String(localized: "paywall.bullet.1", locale: .init(identifier: language)),
            String(localized: "paywall.bullet.2", locale: .init(identifier: language)),
            String(localized: "paywall.bullet.3", locale: .init(identifier: language))
        ]
    }
    var paywallTrialLabel: String { String(localized: "paywall.trialLabel", locale: .init(identifier: language)) }
    var paywallPriceFooter: String { String(localized: "paywall.priceFooter", locale: .init(identifier: language)) }
    var paywallContinueTitle: String { String(localized: "paywall.continue", locale: .init(identifier: language)) }
    var paywallRestoreTitle: String { String(localized: "paywall.restore", locale: .init(identifier: language)) }
    var paywallTermsTitle: String { String(localized: "paywall.terms", locale: .init(identifier: language)) }
    var paywallPrivacyTitle: String { String(localized: "paywall.privacy", locale: .init(identifier: language)) }
    func paywallPurchase() { gameState = .roomSelection }
    func paywallRestore() { }
    func paywallClose() { gameState = .roomSelection }

    // ============================================================
    // MARK: OnboardingRouting
    // ============================================================
    var obIntroTitle: String    { String(localized: "onboarding.intro.title",    locale: .init(identifier: language)) }
    var obIntroSubtitle: String { String(localized: "onboarding.intro.subtitle", locale: .init(identifier: language)) }
    var obStartTitle: String    { String(localized: "onboarding.start",          locale: .init(identifier: language)) }

    var obWhoTitle: String { String(localized: "onboarding.who.title", locale: .init(identifier: language)) }
    var obWhoOptions: [String] {
        [
            String(localized: "onboarding.who.opt.girlz", locale: .init(identifier: language)),
            String(localized: "onboarding.who.opt.boyz",  locale: .init(identifier: language)),
            String(localized: "onboarding.who.opt.mix",   locale: .init(identifier: language))
        ]
    }

    var obMoodTitle: String { String(localized: "onboarding.mood.title", locale: .init(identifier: language)) }
    var obMoodOptions: [String] {
        [
            String(localized: "onboarding.mood.opt.easy",    locale: .init(identifier: language)),
            String(localized: "onboarding.mood.opt.party",   locale: .init(identifier: language)),
            String(localized: "onboarding.mood.opt.sexy",    locale: .init(identifier: language)),
            String(localized: "onboarding.mood.opt.secrets", locale: .init(identifier: language))
        ]
    }

    func obSkip() { finishOnboarding() }
    func obStart() { gameState = .onboardingWho }
    func obSelectWho(_ index: Int) { gameState = .onboardingMood }
    func obSelectMood(_ index: Int) { finishOnboarding() }

    private func finishOnboarding() {
        UserDefaults.standard.set(true, forKey: onboardingKey)
        gameState = .playerSetup
    }

    // ============================================================
    // MARK: TruthOrDareRouting (implementazione)
    // ============================================================
    var isTruthOrDareRound: Bool {
        guard currentIndex < actions.count else { return false }
        return actions[currentIndex].game == "truthOrDare"
    }
    var todIsChoosePhase: Bool { todActive && todPhase == .choose }
    var todIsShowingTruth: Bool { todActive && todPhase == .truth }
    var todIsShowingDare: Bool { todActive && todPhase == .dare }

    var todTitle: String { String(localized: "tod.title", locale: .init(identifier: language)) }
    var todCurrentPlayerName: String? {
        guard todActive, todCursor < todOrder.count else { return nil }
        let idx = todOrder[todCursor]
        return players.indices.contains(idx) ? players[idx] : nil
    }
    var todPromptTitle: String {
        switch todPhase {
        case .truth: return String(localized: "tod.prompt.truth", locale: .init(identifier: language))
        case .dare:  return String(localized: "tod.prompt.dare",  locale: .init(identifier: language))
        case .choose: return ""
        }
    }
    var todPromptText: String? { todText }

    func todChooseTruth() {
        ensureTodPrepared()
        todPhase = .truth
        todText = renderTODPrompt(pickFrom: todTruths)
    }
    func todChooseDare() {
        ensureTodPrepared()
        todPhase = .dare
        todText = renderTODPrompt(pickFrom: todDares)
    }
    func todNext() {
        // passa al prossimo giocatore oppure chiudi round e avanza il deck
        todPhase = .choose
        todText = nil
        todCursor += 1
        if todCursor >= todOrder.count {
            todActive = false
            goNext() // avanza nel mazzo normale
        }
    }

    // ============================================================
    // MARK: Helpers
    // ============================================================
    private func resetDeck(with new: [GameAction]) {
        actions = new
        currentIndex = 0
        secondaryByIndex.removeAll()
        todActive = false; todText = nil; todTruths.removeAll(); todDares.removeAll()
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
        var valid = SpecialGamesProvider.allFor(room: room)
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

            if let content = ContentLoader.loadSpecial(lang: language, id: gid, room: room) {
                deck.insert(
                    GameAction(text: content.action,
                               room: room.rawValue,
                               game: gid,
                               penalty: nil,
                               timerSeconds: content.timerSeconds),
                    at: safeIndex
                )
            } else if let mapped = SpecialGamesProvider.mapToGameType(gid),
                      let one = try? ContentLoader.loadGameDeck(lang: language, game: mapped).randomElement() {
                deck.insert(GameAction(text: one.text,
                                       room: room.rawValue,
                                       game: gid,
                                       penalty: one.penalty,
                                       timerSeconds: one.timerSeconds),
                            at: safeIndex)
            } else {
                deck.insert(GameAction(text: gid, room: room.rawValue, game: gid, penalty: nil, timerSeconds: nil), at: safeIndex)
            }
        }

        if deck.count > MAX_ACTIONS_PER_MATCH { deck = Array(deck.prefix(MAX_ACTIONS_PER_MATCH)) }
        return deck
    }


    // MARK: Truth or Dare helpers
    private func ensureTodPrepared() {
        guard isTruthOrDareRound else { return }

        if !todActive {
            // ordine: giocatore corrente, poi gli altri
            todOrder = []
            if let main = currentMainPlayerIndex {
                todOrder.append(main)
                let others = players.indices.filter { $0 != main }
                todOrder.append(contentsOf: others)
            } else {
                todOrder = Array(players.indices)
            }
            todCursor = 0
            todPhase = .choose
            todActive = true
        }

        if let r = currentRoom,
           let td = try? ContentLoader.loadTruthOrDare(lang: language, room: r) {
            todTruths = td.truths.shuffled()
            todDares  = td.dares.shuffled()
        }
    }

    private func loadTruthOrDareContent() {
        if let r = currentRoom,
           let td = try? ContentLoader.loadTruthOrDare(room: r) {
            todTruths = td.truths.shuffled()
            todDares  = td.dares.shuffled()
            return
        }
        // fallback: usa deck del gioco o frasi base
        if let deck = try? ContentLoader.loadGameDeck(game: .truthOrDare) {
            let all = deck.map { $0.text }
            todTruths = all.shuffled()
            todDares  = all.shuffled()
        } else {
            todTruths = ["Hai mai mentito oggi?", "Qual è il tuo segreto più buffo?"]
            todDares  = ["Fai 10 flessioni", "Parla con accento strano per 1 turno"]
        }
    }

    private func renderTODPrompt(pickFrom source: [String]) -> String {
        let base = source.randomElement() ?? ""
        var s = base

        ensureSecondaryForCurrentIndexIfNeeded(in: s)

        let main = todCurrentPlayerName ?? currentPlayerName ?? ""
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
            s = s.replacingOccurrences(of: "{count}", with: String(Int.random(in: 1...5)))
        }
        return s
    }
}
