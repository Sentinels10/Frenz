import SwiftUI

@main
struct FrenzApp: App {
    @StateObject private var gameVM = GameViewModel()
    @StateObject private var languageManager = LanguageManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                        .environmentObject(gameVM)
                        .environmentObject(languageManager)
                        .environment(\.locale, languageManager.locale)
                        .id(languageManager.locale.identifier)
                        .environment(\.font, .custom("TrebuchetMS", size: 16))
                        .onAppear {
                            gameVM.languageManager = languageManager
                        }
        }
    }
}
