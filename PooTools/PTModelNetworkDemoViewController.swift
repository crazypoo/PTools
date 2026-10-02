//
// English: A deterministic Example screen for PTModel and typed Network response paths.
// Español: Una pantalla determinista del Example para PTModel y rutas de respuesta Network tipadas.
// 中文：PTModel 与类型化 Network 响应路径的确定性 Example 页面。
//

import UIKit
import PooTools

@MainActor
final class PTModelNetworkDemoViewController: PTBaseViewController {
    private struct Profile: Codable, Sendable, Equatable {
        let nickname: String
    }

    private struct User: Codable, Sendable, Equatable {
        let id: Int
        let name: String
        let profile: Profile
    }

    private let outputView = UITextView()

    override func viewDidLoad() {
        super.viewDidLoad()
        pt_Title = "PTModel + Network"
        view.backgroundColor = .systemBackground
        configureView()
        showIntro()
    }

    private func configureView() {
        let scrollView = UIScrollView()
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.alignment = .fill

        view.addSubview(scrollView)
        scrollView.addSubview(stackView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16)
        ])

        let description = UILabel()
        description.numberOfLines = 0
        description.text = "普通 Nested Model、$.data 响应包裹和 Stringified JSON 使用同一套确定性解码入口。"
        stackView.addArrangedSubview(description)

        stackView.addArrangedSubview(makeButton(title: "Decode Nested Object", action: #selector(decodeNestedObject)))
        stackView.addArrangedSubview(makeButton(title: "Decode $.data", action: #selector(decodeResponsePath)))
        stackView.addArrangedSubview(makeButton(title: "Encode Model", action: #selector(encodeModel)))

        outputView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        outputView.isEditable = false
        outputView.isScrollEnabled = false
        outputView.backgroundColor = .secondarySystemBackground
        outputView.layer.cornerRadius = 10
        stackView.addArrangedSubview(outputView)
    }

    private func makeButton(title: String, action: Selector) -> UIButton {
        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        let button = UIButton(configuration: configuration)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    @objc private func decodeNestedObject() {
        let data = Data(#"{"id":1,"name":"Jax","profile":{"nickname":"Nested"}}"#.utf8)
        do {
            let user = try PTModelDecoder(policy: .compatible).decode(User.self, from: data)
            outputView.text = "Nested Object\nuser.profile.nickname = \(user.profile.nickname)\n\n不需要 @PTStringified。"
        } catch {
            outputView.text = "Decode failed: \(error.localizedDescription)"
        }
    }

    @objc private func decodeResponsePath() {
        let data = Data(#"{"code":200,"data":{"id":2,"name":"Jax","profile":{"nickname":"Envelope"}}}"#.utf8)
        let payload = PTNetworkResponsePayload(data: data)
        do {
            let user = try PTNetworkResponseDecoder<User>
                .ptModel(User.self, at: "$.data")
                .decode(payload)
            outputView.text = "Response Envelope\nmodelPath = $.data\nuser.name = \(user.name)"
        } catch {
            outputView.text = "Decode failed: \(error.localizedDescription)"
        }
    }

    @objc private func encodeModel() {
        let user = User(id: 3, name: "Jax", profile: Profile(nickname: "Encoded"))
        do {
            outputView.text = try PTModelEncoder(prettyPrinted: true).jsonString(user)
        } catch {
            outputView.text = "Encode failed: \(error.localizedDescription)"
        }
    }

    private func showIntro() {
        outputView.text = "选择一个操作查看确定性结果。\n\nNetwork 不会自动猜测 data/result/payload；请显式传入 modelPath。"
    }
}
