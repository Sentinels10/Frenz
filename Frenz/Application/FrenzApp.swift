import SwiftUI

@main
struct FrenzApp: App {
    // Inizializzo il GameViewModel una sola volta qui
    @StateObject private var gameVM = GameViewModel()
    
    init() {
            #if DEBUG
            // mostra sempre l’onboarding in debug
            UserDefaults.standard.removeObject(forKey: "onboarding.seen")
            #endif
        }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameVM) // se vuoi passarlo globalmente
                .environment(\.font, .custom("TrebuchetMS", size: 16))
        }
    }
}
