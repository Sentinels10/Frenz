import SwiftUI

struct PlayerSetupView<VM: PlayerSetupRouting>: View {
    @ObservedObject var vm: VM

    var body: some View {
        ZStack {
            // Background
            LinearGradient(colors: [Color(hex: 0x2B0B58), Color(hex: 0x18042F)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                header

                // Titolo grande multi-line
                Text(titleText)
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 6)

                // Lista input
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(vm.inputPlayers, id: \.id) { p in
                            PlayerFieldRow(
                                id: p.id,
                                text: p.name,
                                placeholder: vm.playerInputPlaceholder,
                                onChange: { vm.updatePlayerName(id: p.id, name: $0) },
                                onRemove: {
                                    withAnimation(.spring(response: 0.25)) {
                                        vm.removePlayerInput(id: p.id)
                                    }
                                }
                            )
                        }

                        // Aggiungi un giocatore
                        Button(action: { withAnimation(.spring(response: 0.25)) { vm.addPlayerInput() } }) {
                            HStack(spacing: 10) {
                                Text(vm.addPlayerLabel)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.white)
                                    .font(.system(size: 18, weight: .bold))
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.06))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
                            )
                        }
                        .padding(.top, 6)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 4)
                }

                Spacer(minLength: 6)

                // CTA continua
                Button(action: { vm.startGame() }) {
                    Text(continueTitle)
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.06))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(LinearGradient(colors: [Color(hex: 0xFF3B30),
                                                                Color(hex: 0x00E676)],
                                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                                        lineWidth: 3)
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                        .opacity(canContinue ? 1.0 : 0.5)
                }
                .disabled(!canContinue)
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            Spacer()
            Button(action: { vm.openLanguageSelector() }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.white.opacity(0.18))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        
    }
    


    // MARK: - Computed
    private var canContinue: Bool {
        vm.inputPlayers
            .map { $0.name.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .count >= 2
    }

    // Localizzazione “CONTINUA”
    private var continueTitle: String {
        String(localized: "continue",
               locale: .init(identifier: Locale.current.identifier))
        .uppercased()
    }

    // Titolo grande (metti la tua chiave se ce l’hai)
    private var titleText: String {
        // Se usi LocalizationService, puoi sostituire con: LocalizationService.tr("playerSetup.title", <lang>)
        "Aggiungete i giocatori e diamo inizio alla festa!"
    }
}

// MARK: - Single Player Row
private struct PlayerFieldRow: View {
    let id: Int
    @State var text: String
    let placeholder: String
    let onChange: (String) -> Void
    let onRemove: () -> Void

    var body: some View {
        ZStack {
            // fondo unico
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.12))

            HStack(spacing: 8) {
                TextField(placeholder, text: $text)
                    .onChange(of: text) { onChange(text) }   // compat iOS16/17
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .semibold))
                    .padding(.leading, 14)
                    .padding(.vertical, 14)

                // bottone “X” interno
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.white.opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.trailing, 8)
            }
        }
        .frame(height: 56)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
    }
}


