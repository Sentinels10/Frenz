import SwiftUI

struct TruthOrDareView<VM: TruthOrDareRouting & PlayingRouting>: View {
    @ObservedObject var vm: VM
    @Environment(\.locale) private var locale
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            VStack {
                header

                Spacer(minLength: 24)

                ZStack {
                    Group {
                        if vm.todIsChoosePhase {
                            choosePhase
                        } else {
                            resultPhase
                        }
                    }
                    .id(todContentID)
                    .transition(reduceMotion ? .opacity : .asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.96)).combined(with: .offset(y: 8)),
                        removal: .opacity
                    ))
                }
                .animation(reduceMotion ? nil : .spring(response: 0.32, dampingFraction: 0.72), value: todContentID)

                Spacer()

                // counter in basso come Playing
                Text(String.localizedStringWithFormat(
                    String.frenzLocalized("playing.counter", locale: locale),
                    vm.currentStep, vm.totalSteps
                ))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(counterColor)
                .padding(.bottom, 20)
            }
        }
        .navigationBarHidden(true)
    }

    private var todContentID: String {
        "\(vm.currentStep)|\(vm.todCurrentPlayerName ?? "")|\(vm.todIsChoosePhase)|\(vm.todPromptText ?? "")"
    }
    
    private func roomBackground(room: GameRoom) -> LinearGradient {
        switch room {
        case .party:
            return LinearGradient(colors: [Color(hex: 0x7D3CFF), Color(hex: 0x2C0066)],
                                  startPoint: .top, endPoint: .bottom)
        case .redRoom:
            return LinearGradient(colors: [Color(hex: 0xE61111), Color(hex: 0x5A0013)],
                                  startPoint: .top, endPoint: .bottom)
        case .darkRoom:
            return LinearGradient(colors: [Color(hex: 0x1C1C1C), Color.black],
                                  startPoint: .top, endPoint: .bottom)
        case .partner:
            return LinearGradient(colors: [Color.pink, Color.red.opacity(0.7)],
                                  startPoint: .top, endPoint: .bottom)
        case .roulette:
            return LinearGradient(colors: [Color.purple, Color.pink],
                                  startPoint: .top, endPoint: .bottom)
        case .games:
            return LinearGradient(colors: [Color.gray, Color.black],
                                  startPoint: .top, endPoint: .bottom)
        }
    }
    
    // MARK: - Header
    private var header: some View {
        ZStack {
            HStack {
                Button(action: { vm.backToRooms() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.white.opacity(0.18))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)

            Text(vm.playingTitle.uppercased())
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(.white.opacity(0.7))
                .padding(.top, 12)
        }
    }

    // MARK: - Choose phase (usa i colori della stanza)
    private var choosePhase: some View {
        VStack(spacing: 20) {
            Text(vm.todTitle)
                .font(.rammetto(size: 27))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .shadow(color: .black.opacity(0.28), radius: 4, y: 3)

            if let p = vm.todCurrentPlayerName {
                Text(p)
                    .font(.rammetto(size: 22))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.28), radius: 4, y: 3)
            }

            VStack(spacing: 14) {
                Button(action: { vm.todChooseDare() }) {
                    Text(String.frenzLocalized("tod.dare", locale: locale))
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.black.opacity(0.95))
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                }
                .padding(.horizontal, 24)

                Button(action: { vm.todChooseTruth() }) {
                    Text(String.frenzLocalized("tod.truth", locale: locale))
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                }
                .padding(.horizontal, 24)
            }
            .padding(.top, 6)
        }
    }

    // MARK: - Result phase (resta bianco/nero)
    private var resultPhase: some View {
        VStack(spacing: 18) {
            Text(vm.todPromptTitle)
                .font(.rammetto(size: 25))
                .foregroundColor(vm.todIsShowingTruth ? .black : .white)
                .padding(.top, 12)

            if let t = vm.todPromptText {
                Text(t)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(vm.todIsShowingTruth ? .black : .white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }

            Button(action: { vm.todNext() }) {
                Text(String.frenzLocalized("tod.done", locale: locale))
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(vm.todIsShowingTruth ? .black : .white)
                    .padding(.horizontal, 22).padding(.vertical, 10)
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .stroke(vm.todIsShowingTruth ? .black.opacity(0.6) : .white.opacity(0.6)))
            }
            .padding(.top, 10)
        }
    }

    // MARK: - Background
    private var background: LinearGradient {
        if vm.todIsChoosePhase {
            // schermata di scelta (usa i colori della stanza)
            if let room = vm.currentRoom {
                return roomBackground(room: room)
            }
            return LinearGradient(colors: [Color.red, Color.black],
                                  startPoint: .top, endPoint: .bottom)
        }
        if vm.todIsShowingTruth {
            // sfondo chiaro con gradiente più scuro in alto
            return LinearGradient(colors: [
                Color.white.opacity(0.85),   // parte alta un po’ più scura
                Color.white.opacity(0.95),
                Color.white
            ], startPoint: .top, endPoint: .bottom)
        } else {
            // sfondo scuro violaceo per obbligo
            return LinearGradient(colors: [Color(hex: 0x2B0B58), Color(hex: 0x0D0718)],
                                  startPoint: .top, endPoint: .bottom)
        }
    }

    private var counterColor: Color {
        vm.todIsShowingTruth ? .black.opacity(0.8) : .white.opacity(0.85)
    }

    // MARK: - Helpers gradient in base alla stanza
    private func gradientForRoom(_ room: GameRoom?) -> LinearGradient {
        let colors: [Color]
        switch room {
        case .some(.party):
            // viola Party
            colors = [Color(hex: 0x6E11E0), Color(hex: 0x22084B)]
        case .some(.redRoom):
            colors = [Color(hex: 0xE61111), Color(hex: 0x5A0013)]
        case .some(.darkRoom):
            colors = [Color(hex: 0x1B1B1F), Color(hex: 0x07070A)]
        case .some(.partner):
            colors = [Color(hex: 0xC71B4E), Color(hex: 0x4A0B1F)]
        case .some(.roulette):
            colors = [Color(hex: 0xFF53AC), Color(hex: 0x2B086F)]
        default:
            colors = [Color.black, Color.black]
        }
        return LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
    }
}
