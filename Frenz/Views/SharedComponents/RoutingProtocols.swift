import SwiftUI

// MARK: - Support
public struct AppLanguage: Identifiable, Equatable {
    public let id: String   // "it", "en", ...
    public let name: String // "Italiano", "English", ...
    public let flag: String // "🇮🇹", "🇬🇧", ...
}


// MARK: - Language Selection
@MainActor
public protocol LanguageSelectionRouting: ObservableObject {
    var availableLanguages: [FrenzAppLanguage] { get }
    var title: String { get }
    var closeTitle: String { get }
    var language: String { get }
    func selectLanguage(_ code: String)
    func closeLanguageSelector()
    func goBack()
}

// MARK: - Player Setup
@MainActor
public protocol PlayerSetupRouting: ObservableObject {
    // Dati
    var inputPlayers: [PlayerInput] { get }
    // Testi
    var playerInputPlaceholder: String { get }
    var addPlayerLabel: String { get }
    var backButtonTitle: String { get }
    // Azioni
    func addPlayerInput()
    func updatePlayerName(id: Int, name: String)
    func removePlayerInput(id: Int)
    func startGame()
    // Settings (gear in alto a destra)
    func openLanguageSelector()
}

// MARK: - Room Selection (NUOVO: estetica tipo screenshot)
@MainActor
public protocol RoomSelectionRouting: ObservableObject {
    func togglePremium()                // la View chiede al VM di cambiare stato
    var premiumUnlocked: Bool { get }
    func isRoomPremium(_ room: GameRoom) -> Bool
    func openLanguageSelector()
    func goBack()
    func openPlayerSetup()
    var availableRooms: [GameRoom] { get }
    var roomSelectionTitle: String { get }
    var continueTitle: String { get }

    func displayName(for room: GameRoom) -> String
    func displaySubtitle(for room: GameRoom) -> String

    // Azioni/Hook UI
    func select(room: GameRoom)
    func openSettings()
    func addPlayers()
    func isRoomLocked(_ room: GameRoom) -> Bool
    func showsCrown(_ room: GameRoom) -> Bool
    func progressForParty() -> (current: Int, total: Int)?
    func goBackToPlayerSetup()
    func enterGameSelection()

    // facoltativo ma comodo se la view deve leggere/settare la selezione
    var selectedRoom: GameRoom? { get set }
}

// MARK: - Game Selection (hub “Giochi”)
@MainActor
public protocol GameSelectionRouting: ObservableObject {
    var availableGames: [GameType] { get }
    var gameSelectionTitle: String { get }
    var startMatchTitle: String { get }
    var backButtonTitle: String { get }
    func displayName(for game: GameType) -> String
    func displaySubtitle(for game: GameType) -> String

    func goBackToRoomSelection()
    func beginPlaying()

    var selectedGame: GameType? { get set }
}

// MARK: - Playing
@MainActor
public protocol PlayingRouting: ObservableObject {
    // Stato corrente
    var language: String { get }
    var currentRoom: GameRoom? { get }
    var currentGame: GameType? { get }
    // +++ aggiunte per la nuova UI +++
    var currentStep: Int { get }   // es. 23
    var totalSteps: Int { get }    // es. 50
    func backToRooms()             // torna alla RoomSelection
    var isSpecialCurrent: Bool { get }             // se l’azione corrente è un minigioco
    var currentRenderedActionText: String? { get } // testo con placeholder risolti
    // Testi UI
    var playingTitle: String { get }
    var nextTitle: String { get }
    var skipTitle: String { get }
    var endTitle: String { get }
    var startTimerTitle: String { get }

    // Contenuto azione
    var currentPlayerNameTitle: String? { get }     // Nome giocatore sopra, centrato
    var currentSpecialTitle: String? { get }        // Titolo minigioco (se presente)
    var currentSpecialDescription: String? { get }  // Descrizione/regole (se presente)
    var currentActionText: String? { get }
    var currentPenalty: Int? { get }

    // Stato caricamento/navigazione
    var isLoadingActions: Bool { get }
    var hasMoreActions: Bool { get }

    // Azioni
    func onPlayingAppear()
    func goNext()
    func skip()
    func startTimer()
    func endMatch()
    func requestPaywallAfterGameOver()
}

// MARK: - Truth or Dare (Obbligo o Verità)
@MainActor
public protocol TruthOrDareRouting: ObservableObject {
    // Stato
    var isTruthOrDareRound: Bool { get }
    var todIsChoosePhase: Bool { get }
    var todIsShowingTruth: Bool { get }
    var todIsShowingDare: Bool { get }
    
    // Dati UI
    var todTitle: String { get }                 // "OBBLIGO O VERITÀ?"
    var todCurrentPlayerName: String? { get }    // nome del giocatore
    var todPromptTitle: String { get }           // "OBBLIGO!" / "VERITÀ!"
    var todPromptText: String? { get }           // testo estratto
    
    // Azioni
    func todChooseTruth()
    func todChooseDare()
    func todNext()       // termina la visualizzazione, passa al prossimo giocatore / chiude il round
}

// MARK: - Onboarding
@MainActor
public protocol OnboardingRouting: ObservableObject {
    // Testi (puoi poi localizzare)
    var obIntroTitle: String { get }
    var obIntroSubtitle: String { get }
    var obStartTitle: String { get }

    var obWhoTitle: String { get }
    var obWhoOptions: [String] { get }

    var obMoodTitle: String { get }
    var obMoodOptions: [String] { get }

    // Azioni
    func obSkip()
    func obStart()
    func obSelectWho(_ index: Int)
    func obSelectMood(_ index: Int)
    func goBack()
}
