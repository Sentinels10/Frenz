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
                GameSelectionView_Placeholder()
                    .routeTransition(trigger: gameVM.gameState)

            case .playing:
                PlayingView(vm: gameVM)
                    .routeTransition(trigger: gameVM.gameState)

            case .gameOver:
                GameOverView_Placeholder()
                    .routeTransition(trigger: gameVM.gameState)

            case .paywall:
                PaywallView(vm: gameVM)
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

// MARK: - PLACEHOLDERS (se ti servono ancora)
private struct GameSelectionView_Placeholder: View { var body: some View { PlaceholderScreen(title: "Game Selection") } }
private struct PlayingView_Placeholder: View       { var body: some View { PlaceholderScreen(title: "Playing") } }
private struct GameOverView_Placeholder: View      { var body: some View { PlaceholderScreen(title: "Game Over") } }
private struct PaywallView_Placeholder: View       { var body: some View { PlaceholderScreen(title: "Paywall") } }

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
        .preferredColorScheme(.dark)
}
