import SwiftUI

struct ContentView: View {
    @EnvironmentObject var gameVM: GameViewModel
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

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
                GameSelectionView_Placeholder()
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

            case .paywall:
                // PaywallView rimosso: reindirizzo alla selezione stanze
                RoomSelectionView(vm: gameVM)
                    .routeTransition(trigger: gameVM.gameState)

            case .loading:
                LoadingView(vm: gameVM)
                    .routeTransition(trigger: gameVM.gameState)
            }
        }
        .onAppear { gameVM.subscriptionManager = subscriptionManager }
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

// MARK: - PLACEHOLDERS (se ti servono ancora)
private struct GameSelectionView_Placeholder: View { var body: some View { PlaceholderScreen(title: "Game Selection") } }
private struct PlayingView_Placeholder: View       { var body: some View { PlaceholderScreen(title: "Playing") } }
private struct GameOverView_Placeholder: View      { var body: some View { PlaceholderScreen(title: "Game Over") } }

private struct PlaceholderScreen: View {
    let title: String
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 10) {
                Text(title).foregroundColor(.white).font(.system(size: 24, weight: .bold))
                Text("Sostituisci con la view reale").foregroundColor(.white.opacity(0.6)).font(.system(size: 14))
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(GameViewModel())
        .environmentObject(SubscriptionManager()) // necessario per le preview
        .preferredColorScheme(.dark)
}
