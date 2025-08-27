import SwiftUI

struct OnboardingWhoView<VM: OnboardingRouting>: View {
    @ObservedObject var vm: VM

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            VStack(spacing: 18) {
                header

                Text(vm.obWhoTitle)
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundColor(.white)
                    .padding(.top, 8)

                Spacer(minLength: 8)

                VStack(spacing: 14) {
                    ForEach(Array(vm.obWhoOptions.enumerated()), id: \.offset) { i, title in
                        Button(action: { vm.obSelectWho(i) }) {
                            HStack {
                                Text(title)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(Color.white.opacity(0.08))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
                            )
                            .padding(.horizontal, 20)
                        }
                    }
                }

                Spacer()

                Button("Salta") { vm.obSkip() }
                    .foregroundColor(.white.opacity(0.8))
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.bottom, 12)
            }
        }
        .navigationBarHidden(true)
    }

    private var header: some View {
        HStack {
            Button(action: { vm.obSkip() }) {
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
    }

    private var bg: LinearGradient {
        LinearGradient(colors: [Color(hex: 0x2B0B58), Color(hex: 0x18042F)],
                       startPoint: .top, endPoint: .bottom)
    }
}
