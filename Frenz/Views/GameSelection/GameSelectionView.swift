import SwiftUI


struct GameSelectionView<ViewModel: GameSelectionRouting>: View {
    @ObservedObject var vm: ViewModel

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(vm.availableGames) { game in
                            GameCard(
                                title: vm.displayName(for: game),
                                subtitle: vm.displaySubtitle(for: game),
                                isSelected: vm.selectedGame == game,
                                onTap: { vm.selectedGame = game }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 16)
                }

                footer
            }
        }
    }

    private var header: some View {
        HStack {
            Button(action: { vm.goBackToRoomSelection() }) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                    Text(vm.backButtonTitle)
                }
                .foregroundColor(.white)
            }

            Spacer()

            Text(vm.gameSelectionTitle)
                .foregroundColor(.white)
                .font(.system(size: 18, weight: .semibold))

            Spacer()

            Color.clear.frame(width: 80, height: 1)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 10)
        .background(Color.black)
    }

    private var footer: some View {
        VStack(spacing: 12) {
            Button(action: { vm.beginPlaying() }) {
                Text(vm.startMatchTitle)
                    .font(.system(size: 18, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(vm.selectedGame == nil
                                ? Color.white.opacity(0.15)
                                : Color(red: 0.203, green: 0.596, blue: 0.858))
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(vm.selectedGame == nil)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.black)
    }
}

// MARK: - UI card gioco
private struct GameCard: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.10))
                        .frame(width: 56, height: 56)
                    Image(systemName: "sparkles")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .foregroundColor(.white)
                        .font(.system(size: 17, weight: .semibold))
                    Text(subtitle)
                        .foregroundColor(.white.opacity(0.6))
                        .font(.system(size: 13))
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                    .font(.system(size: 22, weight: .semibold))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(isSelected ? 0.16 : 0.08))
            )
        }
        .buttonStyle(.plain)
    }
}
