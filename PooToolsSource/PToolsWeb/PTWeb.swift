// English: Optional UIKit WebView controller built on the reusable Web bridge.
// Español: Controlador WebView UIKit opcional construido sobre el puente reutilizable.
// 中文：基于可复用 Web Bridge 的可选 UIKit WebView 控制器。

#if canImport(UIKit)
import UIKit
import WebKit
#if SWIFT_PACKAGE
import PToolsWebBridge
#endif

@MainActor
public final class PTWebViewController: UIViewController {
    public let webView: WKWebView
    public private(set) var bridge: PTWebBridge!

    public init(configuration: WKWebViewConfiguration = .init()) {
        webView = WKWebView(frame: .zero, configuration: configuration)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        bridge = PTWebBridge(webView: webView)
    }
}
#endif
