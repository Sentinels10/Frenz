import SwiftUI

struct LoadingView: View {
    @ObservedObject var vm: GameViewModel

    // MARK: - Asset-aware icon helpers (fallback to emoji if asset missing)
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

    var body: some View {
        ZStack {
            // Sfondo viola (come room selection)
            LinearGradient(
                colors: [Color(red: 34/255, green: 0/255, blue: 68/255),
                         Color(red: 18/255, green: 0/255, blue: 36/255)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
            
            decorations

            VStack(spacing: 24) {
                Spacer().frame(height: 40)

                // Icon/emoji top (uses asset if available, else emoji)
                icon("sticker_devil", fallbackEmoji: "😈", size: 120)
                    .accessibilityHidden(true)

                Text(String(localized: "loading.title"))
                    .font(.rammetto(size: 30))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                // Progress bar custom ~4s
                progressBar

                // Card con carosello azioni casuali
                carouselCard

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .navigationBarHidden(true)
    }

    private var progressBar: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(Color.white.opacity(0.12))
                .frame(height: 8)
            Capsule()
                .fill(LinearGradient(colors: [.red, .orange, .blue], startPoint: .leading, endPoint: .trailing))
                .frame(width: max(8, CGFloat(vm.loadingProgress) * UIScreen.main.bounds.width * 0.70), height: 8)
                .animation(.linear(duration: 0.04), value: vm.loadingProgress)
        }
        .padding(.horizontal, 8)
    }

    private var carouselCard: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.white.opacity(0.38))
            .overlay(
                Text(currentSnippet)
                    .font(.system(size: 20, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding(20)
            )
            // Clouds sticker posizionato SOTTO la tile (sborda in basso)
            .background(alignment: .bottom) {
                icon("sticker_clouds", fallbackEmoji: "☁️", size: 160)
                    .rotationEffect(.degrees(8))
                    .opacity(0.95)
                    .offset(x: 150, y: 84) // abbassato leggermente
                    .allowsHitTesting(false)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 8)
    }

    private var currentSnippet: String {
        guard !vm.loadingSnippets.isEmpty else { return String(localized: "loading.fallback") }
        return vm.loadingSnippets[min(vm.carouselIndex, vm.loadingSnippets.count - 1)]
    }
    
    // MARK: - Decorative icons (asset-aware like IntroView)
    private var decorations: some View {
        GeometryReader { geo in
            ZStack {
                // Bottom-left: collar/lock
                icon("sticker_collar_lock", fallbackEmoji: "🔒", size: 92)
                    .rotationEffect(.degrees(-12))
                    .opacity(0.95)
                    .position(x: 64,
                              y: geo.size.height * 0.66) // abbassato un po'

                // Bottom center: bra
                icon("sticker_bra", fallbackEmoji: "💗", size: 120)
                    .opacity(0.95)
                    .position(x: geo.size.width / 2,
                              y: geo.size.height - (8 + 36))  // abbassato leggermente
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
    }
}
