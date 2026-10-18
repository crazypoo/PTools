// English: Detail uses UITextView so long license text remains selectable, accessible, and offline.
// Español: El detalle usa UITextView para que el texto largo sea seleccionable, accesible y offline.
// 中文：详情页使用 UITextView，保证长许可证原文可选择、可访问且离线可读。

#if canImport(UIKit)
import UIKit
#if canImport(PToolsConstraintLayout)
import PToolsConstraintLayout
#endif
import SnapKit
#if canImport(PToolsAcknowledgementsCore)
import PToolsAcknowledgementsCore
#endif
#if canImport(ptools)
import ptools
#endif
#if canImport(PToolsSymbols)
import PToolsSymbols
#endif

@MainActor
public final class PTAcknowledgementDetailViewController: PTBaseViewController {
    private let entry: PTAcknowledgement
    private let textView = UITextView()

    public init(entry: PTAcknowledgement) {
        self.entry = entry
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        pt_Title = entry.name
        view.backgroundColor = .systemBackground
        configureTextView()
        configureActions()
    }

    private func configureActions() {
        let shareButton = UIButton(type: .system)
        #if canImport(PToolsSymbols)
        shareButton.setImage(UIImage(ptSymbol: .squareAndArrowUp), for: .normal)
        #else
        shareButton.setImage(UIImage(), for: .normal)
        #endif
        shareButton.accessibilityLabel = "分享"
        shareButton.addTarget(self, action: #selector(shareText), for: .touchUpInside)

        let copyButton = UIButton(type: .system)
        #if canImport(PToolsSymbols)
        copyButton.setImage(UIImage(ptSymbol: .docOnDoc), for: .normal)
        #else
        copyButton.setImage(UIImage(), for: .normal)
        #endif
        copyButton.accessibilityLabel = "复制"
        copyButton.addTarget(self, action: #selector(copyText), for: .touchUpInside)
        setCustomRightButtons(buttons: [shareButton, copyButton])
    }

    private func configureTextView() {
        textView.isEditable = false
        textView.isSelectable = true
        textView.adjustsFontForContentSizeCategory = true
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.textColor = .label
        textView.backgroundColor = .systemBackground
        textView.text = makeText()
        view.addSubview(textView)
        textView.ptLayout.makeConstraints { make in
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(16)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(12)
            make.bottom.equalToSuperview()
        }
    }

    private func makeText() -> String {
        var lines = [entry.name]
        if let version = entry.version { lines.append("Version: \(version)") }
        lines.append("License: \(entry.licenseExpression ?? "UNKNOWN")")
        for document in entry.licenseTexts {
            lines.append("\n--- \(document.fileName) ---\n\(document.text)")
        }
        for document in entry.notices {
            lines.append("\n--- NOTICE: \(document.fileName) ---\n\(document.text)")
        }
        return lines.joined(separator: "\n")
    }

    @objc private func copyText() {
        UIPasteboard.general.string = textView.text
    }

    @objc private func shareText() {
        let controller = UIActivityViewController(activityItems: [textView.text ?? ""], applicationActivities: nil)
        if let popover = controller.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItems?.first
        }
        present(controller, animated: true)
    }
}
#endif
