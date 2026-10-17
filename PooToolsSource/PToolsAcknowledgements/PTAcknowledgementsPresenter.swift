// English: Presentation starts from an explicit controller and never searches for a global key window.
// Español: La presentación parte de un controlador explícito y nunca busca una key window global.
// 中文：展示从明确的控制器开始，不猜测全局 key window。

#if canImport(UIKit)
import UIKit
#if canImport(PToolsAcknowledgementsCore)
import PToolsAcknowledgementsCore
#endif

@MainActor
public enum PTAcknowledgementsPresenter {
    public enum Style: Sendable {
        case push
        case sheet
        case fullScreen
    }

    public static func present(
        from host: UIViewController,
        style: Style = .sheet,
        configuration: PTAcknowledgementsConfiguration = .init(),
        dataSource: any PTAcknowledgementsDataSource = PTBundleAcknowledgementsDataSource(),
        additionalEntries: [PTAcknowledgement] = []
    ) {
        let viewController = PTAcknowledgementsViewController(
            configuration: configuration,
            dataSource: dataSource,
            additionalEntries: additionalEntries
        )
        switch style {
        case .push:
            if let navigationController = host.navigationController {
                navigationController.pushViewController(viewController, animated: true)
            } else {
                viewController.modalPresentationStyle = .fullScreen
                host.present(viewController, animated: true)
            }
        case .sheet:
            let navigationController = UINavigationController(rootViewController: viewController)
            navigationController.modalPresentationStyle = .formSheet
            host.present(navigationController, animated: true)
        case .fullScreen:
            viewController.modalPresentationStyle = .fullScreen
            host.present(viewController, animated: true)
        }
    }
}
#endif
