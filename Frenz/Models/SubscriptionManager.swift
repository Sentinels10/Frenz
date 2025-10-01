import Foundation
import Combine
import SwiftUI
import SuperwallKit

@MainActor final class SubscriptionManager: ObservableObject {
    static let paywallsEnabled = false

    @Published private(set) var isPro: Bool = !SubscriptionManager.paywallsEnabled

    private var cancellables = Set<AnyCancellable>()

    #if DEBUG
    private let debugKey = "debug_force_pro"
    #endif

    init() {
        guard Self.paywallsEnabled else {
            isPro = true
            return
        }

        refreshFromSuperwall()

        #if canImport(UIKit)
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.refreshFromSuperwall()
            }
            .store(in: &cancellables)
        #endif
    }

    func refreshFromSuperwall() {
        guard Self.paywallsEnabled else {
            isPro = true
            return
        }

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

    func refreshEntitlements() {
        refreshFromSuperwall()
    }

    func showPaywall(
        placement: GameViewModel.PaywallPlacement,
        onFinish: @escaping (Bool) -> Void = { _ in }
    ) {
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
            eventName = key
        }
        showPaywall(placement: eventName, onFinish: onFinish)
    }

    func showPaywall(
        placement: String,
        onFinish: @escaping (Bool) -> Void = { _ in }
    ) {
        guard Self.paywallsEnabled else {
            isPro = true
            onFinish(true)
            return
        }

        Superwall.shared.register(placement: placement, params: nil) {
            self.refreshEntitlements()
            onFinish(self.isPro)
        }
    }

    var premiumUnlocked: Bool { isPro }
}

#if DEBUG
extension SubscriptionManager {
    func debugTogglePro() {
        let newValue = !UserDefaults.standard.bool(forKey: debugKey)
        UserDefaults.standard.set(newValue, forKey: debugKey)
        refreshFromSuperwall()
    }

    func setProForTesting(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: debugKey)
        refreshFromSuperwall()
    }
}
#endif
