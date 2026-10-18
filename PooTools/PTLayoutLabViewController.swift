// English: Interactive PTLayout 3.0 demo with safe failure scenarios and native fallbacks.
// Español: Demo interactivo de PTLayout 3.0 con escenarios seguros y fallback nativo.
// 中文：PTLayout 3.0 交互 Demo，包含安全失败场景和原生兼容回退。

import UIKit
import PooTools
import SnapKit

#if canImport(PToolsConstraintLayout)
import PToolsConstraintLayout
#endif

@MainActor
final class PTLayoutLabViewController: PTBaseViewController {
    private let demoID: PTDemoID
    private let statusLabel = UILabel()
    private let sampleView = UIView()
    private let actionButton = UIButton(type: .system)

    init(demoID: PTDemoID) {
        self.demoID = demoID
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "PTLayout 3.0"
        view.backgroundColor = .systemBackground
        configureUI()
        runScenario()
    }

    private func configureUI() {
        let titleLabel = UILabel()
        titleLabel.text = demoID.rawValue
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.numberOfLines = 0

        let descriptionLabel = UILabel()
        descriptionLabel.text = "原生 Auto Layout DSL · 失败返回 PTLayoutResult · 不主动 fatalError\nDSL nativo · errores tipados · sin fatalError"
        descriptionLabel.font = .preferredFont(forTextStyle: .subheadline)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 0

        sampleView.backgroundColor = .systemBlue
        sampleView.layer.cornerRadius = 12

        statusLabel.font = .preferredFont(forTextStyle: .footnote)
        statusLabel.textColor = .secondaryLabel
        statusLabel.numberOfLines = 0
        statusLabel.accessibilityIdentifier = "ptlayout.status"

        actionButton.setTitle("重新运行 / Ejecutar / Run", for: .normal)
        actionButton.addTarget(self, action: #selector(runScenario), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel, sampleView, statusLabel, actionButton])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view.layoutMarginsGuide)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide).inset(20)
        }
        #if !canImport(PToolsConstraintLayout)
        sampleView.snp.makeConstraints { make in
            make.height.equalTo(120)
        }
        #endif
    }

    @objc private func runScenario() {
        #if canImport(PToolsConstraintLayout)
        let result = runPTLayoutScenario()
        statusLabel.text = result
        #else
        sampleView.snp.remakeConstraints { make in
            make.height.equalTo(120)
        }
        statusLabel.text = "PToolsConstraintLayout 未链接；当前使用兼容布局。\nProducto no enlazado; usando fallback de compatibilidad.\nThe standalone product is not linked; compatibility fallback is active."
        #endif
    }

    #if canImport(PToolsConstraintLayout)
    private func runPTLayoutScenario() -> String {
        switch demoID.rawValue {
        case "ui.layout.missing-superview-no-crash":
            let orphan = UILabel()
            let result = orphan.ptLayout.makeConstraints { make in
                make.top.equalToSuperview()
                make.height.equalTo(44)
            }
            return describe(result, expected: "PTL001，未安装约束")
        case "ui.layout.size-only-without-parent":
            let result = sampleView.ptLayout.makeConstraints { make in
                make.width.equalTo(180)
                make.height.greaterThanOrEqualTo(80)
            }
            return describe(result, expected: "独立尺寸成功")
        case "ui.layout.cross-tree-error":
            let otherTree = UIView()
            let result = sampleView.ptLayout.makeConstraints { make in
                make.center.equalTo(otherTree)
            }
            return describe(result, expected: "PTL002，跨树拒绝")
        case "ui.layout.safe-remake":
            let initial = sampleView.ptLayout.remakeConstraints { make in
                make.height.equalTo(120)
            }
            let failed = sampleView.ptLayout.remakeConstraints { make in
                make.top.equalTo(UIView())
            }
            return "初始 \(initial.isSuccess ? "成功" : "失败")；非法重建 \(failed.issue?.code.rawValue ?? "无错误")，旧布局保留。"
        case "ui.layout.update-mismatch":
            let result = sampleView.ptLayout.updateConstraints { make in
                make.width.equalTo(200)
            }
            return describe(result, expected: "不存在的签名不自动新增")
        case "ui.layout.profile-compare":
            PTLayoutProfiler.isEnabled = true
            PTLayoutProfiler.reset()
            _ = sampleView.ptLayout.makeConstraints { make in
                make.height.equalTo(120).labeled(PTLayoutID("profile.height"))
            }
            let snapshot = PTLayoutProfiler.snapshot()
            return "本地 PTLayout 计数：make=\(snapshot.makeCount)，prepare=\(snapshot.prepareCount)，安装=\(snapshot.installedConstraintCount)。不虚构跨引擎耗时。"
        default:
            let result = sampleView.ptLayout.remakeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(20)
                make.height.equalTo(120).priority(.high)
            }
            return describe(result, expected: "安全区、Duo、RTL 由真实容器约束处理")
        }
    }

    private func describe(_ result: PTLayoutResult, expected: String) -> String {
        if let issue = result.issue {
            return "\(expected)；返回 \(issue.code.rawValue)：\(issue.reason)"
        }
        return "\(expected)；安装约束数：\(result.changeCount)"
    }
    #endif
}
