import SwiftUI

struct LoadingView: View {
    @ObservedObject var vm: GameViewModel

    var body: some View {
        ZStack {
            // Sfondo viola (come room selection)
            LinearGradient(
                colors: [Color(red: 34/255, green: 0/255, blue: 68/255),
                         Color(red: 18/255, green: 0/255, blue: 36/255)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer().frame(height: 40)

                // Icon/emoji top (puoi mettere una tua Asset)
                Text("😈")
                    .font(.system(size: 64))

                Text("Pronti? lasciaci cucinare…")
                    .font(.system(size: 24, weight: .heavy))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)

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
            .fill(Color.white.opacity(0.1))
            .overlay(
                Text(currentSnippet)
                    .font(.system(size: 20, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding(20)
            )
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 8)
    }

    private var currentSnippet: String {
        guard !vm.loadingSnippets.isEmpty else { return "Prepariamo la serata…" }
        return vm.loadingSnippets[min(vm.carouselIndex, vm.loadingSnippets.count - 1)]
    }
}
