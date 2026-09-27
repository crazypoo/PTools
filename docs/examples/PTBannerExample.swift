// English: Small UIKit example covering the supported PToolsBanner entry points.
// Español: Ejemplo UIKit pequeño que cubre las entradas soportadas de PToolsBanner.
// 中文：覆盖 PToolsBanner 常用入口的 UIKit 示例。

import UIKit

@MainActor
final class PTBannerExampleViewController: UIViewController {
    private var uploadHandle: PTBannerHandle?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let showButton = UIButton(type: .system)
        showButton.setTitle("Show Banner", for: .normal)
        showButton.addAction(UIAction { [weak self] _ in
            self?.showBanner(.success(title: "保存成功", subtitle: "支持 Dynamic Type 和 VoiceOver"))
        }, for: .touchUpInside)
        showButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(showButton)
        NSLayoutConstraint.activate([
            showButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            showButton.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
