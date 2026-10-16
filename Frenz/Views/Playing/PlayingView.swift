import SwiftUI

struct PlayingView<VM: PlayingRouting>: View {
    @ObservedObject var vm: VM
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            backgroundGradient.ignoresSafeArea()

            VStack {
                header

                Spacer(minLength: 24)

                // Centro: titolo (special o player) + azione renderizzata
                ZStack {
                    cardText
                        .id(vm.currentStep)
                        .transition(cardTransition)
                }
                .animation(cardAnimation, value: vm.currentStep)

                Spacer()

                // Counter in basso
                Text("\(vm.currentStep)/\(vm.totalSteps)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.bottom, 20)
            }
        }
        .navigationBarHidden(true)
        .contentShape(Rectangle())
        .onTapGesture {
            HapticFeedback.lightTap()
            vm.goNext()
        }
        .onAppear { vm.onPlayingAppear() }
    }

    private var cardText: some View {
        VStack(spacing: 18) {
            if vm.isSpecialCurrent, let special = vm.currentSpecialTitle {
                cardTitle(special)
            } else if let player = vm.currentPlayerNameTitle, !player.isEmpty {
                cardTitle(player)
            }

            if let text = vm.currentRenderedActionText {
                Text(text)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .shadow(color: .black.opacity(0.15), radius: 3, y: 2)
            }
        }
    }

    private func cardTitle(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.rammetto(size: 25))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 24)
            .shadow(color: .black.opacity(0.28), radius: 4, y: 3)
    }

    private var cardTransition: AnyTransition {
        reduceMotion ? .opacity : .asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.96)).combined(with: .offset(y: 8)),
            removal: .opacity
        )
    }

    private var cardAnimation: Animation? {
        reduceMotion ? nil : .spring(response: 0.32, dampingFraction: 0.72)
    }

    // MARK: Header (back + nome modalità in grigino)
    private var header: some View {
        ZStack {
            HStack {
                Button(action: { vm.backToRooms() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(10)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)

            Text(roomTitle.uppercased())
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(.white.opacity(0.7))
                .padding(.top, 12)
        }
    }

    // MARK: Gradient per modalità
    private var backgroundGradient: LinearGradient {
        if let id = vm.currentSpecialGameID,
           let colors = SpecialGamePalette.colors(for: id) {
            return LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
        }

        if vm.currentRoom == .games,
           let game = vm.currentGame,
           let colors = SpecialGamePalette.colors(for: game) {
            return LinearGradient(colors: colors,
                                  startPoint: .top, endPoint: .bottom)
        }

        let colors: [Color]
        switch vm.currentRoom {
        case .some(.party):
            colors = [Color(hex: 0x6E11E0), Color(hex: 0x22084B)]
        case .some(.redRoom):
            colors = [Color(hex: 0xE61111), Color(hex: 0x5A0013)]
        case .some(.darkRoom):
            colors = [Color(hex: 0x1B1B1F), Color(hex: 0x07070A)]
        case .some(.partner):
            colors = [Color(hex: 0xC71B4E), Color(hex: 0x4A0B1F)]
        case .some(.roulette):
            colors = [Color(hex: 0xFF3CAC), Color(hex: 0x2B086F)]
        default:
            colors = [Color.black, Color.black]
        }
        return LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
    }

    private var roomTitle: String {
        vm.playingTitle
    }
}
