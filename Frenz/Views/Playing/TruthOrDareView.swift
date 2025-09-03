import SwiftUI

struct TruthOrDareView<VM: TruthOrDareRouting & PlayingRouting>: View {
    @ObservedObject var vm: VM

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            VStack {
                header

                Spacer(minLength: 24)

                if vm.todIsChoosePhase {
                    choosePhase
                } else {
                    resultPhase
                }

                Spacer()

                // counter in basso come Playing
                Text("\(vm.currentStep)/\(vm.totalSteps)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(counterColor)
                    .padding(.bottom, 20)
            }
        }
        .navigationBarHidden(true)
    }

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

    private var choosePhase: some View {
        VStack(spacing: 20) {
            Text(vm.todTitle)
                .font(.system(size: 32, weight: .heavy))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            if let p = vm.todCurrentPlayerName {
                Text(p)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(spacing: 14) {
                Button(action: { vm.todChooseDare() }) {
                    Text(NSLocalizedString("OBBLIGO", comment: ""))
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.black.opacity(0.95))
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                }
                .padding(.horizontal, 24)

                Button(action: { vm.todChooseTruth() }) {
                    Text(NSLocalizedString("VERITÀ", comment: ""))
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

    private var resultPhase: some View {
        VStack(spacing: 18) {
            Text(vm.todPromptTitle)
                .font(.system(size: 28, weight: .heavy))
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
                Text(NSLocalizedString("FATTO", comment: ""))
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(vm.todIsShowingTruth ? .black : .white)
                    .padding(.horizontal, 22).padding(.vertical, 10)
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .stroke(vm.todIsShowingTruth ? .black.opacity(0.6) : .white.opacity(0.6)))
            }
            .padding(.top, 10)
        }
    }

    private var background: LinearGradient {
        if vm.todIsChoosePhase {
            return LinearGradient(colors: [Color(hex: 0xE61111), Color(hex: 0x5A0013)],
                                  startPoint: .top, endPoint: .bottom)
        }
        if vm.todIsShowingTruth {
            // sfondo chiaro
            return LinearGradient(colors: [Color.white, Color.white.opacity(0.96)],
                                  startPoint: .top, endPoint: .bottom)
        } else {
            // sfondo scuro violaceo
            return LinearGradient(colors: [Color(hex: 0x2B0B58), Color(hex: 0x0D0718)],
                                  startPoint: .top, endPoint: .bottom)
        }
    }

    private var counterColor: Color {
        vm.todIsShowingTruth ? .black.opacity(0.8) : .white.opacity(0.85)
    }
}
