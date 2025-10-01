import SwiftUI

public enum FrenzAppLanguage: String, CaseIterable, Identifiable {
    case system = "system"
    case it = "it"
    case en = "en"
    case fr = "fr"
    case de = "de"

    public var id: String { rawValue }

    // Se usi questi in UI, esportali pubblici
    public var name: String {
        switch self {
        case .system: return NSLocalizedString("language.system", comment: "")
        case .it:     return "Italiano"
        case .en:     return "English"
        case .fr:     return "Français"
        case .de:     return "Deutsch"
        }
    }

    public var flag: String {
        switch self {
        case .system: return "🛠️"
        case .it:     return "🇮🇹"
        case .en:     return "🇬🇧"
        case .fr:     return "🇫🇷"
        case .de:     return "🇩🇪"
        }
    }
}

final class LanguageManager: ObservableObject {
    @AppStorage("appLanguage") var selected: FrenzAppLanguage = .system {
        didSet {
            // Aggiorna la Locale pubblicata così SwiftUI ritraduce subito le Text(LocalizedStringKey)
            locale = Self.resolveLocale(for: selected)
        }
    }

    // Locale usata in .environment(\.locale, languageManager.locale)
    @Published var locale: Locale

    init() {
        // Leggi il valore salvato direttamente da UserDefaults per evitare l'accesso a `self.selected`
        let storedRaw = UserDefaults.standard.string(forKey: "appLanguage")
        let stored = storedRaw.flatMap { FrenzAppLanguage(rawValue: $0) } ?? .system
        self.locale = Self.resolveLocale(for: stored)
    }

    static func resolveLocale(for lang: FrenzAppLanguage) -> Locale {
        switch lang {
        case .system:
            // Usa l'identificatore preferito (es. "it-IT") per forzare un cambio anche se .current.languageCode coincide
            let id = Locale.preferredLanguages.first ?? Locale.current.identifier
            return Locale(identifier: id)
        default:
            return Locale(identifier: lang.rawValue)
        }
    }

    // Comodo wrapper, se vuoi chiamarlo dai pulsanti
    func setLanguage(_ lang: FrenzAppLanguage) {
        selected = lang
    }
}
