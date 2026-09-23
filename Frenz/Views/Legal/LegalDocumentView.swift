import SwiftUI

enum LegalDocument {
    case privacyPolicy
    case termsOfUse

    func title(locale: Locale) -> String {
        String.frenzLocalized(self == .privacyPolicy ? "legal.privacy" : "legal.terms", locale: locale)
    }

    func sections(language: String) -> [(String, String)] {
        let italian = language == "it"
        switch self {
        case .privacyPolicy:
            return italian ? [
                ("Ultimo aggiornamento", "23 settembre 2026"),
                ("Cosa raccogliamo", "Frenz non richiede un account e non invia dati personali a un server. I nomi dei giocatori restano sul dispositivo e vengono usati solo durante la partita. Lingua e onboarding sono salvati localmente."),
                ("Permessi e condivisione", "Frenz non richiede fotocamera, microfono, contatti, posizione, foto o notifiche. La versione attuale non usa pubblicità, analytics o SDK di tracciamento e non condivide dati con terze parti."),
                ("Conservazione e cancellazione", "I dati locali restano sul dispositivo finché non vengono cancellati dall’utente. Per eliminarli è sufficiente disinstallare Frenz."),
                ("Modifiche", "Se cambieranno dati trattati o funzionalità, aggiorneremo questa informativa. Per domande sulla privacy, usa il supporto indicato nella pagina App Store.")
            ] : [
                ("Last updated", "September 23, 2026"),
                ("What we collect", "Frenz does not require an account and does not send personal data to a server. Player names remain on the device and are used only during a game. Language and onboarding state are stored locally."),
                ("Permissions and sharing", "Frenz does not request camera, microphone, contacts, location, photos, or notification access. The current version uses no advertising, analytics, or tracking SDKs and does not share data with third parties."),
                ("Retention and deletion", "Local data remains on the device until deleted by the user. To remove it, uninstall Frenz."),
                ("Changes", "If our data practices or features change, we will update this notice. For privacy questions, use the support information on the App Store page.")
            ]
        case .termsOfUse:
            return italian ? [
                ("Ultimo aggiornamento", "23 settembre 2026"),
                ("Uso dell’app", "Frenz è un gioco di intrattenimento per adulti. Usalo solo se hai l’età minima prevista nella tua regione e nel rispetto delle leggi locali."),
                ("Consenso e sicurezza", "Ogni partecipante deve poter saltare una domanda o una sfida senza pressioni. Non condividere dati privati o immagini intime e non usare l’app per molestare, umiliare o mettere in pericolo qualcuno."),
                ("Alcol e rischi", "Alcune carte possono riferirsi all’alcol o a situazioni provocatorie. Non bere per obbligo, non guidare dopo aver bevuto e non eseguire sfide pericolose o illegali."),
                ("Natura del contenuto", "Le carte sono suggerimenti di gioco e non consulenza medica, psicologica o legale. Ogni partecipante decide liberamente e può interrompere la partita in qualsiasi momento."),
                ("Modifiche", "Possiamo aggiornare questi termini quando cambiano l’app o le norme applicabili.")
            ] : [
                ("Last updated", "September 23, 2026"),
                ("Using the app", "Frenz is an entertainment game for adults. Use it only if you meet the minimum age required in your region and comply with local law."),
                ("Consent and safety", "Every participant must be free to skip a question or challenge without pressure. Do not share private data or intimate images, and do not use the app to harass, humiliate, or endanger anyone."),
                ("Alcohol and risks", "Some cards may refer to alcohol or provocative situations. Never drink under pressure, drive after drinking, or perform dangerous or illegal challenges."),
                ("Nature of the content", "The cards are game prompts, not medical, psychological, or legal advice. Each participant chooses freely and may stop playing at any time."),
                ("Changes", "We may update these terms when the app or applicable rules change.")
            ]
        }
    }
}

struct LegalDocumentView<VM: LanguageSelectionRouting>: View {
    let document: LegalDocument
    @ObservedObject var vm: VM
    @EnvironmentObject private var lang: LanguageManager

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Button(action: vm.goBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                    }

                    Text(document.title(locale: lang.locale))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    ForEach(Array(document.sections(language: vm.language).enumerated()), id: \.offset) { _, section in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(section.0)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                            Text(section.1)
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.78))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
        }
    }
}
