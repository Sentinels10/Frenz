import SwiftUI

/// Mostra la schermata di fine partita con grafica e CTA.
/// Il VM deve esporre almeno `backToRooms()` (già presente in GameViewModel).
struct GameOverView<VM: PlayingRouting>: View {
    @ObservedObject var vm: VM

    var body: some View {
        ZStack {
            // Sfondo viola profondo
            LinearGradient(
                colors: [Color(hex: 0x3D0C7E), Color(hex: 0x170530)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            // Decorazioni (sostituisci i nomi con i tuoi asset)
            ZStack {
                Image("sticker_heart_fire")
                    .resizable().scaledToFit()
                    .frame(width: 110)
                    .rotationEffect(.degrees(-15))
                    .opacity(0.95)
                    .position(x: 86, y: 180)

                Image("sticker_money")
                    .resizable().scaledToFit()
                    .frame(width: 70)
                    .rotationEffect(.degrees(12))
                    .opacity(0.9)
                    .position(x: 205, y: 160)

                Image("sticker_cocktail")
                    .resizable().scaledToFit()
                    .frame(width: 120)
                    .rotationEffect(.degrees(-6))
                    .opacity(0.95)
                    .position(x: 310, y: 190)

                Image("sticker_lips_lock")
                    .resizable().scaledToFit()
                    .frame(width: 150)
                    .rotationEffect(.degrees(-10))
                    .opacity(0.95)
                    .position(x: 85, y: 560)

                Image("sticker_bra")
                    .resizable().scaledToFit()
                    .frame(width: 120)
                    .rotationEffect(.degrees(10))
                    .opacity(0.95)
                    .position(x: 300, y: 600)
            }
            .allowsHitTesting(false)

            // Testo centrale
            VStack(spacing: 18) {
                Text(String(localized: "gameOver.part1"))
                    .font(.rammetto(size: 54))
                    .kerning(1)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.35), radius: 8, y: 6)

                Text(String(localized: "gameOver.part2"))
                    .font(.rammetto(size: 54))
                    .kerning(1)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.35), radius: 8, y: 6)
            }
        }
        .contentShape(Rectangle())                 // per il tap su tutta la schermata
        .onTapGesture { vm.backToRooms() }         // tap = torna alle stanze
    }
}
