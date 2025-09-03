import SwiftUI


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
                            .background(Color.white.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Spacer()

                    Text("Scegli la stanza")
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: { vm.openLanguageSelector() }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.white.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
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
                    VStack(spacing: 14) {

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
                                icon: leadingIcon(for: room),
                                gradient: cardGradient(for: room),
                                showCrown: vm.isRoomPremium(room) && !vm.premiumUnlocked
                            ) {
                                vm.select(room: room)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }

                // CTA "Aggiungi giocatori" (se la usi in basso)
                HStack(spacing: 12) {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.white)
                    Text("Aggiungi giocatori")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .semibold))
                    Spacer()
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.green.opacity(0.92))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                .onTapGesture { vm.openPlayerSetup() }
            }
        }
    }

    // MARK: - Presentazione (testi, icone, gradienti)

    private func title(for room: GameRoom) -> String {
        switch room {
        case .party:    return "CHILLING"
        case .darkRoom: return "DARK ROOM"
        case .partner:  return "PARTNER"
        case .roulette: return "ROULETTE"
        case .redRoom:  return "RED ROOM"
        case .games:    return "GIOCHI"
        }
    }

    private func subtitle(for room: GameRoom) -> String {
        switch room {
        case .party:    return "Leggera, sociale, per scaldare la serata."
        case .darkRoom: return "Drama, segreti, paure: confessa senza filtri."
        case .partner:  return "Sfide per coppie: complicità e pepe."
        case .roulette: return "Mix casuale di tutte le modalità."
        case .redRoom:  return "Piccante e provocante, gioca con il consenso."
        case .games:    return "Mini-giochi dedicati."
        }
    }

    private func leadingIcon(for room: GameRoom) -> String {
        switch room {
        case .party:    return "cloud.fill"
        case .darkRoom: return "lock.fill"              // icona solo grafica; la premium la indica la corona
        case .partner:  return "heart.fill"
        case .roulette: return "circle.grid.3x3.fill"
        case .redRoom:  return "lips"
        case .games:    return "gamecontroller.fill"
        }
    }

    private func cardGradient(for room: GameRoom) -> [Color] {
        switch room {
        case .party:
            return [Color(red: 0.64, green: 0.84, blue: 1.0), Color(red: 0.38, green: 0.63, blue: 1.0)] // azzurro/blu
        case .darkRoom:
            return [Color(red: 0.18, green: 0.10, blue: 0.32), Color(red: 0.10, green: 0.06, blue: 0.20)] // viola scuro
        case .partner:
            return [Color(red: 0.98, green: 0.53, blue: 0.49), Color(red: 0.76, green: 0.27, blue: 0.26)] // rosso/corallo
        case .roulette:
            return [Color(red: 0.94, green: 0.63, blue: 0.98), Color(red: 0.69, green: 0.45, blue: 0.86)] // lilla/viola
        case .redRoom:
            return [Color(red: 0.97, green: 0.44, blue: 0.35), Color(red: 0.55, green: 0.16, blue: 0.14)] // arancio/rosso
        case .games:
            return [Color.purple, Color.pink]
        }
    }
}

// MARK: - UI Components

private struct PremiumBannerCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("PREMIUM")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundColor(.white)
                    Text("Sblocca tutte le modalità!")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.95))
                }
                Spacer()
                Image(systemName: "crown.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(18)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.45, green: 0.75, blue: 1.0),
                             Color(red: 0.55, green: 0.45, blue: 1.0),
                             Color(red: 1.0,  green: 0.45, blue: 0.75)],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
}

private struct RoomCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradient: [Color]
    let showCrown: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .font(.system(size: 20, weight: .bold))
                    .frame(width: 38, height: 38)
                    .background(Color.white.opacity(0.16))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundColor(.white)
                        if showCrown {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                                .font(.system(size: 14, weight: .bold))
                        }
                    }
                    Text(subtitle)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(2)
                }
                Spacer()
            }
            .padding(16)
            .background(
                LinearGradient(colors: gradient, startPoint: .leading, endPoint: .trailing)
                    .opacity(0.95)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
}
