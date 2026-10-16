import SwiftUI
import UIKit

@MainActor
enum HapticFeedback {
    static func lightTap() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.45)
    }
}

struct HapticButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    HapticFeedback.lightTap()
                }
            }
    }
}
