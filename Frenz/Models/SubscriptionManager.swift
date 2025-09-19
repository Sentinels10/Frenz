import Foundation
import Combine
import SwiftUI
import SuperwallKit

/// Gestisce lo stato di abbonamento (PRO) usando Superwall.
/// Espone `isPro` per abilitare/disabilitare feature premium in tutta l’app.
@MainActor final class SubscriptionManager: ObservableObject {

    /// True se l’utente ha un abbonamento attivo secondo Superwall.
    @Published private(set) var isPro: Bool = false

    private var cancellables = Set<AnyCancellable>()

    #if DEBUG
    private let debugKey = "debug_force_pro"
    #endif

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
        let hasEntitlement: Bool
        switch status {
        case .active:
            hasEntitlement = true
        case .inactive, .unknown:
            hasEntitlement = false
        @unknown default:
            hasEntitlement = false
        }

        #if DEBUG
        let forced = UserDefaults.standard.bool(forKey: debugKey)
        isPro = hasEntitlement || forced
        #else
        isPro = hasEntitlement
        #endif
    }

    /// Chiamare dopo un acquisto/restore o la chiusura del paywall
    /// per riallineare lo stato PRO esposto dall'app.
    func refreshEntitlements() {
        // Se Superwall espone una API di refresh più specifica
        // la puoi invocare qui. Per ora riallineiamo dal
        // `subscriptionStatus` corrente.
        refreshFromSuperwall()
    }

    /// Presents the Superwall paywall for a given placement.
    /// Calls `onFinish` with `true` if the user appears PRO afterwards (purchase/restore),
    /// otherwise `false`. Also refreshes the local entitlement state.
    func showPaywall(
        placement: GameViewModel.PaywallPlacement,
        onFinish: @escaping (Bool) -> Void = { _ in }
    ) {
        // Accetta sia enum (descrizione del case) sia stringhe già pronte.
        let key = String(describing: placement)
        let eventName: String
        switch key {
        case "afterPlayerSetup":
            eventName = "after_player_setup_continue"
        case "roomSelectionGate":
            eventName = "room_selection_premium_gate"
        case "afterGameOver":
            eventName = "after_game_over_continue"
        default:
            // Se `placement` è già una stringa Superwall, usala così com'è
            eventName = key
        }
        showPaywall(placement: eventName, onFinish: onFinish)
    }

    func showPaywall(
        placement: String,
        onFinish: @escaping (Bool) -> Void = { _ in }
    ) {
        Superwall.shared.register(placement: placement, params: nil) {
            self.refreshEntitlements()
            onFinish(self.isPro)
        }
    }

    /// Comodità per i tuoi ViewModel che già usano `premiumUnlocked`.
    var premiumUnlocked: Bool { isPro }
}

#if DEBUG
extension SubscriptionManager {
    /// Alterna localmente lo stato PRO per i test (persistente tra i run)
    func debugTogglePro() {
        let newValue = !UserDefaults.standard.bool(forKey: debugKey)
        UserDefaults.standard.set(newValue, forKey: debugKey)
        refreshFromSuperwall()
        print("[SubscriptionManager] debugTogglePro -> forced=\(newValue), isPro=\(isPro)")
    }

    /// Imposta direttamente lo stato PRO forzato (persistente)
    func setProForTesting(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: debugKey)
        refreshFromSuperwall()
    }
}
#endif
