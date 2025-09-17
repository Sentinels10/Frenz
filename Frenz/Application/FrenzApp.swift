import SwiftUI
import SuperwallKit

@main
struct FrenzApp: App {
    // Inizializzo il GameViewModel una sola volta qui
    @StateObject private var gameVM = GameViewModel()
    @StateObject private var subscriptionManager = SubscriptionManager()
    
    init() {
        // Superwall configuration — replace with your actual Public API Key from the dashboard
        Superwall.configure(apiKey: "pk_7151d53db93683b28768f3f79de15c024c52737c7f2028f5")
        // Optional: enable debug logs
        // Superwall.shared.logger.level = .debug
        #if DEBUG
        // mostra sempre l’onboarding in debug
        UserDefaults.standard.removeObject(forKey: "onboarding.seen")
        #endif
    }
    
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameVM) // se vuoi passarlo globalmente
                .environmentObject(subscriptionManager)
                .environment(\.font, .custom("TrebuchetMS", size: 16))
                .onAppear {
                    gameVM.subscriptionManager = subscriptionManager
                }
        }
    }
}
