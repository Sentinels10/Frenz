import SwiftUI
import Combine

// MARK: - Stato app (senza .welcome)
enum GameState: Equatable {
    case onboardingIntro
    case onboardingWho
    case onboardingMood
    case languageSelection
    case privacyPolicy
    case termsOfUse
    case playerSetup
    case roomSelection
    case gameSelection
    case playing
    case gameOver
    case loading
}

@MainActor
final class GameViewModel: ObservableObject,
    // Routing (NO WelcomeRouting)
    LanguageSelectionRouting, PlayerSetupRouting,
    RoomSelectionRouting, GameSelectionRouting,
    PlayingRouting, OnboardingRouting,
    TruthOrDareRouting
{
    
    // ============================================================
    // MARK: Base / Persistenza
    // ============================================================
    @Published var gameState: GameState = .playerSetup
    private let onboardingKey = "onboarding.seen"

    var languageManager: LanguageManager? {
        didSet {
            languageCancellable = languageManager?.$locale.sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            objectWillChange.send()
        }
    }

    private var languageCancellable: AnyCancellable?
    
    var language: String {
        languageManager?.resolvedLanguageCode ?? LanguageManager.resolvedLanguageCode(for: .system)
    }

    private var currentLocale: Locale {
        languageManager?.locale ?? .current
    }
    
    // MARK: Loading (splash tra stanza e partita)
    @Published var loadingProgress: Double = 0 // 0...1
    @Published var loadingSnippets: [String] = [] // frasi che ruotano
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
    private var renderedActionByIndex: [Int: String] = [:]
    
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
    private var todOrder: [Int] = [] // indici dei giocatori per il giro
    private var todCursor: Int = 0
    @Published private var todText: String? = nil
    private var todTruths: [String] = []
    private var todDares: [String] = []
    
    // ============================================================
    // MARK: Init
    // ============================================================
    init() {
        if !UserDefaults.standard.bool(forKey: onboardingKey) {
            gameState = .onboardingIntro
        } else {
            gameState = .playerSetup
        }
    }
    
    // ============================================================
    // MARK: LanguageSelectionRouting
    // ============================================================
    var availableLanguages: [FrenzAppLanguage] { LanguageManager.selectableLanguages }
    var title: String { String.frenzLocalized("languageSelectTitle", locale: currentLocale) }
    var closeTitle: String { String.frenzLocalized("close", locale: currentLocale) }
    
    func selectLanguage(_ code: String) {
        guard let lang = FrenzAppLanguage.allCases.first(where: { $0.id == code }) else { return }
        languageManager?.selected = lang
    }
    
    func closeLanguageSelector() { gameState = .playerSetup }
    
    // Bootstrap opzionale per Truth or Dare
    func todChoosePhaseBootstrapIfNeeded() {
        guard isTruthOrDareRound else { return }
        ensureTodPrepared()
    }
    
    // ============================================================
    // MARK: PlayerSetupRouting
    // ============================================================
    var playerSetupTitle: String { String.frenzLocalized("playerSetup.title", locale: currentLocale) }
    var playerInputPlaceholder: String { String.frenzLocalized("playerInputPlaceholder", locale: currentLocale) }
    var addPlayerLabel: String { String.frenzLocalized("addPlayerLabel", locale: currentLocale) }
    var backButtonTitle: String { String.frenzLocalized("backButton", locale: currentLocale) }
    
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
    func openPrivacyPolicy() { gameState = .privacyPolicy }
    func openTermsOfUse() { gameState = .termsOfUse }
    
    // ============================================================
    // MARK: RoomSelectionRouting
    // ============================================================
    var availableRooms: [GameRoom] { [.party, .darkRoom, .partner, .roulette, .redRoom, .games] }
    var roomSelectionTitle: String { String.frenzLocalized("roomSelectionTitle", locale: currentLocale) }
    var roomSelectionAddPlayersTitle: String { String.frenzLocalized("roomSelection.addPlayers", locale: currentLocale) }
    var continueTitle: String { String.frenzLocalized("continue", locale: currentLocale) }
    
    func displayName(for room: GameRoom) -> String {
        switch room {
        case .party: return String.frenzLocalized("room.party.title", locale: currentLocale)
        case .redRoom: return String.frenzLocalized("room.red.title", locale: currentLocale)
        case .darkRoom: return String.frenzLocalized("room.dark.title", locale: currentLocale)
        case .partner: return String.frenzLocalized("room.partner.title", locale: currentLocale)
        case .roulette: return String.frenzLocalized("room.roulette.title", locale: currentLocale)
        case .games: return String.frenzLocalized("room.games.title", locale: currentLocale)
        }
    }
    
    func displaySubtitle(for room: GameRoom) -> String {
        switch room {
        case .party: return String.frenzLocalized("room.party.subtitle", locale: currentLocale)
        case .redRoom: return String.frenzLocalized("room.red.subtitle", locale: currentLocale)
        case .darkRoom: return String.frenzLocalized("room.dark.subtitle", locale: currentLocale)
        case .partner: return String.frenzLocalized("room.partner.subtitle", locale: currentLocale)
        case .roulette: return String.frenzLocalized("room.roulette.subtitle", locale: currentLocale)
        case .games: return String.frenzLocalized("room.games.subtitle", locale: currentLocale)
        }
    }
    
    func goBack() {
        switch gameState {
        case .onboardingMood: gameState = .onboardingWho
        case .onboardingWho: gameState = .onboardingIntro
        case .gameSelection: gameState = .roomSelection
        case .roomSelection: gameState = .playerSetup
        case .languageSelection: gameState = .playerSetup
        case .privacyPolicy, .termsOfUse: gameState = .languageSelection
        case .playing: gameState = .roomSelection
        case .gameOver: gameState = .roomSelection
        default: break
        }
    }
    
    func openPlayerSetup() {
        gameState = .playerSetup
    }
    
    func select(room: GameRoom) {
        startLoadingAndEnter(room: room)
    }
    
    func startLoadingAndEnter(room: GameRoom) {
        currentRoom = room
        currentGame = nil
        loadingProgress = 0
        loadingSnippets = []
        carouselIndex = 0
        gameState = .loading
        let lang = language
        
        DispatchQueue.global(qos: .userInitiated).async {
            let deck = (try? ContentLoader.loadRoomDeck(lang: lang, room: room)) ?? []
            let texts = deck
                .map(\.text)
                .filter(Self.isSafeLoadingSnippet)
                .shuffled()
                .prefix(4)
            DispatchQueue.main.async {
                self.loadingSnippets = Array(texts)
            }
        }
        
        loadingTimerCancellable?.cancel()
        loadingTimerCancellable = Timer.publish(every: 0.04, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.loadingProgress += 0.01
                if self.loadingProgress >= 1.0 {
                    self.loadingTimerCancellable?.cancel()
                    self.finishLoadingAndStartMatch()
                }
            }
        
        carouselTimerCancellable?.cancel()
        carouselTimerCancellable = Timer.publish(every: 1.2, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, !self.loadingSnippets.isEmpty else { return }
                self.carouselIndex = (self.carouselIndex + 1) % self.loadingSnippets.count
            }
    }

    private nonisolated static func isSafeLoadingSnippet(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        // Il carosello mostra testo grezzo: escludi placeholder e note tra parentesi.
        return trimmed.rangeOfCharacter(from: CharacterSet(charactersIn: "()[]{}")) == nil
    }
    
    private func finishLoadingAndStartMatch() {
        carouselTimerCancellable?.cancel()
        let room = currentRoom
        let game = currentGame
        let lang = language
        let maxActions = MAX_ACTIONS_PER_MATCH
        let minSpecialSpacing = MIN_SPACING_BETWEEN_SPECIAL
        DispatchQueue.global(qos: .userInitiated).async {
            var deck: [GameAction] = []
            if let r = room, r != .games {
                deck = (try? ContentLoader.loadRoomDeck(lang: lang, room: r)) ?? []
                deck = Self.injectSpecialGames(
                    into: deck,
                    for: r,
                    lang: lang,
                    maxActions: maxActions,
                    minSpacingBetweenSpecial: minSpecialSpacing
                )
            } else if let g = game {
                deck = (try? ContentLoader.loadGameDeck(lang: lang, game: g)) ?? []
            }
            
            if deck.count > maxActions {
                deck = Array(deck.prefix(maxActions))
            }
            
            DispatchQueue.main.async {
                self.resetDeck(with: deck)
                self.gameState = .playing
            }
        }
    }
    
    func openSettings() { }
    
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
    var availableGames: [GameType] { [.truthOrDare, .wouldYouRather, .neverHaveIEver, .priceGame] }
    var gameSelectionTitle: String { String.frenzLocalized("gameSelectionTitle", locale: currentLocale) }
    var startMatchTitle: String { String.frenzLocalized("startMatch", locale: currentLocale) }
    
    func displayName(for game: GameType) -> String {
        switch game {
        case .truthOrDare: return String.frenzLocalized("game.truthOrDare.title", locale: currentLocale)
        case .wouldYouRather: return String.frenzLocalized("game.wyr.title", locale: currentLocale)
        case .neverHaveIEver: return String.frenzLocalized("game.nhie.title", locale: currentLocale)
        case .priceGame: return String.frenzLocalized("game.price.title", locale: currentLocale)
        case .miniChallenges: return String.frenzLocalized("game.minich.title", locale: currentLocale)
        }
    }
    
    func displaySubtitle(for game: GameType) -> String {
        switch game {
        case .truthOrDare: return String.frenzLocalized("game.truthOrDare.subtitle", locale: currentLocale)
        case .wouldYouRather: return String.frenzLocalized("game.wyr.subtitle", locale: currentLocale)
        case .neverHaveIEver: return String.frenzLocalized("game.nhie.subtitle", locale: currentLocale)
        case .priceGame: return String.frenzLocalized("game.price.subtitle", locale: currentLocale)
        case .miniChallenges: return String.frenzLocalized("game.minich.subtitle", locale: currentLocale)
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
        return String.frenzLocalized("playing", locale: currentLocale)
    }
    
    var nextTitle: String { String.frenzLocalized("next", locale: currentLocale) }
    var skipTitle: String { String.frenzLocalized("skip", locale: currentLocale) }
    var endTitle: String { String.frenzLocalized("end", locale: currentLocale) }
    var startTimerTitle: String { String.frenzLocalized("startTimer", locale: currentLocale) }
    var gameOverPart1: String { String.frenzLocalized("gameOver.part1", locale: currentLocale) }
    var gameOverPart2: String { String.frenzLocalized("gameOver.part2", locale: currentLocale) }
    var currentPlayerNameTitle: String? { currentPlayerName }
    
    private var currentPlayerName: String? {
        guard let idx = currentMainPlayerIndex, players.indices.contains(idx) else { return nil }
        return players[idx]
    }
    
    var currentSpecialTitle: String? {
        guard currentIndex < actions.count, let gid = actions[currentIndex].game else { return nil }
        return ContentLoader.specialMeta(lang: language, id: gid)?.title
    }
    
    var currentSpecialDescription: String? {
        guard currentIndex < actions.count, let gid = actions[currentIndex].game else { return nil }
        return ContentLoader.specialMeta(lang: language, id: gid)?.description
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
        if let rendered = renderedActionByIndex[currentIndex] { return rendered }
        guard let text = currentActionText else { return nil }
        let main = currentPlayerName ?? ""
        let otherIndices = players.indices.filter { $0 != currentMainPlayerIndex }.shuffled()
        if let secondary = otherIndices.first {
            secondaryByIndex[currentIndex] = secondary
        }
        let rendered = ActionTextRenderer.render(
            text,
            mainPlayer: main,
            otherPlayers: otherIndices.map { players[$0] },
            includeMainForAnonymousPlayers: actions[currentIndex].game == "penitenzeGruppo",
            language: language,
            penalty: currentPenalty,
            count: Int.random(in: 1...5)
        )
        renderedActionByIndex[currentIndex] = rendered
        return rendered
    }
    
    var hasMoreActions: Bool { currentIndex < actions.count }
    
    func onPlayingAppear() {
        guard actions.isEmpty else { return }
        isLoadingActions = true
        let room = self.currentRoom
        let game = self.currentGame
        let lang = language
        let maxActions = MAX_ACTIONS_PER_MATCH
        let minSpecialSpacing = MIN_SPACING_BETWEEN_SPECIAL
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                var deck: [GameAction] = []
                if let r = room, r != .games {
                    deck = try ContentLoader.loadRoomDeck(lang: lang, room: r)
                    deck = Self.injectSpecialGames(
                        into: deck,
                        for: r,
                        lang: lang,
                        maxActions: maxActions,
                        minSpacingBetweenSpecial: minSpecialSpacing
                    )
                } else if let g = game {
                    deck = try ContentLoader.loadGameDeck(lang: lang, game: g)
                }
                
                if deck.count > maxActions {
                    deck = Array(deck.prefix(maxActions))
                }
                
                DispatchQueue.main.async {
                    self.resetDeck(with: deck)
                    self.isLoadingActions = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.resetDeck(with: [])
                    self.isLoadingActions = false
                }
            }
        }
    }
    
    func goNext() {
        guard !actions.isEmpty else { return }
        if todActive && isTruthOrDareRound { return }
        let next = currentIndex + 1
        advancePlayer()
        if next < actions.count && next < MAX_ACTIONS_PER_MATCH {
            currentIndex = next
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
        guard currentIndex < actions.count else { return }
    }
    
    func endMatch() {
        actions.removeAll(); currentIndex = 0
        currentGame = nil; currentRoom = nil
        players.removeAll(); playerOrder.removeAll(); playerCursor = 0
        secondaryByIndex.removeAll(); renderedActionByIndex.removeAll()
        todActive = false; todText = nil; todTruths.removeAll(); todDares.removeAll()
        gameState = .gameOver
    }
    
    var currentStep: Int { min(currentIndex + 1, MAX_ACTIONS_PER_MATCH) }
    var totalSteps: Int { MAX_ACTIONS_PER_MATCH }
    func backToRooms() { gameState = .roomSelection }
    
    func continueFromGameOver() {
        backToRooms()
    }
    
    // ============================================================
    // MARK: OnboardingRouting
    // ============================================================
    var obIntroTitle: String { String.frenzLocalized("onboarding.intro.title", locale: currentLocale) }
    var obIntroSubtitle: String { String.frenzLocalized("onboarding.intro.subtitle", locale: currentLocale) }
    var obStartTitle: String { String.frenzLocalized("onboarding.start", locale: currentLocale) }
    var obWhoTitle: String { String.frenzLocalized("onboarding.who.title", locale: currentLocale) }
    var obWhoOptions: [String] {
        [
            String.frenzLocalized("onboarding.who.opt.girlz", locale: currentLocale),
            String.frenzLocalized("onboarding.who.opt.boyz", locale: currentLocale),
            String.frenzLocalized("onboarding.who.opt.mix", locale: currentLocale)
        ]
    }
    var obMoodTitle: String { String.frenzLocalized("onboarding.mood.title", locale: currentLocale) }
    var obMoodOptions: [String] {
        [
            String.frenzLocalized("onboarding.mood.opt.easy", locale: currentLocale),
            String.frenzLocalized("onboarding.mood.opt.sexy", locale: currentLocale),
            String.frenzLocalized("onboarding.mood.opt.secrets", locale: currentLocale)
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
    // MARK: TruthOrDareRouting
    // ============================================================
    var isTruthOrDareRound: Bool {
        guard currentIndex < actions.count else { return false }
        return actions[currentIndex].game == "truthOrDare"
    }
    
    var todIsChoosePhase: Bool { todActive && todPhase == .choose }
    var todIsShowingTruth: Bool { todActive && todPhase == .truth }
    var todIsShowingDare: Bool { todActive && todPhase == .dare }
    var todTitle: String { String.frenzLocalized("tod.title", locale: currentLocale) }
    
    var todCurrentPlayerName: String? {
        guard todActive, todCursor < todOrder.count else { return nil }
        let idx = todOrder[todCursor]
        return players.indices.contains(idx) ? players[idx] : nil
    }
    
    var todPromptTitle: String {
        switch todPhase {
        case .truth: return String.frenzLocalized("tod.prompt.truth", locale: currentLocale)
        case .dare: return String.frenzLocalized("tod.prompt.dare", locale: currentLocale)
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
        todPhase = .choose
        todText = nil
        todCursor += 1
        if todCursor >= todOrder.count {
            todActive = false
            goNext()
        }
    }
    
    // ============================================================
    // MARK: Helpers
    // ============================================================
    private func resetDeck(with new: [GameAction]) {
        actions = new
        currentIndex = 0
        secondaryByIndex.removeAll(); renderedActionByIndex.removeAll()
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
        playerCursor += 1
    }
    
    nonisolated private static func injectSpecialGames(
        into base: [GameAction],
        for room: GameRoom,
        lang: String,
        maxActions: Int,
        minSpacingBetweenSpecial: Int
    ) -> [GameAction] {
        guard !base.isEmpty else { return base }
        var deck = base
        var valid = SpecialGamesProvider.allFor(room: room)
        valid.shuffle()
        let numSpecials = min(10, valid.count)
        let startPos = 5
        let endPos = max(startPos + 1, min(maxActions - 2, deck.count - 1))
        let available = max(1, endPos - startPos)
        let interval = max(minSpacingBetweenSpecial, available / max(1, numSpecials))
        var positions: [Int] = []
        for i in 0..<numSpecials {
            let basePos = startPos + i * interval
            let maxOffset = (interval > minSpacingBetweenSpecial) ? (interval - minSpacingBetweenSpecial) : 0
            let randomOffset = (maxOffset > 0) ? Int.random(in: 0...maxOffset) : 0
            positions.append(min(endPos, basePos + randomOffset))
        }

        for (i, pos) in positions.enumerated() {
            let gid = valid[i % valid.count]
            let safeIndex = min(max(0, pos), deck.count)
            if let content = ContentLoader.loadSpecial(lang: lang, id: gid, room: room) {
                deck.insert(
                    GameAction(text: content.action,
                              room: room.rawValue,
                              game: gid,
                              penalty: nil,
                              timerSeconds: content.timerSeconds),
                    at: safeIndex
                )
            } else if let mapped = SpecialGamesProvider.mapToGameType(gid),
                      let one = try? ContentLoader.loadGameDeck(lang: lang, game: mapped).randomElement() {
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
        if deck.count > maxActions { deck = Array(deck.prefix(maxActions)) }
        return deck
    }
    
    // MARK: Truth or Dare helpers
    private func ensureTodPrepared() {
        guard isTruthOrDareRound else { return }
        if !todActive {
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
        
        let lang = language
        if let r = currentRoom,
           let td = try? ContentLoader.loadTruthOrDare(lang: lang, room: r) {
            todTruths = td.truths.shuffled()
            todDares = td.dares.shuffled()
        }
    }
    
    private func loadTruthOrDareContent() {
        let lang = language
        if let r = currentRoom,
           let td = try? ContentLoader.loadTruthOrDare(lang: lang, room: r) {
            todTruths = td.truths.shuffled()
            todDares = td.dares.shuffled()
            return
        }
        
        if let deck = try? ContentLoader.loadGameDeck(lang: lang, game: .truthOrDare) {
            let all = deck.map { $0.text }
            todTruths = all.shuffled()
            todDares = all.shuffled()
        } else {
            todTruths = ["Hai mai mentito oggi?", "Qual è il tuo segreto più buffo?"]
            todDares = ["Fai 10 flessioni", "Parla con accento strano per 1 turno"]
        }
    }
    
    private func renderTODPrompt(pickFrom source: [String]) -> String {
        let base = source.randomElement() ?? ""
        let main = todCurrentPlayerName ?? currentPlayerName ?? ""
        let currentTODIndex = todActive && todCursor < todOrder.count ? todOrder[todCursor] : currentMainPlayerIndex
        let others = players.indices.filter { $0 != currentTODIndex }.shuffled().map { players[$0] }
        return ActionTextRenderer.render(
            base,
            mainPlayer: main,
            otherPlayers: others,
            includeMainForAnonymousPlayers: false,
            language: language,
            penalty: currentPenalty,
            count: Int.random(in: 1...5)
        )
    }
}
