import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

// Ritorna l'immagine dall'asset se esiste, altrimenti un SF Symbol
@ViewBuilder
private func assetOrSymbol(_ assetName: String, system symbolName: String) -> some View {
    #if canImport(UIKit)
    if let ui = UIImage(named: assetName) {
        Image(uiImage: ui)
            .renderingMode(.original)
            .resizable()
    } else {
        Image(systemName: symbolName)
            .resizable()
            .renderingMode(.template)
    }
    #else
    Image(systemName: symbolName)
        .resizable()
        .renderingMode(.template)
    #endif
}


// MARK: - View
struct RoomSelectionView<VM: RoomSelectionRouting>: View {
    @ObservedObject var vm: VM

    private let rooms: [GameRoom] = [.party, .darkRoom, .partner, .roulette, .redRoom]

    var body: some View {
        ZStack {
            // Sfondo identico: viola profondo
            LinearGradient(
                colors: [
                    Color(red: 34/255, green: 0/255, blue: 68/255),
                    Color(red: 18/255, green: 0/255, blue: 36/255)
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {

                // Header
                HStack {
                    Button(action: { vm.goBack() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                    }

                    Spacer()

                    Text(String(localized: "roomSelection.title"))
                        .font(.rammetto(size: 24))
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: { vm.openLanguageSelector() }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                    }
                    // 🔑 bottone toggle premium (solo per debug/test)
                    Button(action: { vm.togglePremium() }) {
                        Image(systemName: vm.premiumUnlocked ? "crown.fill" : "lock.fill")
                            .foregroundColor(vm.premiumUnlocked ? .yellow : .white)
                            .padding(8)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 6) {

                        // Banner PREMIUM — stile simile a prima (gradiente blu/viola/rosa)
                        PremiumBannerCard {
                            // apri paywall “virtualmente” selezionando una stanza premium:
                            // il VM intercetta e porta al paywall se non sbloccato.
                            vm.select(room: .redRoom)
                        }

                        ForEach(rooms, id: \.self) { room in
                            RoomCard(
                                title: title(for: room),
                                subtitle: subtitle(for: room),
                                iconAsset: leadingIcon(for: room).asset,
                                iconSystem: leadingIcon(for: room).system,
                                gradient: cardGradient(for: room),
                                showCrown: vm.isRoomPremium(room) && !vm.premiumUnlocked
                            ) {
                                vm.select(room: room)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 2)
                }

                // ===== Footer: linea arcobaleno + call-to-action piatto =====
                // Divider arcobaleno (separato dal footer)
                LinearGradient(
                    colors: [
                        Color(red: 0.27, green: 0.95, blue: 0.56),
                        Color(red: 0.53, green: 0.27, blue: 0.95)
                    ],
                    startPoint: .leading, endPoint: .trailing
                )
                .frame(height: 2)
                .padding(.horizontal, -16) // to visually go edge-to-edge with content padding
                
                // Footer “piatto”, senza capsule né sfondi colorati
                HStack(spacing: 12) {
                    assetOrSymbol("ic_addplayers_left", system: "person.2.fill")
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .foregroundColor(.white)
                    
                    Spacer(minLength: 0)
                    
                    Text(String(localized: "roomSelection.addPlayers"))
                        .foregroundColor(.white)
                        .font(.rammetto(size: 18))
                    
                    Spacer(minLength: 0)
                    
                    assetOrSymbol("ic_addplayers_plus", system: "plus.circle.fill")
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .foregroundColor(.white)
                }
                .contentShape(Rectangle())
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .onTapGesture { vm.openPlayerSetup() }
                .padding(.bottom, 2)
            }
        }
    }

    // MARK: - Presentazione (testi, icone, gradienti)

    private func title(for room: GameRoom) -> String {
        switch room {
        case .party:    return String(localized: "room.party.title")
        case .darkRoom: return String(localized: "room.dark.title")
        case .partner:  return String(localized: "room.partner.title")
        case .roulette: return String(localized: "room.roulette.title")
        case .redRoom:  return String(localized: "room.red.title")
        case .games:    return String(localized: "room.games.title")
        }
    }

    private func subtitle(for room: GameRoom) -> String {
        switch room {
        case .party:    return String(localized: "room.party.subtitle")
        case .darkRoom: return String(localized: "room.dark.subtitle")
        case .partner:  return String(localized: "room.partner.subtitle")
        case .roulette: return String(localized: "room.roulette.subtitle")
        case .redRoom:  return String(localized: "room.red.subtitle")
        case .games:    return String(localized: "room.games.subtitle")
        }
    }

    private func leadingIcon(for room: GameRoom) -> (asset: String, system: String) {
        switch room {
        case .party:    return ("ic_room_cloud", "cloud.fill")
        case .darkRoom: return ("ic_room_lock", "lock.fill")
        case .partner:  return ("ic_room_heart", "heart.fill")
        case .roulette: return ("ic_room_roulette", "circle.grid.3x3.fill")
        case .redRoom:  return ("ic_room_lips", "face.smiling.fill")
        case .games:    return ("ic_room_games", "gamecontroller.fill")
        }
    }

    private func cardGradient(for room: GameRoom) -> [Color] {
        switch room {
        case .party:
            return [Color(red: 0.18, green: 0.46, blue: 0.92), Color(red: 0.28, green: 0.56, blue: 0.98), Color(red: 0.45, green: 0.70, blue: 1.00), Color(red: 0.70, green: 0.88, blue: 1.00)]
        case .darkRoom:
            return [Color(red: 0.10, green: 0.05, blue: 0.18), Color(red: 0.16, green: 0.08, blue: 0.28), Color(red: 0.24, green: 0.12, blue: 0.36)]
        case .partner:
            return [Color(red: 0.78, green: 0.18, blue: 0.18), Color(red: 0.86, green: 0.25, blue: 0.22), Color(red: 0.94, green: 0.39, blue: 0.31), Color(red: 0.99, green: 0.58, blue: 0.52)]
        case .roulette:
            return [Color(red: 0.58, green: 0.31, blue: 0.78), Color(red: 0.73, green: 0.40, blue: 0.87), Color(red: 0.86, green: 0.49, blue: 0.93), Color(red: 0.99, green: 0.64, blue: 0.98)]
        case .redRoom:
            return [Color(red: 0.62, green: 0.08, blue: 0.08), Color(red: 0.78, green: 0.16, blue: 0.14), Color(red: 0.92, green: 0.29, blue: 0.23), Color(red: 0.99, green: 0.52, blue: 0.40)]
        case .games:
            return [Color.purple, Color.pink, Color.orange]
        }
    }
}

// MARK: - UI Components

private struct PremiumBannerCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .leading) {
                // Card background at same height as other buttons (icons can overflow)
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.45, green: 0.85, blue: 1.00), // cyan
                                Color(red: 0.55, green: 0.65, blue: 1.00), // blue
                                Color(red: 0.66, green: 0.50, blue: 1.00), // violet
                                Color(red: 1.00, green: 0.50, blue: 0.85), // pink
                                Color(red: 1.00, green: 0.70, blue: 0.40)  // orange
                            ],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(height: 96)

                // Text left-aligned, above the left sticker
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(localized: "premium.banner.title"))
                            .font(.rammetto(size: 20))
                            .foregroundColor(.white)
                        Text(String(localized: "premium.banner.subtitle"))
                            .font(.trebuchet(size: 13))
                            .foregroundColor(.white.opacity(0.95))
                            .lineLimit(2)
                    }
                    .padding(.leading, 16)
                    .padding(.trailing, 100) // leave room for right sticker

                    Spacer(minLength: 0)
                }
                .frame(height: 96)

                // Left sprinkles sticker — overflowing like other icons
                assetOrSymbol("ic_premium_sparkles", system: "sparkles")
                    .scaledToFit()
                    .frame(width: 112, height: 112)
                    .offset(x: -10, y: 12)
                    .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
                    .allowsHitTesting(false)

                // Right crown-with-glasses sticker — overflowing
                assetOrSymbol("ic_premium_crown_glasses", system: "crown.fill")
                    .scaledToFit()
                    .frame(width: 112, height: 112)
                    .offset(x: 10)
                    .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 8)
                    .allowsHitTesting(false)
            }
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }
}

private struct RoomCard: View {
    let title: String
    let subtitle: String
    let iconAsset: String
    let iconSystem: String
    let gradient: [Color]
    let showCrown: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .leading) {
                // Background card (keeps the original compact height)
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(LinearGradient(colors: gradient, startPoint: .leading, endPoint: .trailing)
                            .opacity(0.95))
                    .frame(height: 96)

                // Big icon that slightly overflows the card bounds
                assetOrSymbol(iconAsset, system: iconSystem)
                    .scaledToFit()
                    .frame(width: 112, height: 112)
                    .offset(x: -10) // pushes a bit outside the left edge
                    .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)

                // Text content with left padding to leave room for the big icon
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.rammetto(size: 20))
                            .foregroundColor(.white)
                        Text(subtitle)
                            .font(.trebuchet(size: 13))
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(2)
                    }
                    .padding(.leading, 98) // space reserved for the icon
                    .padding(.trailing, 16)

                    Spacer(minLength: 0)
                }
                .frame(height: 96)
            }
            // Crown in the top-right corner, outside text stacking so it doesn’t affect layout
            .overlay(alignment: .topTrailing) {
                if showCrown {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                        .font(.system(size: 16, weight: .bold))
                        .padding(12)
                }
            }
        }
        // Make the tappable area match the rounded rectangle even if the icon overflows
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
