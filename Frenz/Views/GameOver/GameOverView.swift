import SwiftUI
import UIKit
import StoreKit

/// Mostra la schermata di fine partita con grafica e CTA.
/// Il VM deve esporre almeno `backToRooms()` (già presente in GameViewModel).
struct GameOverView<VM: PlayingRouting>: View {
    @ObservedObject var vm: VM
    @State private var float = false
    @Environment(\.locale) private var locale

    var body: some View {
        ZStack {
            // Sfondo viola profondo
            LinearGradient(
                colors: [Color(hex: 0x3D0C7E), Color(hex: 0x170530)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            // Decorazioni responsive + safe loading
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height

                ZStack {
                    // in alto a sinistra
                    sticker("sticker_heart_fire",
                            width: w * 0.31,
                            rotation: -15,
                            x: w * 0.22,
                            y: h * 0.23,
                            dyAmp: 10,
                            delay: 0.0)

                    // banconote
                    sticker("sticker_money",
                            width: w * 0.20,
                            rotation: 12,
                            x: w * 0.46,
                            y: h * 0.20,
                            opacity: 0.9,
                            dyAmp: 6,
                            delay: 0.25)

                    // cocktail in alto a destra
                    sticker("sticker_cocktail",
                            width: w * 0.33,
                            rotation: -6,
                            x: w * 0.80,
                            y: h * 0.25,
                            dyAmp: 12,
                            delay: 0.45)

                    // ragazza/lips in basso a sinistra
                    sticker("who_girlz_right",
                            width: w * 0.38,
                            rotation: -10,
                            x: w * 0.20,
                            y: h * 0.78,
                            dyAmp: 10,
                            delay: 0.15)

                    // reggiseno in basso a destra
                    sticker("sticker_bra",
                            width: w * 0.31,
                            rotation: 10,
                            x: w * 0.78,
                            y: h * 0.84,
                            dyAmp: 9,
                            delay: 0.35)

                    // melanzana (sinistra, metà schermo)
                    sticker("sticker_eggplant",
                            width: w * 0.24,
                            rotation: 8,
                            x: w * 0.14,
                            y: h * 0.46,
                            opacity: 0.95,
                            dyAmp: 8,
                            delay: 0.2)

                    // occhiali (in alto verso destra)
                    sticker("sticker_glasses",
                            width: w * 0.18,
                            rotation: -5,
                            x: w * 0.62,
                            y: h * 0.15,
                            opacity: 0.9,
                            dyAmp: 5,
                            delay: 0.3)

                    // fiammella (destra, metà-basso)
                    sticker("sticker_flame",
                            width: w * 0.17,
                            rotation: 0,
                            x: w * 0.90,
                            y: h * 0.58,
                            opacity: 0.92,
                            dyAmp: 7,
                            delay: 0.4)

                    // collare con lucchetto (in basso centro-sinistra)
                    sticker("sticker_collar_lock",
                            width: w * 0.22,
                            rotation: 6,
                            x: w * 0.38,
                            y: h * 0.90,
                            opacity: 0.95,
                            dyAmp: 6,
                            delay: 0.5)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(false)
            }

            // Testo centrale
            VStack(spacing: 18) {
                Text("gameOver.part1")
                    .font(.rammetto(size: 54))
                    .kerning(1)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.35), radius: 8, y: 6)

                Text("gameOver.part2")
                    .font(.rammetto(size: 54))
                    .kerning(1)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.35), radius: 8, y: 6)
            }
        }
        .contentShape(Rectangle())                 // per il tap su tutta la schermata
        .onTapGesture { vm.requestPaywallAfterGameOver() } // tap = nuovo Superwall-aware flow
        .onAppear {
            float = true
            // Mostra il popup di rating subito sopra al GameOver (con un piccolo delay per sicurezza)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                requestAppReview()
            }
        }
    }
    // Chiede il popup nativo di rating sopra il GameOver
    private func requestAppReview() {
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else { return }

        if #available(iOS 18.0, *) {
            // StoreKit 2 (iOS 18+) — async API
            Task {
                try? await AppStore.requestReview(in: scene)
            }
        } else {
            // Fallback to StoreKit 1 on older iOS
            SKStoreReviewController.requestReview(in: scene)
        }
    }

    // MARK: - Helpers (asset-safe stickers + float animation)
    private func sticker(_ name: String,
                         width: CGFloat,
                         rotation: Double,
                         x: CGFloat,
                         y: CGFloat,
                         opacity: Double = 0.95,
                         dxAmp: CGFloat = 0,
                         dyAmp: CGFloat = 8,
                         delay: Double = 0.0) -> some View {
        Group {
            if let ui = UIImage(named: name) {
                Image(uiImage: ui)
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
            } else {
                #if DEBUG
                Text("missing \(name)")
                    .font(.caption2)
                    .foregroundColor(.red)
                #endif
            }
        }
        .frame(width: width)
        .rotationEffect(.degrees(rotation))
        .opacity(opacity)
        .position(x: x, y: y)
        .offset(x: dxAmp == 0 ? 0 : (float ? dxAmp : -dxAmp),
                y: dyAmp == 0 ? 0 : (float ? dyAmp : -dyAmp))
        .animation(
            .easeInOut(duration: 2.6)
                .repeatForever(autoreverses: true)
                .delay(delay),
            value: float
        )
        .allowsHitTesting(false)
    }
}
