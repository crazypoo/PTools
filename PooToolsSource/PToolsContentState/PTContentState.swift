// English: A single, cancellable page-state model for loading, content and recovery UI.
// Español: Un único modelo cancelable para la UI de carga, contenido y recuperación.
// 中文：统一、可取消的页面 loading、content 与恢复状态模型。

import Foundation

#if SWIFT_PACKAGE
import PToolsConnectivity
#endif

#if canImport(UIKit)
import UIKit
#endif

public struct PTEmptyState: Codable, Hashable, Sendable {
    public let title: String
    public let message: String?
    public let actionTitle: String?

    public init(title: String = "No Content", message: String? = nil, actionTitle: String? = nil) {
        self.title = title; self.message = message; self.actionTitle = actionTitle
    }
}

public struct PTContentError: Codable, Hashable, Sendable, LocalizedError {
    public let message: String
    public let retryable: Bool

    public init(message: String, retryable: Bool = true) {
        self.message = message; self.retryable = retryable
    }

    public var errorDescription: String? { message }
}

public enum PTContentState<Content: Sendable>: Sendable {
    case idle
    case loading(previous: Content?)
    case content(Content)
    case empty(PTEmptyState)
    case error(PTContentError)
    case offline(previous: Content?)
}

public enum PTContentStateDisplay: Sendable, Equatable {
    case idle
    case loading
    case content
    case empty(PTEmptyState)
    case error(PTContentError)
    case offline
}

public extension PTContentState {
    var display: PTContentStateDisplay {
        switch self {
        case .idle: .idle
        case .loading: .loading
        case .content: .content
        case .empty(let state): .empty(state)
        case .error(let error): .error(error)
        case .offline: .offline
        }
    }

    // English: Expose the last usable value for offline and loading recovery UI.
    // Español: Expone el último valor utilizable para la recuperación offline y de carga.
    // 中文：暴露 loading/offline 恢复界面需要的最近可用内容。
    var previousContent: Content? {
        switch self {
        case .content(let content): content
        case .loading(let content), .offline(let content): content
        case .idle, .empty, .error: nil
        }
    }
}

#if canImport(UIKit)
@MainActor
public final class PTContentStateView: UIView {
    public var onRetry: (@MainActor @Sendable () -> Void)?
    public private(set) var displayState: PTContentStateDisplay = .idle

    public let contentHost = UIView()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let retryButton = UIButton(type: .system)
    private let offlineLabel = UILabel()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        isAccessibilityElement = false
        addSubview(contentHost)
        addSubview(activityIndicator)
        addSubview(titleLabel)
        addSubview(messageLabel)
        addSubview(retryButton)
        addSubview(offlineLabel)
        [contentHost, activityIndicator, titleLabel, messageLabel, retryButton, offlineLabel].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            contentHost.leadingAnchor.constraint(equalTo: leadingAnchor), contentHost.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentHost.topAnchor.constraint(equalTo: topAnchor), contentHost.bottomAnchor.constraint(equalTo: bottomAnchor),
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor), activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor), titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -18),
            messageLabel.centerXAnchor.constraint(equalTo: centerXAnchor), messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            retryButton.centerXAnchor.constraint(equalTo: centerXAnchor), retryButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 12),
            offlineLabel.centerXAnchor.constraint(equalTo: centerXAnchor), offlineLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8)
        ])
        titleLabel.textAlignment = .center; titleLabel.numberOfLines = 0
        messageLabel.textAlignment = .center; messageLabel.numberOfLines = 0
        offlineLabel.text = "Offline"; offlineLabel.textAlignment = .center
        retryButton.addAction(UIAction { [weak self] _ in self?.onRetry?() }, for: .touchUpInside)
    }

    public func render(_ state: PTContentStateDisplay) {
        displayState = state
        contentHost.isHidden = state == .idle || state == .loading || state == .empty || state == .error
        activityIndicator.isHidden = state != .loading
        titleLabel.isHidden = true; messageLabel.isHidden = true; retryButton.isHidden = true; offlineLabel.isHidden = true
        switch state {
        case .idle, .content:
            break
        case .loading:
            activityIndicator.startAnimating()
        case .empty(let empty):
            titleLabel.text = empty.title; messageLabel.text = empty.message; retryButton.setTitle(empty.actionTitle, for: .normal)
            titleLabel.isHidden = false; messageLabel.isHidden = empty.message == nil; retryButton.isHidden = empty.actionTitle == nil
        case .error(let error):
            titleLabel.text = "Error"; messageLabel.text = error.message; retryButton.setTitle("Retry", for: .normal)
            titleLabel.isHidden = false; messageLabel.isHidden = false; retryButton.isHidden = !error.retryable
        case .offline:
            offlineLabel.text = "Offline"
            offlineLabel.isHidden = false
        }
        if state != .loading { activityIndicator.stopAnimating() }
    }

    public func render<Content: Sendable>(_ state: PTContentState<Content>) { render(state.display) }
}

@MainActor
public final class PTContentStateController<Content: Sendable> {
    public private(set) var state: PTContentState<Content> = .idle { didSet { onChange?(state) } }
    public var onChange: (@MainActor @Sendable (PTContentState<Content>) -> Void)?

    public init() {}

    public func set(_ state: PTContentState<Content>) { self.state = state }
}

// English: Opt-in bridge that maps connectivity changes to an existing content-state controller.
// Español: Puente opt-in que convierte cambios de conectividad en estados del controlador existente.
// 中文：可选桥接器，把网络状态变化映射到现有内容状态控制器。
@MainActor
public final class PTContentConnectivityAdapter<Content: Sendable> {
    private let provider: any PTConnectivityProviding
    private let controller: PTContentStateController<Content>
    private var observationTask: Task<Void, Never>?

    public var onReconnect: (@MainActor @Sendable () -> Void)?

    public init(provider: any PTConnectivityProviding,
                controller: PTContentStateController<Content>) {
        self.provider = provider
        self.controller = controller
    }

    public func start() {
        guard observationTask == nil else { return }
        let provider = self.provider
        observationTask = Task { @MainActor [weak self] in
            let stream = await provider.snapshots()
            for await snapshot in stream {
                guard let self, !Task.isCancelled else { return }
                self.apply(snapshot)
            }
        }
    }

    public func stop() {
        observationTask?.cancel()
        observationTask = nil
    }

    private func apply(_ snapshot: PTConnectivitySnapshot) {
        guard !snapshot.isReachable else {
            if case .offline(let previous) = controller.state, let previous {
                controller.set(.content(previous))
                onReconnect?()
            }
            return
        }
        switch controller.state {
        case .content(let content): controller.set(.offline(previous: content))
        case .loading(let previous): controller.set(.offline(previous: previous))
        case .offline, .idle, .empty, .error: break
        }
    }
}
#endif
