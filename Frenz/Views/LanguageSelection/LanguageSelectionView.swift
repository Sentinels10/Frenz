import SwiftUI


struct LanguageSelectionView<ViewModel: LanguageSelectionRouting>: View {
    @ObservedObject var vm: ViewModel
    @EnvironmentObject private var lang: LanguageManager

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                list
                footer
            }
        }
        .id(lang.selected.rawValue)
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text(vm.title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .padding(.top, 24)
            Text(currentLanguageSubtitle)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.bottom, 16)
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(vm.availableLanguages) { langItem in
                    LanguageRow(
                        lang: langItem,
                        isSelected: langItem.id == lang.selected.rawValue
                    ) {
                        // Aggiorna subito il LanguageManager globale (con animazione) e poi delega al VM
                        withAnimation(.easeInOut(duration: 0.2)) {
                            lang.selected = .init(rawValue: langItem.id) ?? .system
                        }
                        vm.selectLanguage(langItem.id)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
    }

    private var footer: some View {
        VStack {
            Button(action: { vm.goBack() }) {
                Text(vm.closeTitle)
                    .font(.system(size: 17, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.08))
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
        .background(Color.black)
    }

    private var currentLanguageSubtitle: String {
        let code = lang.selected.rawValue
        let flag = languageFlag(code)
        return "\(flag) \(code.uppercased())"
    }

    private func languageFlag(_ code: String) -> String {
        switch code {
        case "it": return "🇮🇹"
        case "en": return "🇬🇧"
        case "fr": return "🇫🇷"
        case "de": return "🇩🇪"
        default:   return "🌐"
        }
    }
}

// MARK: - Singola riga
private struct LanguageRow: View {
    let lang: FrenzAppLanguage
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Text(lang.flag)
                    .font(.system(size: 24))

                VStack(alignment: .leading, spacing: 2) {
                    Text(lang.name)
                        .foregroundColor(.white)
                        .font(.system(size: 17, weight: .semibold))
                    Text(lang.id.uppercased())
                        .foregroundColor(.white.opacity(0.5))
                        .font(.system(size: 12))
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color(red: 0.203, green: 0.596, blue: 0.858)) // #3498db
                        .transition(.scale)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(isSelected ? 0.10 : 0.06))
            )
        }
        .buttonStyle(.plain)
    }
}
