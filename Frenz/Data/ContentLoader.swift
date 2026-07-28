import Foundation

enum ContentLoaderError: Error {
    case fileNotFound
    case invalidFormat
}

/// Contenuto per un minigioco
public struct SpecialGameContent {
    public let title: String
    public let description: String?
    public let action: String
    public let timerSeconds: Int?
}

/// NUOVO: bundle per Obbligo/Verità (Truth or Dare)
public struct TruthOrDareBundle {
    public let truths: [String]
    public let dares:  [String]
}

struct ContentLoader {

    // MARK: - API pubblica (lingua opzionale: se nil sceglie da solo)
    static func loadRoomDeck(lang: String? = nil, room: GameRoom) throws -> [GameAction] {
        let dict = try loadMergedDict(lang: lang)
        return actionsForRoomDict(dict, room: room)
    }

    static func loadGameDeck(lang: String? = nil, game: GameType) throws -> [GameAction] {
        let dict = try loadMergedDict(lang: lang)
        return actionsForGameDict(dict, game: game)
    }

    static func loadSpecial(lang: String? = nil, id: String, room: GameRoom) -> SpecialGameContent? {
        guard let dict = (try? loadMergedDict(lang: lang)) else { return nil }
        let titleLanguage = languageCandidates(for: lang).first ?? "en"
        return buildSpecial(from: dict, id: id, room: room, titleLanguage: titleLanguage)
    }

    static func specialMeta(lang: String? = nil, id: String) -> (title: String, description: String?)? {
        guard let dict = (try? loadMergedDict(lang: lang)) else { return nil }
        let titleLanguage = languageCandidates(for: lang).first ?? "en"
        return buildSpecialMeta(from: dict, id: id, titleLanguage: titleLanguage)
    }

    /// NUOVO: ritorna le liste di VERITÀ e OBBLIGHI per la stanza richiesta
    /// Supporta sia "truthDareGame" (tuo JSON storico) sia "truthOrDare"
    static func loadTruthOrDare(lang: String? = nil, room: GameRoom) throws -> TruthOrDareBundle {
        let dict = try loadMergedDict(lang: lang)

        // Nodo principale (in ordine di priorità: il tuo nome storico → quello nuovo)
        let node = (dict["truthDareGame"] as? [String: Any])
                ?? (dict["truthOrDare"]   as? [String: Any])

        guard let tod = node else {
            // nessun nodo ToD: restituisco array vuoti (più tollerante di un throw)
            return TruthOrDareBundle(truths: [], dares: [])
        }

        // Estraggo truths
        let truths: [String] = {
            if let map = tod["truth"] as? [String: Any] {
                return pickRoomArray(map, for: room)
            } else if let arr = tod["truth"] as? [String] {
                return arr
            } else if let verita = tod["verita"] as? [String] {   // eventuale alias IT
                return verita
            } else if let veritaMap = tod["verita"] as? [String: Any] {
                return pickRoomArray(veritaMap, for: room)
            }
            return []
        }()

        // Estraggo dares
        let dares: [String] = {
            if let map = tod["dare"] as? [String: Any] {
                return pickRoomArray(map, for: room)
            } else if let arr = tod["dare"] as? [String] {
                return arr
            } else if let obblighi = tod["obblighi"] as? [String] { // eventuale alias IT
                return obblighi
            } else if let obbligoMap = tod["obblighi"] as? [String: Any] {
                return pickRoomArray(obbligoMap, for: room)
            } else if let obbligoMap2 = tod["obbligo"] as? [String: Any] {
                return pickRoomArray(obbligoMap2, for: room)
            }
            return []
        }()

        return TruthOrDareBundle(truths: truths, dares: dares)
    }

    // =====================================================================
    // MARK: - Gestione lingua automatica + fallback
    // =====================================================================

    private static func languageCandidates(for lang: String?) -> [String] {
        var list: [String] = []
        if let lang {
            list.append(normalizeLanguageCode(lang))
        } else if let stored = UserDefaults.standard.string(forKey: "appLanguage"),
                  let selected = FrenzAppLanguage(rawValue: stored) {
            list.append(LanguageManager.resolvedLanguageCode(for: selected))
        } else if let legacy = UserDefaults.standard.string(forKey: "app.language") {
            list.append(normalizeLanguageCode(legacy))
        }

        list.append(LanguageManager.resolvedLanguageCode(for: .system))
        list.append("en")
        list.append("it")

        var seen = Set<String>()
        return list.filter { seen.insert($0).inserted }
    }

    private static func normalizeLanguageCode(_ code: String) -> String {
        let lower = code.lowercased().replacingOccurrences(of: "_", with: "-")
        return lower.split(separator: "-").first.map(String.init) ?? "en"
    }

    private static func loadMergedDict(lang: String?) throws -> [String: Any] {
        let candidates = languageCandidates(for: lang)
        for code in candidates {
            if let d = loadRawDict(named: "backupActions_\(code)") ??
                      loadRawDict(named: "backupActions_\(code)", subdirectory: "Resources") {
                return d
            }
        }
        throw ContentLoaderError.fileNotFound
    }

    private static func loadRawDict(named name: String, subdirectory: String? = nil) -> [String: Any]? {
        if let url = Bundle.main.url(forResource: name, withExtension: "json", subdirectory: subdirectory) {
            do {
                let data = try Data(contentsOf: url)
                let obj = try JSONSerialization.jsonObject(with: data, options: [])
                return obj as? [String: Any]
            } catch {
                return nil
            }
        }
        return nil
    }

    // =====================================================================
    // MARK: - Stanze (aderente al tuo JSON)
    // =====================================================================

    private static func actionsForRoomDict(_ dict: [String: Any], room: GameRoom) -> [GameAction] {
        func items(from key: String) -> [GameAction] {
            guard let arr = dict[key] as? [[String: Any]] else { return [] }
            return arr.compactMap { item in
                if let text = item["text"] as? String {
                    return GameAction(text: text, room: room.rawValue, game: nil, penalty: nil, timerSeconds: nil)
                }
                return nil
            }
        }

        switch room {
        case .party:    return items(from: "party").shuffled()
        case .redRoom:  return items(from: "redRoom").shuffled()
        case .darkRoom: return items(from: "darkRoom").shuffled()
        case .partner:  return items(from: "coppie").shuffled()       // mappavi "coppie" nel tuo JSON
        case .roulette:
            let combined = items(from: "party") + items(from: "redRoom") + items(from: "darkRoom")
            return combined.shuffled()
        case .games:    return []
        }
    }

    // =====================================================================
    // MARK: - Giochi (hub)
    // =====================================================================

    private static func actionsForGameDict(_ dict: [String: Any], game: GameType) -> [GameAction] {
        var result: [GameAction] = []

        switch game {
        case .truthOrDare:
            // Manteniamo il tuo schema storico "truthDareGame", ma accettiamo anche "truthOrDare"
            if let td = dict["truthDareGame"] as? [String: Any] {
                if let truth = td["truth"] as? [String: Any] {
                    flattenRoomStringMap(truth).forEach {
                        result.append(GameAction(text: $0, room: "games", game: game.rawValue, penalty: nil, timerSeconds: nil))
                    }
                }
                if let dare = td["dare"] as? [String: Any] {
                    flattenRoomStringMap(dare).forEach {
                        result.append(GameAction(text: $0, room: "games", game: game.rawValue, penalty: nil, timerSeconds: nil))
                    }
                }
            } else if let td2 = dict["truthOrDare"] as? [String: Any] {
                // supporto futuro
                let truths = (td2["truth"] as? [String]) ?? flattenRoomStringMap(td2["truth"] as? [String: Any] ?? [:])
                let dares  = (td2["dare"]  as? [String]) ?? flattenRoomStringMap(td2["dare"]  as? [String: Any] ?? [:])
                (truths + dares).forEach {
                    result.append(GameAction(text: $0, room: "games", game: game.rawValue, penalty: nil, timerSeconds: nil))
                }
            }

        case .wouldYouRather:
            wouldYouRatherPool(dict: dict, room: nil).forEach {
                result.append(GameAction(text: $0, room: "games", game: game.rawValue, penalty: nil, timerSeconds: nil))
            }

        case .neverHaveIEver:
            if let sg = dict["specialGames"] as? [String: Any],
               let nh = sg["nonHoMai"] as? [String: Any] {
                let arrays = (nh["party"] as? [String] ?? [])
                           + (nh["redRoom"] as? [String] ?? [])
                           + (nh["darkRoom"] as? [String] ?? [])
                           + (nh["coppie"] as? [String] ?? [])
                arrays.forEach {
                    result.append(GameAction(text: $0, room: "games", game: game.rawValue, penalty: nil, timerSeconds: nil))
                }
                if let txt = nh["text"] as? String, !txt.isEmpty {
                    result.append(GameAction(text: txt, room: "games", game: game.rawValue, penalty: nil, timerSeconds: nil))
                }
            }

        case .priceGame:
            if let sg = dict["specialGames"] as? [String: Any],
               let price = sg["tuttoHaUnPrezzo"] as? [String: Any] {
                let arrays = (price["party"] as? [String] ?? [])
                           + (price["redRoom"] as? [String] ?? [])
                arrays.forEach {
                    result.append(GameAction(text: $0, room: "games", game: game.rawValue, penalty: nil, timerSeconds: nil))
                }
                if let txt = price["text"] as? String, !txt.isEmpty {
                    result.append(GameAction(text: txt, room: "games", game: game.rawValue, penalty: nil, timerSeconds: nil))
                }
            }

        case .miniChallenges:
            if let sg = dict["specialGames"] as? [String: Any],
               let tc = sg["timerChallenge"] as? [String: Any] {
                let arrays = (tc["party"] as? [String] ?? [])
                           + (tc["redRoom"] as? [String] ?? [])
                           + (tc["darkRoom"] as? [String] ?? [])
                arrays.forEach {
                    result.append(GameAction(text: $0, room: "games", game: game.rawValue, penalty: nil, timerSeconds: 15))
                }
                if let txt = tc["text"] as? String, !txt.isEmpty {
                    result.append(GameAction(text: txt, room: "games", game: game.rawValue, penalty: nil, timerSeconds: 15))
                }
            }
        }

        return result.shuffled()
    }

    // =====================================================================
    // MARK: - Special games in stanza (titolo/descrizione/azione)
    // =====================================================================

    private static func buildSpecial(from dict: [String: Any], id: String, room: GameRoom, titleLanguage: String) -> SpecialGameContent? {
        
        // Caso “Questo o Quello” (tollerante: top-level o specialGames, alias stanza)
        if id == "questoOQuello" {
            // accetta sia top-level che sotto specialGames
            let qoqNode: [String: Any]? = {
                if let top = dict["questoOQuello"] as? [String: Any] { return top }
                if let sg  = dict["specialGames"] as? [String: Any],
                   let sub = sg["questoOQuello"] as? [String: Any] { return sub }
                return nil
            }()

            guard let qoq = qoqNode else { return nil }

            let title = gameTitle(id: id, lang: titleLanguage)
            let description = qoq["text"] as? String

            // array helper con alias stanza
            func arrAny(_ keys: [String]) -> [String] {
                for k in keys {
                    if let a = qoq[k] as? [String], !a.isEmpty { return a }
                }
                return []
            }

            // pool per stanza con alias (es. partner→coppie)
            let pool: [String]
            switch room {
            case .party:
                pool = arrAny(["party"])
            case .redRoom:
                pool = arrAny(["redRoom","redroom"])
            case .darkRoom:
                pool = arrAny(["darkRoom","darkroom"])
            case .partner:
                // preferisci "coppie", fallback a party
                let coppie = arrAny(["coppie","partner"])
                pool = !coppie.isEmpty ? coppie : arrAny(["party"])
            case .roulette:
                pool = arrAny(["party"]) + arrAny(["redRoom","redroom"]) + arrAny(["darkRoom","darkroom"])
            case .games:
                pool = []
            }

            // fallback totale se la stanza è vuota
            let fallback = arrAny(["party"]) + arrAny(["redRoom","redroom"]) + arrAny(["darkRoom","darkroom"])
                + (room == .roulette ? [] : arrAny(["coppie","partner"]))
            if let action = (pool.isEmpty ? fallback.randomElement() : pool.randomElement()) {
                return SpecialGameContent(title: title, description: description, action: action, timerSeconds: nil)
            }
            return nil
        }



        // Would You Rather (azioni top-level + descrizione in specialGames)
        if id == "wouldYouRather" {
            let title = gameTitle(id: id, lang: titleLanguage)
            let desc  = (dict["specialGames"] as? [String: Any])?["wouldYouRather"] as? [String: Any]
            let description = desc?["text"] as? String
            let pool = wouldYouRatherPool(dict: dict, room: room)
            if let action = pool.randomElement() {
                return SpecialGameContent(title: title, description: description, action: action, timerSeconds: nil)
            }
            return nil
        }

        // Truth or Dare (prende una frase tra truth/dare) — resta compatibile col tuo schema
        if id == "truthOrDare" {
            let title = gameTitle(id: id, lang: titleLanguage)
            let descriptionNew = (dict["specialGames"] as? [String: Any])?["truthOrDare"].flatMap { $0 as? [String: Any] }?["text"] as? String
            let descriptionOld = (dict["truthDareGame"] as? [String: Any])?["text"] as? String
            let description = descriptionNew ?? descriptionOld

            if let action = truthOrDareOne(dict: dict, room: room) {
                return SpecialGameContent(title: title, description: description, action: action, timerSeconds: nil)
            }
            return nil
        }

        // Altri giochi in specialGames
        guard let sg = dict["specialGames"] as? [String: Any],
              let node = sg[id] as? [String: Any] else { return nil }

        let title = gameTitle(id: id, lang: titleLanguage)
        let description = node["text"] as? String
        let timerSec = (id == "timerChallenge") ? 15 : nil

        let pool = poolForRoom(node: node, room: room)
        if let action = pool.randomElement() {
            return SpecialGameContent(title: title, description: description, action: action, timerSeconds: timerSec)
        }
        if let description, !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return SpecialGameContent(title: title, description: description, action: description, timerSeconds: timerSec)
        }
        return nil
    }

    private static func buildSpecialMeta(from dict: [String: Any], id: String, titleLanguage: String) -> (title: String, description: String?)? {
        if id == "questoOQuello" {
            let desc = (dict["questoOQuello"] as? [String: Any])?["text"] as? String
            return (gameTitle(id: id, lang: titleLanguage), desc)
        }
        if id == "wouldYouRather" {
            let desc = (dict["specialGames"] as? [String: Any])?["wouldYouRather"] as? [String: Any]
            return (gameTitle(id: id, lang: titleLanguage), (desc?["text"] as? String))
        }
        if id == "truthOrDare" {
            // meta opzionale sia nello schema nuovo che nel vecchio
            let descNew = (dict["specialGames"] as? [String: Any])?["truthOrDare"].flatMap { $0 as? [String: Any] }?["text"] as? String
            let descOld = (dict["truthDareGame"] as? [String: Any])?["text"] as? String
            return (gameTitle(id: id, lang: titleLanguage), descNew ?? descOld)
        }
        if let sg = dict["specialGames"] as? [String: Any],
           let node = sg[id] as? [String: Any] {
            let title = gameTitle(id: id, lang: titleLanguage)
            let desc  = node["text"] as? String
            return (title, desc)
        }
        return nil
    }

    // =====================================================================
    // MARK: - Helpers di parsing
    // =====================================================================

    private static func wouldYouRatherPool(dict: [String: Any], room: GameRoom?) -> [String] {
        guard let wyr = dict["wouldYouRather"] as? [String: Any] else { return [] }
        func items(_ obj: Any?) -> [String] {
            guard let arr = obj as? [[String: Any]] else { return [] }
            return arr.compactMap { $0["text"] as? String }
        }
        if let room {
            switch room {
            case .party:    return items(wyr["party"])
            case .redRoom:  return items(wyr["redRoom"])
            case .darkRoom: return items(wyr["darkRoom"])
            case .partner:
                let partnerItems = items(wyr["coppie"])
                return partnerItems.isEmpty ? items(wyr["party"]) : partnerItems
            case .roulette: return items(wyr["party"]) + items(wyr["redRoom"]) + items(wyr["darkRoom"])
            case .games:    return []
            }
        } else {
            return items(wyr["party"]) + items(wyr["redRoom"]) + items(wyr["darkRoom"])
        }
    }

    /// Usa il tuo nodo storico "truthDareGame" (o in futuro "truthOrDare") per pescare UNA frase
    private static func truthOrDareOne(dict: [String: Any], room: GameRoom) -> String? {
        if let td = dict["truthDareGame"] as? [String: Any] {
            func pick(_ map: [String: Any]) -> String? {
                let pool: [String]
                switch room {
                case .party:    pool = (map["party"] as? [String]) ?? []
                case .redRoom:  pool = (map["redRoom"] as? [String]) ?? []
                case .darkRoom: pool = (map["darkRoom"] as? [String]) ?? []
                case .partner:
                    let partnerPool = (map["coppie"] as? [String]) ?? []
                    pool = partnerPool.isEmpty ? ((map["party"] as? [String]) ?? []) : partnerPool
                case .roulette: pool = ((map["party"] as? [String]) ?? []) + ((map["redRoom"] as? [String]) ?? []) + ((map["darkRoom"] as? [String]) ?? [])
                case .games:    pool = []
                }
                return pool.randomElement()
            }
            if let truth = td["truth"] as? [String: Any], let t = pick(truth) { return t }
            if let dare  = td["dare"]  as? [String: Any], let d = pick(dare)  { return d }
            return nil
        } else if let td2 = dict["truthOrDare"] as? [String: Any] {
            // supporto futuro: mixa truth+dare globali (se array)
            let truths = (td2["truth"] as? [String]) ?? []
            let dares  = (td2["dare"]  as? [String]) ?? []
            return (truths + dares).randomElement()
        }
        return nil
    }

    /// Helper per loadTruthOrDare: prende l'array della stanza richiesta, con fallback sensati.
    private static func pickRoomArray(_ map: [String: Any], for room: GameRoom) -> [String] {
        func arr(_ k: String) -> [String] { map[k] as? [String] ?? [] }
        switch room {
        case .party:    return arr("party").isEmpty ? (arr("all")+arr("common")) : arr("party")
        case .redRoom:  return arr("redRoom").isEmpty ? (arr("all")+arr("common")) : arr("redRoom")
        case .darkRoom: return arr("darkRoom").isEmpty ? (arr("all")+arr("common")) : arr("darkRoom")
        case .partner:  return arr("coppie").isEmpty ? (arr("party").isEmpty ? (arr("all")+arr("common")) : arr("party")) : arr("coppie")
        case .roulette:
            let merged = arr("party") + arr("redRoom") + arr("darkRoom") + arr("all") + arr("common")
            return merged
        case .games:    return []
        }
    }

    private static func poolForRoom(node: [String: Any], room: GameRoom) -> [String] {
        func arr(_ key: String) -> [String] { node[key] as? [String] ?? [] }
        switch room {
        case .party:    return arr("party")
        case .redRoom:  return arr("redRoom")
        case .darkRoom: return arr("darkRoom")
        case .partner:  return arr("coppie").isEmpty ? arr("party") : arr("coppie")
        case .roulette: return arr("party") + arr("redRoom") + arr("darkRoom")
        case .games:    return []
        }
    }

    private static func gameTitle(id: String, lang: String? = nil) -> String {
        let code = normalizeLanguageCode(lang ?? "en")
        if code == "it" {
            switch id {
            case "questoOQuello":   return "Questo o Quello"
            case "tuttiQuelliChe":  return "Tutti quelli che..."
            case "nonHoMai":        return "Non ho mai"
            case "tuttoHaUnPrezzo": return "Tutto ha un prezzo"
            case "timerChallenge":  return "Mini-sfida (Timer)"
            case "penitenzaRandom": return "Penitenza random"
            case "penitenzeGruppo": return "Penitenze di gruppo"
            case "chiEPiuProbabile":return "Chi è più probabile..."
            case "pointFinger":     return "Punta il dito"
            case "infamata":        return "Infamata"
            case "chatDetective":   return "Chat Detective"
            case "happyHour":       return "Happy Hour"
            case "newRule":         return "Nuova regola"
            case "oneVsOne":        return "1 vs 1"
            case "truthOrDare":     return "Obbligo o Verità"
            case "wouldYouRather":  return "Preferiresti"
            default:                return "Mini-gioco"
            }
        }

        switch id {
        case "questoOQuello":   return "This or That"
        case "tuttiQuelliChe":  return "Everyone Who..."
        case "nonHoMai":        return "Never Have I Ever"
        case "tuttoHaUnPrezzo": return "Everything Has a Price"
        case "timerChallenge":  return "Mini Challenge (Timer)"
        case "penitenzaRandom": return "Random Penalty"
        case "penitenzeGruppo": return "Group Penalties"
        case "chiEPiuProbabile":return "Most Likely To..."
        case "pointFinger":     return "Point the Finger"
        case "infamata":        return "Callout"
        case "chatDetective":   return "Chat Detective"
        case "happyHour":       return "Happy Hour"
        case "newRule":         return "New Rule"
        case "oneVsOne":        return "1 vs 1"
        case "truthOrDare":     return "Truth or Dare"
        case "wouldYouRather":  return "Would You Rather"
        default:                return "Mini Game"
        }
    }

    private static func flattenRoomStringMap(_ dict: [String: Any]) -> [String] {
        var out: [String] = []
        for (_, v) in dict {
            if let arr = v as? [String] { out.append(contentsOf: arr) }
        }
        return out
    }
}
