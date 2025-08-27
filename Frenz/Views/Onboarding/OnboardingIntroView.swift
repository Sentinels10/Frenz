import SwiftUI

struct OnboardingIntroView<VM: OnboardingRouting>: View {
    @ObservedObject var vm: VM

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            VStack(spacing: 22) {
                Spacer()

                // (qui potresti mettere un collage di sticker/immagini)
                Text(vm.obIntroTitle)
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Text(vm.obIntroSubtitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)

                Spacer()

                Button(action: { vm.obStart() }) {
                    Text(vm.obStartTitle)
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(colors: [Color(hex: 0xC86BFF), Color(hex: 0x9E45FF)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: Color(hex: 0xC86BFF, alpha: 0.6), radius: 18, x: 0, y: 10)
                        .padding(.horizontal, 24)
                }

                Button("Salta") { vm.obSkip() }
                    .foregroundColor(.white.opacity(0.8))
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.top, 6)

                Spacer(minLength: 16)
            }
        }
        .navigationBarHidden(true)
    }

    private var bg: LinearGradient {
        LinearGradient(colors: [Color(hex: 0x2B0B58), Color(hex: 0x18042F)],
                       startPoint: .top, endPoint: .bottom)
    }
}
