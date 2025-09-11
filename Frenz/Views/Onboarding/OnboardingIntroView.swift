import SwiftUI
import UIKit

struct OnboardingIntroView<VM: OnboardingRouting>: View {
    @ObservedObject var vm: VM

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            VStack(spacing: 22) {
                Spacer(minLength: 8)

                // collage di card + sticker
                stickerWall
                    .frame(height: 320)
                    .padding(.horizontal, 12)

                Spacer(minLength: 8)

                Text(vm.obIntroTitle)
                    .font(.rammetto(size: 26))
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
                        .font(.rammetto(size: 20))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(Color.white.opacity(0.10))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(
                                    LinearGradient(colors: [
                                        Color(hex: 0xFF5F6D), // pink
                                        Color(hex: 0xFFC371), // orange
                                        Color(hex: 0x62FF8E)  // green
                                    ], startPoint: .leading, endPoint: .trailing),
                                    lineWidth: 3
                                )
                        )
                        .shadow(color: Color.black.opacity(0.45), radius: 20, x: 0, y: 12)
                        .padding(.horizontal, 24)
                }

                Button(String(localized: "onboarding.skip")) { vm.obSkip() }
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

    // MARK: - Intro collage (card + sticker)
    @State private var dummyAnim: Bool = false

    /// Ritorna un'icona da asset se presente (usa nomi descrittivi es: "sticker_banana", "sticker_flame"), altrimenti un'emoji di fallback.
    @ViewBuilder
    private func icon(_ name: String, fallbackEmoji: String, size: CGFloat) -> some View {
        if let ui = UIImage(named: name) {
            Image(uiImage: ui)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 6)
        } else {
            Text(fallbackEmoji)
                .font(.system(size: size))
        }
    }

    @ViewBuilder
    private func card(text: String,
                      colors: [Color],
                      textSize: CGFloat = 18,
                      rotation: Angle,
                      size: CGSize,
                      offset: CGSize,
                      leadingIcon: (name: String, emoji: String, size: CGFloat, dx: CGFloat, dy: CGFloat)? = nil,
                      trailingIcon: (name: String, emoji: String, size: CGFloat, dx: CGFloat, dy: CGFloat)? = nil) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: colors.last?.opacity(0.45) ?? .black.opacity(0.3), radius: 16, x: 0, y: 10)

            HStack {
                Spacer(minLength: 0)
                Text(text)
                    .font(.rammetto(size: textSize))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 18)

            if let l = leadingIcon {
                icon(l.name, fallbackEmoji: l.emoji, size: l.size)
                    .offset(x: -size.width * 0.36 + l.dx, y: l.dy)
            }
            if let r = trailingIcon {
                icon(r.name, fallbackEmoji: r.emoji, size: r.size)
                    .offset(x:  size.width * 0.36 + r.dx, y: r.dy)
            }
        }
        .frame(width: size.width, height: size.height)
        .rotationEffect(rotation)
        .offset(x: offset.width, y: offset.height)
    }

    private var stickerWall: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                // 1) 1v1! (in alto, leggermente a sinistra)
                card(
                    text: "1v1!",
                    colors: [Color(hex: 0xF869FF), Color(hex: 0xA030FF)],
                    textSize: 16,
                    rotation: .degrees(10),
                    size: .init(width: w * 0.44, height: h * 0.22),
                    offset: .init(width:  w * 0.14, height: -h * 0.32),
                    leadingIcon: ("sticker_clouds", "☁️", h * 0.20, -10, 6)
                )

                // 2) Preferiresti? (sotto la prima, verso sinistra)
                card(
                    text: "PREFERIRESTI?",
                    colors: [Color(hex: 0xFF5E57), Color(hex: 0xE43A2E)],
                    textSize: 18,
                    rotation: .degrees(-10),
                    size: .init(width: w * 0.76, height: h * 0.30),
                    offset: .init(width: -w * 0.16, height: -h * 0.12),
                    leadingIcon: ("sticker_flame", "🔥", h * 0.16, -10, -2),
                    trailingIcon: ("sticker_banana", "🍌", h * 0.24, 10, -2)
                )

                // 3) Obbligo o verità? (centrata più in basso, ruotata in senso opposto)
                card(
                    text: "OBBLIGO\nO VERITÀ?",
                    colors: [Color(hex: 0x7F66FF), Color(hex: 0x5A33FF)],
                    textSize: 18,
                    rotation: .degrees(12),
                    size: .init(width: w * 0.64, height: h * 0.32),
                    offset: .init(width:  w * 0.12, height:  h * 0.02),
                    trailingIcon: ("sticker_devil", "😈", h * 0.22, 8, -2)
                )

                // 4) Non ho mai… (in basso a sinistra)
                card(
                    text: "NON\nHO MAI…",
                    colors: [Color(hex: 0xFF9C33), Color(hex: 0xFF6A00)],
                    textSize: 18,
                    rotation: .degrees(-7),
                    size: .init(width: w * 0.66, height: h * 0.30),
                    offset: .init(width: -w * 0.20, height:  h * 0.18),
                    leadingIcon: ("sticker_angry", "😤", h * 0.20, -8, -6),
                    trailingIcon: ("sticker_bra", "💗", h * 0.18, 2, 6)
                )
            }
        }
    }
}
