import SwiftUI

struct ContentView: View {
    @EnvironmentObject var gameVM: GameViewModel

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch gameVM.gameState {

            case .onboardingIntro:
                OnboardingIntroView(vm: gameVM)

            case .onboardingWho:
                OnboardingWhoView(vm: gameVM)

            case .onboardingMood:
                OnboardingMoodView(vm: gameVM)

            case .languageSelection:
                LanguageSelectionView(vm: gameVM)
                    .routeTransition(trigger: gameVM.gameState)

            case .playerSetup:
                PlayerSetupView(vm: gameVM)
                    .routeTransition(trigger: gameVM.gameState)

            case .roomSelection:
                RoomSelectionView(vm: gameVM)
                    .routeTransition(trigger: gameVM.gameState)

            case .gameSelection:
                GameSelectionView(vm: gameVM)
                    .routeTransition(trigger: gameVM.gameState)

            case .playing:
                if gameVM.isTruthOrDareRound {
                    TruthOrDareView(vm: gameVM)
                        .onAppear(perform: gameVM.todChoosePhaseBootstrapIfNeeded)
                        .routeTransition(trigger: gameVM.gameState)
                } else {
                    PlayingView(vm: gameVM)
                        .routeTransition(trigger: gameVM.gameState)
                }

            case .gameOver:
                GameOverView(vm: gameVM)
                    .routeTransition(trigger: gameVM.gameState)

            case .loading:
                LoadingView(vm: gameVM)
                    .routeTransition(trigger: gameVM.gameState)
            }
        }
    }
}

// MARK: - Transizione: anima solo quando cambia il trigger (es. gameState)
private extension View {
    func routeTransition<T: Equatable>(trigger: T) -> some View {
        self
            .transition(.opacity.combined(with: .move(edge: .trailing)))
            .animation(.easeInOut(duration: 0.25), value: trigger)
    }
}

#Preview {
    ContentViewPreview()
}

private struct ContentViewPreview: View {
    @StateObject private var languageManager = LanguageManager()
    @StateObject private var gameVM = GameViewModel()

    var body: some View {
        ContentView()
            .environmentObject(gameVM)
            .environmentObject(languageManager)
            .environment(\.locale, languageManager.locale)
            .preferredColorScheme(.dark)
            .onAppear {
                gameVM.languageManager = languageManager
            }
    }
}
