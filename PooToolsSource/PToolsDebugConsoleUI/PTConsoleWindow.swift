// Scene-scoped transparent Debug console window. A presentation-only
// leaf: no LogBuffer, hooks, capture collectors or other Debug ownership.
import UIKit
import SnapKit
#if SWIFT_PACKAGE
import PToolsOverlay
#endif

@MainActor
public final class PTConsoleWindow: UIWindow {

    // Keep the old shared entry point for source compatibility; active UI is resolved per scene.
    // Conserva la entrada compartida anterior por compatibilidad de código; la UI activa se resuelve por escena.
    // 保留旧的 shared 入口以兼容现有代码；实际显示的 UI 在下面按场景解析。
    public static let shared = PTConsoleWindow()

    public static var onSceneDisconnect: (@MainActor (UIWindowScene) -> Void)?

    private static var windowsBySceneID: [String: PTConsoleWindow] = [:]
    private static var sceneDisconnectObserver: NSObjectProtocol?

    // English: Reuse the shared overlay z-order so debug windows stay above feature overlays.
    // Español: Reutiliza el orden Z compartido para que las ventanas de depuración queden sobre los overlays.
    // 中文：复用统一浮层层级，确保调试窗口始终位于功能浮层之上。
    static let debugWindowLevel: UIWindow.Level = PTOverlayZOrder.windowLevel(for: .debug)
    
    private weak var debugView: UIView?

    private init() {
        super.init(frame: .zero)
        windowLevel = PTConsoleWindow.debugWindowLevel
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { return nil }

    // English: Return the console window owned by the requested scene without selecting a random connected scene.
    // Español: Devuelve la ventana de consola de la escena solicitada sin elegir una escena conectada al azar.
    // 中文：返回指定场景所属的控制台窗口，不再随机选择已连接场景。
    public static func window(for scene: UIWindowScene?) -> PTConsoleWindow {
        guard let scene else { return shared }
        installSceneDisconnectObserverIfNeeded()
        windowsBySceneID = windowsBySceneID.filter { $0.value.windowScene != nil }
        let sceneID = scene.session.persistentIdentifier
        if let window = windowsBySceneID[sceneID] {
            window.attach(to: scene)
            return window
        }

        let window = PTConsoleWindow()
        window.attach(to: scene)
        windowsBySceneID[sceneID] = window
        return window
    }

    // English: Release scene-owned console windows as soon as UIKit disconnects their scene.
    // Español: Libera las ventanas de consola de la escena en cuanto UIKit desconecta esa escena.
    // 中文：UIKit 断开场景后立即释放该场景所属的控制台窗口。
    private static func installSceneDisconnectObserverIfNeeded() {
        guard sceneDisconnectObserver == nil else { return }
        sceneDisconnectObserver = NotificationCenter.default.addObserver(
            forName: UIScene.didDisconnectNotification,
            object: nil,
            queue: .main
        ) { notification in
            guard let scene = notification.object as? UIWindowScene else { return }
            Task { @MainActor in
                PTConsoleWindow.removeWindow(for: scene)
            }
        }
    }

    // English: Remove the scene association when UIKit disconnects a scene.
    // Español: Elimina la asociación de la escena cuando UIKit desconecta una escena.
    // 中文：UIKit 断开场景时清理该场景的窗口关联。
    static func removeWindow(for scene: UIWindowScene) {
        let window = windowsBySceneID.removeValue(forKey: scene.session.persistentIdentifier)
        onSceneDisconnect?(scene)
        window?.isHidden = true
        window?.rootViewController = nil
    }

    // English: Attach the reusable window before it becomes visible.
    // Español: Conecta la ventana reutilizable antes de hacerla visible.
    // 中文：在窗口显示前，将可复用窗口挂载到目标场景。
    func attach(to scene: UIWindowScene) {
        if windowScene !== scene {
            windowScene = scene
        }
        frame = scene.coordinateSpace.bounds
    }
        
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let rootView = rootViewController?.view else { return nil }

        let hitView = super.hitTest(point, with: event)

        // ✅ 关键：如果点到的是“背景 view”，直接穿透
        if hitView == rootView {
            return nil
        }

        return hitView
    }

    public func show(view:UIView) {
        if debugView != nil {
            isHidden = false
            return
        }

        addSubview(view)
        view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        debugView = view

        isHidden = false
    }
}
