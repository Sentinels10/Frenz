import SwiftUI
import SuperwallKit

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
                Text("playerSetup.title")
                    .font(.rammetto(size: 23))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 6)
                    .lineSpacing(3)
                    .shadow(color: .black.opacity(0.35), radius: 6, x: 0, y: 3)

                // Lista input
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(vm.inputPlayers, id: \.id) { p in
                            PlayerFieldRow(
                                id: p.id,
                                text: p.name,
                                placeholder: vm.playerInputPlaceholder,
                                isDuplicate: isDuplicateName(p.name),
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
                                Text(LocalizedStringKey(vm.addPlayerLabel))
                                    .font(.rammetto(size: 15))
                                    .foregroundColor(.white)
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white.opacity(0.10))
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(0.9), lineWidth: 2)
                                    Image(systemName: "plus")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                .frame(width: 32, height: 32)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.08))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.20), lineWidth: 1)
                            )
                        }
                        .padding(.top, 6)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 4)
                }

                Spacer(minLength: 6)

                // CTA continua — footer sottile con separatore
                VStack(spacing: 0) {
                    // sottile riga divisoria
                    Rectangle()
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 1)
                        .frame(maxWidth: .infinity)

                    Button(action: {
                        Superwall.shared.register(placement: "after_player_setup_continue") {
                            vm.startGame()
                        }
                    }) {
                        Text("continue")
                            .font(.rammetto(size: 18))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14) // un po' meno alto per un footer più sottile
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color(hex: 0x210041)) // colore interno richiesto
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 22)
                                    .strokeBorder(LinearGradient.frenzRainbow(), lineWidth: 3)
                            )
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8) // meno padding per ridurre lo spessore del footer
                            .opacity(canContinue ? 1.0 : 0.5)
                    }
                    .disabled(!canContinue)
                }
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
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        
    }
    


    // MARK: - Computed
    // Normalizza i nomi per i confronti (spazi/maiuscole)
    private func normalized(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    // Set delle chiavi (nomi normalizzati) che compaiono più di una volta
    private var duplicateNameKeys: Set<String> {
        var freq: [String: Int] = [:]
        for p in vm.inputPlayers {
            let key = normalized(p.name)
            guard !key.isEmpty else { continue }
            freq[key, default: 0] += 1
        }
        return Set(freq.filter { $0.value > 1 }.map { $0.key })
    }

    private func isDuplicateName(_ raw: String) -> Bool {
        let key = normalized(raw)
        return !key.isEmpty && duplicateNameKeys.contains(key)
    }

    private var canContinue: Bool {
        let filled = vm.inputPlayers
            .map { normalized($0.name) }
            .filter { !$0.isEmpty }

        let unique = Set(filled)
        // Almeno 2 nomi non vuoti, nessun duplicato
        return filled.count >= 2 && duplicateNameKeys.isEmpty && unique.count == filled.count
    }
}

// MARK: - Single Player Row
private struct PlayerFieldRow: View {
    let id: Int
    @State var text: String
    let placeholder: String
    let isDuplicate: Bool
    let onChange: (String) -> Void
    let onRemove: () -> Void

    var body: some View {
        ZStack {
            // fondo unico
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(colors: [Color(hex: 0x4E35A8).opacity(0.55),
                                            Color(hex: 0x3A1E7A).opacity(0.55)],
                                   startPoint: .top, endPoint: .bottom)
                )

            HStack(spacing: 8) {
                ZStack(alignment: .leading) {
                    if text.isEmpty {
                        Text(LocalizedStringKey(placeholder))
                            .font(.rammetto(size: 15))
                            .foregroundColor(Color(hex: 0xBCA7FF))
                            .padding(.leading, 14)
                    }
                    TextField("", text: $text)
                        .onChange(of: text) { onChange(text) }   // compat iOS16/17
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                        .foregroundColor(.white)
                        .font(.rammetto(size: 15))
                        .padding(.leading, 14)
                        .padding(.vertical, 14)
                }

                // bottone “X” interno
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(10)
                }
                .padding(.trailing, 8)
            }
        }
        .frame(height: 56)
        .overlay(
            Group {
                if isDuplicate {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.red.opacity(0.95), lineWidth: 2)
                        .shadow(color: Color.red.opacity(0.6), radius: 6, x: 0, y: 0)
                        .animation(.easeInOut(duration: 0.2), value: isDuplicate)
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                }
            }
        )
    }
}
