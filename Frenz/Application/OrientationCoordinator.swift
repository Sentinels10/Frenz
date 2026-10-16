import UIKit

final class OrientationAppDelegate: NSObject, UIApplicationDelegate {
    static var allowedOrientations: UIInterfaceOrientationMask = .portrait

    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        Self.allowedOrientations
    }
}

@MainActor
enum OrientationCoordinator {
    static func update(for state: GameState) {
        let allowed: UIInterfaceOrientationMask = state == .playing ? .allButUpsideDown : .portrait
        OrientationAppDelegate.allowedOrientations = allowed

        for scene in UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }) {
            for window in scene.windows {
                window.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
            }
            scene.requestGeometryUpdate(.iOS(interfaceOrientations: allowed))
        }
    }
}
