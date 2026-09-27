// English: Scene lifecycle bridge shared by overlay presenters.
// Español: Puente del ciclo de vida de la escena compartido por los presenters.
// 中文：供所有浮层 Presenter 共用的 Scene 生命周期桥接。

import UIKit

public enum PTOverlayLifecycleEvent: Sendable {
    case didEnterBackground
    case didBecomeActive
    case didDisconnect
}

@MainActor
public final class PTOverlayLifecycle: NSObject {
    public typealias Handler = @MainActor @Sendable (PTOverlayLifecycleEvent) -> Void

    private let handler: Handler
    private weak var scene: UIWindowScene?

    public init(scene: UIWindowScene, handler: @escaping Handler) {
        self.scene = scene
        self.handler = handler
        super.init()
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(sceneDidEnterBackground), name: UIScene.didEnterBackgroundNotification, object: scene)
        center.addObserver(self, selector: #selector(sceneDidBecomeActive), name: UIScene.didActivateNotification, object: scene)
        center.addObserver(self, selector: #selector(sceneDidDisconnect), name: UIScene.didDisconnectNotification, object: scene)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func sceneDidEnterBackground() {
        handler(.didEnterBackground)
    }

    @objc private func sceneDidBecomeActive() {
        handler(.didBecomeActive)
    }

    @objc private func sceneDidDisconnect() {
        handler(.didDisconnect)
    }
}
