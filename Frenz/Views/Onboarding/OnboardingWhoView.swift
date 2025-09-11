import SwiftUI
import UIKit

struct OnboardingWhoView<VM: OnboardingRouting>: View {
    @ObservedObject var vm: VM
    private let cardHeight: CGFloat = 84
    private let horizontalPad: CGFloat = 22

    // Fallback-safe asset loader (returns nil if the asset is missing or the name is wrong)
    private func asset(_ name: String) -> Image? {
        if let ui = UIImage(named: name) {
            return Image(uiImage: ui)
        }
        return nil
    }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            VStack(spacing: 22) {
                header

                Text(vm.obWhoTitle)
                    .font(.rammetto(size: 28))
                    .foregroundColor(.white)
                    .padding(.top, 4)

                Spacer(minLength: 12)

                // NOTE: Asset names expected: ic_onb_who_girlz, ic_onb_who_boyz (no asset for Mix)
                VStack(spacing: 10) {
                    ForEach(Array(vm.obWhoOptions.enumerated()), id: \.offset) { i, title in
                        Button(action: { vm.obSelectWho(i) }) {
                            if i == 0 || i == 1 {
                                ZStack {
                                    // Big decorative icons UNDER the content, clipped by the rounded rect
                                    HStack {
                                        (asset(i == 0 ? "who_girlz_left" : "sticker_banana") ?? Image(systemName: "photo"))
                                            .renderingMode(.original)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: i == 0 ? 230 : 145, height: i == 0 ? 230 : 145)
                                            .offset(
                                                x: i == 0 ? 30 : -30,
                                                y: i == 0 ? 30 : 20
                                            )
                                        Spacer(minLength: 0)
                                        if i == 0 {
                                            (asset("who_girlz_right") ?? Image(systemName: "photo"))
                                                .renderingMode(.original)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 340, height: 340)
                                                .offset(x: 40)
                                                .allowsHitTesting(false)
                                        } else {
                                            (asset("who_boyz_right") ?? Image(systemName: "photo"))
                                                .renderingMode(.original)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 250, height: 250)
                                                .offset(x: 55, y: 40)
                                                .allowsHitTesting(false)
                                        }
                                    }
                                    .padding(.horizontal, 8)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: cardHeight)
                                    .clipped()
                                    .allowsHitTesting(false)

                                    // Title on top
                                    HStack {
                                        Spacer()
                                        Text(title)
                                            .font(.trebuchet(size: 26))
                                            .foregroundColor(.white)
                                            .shadow(color: .black.opacity(0.28), radius: 3, x: 0, y: 2)
                                            .padding(.horizontal, 22)
                                        Spacer()
                                    }
                                }
                                .frame(width: UIScreen.main.bounds.width - horizontalPad * 2, height: cardHeight)
                                .background(
                                    RoundedRectangle(cornerRadius: 22)
                                        .fill(i == 0
                                              ? LinearGradient(colors: [
                                                    Color(hex: 0xFF5EB5),
                                                    Color(hex: 0xFF6AB0),
                                                    Color(hex: 0xF76BD5)
                                                ], startPoint: .leading, endPoint: .trailing)
                                              : LinearGradient(colors: [
                                                    Color(hex: 0xFFB64D),
                                                    Color(hex: 0xFF6E7F),
                                                    Color(hex: 0x6FC3FF)
                                                ], startPoint: .leading, endPoint: .trailing))
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 22))
                                .contentShape(RoundedRectangle(cornerRadius: 22))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22)
                                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                                )
                            } else {
                                // MIX — NO ICON, centered text only
                                HStack {
                                    Spacer()
                                    Text(title)
                                        .font(.trebuchet(size: 26))
                                        .foregroundColor(.white)
                                        .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 1)
                                    Spacer()
                                }
                                .frame(width: UIScreen.main.bounds.width - horizontalPad * 2, height: cardHeight)
                                .background(
                                    RoundedRectangle(cornerRadius: 22)
                                        .fill(LinearGradient(colors: [
                                            Color(hex: 0xFF4D96),
                                            Color(hex: 0xFFB86E),
                                            Color(hex: 0x5ED3FF),
                                            Color(hex: 0x7CF2C7)
                                        ], startPoint: .leading, endPoint: .trailing))
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 22))
                                .contentShape(RoundedRectangle(cornerRadius: 22))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22)
                                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                                )
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer()

                Button(String(localized: "onboarding.skip")) { vm.obSkip() }
                    .foregroundColor(.white.opacity(0.9))
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
