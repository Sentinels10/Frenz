import SwiftUI
import UIKit

struct OnboardingMoodView<VM: OnboardingRouting>: View {
    @ObservedObject var vm: VM
    private let cardHeight: CGFloat = 104
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

                Text(vm.obMoodTitle)
                    .font(.rammetto(size: 23))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 28)
                    .padding(.top, 4)

                Spacer(minLength: 12)

                // NOTE: Asset names expected: ic_onb_who_girlz, ic_onb_who_boyz (no asset for Mix)
                VStack(spacing: 10) {
                    ForEach(Array(vm.obMoodOptions.enumerated()), id: \.offset) { i, title in
                        Button(action: { vm.obSelectMood(i) }) {
                            if i == 0 || i == 1 {
                                ZStack {
                                    // Big decorative icons UNDER the content, clipped by the rounded rect
                                    HStack {
                                        (asset(i == 0 ? "sticker_cocktail" : "sticker_heart_fire") ?? Image(systemName: "photo"))
                                            .renderingMode(.original)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: i == 0 ? 170 : 120, height: i == 0 ? 170 : 120)
                                            .offset(
                                                x: i == 0 ? 20 : -20,
                                                y: i == 0 ? 22 : 14
                                            )
                                        Spacer(minLength: 0)
                                        if i == 0 {
                                            (asset("sticker_glasses") ?? Image(systemName: "photo"))
                                                .renderingMode(.original)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 280, height: 280)
                                                .offset(x: 34)
                                                .allowsHitTesting(false)
                                        } else {
                                            (asset("sticker_bra") ?? Image(systemName: "photo"))
                                                .renderingMode(.original)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 200, height: 200)
                                                .offset(x: 46, y: 32)
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
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .shadow(color: .black.opacity(0.28), radius: 3, x: 0, y: 2)
                                            .padding(.horizontal, 22)
                                        Spacer()
                                    }
                                }
                                .frame(width: UIScreen.main.bounds.width - horizontalPad * 2, height: cardHeight)
                                .background(
                                    RoundedRectangle(cornerRadius: 22)
                                        .fill(
                                            i == 0
                                            ? LinearGradient(
                                                colors: [
                                                    Color(hex: 0x1DB2FF), // azzurro
                                                    Color(hex: 0x6BE0D6), // verdino
                                                    Color(hex: 0xFFE252)  // giallo
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                            : LinearGradient(
                                                colors: [
                                                    Color(hex: 0xFF2E2E), // rosso
                                                    Color(hex: 0xFF58EF)  // rosa
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 22))
                                .contentShape(RoundedRectangle(cornerRadius: 22))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22)
                                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                                )
                            } else {
                                // MIX — aggiungi due icone laterali come negli altri due
                                ZStack {
                                    // Big decorative icons UNDER the content, clipped by the rounded rect
                                    HStack {
                                        (asset("sticker_angry") ?? Image(systemName: "photo"))
                                            .renderingMode(.original)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 150, height: 150)
                                            .offset(x: -6, y: 14)
                                        Spacer(minLength: 0)
                                        (asset("sticker_mouth") ?? Image(systemName: "photo"))
                                            .renderingMode(.original)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 180, height: 180)
                                            .offset(x: 8, y: 18)
                                            .allowsHitTesting(false)
                                    }
                                    .padding(.horizontal, 8)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: cardHeight)
                                    .clipped()
                                    .allowsHitTesting(false)

                                    // Title
                                    HStack {
                                        Spacer()
                                        Text(title)
                                            .font(.trebuchet(size: 26))
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 1)
                                            .padding(.horizontal, 22)
                                        Spacer()
                                    }
                                }
                                .frame(width: UIScreen.main.bounds.width - horizontalPad * 2, height: cardHeight)
                                .background(
                                    RoundedRectangle(cornerRadius: 22)
                                        .fill(
                                            LinearGradient(colors: [
                                                Color(hex: 0xFF1919), // rosso
                                                Color(hex: 0xFF58EF), // rosa
                                                Color(hex: 0xFFE252), // giallo
                                                Color(hex: 0x57EFFF)  // azzurro
                                            ], startPoint: .leading, endPoint: .trailing)
                                        )
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
                    .foregroundColor(.white.opacity(0.2))
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.bottom, 12)
            }
        }
        .navigationBarHidden(true)
    }

    private var header: some View {
        HStack {
            Button(action: { vm.goBack() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(10)
            }
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.top, 10)
    }

    private var bg: LinearGradient {
        LinearGradient(colors: [Color(hex: 0x2B0B58), Color(hex: 0x18042F)],
                       startPoint: .top, endPoint: .bottom)
    }
}
