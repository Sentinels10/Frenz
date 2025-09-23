import SwiftUI
import SuperwallKit

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
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

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
                    Button(action: {
                        #if DEBUG
                        subscriptionManager.debugTogglePro()
                        #endif
                    }) {
                        let isPro = subscriptionManager.isPro
                        Image(systemName: isPro ? "crown.fill" : "lock.fill")
                            .foregroundColor(isPro ? .yellow : .white)
                            .padding(8)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 6) {

                        // Banner PREMIUM — visibile solo se NON premium
                        if !subscriptionManager.isPro {
                            PremiumBannerCard {
                                // Mostra il paywall Superwall per l'upgrade premium
                                Superwall.shared.register(placement: "room_selection_premium_gate") { }
                            }
                        }

                        ForEach(rooms, id: \.self) { room in
                            RoomCard(
                                title: title(for: room),
                                subtitle: subtitle(for: room),
                                iconAsset: leadingIcon(for: room).asset,
                                iconSystem: leadingIcon(for: room).system,
                                gradient: cardGradient(for: room),
                                iconSize: iconSize(for: room),
                                showCrown: vm.isRoomPremium(room) && !subscriptionManager.isPro
                            ) {
                                if vm.isRoomPremium(room) && !subscriptionManager.isPro {
                                    // Gate: mostra il paywall
                                    print("[RoomSelection] present paywall for premium room: \(room) — isPro=\(subscriptionManager.isPro)")
                                    Superwall.shared.register(placement: "room_selection_premium_gate") {
                                        // In caso di Non-Gated, potresti voler proseguire
                                        // Qui NON selezioniamo automaticamente la stanza,
                                        // perché vogliamo che l’accesso resti gated.
                                    }
                                } else {
                                    vm.select(room: room)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 2)
                }

                // Divider arcobaleno (separato dal footer)
                LinearGradient.frenzRainbow()
                    .frame(height: 2)
                    .padding(.horizontal, -16) // per andare otticamente edge-to-edge
                
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
                .padding(.bottom, -6)
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
        case .party:    return ("sticker_clouds", "cloud.fill")
        case .darkRoom: return ("ic_room_lock", "lock.fill")
        case .partner:  return ("ic_room_heart", "heart.fill")
        case .roulette: return ("ic_room_roulette", "circle.grid.3x3.fill")
        case .redRoom:  return ("ic_room_lips", "face.smiling.fill")
        case .games:    return ("ic_room_games", "gamecontroller.fill")
        }
    }

    private func iconSize(for room: GameRoom) -> CGFloat {
        switch room {
        case .roulette:
            return 100 // slightly smaller than default to reduce the roulette icon
        default:
            return 112
        }
    }

    private func cardGradient(for room: GameRoom) -> [Color] {
        switch room {
        case .party:
            return [Color(hex: 0x1900b1), Color(hex: 0x5df1ff)]
        case .roulette:
            return [Color(hex: 0x1b0015), Color(hex: 0xf600fb)]
        case .partner:
            return [Color(hex: 0x20000a), Color(hex: 0xa8023d)]
        case .darkRoom:
            return [Color(hex: 0x010002), Color(hex: 0x3f008c)]
        case .redRoom:
            return [Color(hex: 0x1b0000), Color(hex: 0xfb0000)]
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
                                Color(hex: 0x57e5ff),
                                Color(hex: 0xff58ef),
                                Color(hex: 0xffe252),
                                Color(hex: 0xff1919)
                            ],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(height: 96)

                // Text left-aligned, above the left sticker
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(localized: "premium.banner.title"))
                            .font(.rammetto(size: 26))
                            .foregroundColor(.white)
                        Text(String(localized: "premium.banner.subtitle"))
                            .font(.trebuchet(size: 13))
                            .fontWeight(.bold)
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
    let iconSize: CGFloat
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
                    .frame(width: iconSize, height: iconSize)
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
                            .fontWeight(.bold)
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
