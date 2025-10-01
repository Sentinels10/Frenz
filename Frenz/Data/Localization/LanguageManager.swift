import SwiftUI

public enum FrenzAppLanguage: String, CaseIterable, Identifiable {
    case system = "system"
    case it = "it"
    case en = "en"
    case fr = "fr"
    case es = "es"
    case de = "de"

    public var id: String { rawValue }

    public var name: String {
        switch self {
        case .system: return String(localized: "language.system")
        case .it:     return "Italiano"
        case .en:     return "English"
        case .fr:     return "Français"
        case .es:     return "Español"
        case .de:     return "Deutsch"
        }
    }

    public var flag: String {
        switch self {
        case .system: return "🛠️"
        case .it:     return "🇮🇹"
        case .en:     return "🇬🇧"
        case .fr:     return "🇫🇷"
        case .es:     return "🇪🇸"
        case .de:     return "🇩🇪"
        }
    }
}

final class LanguageManager: ObservableObject {
    static let manualLanguages: [FrenzAppLanguage] = [.it, .en, .fr, .es]
    static let selectableLanguages: [FrenzAppLanguage] = [.system] + manualLanguages
    private static let fallbackLanguage: FrenzAppLanguage = .en

    @AppStorage("appLanguage") var selected: FrenzAppLanguage = .system {
        didSet {
            locale = Self.resolveLocale(for: selected)
        }
    }

    @Published var locale: Locale

    init() {
        if UserDefaults.standard.string(forKey: "appLanguage") == nil,
           let legacyRaw = UserDefaults.standard.string(forKey: "app.language"),
           let legacy = FrenzAppLanguage(rawValue: legacyRaw) {
            UserDefaults.standard.set(legacy.rawValue, forKey: "appLanguage")
        }

        let storedRaw = UserDefaults.standard.string(forKey: "appLanguage")
        let stored = storedRaw.flatMap { FrenzAppLanguage(rawValue: $0) } ?? .system
        self.locale = Self.resolveLocale(for: stored)

        NotificationCenter.default.addObserver(
            forName: NSLocale.currentLocaleDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self, self.selected == .system else { return }
            self.locale = Self.resolveLocale(for: .system)
        }
    }

    static func resolveLocale(for lang: FrenzAppLanguage) -> Locale {
        Locale(identifier: resolvedLanguageCode(for: lang))
    }

    static func resolvedLanguageCode(for lang: FrenzAppLanguage) -> String {
        if manualLanguages.contains(lang) {
            return lang.rawValue
        }

        return systemLanguageCode()
    }

    private static func systemLanguageCode() -> String {
        let preferred = Locale.preferredLanguages.first ?? Locale.current.identifier
        let code = normalizeLanguageCode(preferred)
        return manualLanguages.map(\.rawValue).contains(code) ? code : fallbackLanguage.rawValue
    }

    private static func normalizeLanguageCode(_ raw: String) -> String {
        let lower = raw.lowercased().replacingOccurrences(of: "_", with: "-")
        return lower.split(separator: "-").first.map(String.init) ?? fallbackLanguage.rawValue
    }

    func setLanguage(_ lang: FrenzAppLanguage) {
        selected = lang
    }

    var resolvedLanguageCode: String {
        Self.resolvedLanguageCode(for: selected)
    }
}

extension String {
    static func frenzLocalized(_ key: String, locale: Locale) -> String {
        let code = locale.identifier
            .lowercased()
            .replacingOccurrences(of: "_", with: "-")
            .split(separator: "-")
            .first
            .map(String.init) ?? "en"

        let bundle = Bundle.main.path(forResource: code, ofType: "lproj")
            .flatMap(Bundle.init(path:)) ?? .main

        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }
}
