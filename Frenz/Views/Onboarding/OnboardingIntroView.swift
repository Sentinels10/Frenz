import SwiftUI
import UIKit

struct OnboardingIntroView<VM: OnboardingRouting>: View {
    @ObservedObject var vm: VM

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                bg.ignoresSafeArea()

                VStack(spacing: 22) {
                    Spacer(minLength: 8)

                    // Collage responsive: max 380 pt or 42% of available height
                    let collageH = min(380, proxy.size.height * 0.42)

                    stickerWall
                        .frame(height: collageH)
                        .padding(.horizontal, 12)
                        .offset(y: 24)

                    Spacer(minLength: 8)

                    Text(vm.obIntroTitle)
                        .font(.rammetto(size: 23))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .layoutPriority(2)
                        .padding(.horizontal, 24)

                    Text(vm.obIntroSubtitle)
                        .font(.system(size: 16, weight: .semibold))
                        .lineSpacing(5)
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .layoutPriority(1)
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
                                    .fill(Color(hex: 0x210041))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 22)
                                    .strokeBorder(LinearGradient.frenzRainbow(), lineWidth: 3)
                            )
                            .shadow(color: Color.black.opacity(0.45), radius: 20, x: 0, y: 12)
                            .padding(.horizontal, 24)
                    }

                    Button(String(localized: "onboarding.skip")) { vm.obSkip() }
                        .foregroundColor(.white.opacity(0.2))
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.top, 6)

                    Spacer(minLength: 16)
                }
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
    private func sticker(_ name: String,
                         fallbackEmoji: String,
                         size: CGFloat,
                         rotation: Angle = .degrees(0),
                         x: CGFloat,
                         y: CGFloat) -> some View {
        icon(name, fallbackEmoji: fallbackEmoji, size: size)
            .rotationEffect(rotation)
            .offset(x: x, y: y)
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
                    .offset(x: -size.width * 0.52 + l.dx, y: l.dy)
            }
            if let r = trailingIcon {
                icon(r.name, fallbackEmoji: r.emoji, size: r.size)
                    .offset(x:  size.width * 0.52 + r.dx, y: r.dy)
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
                // 1) 1v1! (in alto, centrata leggermente a destra)
                card(
                    text: String(localized: "onboarding.intro.tile.1v1"),
                    colors: [Color(hex: 0xF869FF), Color(hex: 0xA030FF)],
                    textSize: 16,
                    rotation: .degrees(-5),
                    size: .init(width: w * 0.34, height: h * 0.20),
                    offset: .init(width: w * 0.42, height: -h * 0.15)
                )

                // 2) Preferiresti? (centrata, più grande)
                card(
                    text: String(localized: "onboarding.intro.tile.wyr"),
                    colors: [Color(hex: 0xFF5E57), Color(hex: 0xE43A2E)],
                    textSize: 18,
                    rotation: .degrees(10),
                    size: .init(width: w * 0.65, height: h * 0.24),
                    offset: .init(width: 0, height:  h * 0.15)
                )

                // 3) Obbligo o verità? (subito sotto, centrata)
                card(
                    text: String(localized: "onboarding.intro.tile.tod"),
                    colors: [Color(hex: 0x7F66FF), Color(hex: 0x5A33FF)],
                    textSize: 18,
                    rotation: .degrees(-15),
                    size: .init(width: w * 0.56, height: h * 0.28),
                    offset: .init(width:  w * 0.40, height: h * 0.36)
                )

                // 4) Non ho mai… (più in basso, leggermente a sinistra)
                card(
                    text: String(localized: "onboarding.intro.tile.nhie"),
                    colors: [Color(hex: 0xFF9C33), Color(hex: 0xFF6A00)],
                    textSize: 18,
                    rotation: .degrees(12),
                    size: .init(width: w * 0.62, height: h * 0.24),
                    offset: .init(width: -w * 0.01, height: h * 0.58)
                )

                // ===== Standalone stickers (independent from the tiles) =====
                // Top-left clouds
                sticker("sticker_clouds", fallbackEmoji: "☁️", size: h * 0.25, rotation: .degrees(0), x:  w * 0.14, y:  h * 0.40)
                // Small flame near WYR left edge
                sticker("sticker_flame", fallbackEmoji: "🔥", size: h * 0.18, rotation: .degrees(0), x: -w * 0.30, y:  -h * 0.02)
                // Banana on the right of WYR
                sticker("sticker_banana", fallbackEmoji: "🍌", size: h * 0.20, rotation: .degrees(12), x:  w * 0.30, y: -h * 0.04)
                
                // Devil head to the right of ToD card
                sticker("sticker_devil", fallbackEmoji: "😈", size: h * 0.22, rotation: .degrees(0), x:  w * 0.62, y:  h * 0.32)
                // Angry face near NHIE left
                sticker("sticker_angry", fallbackEmoji: "😤", size: h * 0.21, rotation: .degrees(0), x: -w * 0.29, y:  h * 0.52)
                // Bra to the lower-right area
                sticker("sticker_bra", fallbackEmoji: "💗", size: h * 0.22, rotation: .degrees(-8), x:  w * 0.25, y:  h * 0.68)
            }
        }
    }
}
