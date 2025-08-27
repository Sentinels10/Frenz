import SwiftUI

struct RoomSelectionView<VM: RoomSelectionRouting>: View {
    @ObservedObject var vm: VM

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x2B0B58), Color(hex: 0x18042F)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        premiumBanner

                        // CHILLING = party
                        RoomCard(
                            title: "CHILLING",
                            subtitle: vm.displaySubtitle(for: .party),
                            leftIcon: .sfSymbol("cloud.fill"),
                            gradient: [Color(hex: 0x4BD3FF), Color(hex: 0x7B5CFF)],
                            overlaySparkle: true,
                            crown: vm.showsCrown(.party),
                            progress: vm.progressForParty(),
                            locked: vm.isRoomLocked(.party),
                            tap: { vm.isRoomLocked(.party) ? vm.openPaywall() : vm.select(room: .party) }
                        )

                        RoomCard(
                            title: vm.displayName(for: .darkRoom).uppercased(),
                            subtitle: vm.displaySubtitle(for: .darkRoom),
                            leftIcon: .sfSymbol("lock.fill"),
                            gradient: [Color(hex: 0x3D1B72), Color(hex: 0x27104A)],
                            crown: vm.showsCrown(.darkRoom),
                            locked: vm.isRoomLocked(.darkRoom),
                            tap: { vm.isRoomLocked(.darkRoom) ? vm.openPaywall() : vm.select(room: .darkRoom) }
                        )

                        RoomCard(
                            title: vm.displayName(for: .partner).uppercased(),
                            subtitle: vm.displaySubtitle(for: .partner),
                            leftIcon: .sfSymbol("heart.fill"),
                            gradient: [Color(hex: 0xE85A6B), Color(hex: 0xA12C3A)],
                            crown: vm.showsCrown(.partner),
                            locked: vm.isRoomLocked(.partner),
                            tap: { vm.isRoomLocked(.partner) ? vm.openPaywall() : vm.select(room: .partner) }
                        )

                        RoomCard(
                            title: vm.displayName(for: .roulette).uppercased(),
                            subtitle: vm.displaySubtitle(for: .roulette),
                            leftIcon: .sfSymbol("circle.grid.3x3.fill"),
                            gradient: [Color(hex: 0xFF3CAC), Color(hex: 0x784BA0)],
                            crown: vm.showsCrown(.roulette),
                            locked: vm.isRoomLocked(.roulette),
                            tap: { vm.isRoomLocked(.roulette) ? vm.openPaywall() : vm.select(room: .roulette) }
                        )

                        RoomCard(
                            title: vm.displayName(for: .redRoom).uppercased(),
                            subtitle: vm.displaySubtitle(for: .redRoom),
                            leftIcon: .sfSymbol("mouth.fill"), // fallback; sostituiscilo con un asset “lips”
                            gradient: [Color(hex: 0xFF6A55), Color(hex: 0x5E130C)],
                            crown: vm.showsCrown(.redRoom),
                            locked: vm.isRoomLocked(.redRoom),
                            tap: { vm.isRoomLocked(.redRoom) ? vm.openPaywall() : vm.select(room: .redRoom) }
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .padding(.bottom, 12)
                }

                addPlayersBar
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: Header
    private var header: some View {
        HStack {
            Button(action: { vm.goBackToPlayerSetup() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            Spacer()
            Text(vm.roomSelectionTitle)
                .foregroundColor(.white)
                .font(.system(size: 24, weight: .heavy))
            Spacer()
            Button(action: { vm.openSettings() }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }

    // MARK: Premium banner
    private var premiumBanner: some View {
        Button(action: { vm.openPaywall() }) {
            ZStack(alignment: .topLeading) {
                LinearGradient(colors: [Color(hex: 0x63E6FF), Color(hex: 0x7B5CFF), Color(hex: 0xFF5ACD)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .frame(maxWidth: .infinity)
                    .frame(height: 110)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 6)

                VStack(alignment: .leading, spacing: 4) {
                    Text("PREMIUM")
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundColor(.white)
                        .shadow(radius: 0)
                    Text("Sblocca tutte le modalità!")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(16)
            }
        }
    }

    // MARK: Bottom bar
    private var addPlayersBar: some View {
        Button(action: { vm.addPlayers() }) {
            HStack(spacing: 10) {
                Image(systemName: "person.2.fill")
                    .foregroundColor(.white)
                Text("Aggiungi giocatori")
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.white)
            }
            .padding()
            .background(
                LinearGradient(colors: [Color(hex: 0x00C853), Color(hex: 0x00E676)], startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
            .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 6)
        }
    }
}

// MARK: - RoomCard component
private struct RoomCard: View {
    let title: String
    let subtitle: String
    let leftIcon: CardIcon
    let gradient: [Color]
    var overlaySparkle: Bool = false
    var crown: Bool = false
    var progress: (current: Int, total: Int)? = nil
    var locked: Bool = false
    let tap: () -> Void

    var body: some View {
        Button(action: tap) {
            ZStack(alignment: .topTrailing) {
                LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .frame(maxWidth: .infinity)
                    .frame(height: 96)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
                    .opacity(locked ? 0.55 : 1)
                    .overlay(overlaySparkle ? sparkles : nil)
                    .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 6)

                HStack(spacing: 12) {
                    leftIconView
                        .padding(.leading, 14)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(title)
                                .font(.system(size: 20, weight: .heavy))
                                .foregroundColor(.white)
                            if crown {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.yellow)
                                    .shadow(radius: 0)
                            }
                            Spacer()
                            if let p = progress {
                                Text("\(p.current)/\(p.total)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.black.opacity(0.25))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        Image(systemName: "flame.fill")
                                            .foregroundColor(.orange)
                                            .offset(x: 6, y: -12)
                                    )
                            }
                        }
                        Text(subtitle)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(2)
                    }
                    Spacer()
                }
                .frame(height: 96)

                if locked {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.25))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(10)
                }
            }
        }
    }

    @ViewBuilder private var leftIconView: some View {
        switch leftIcon {
        case .sfSymbol(let name):
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 60, height: 60)
                Image(systemName: name)
                    .foregroundColor(.white)
                    .font(.system(size: 28, weight: .bold))
            }
        case .asset(let name):
            Image(name).resizable().scaledToFit()
                .frame(width: 60, height: 60)
        }
    }

    private var sparkles: some View {
        ZStack {
            Circle().fill(Color.white.opacity(0.25)).frame(width: 6, height: 6).offset(x: -30, y: 10)
            Circle().fill(Color.white.opacity(0.18)).frame(width: 4, height: 4).offset(x: -6, y: -14)
            Circle().fill(Color.white.opacity(0.18)).frame(width: 5, height: 5).offset(x: -100, y: 20)
        }
        .padding(12)
    }
}

private enum CardIcon {
    case sfSymbol(String)
    case asset(String)
}
