import Foundation
import Combine
import SwiftUI
import SuperwallKit

/// Gestisce lo stato di abbonamento (PRO) usando Superwall.
/// Espone `isPro` per abilitare/disabilitare feature premium in tutta l’app.
final class SubscriptionManager: ObservableObject {

    /// True se l’utente ha un abbonamento attivo secondo Superwall.
    @Published private(set) var isPro: Bool = false

    private var cancellables = Set<AnyCancellable>()

    init() {
        // 1) Prima lettura all'avvio
        refreshFromSuperwall()

        // 2) Aggiorna quando l’app torna in foreground (es. dopo acquisti/restore esterni)
        #if canImport(UIKit)
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.refreshFromSuperwall()
            }
            .store(in: &cancellables)
        #endif
    }

    /// Forza un refresh manuale (da chiamare dopo un placement, restore, ecc. se vuoi un update immediato).
    func refreshFromSuperwall() {
        let status = Superwall.shared.subscriptionStatus
        switch status {
        case .active:
            isPro = true
        case .inactive, .unknown:
            isPro = false
        @unknown default:
            isPro = false
        }
    }

    /// Comodità per i tuoi ViewModel che già usano `premiumUnlocked`.
    var premiumUnlocked: Bool { isPro }
}

#if DEBUG
extension SubscriptionManager {
    /// Alterna localmente lo stato PRO per i test (non sincronizza con Superwall)
    func toggleForTesting() { isPro.toggle() }
    /// Imposta direttamente lo stato PRO per i test
    func setProForTesting(_ value: Bool) { isPro = value }
}
#endif
