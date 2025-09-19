import SwiftUI
import UIKit

struct OnboardingMoodView<VM: OnboardingRouting>: View {
    @ObservedObject var vm: VM
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            VStack(spacing: 18) {
                header

                Text(vm.obMoodTitle)
                    .font(.rammetto(size: 22))
                    .foregroundColor(.white)
                    .padding(.top, 8)

                Spacer(minLength: 8)

                VStack(spacing: 16) {
                    ForEach(Array(vm.obMoodOptions.enumerated()), id: \.offset) { i, title in
                        Button(action: { vm.obSelectMood(i) }) {
                            HStack {
                                Text(title)
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                                moodIcon(for: i, size: 30)
                                    .padding(.leading, 12)
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 22)
                            .frame(minHeight: 88)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.08))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
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
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }

    @ViewBuilder
    private func moodIcon(for index: Int, size: CGFloat) -> some View {
        // Suggested asset names; rename freely to match your Assets.xcassets
        let names  = ["mood_easy", "mood_party", "mood_spicy", "mood_secret"]
        let emojis = ["🙂",        "💀",          "🌶️",          "💋"]
        let i = max(0, min(index, names.count - 1))
        if let ui = UIImage(named: names[i]) {
            Image(uiImage: ui)
                .resizable()
                .renderingMode(.original)
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            Text(emojis[i])
                .font(.system(size: size))
        }
    }

    private var bg: LinearGradient {
        LinearGradient(colors: [Color(hex: 0x2B0B58), Color(hex: 0x18042F)],
                       startPoint: .top, endPoint: .bottom)
    }
}
