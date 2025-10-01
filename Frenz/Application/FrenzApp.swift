import SwiftUI
import SuperwallKit

@main
struct FrenzApp: App {
    @StateObject private var gameVM = GameViewModel()
    @StateObject private var subscriptionManager = SubscriptionManager()
    @StateObject private var languageManager = LanguageManager()
    
    init() {
        Superwall.configure(apiKey: "pk_7151d53db93683b28768f3f79de15c024c52737c7f2028f5")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                        .environmentObject(gameVM)
                        .environmentObject(subscriptionManager)
                        .environmentObject(languageManager)
                        .environment(\.locale, languageManager.locale)
                        .id(languageManager.locale.identifier)
                        .environment(\.font, .custom("TrebuchetMS", size: 16))
                        .onAppear {
                            gameVM.subscriptionManager = subscriptionManager
                            gameVM.languageManager = languageManager
                        }
        }
    }
}
