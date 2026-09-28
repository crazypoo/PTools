// English: UIKit-only section renderers keep supplementary views outside the Sendable form model.
// Español: Los renderizadores de sección UIKit mantienen las vistas suplementarias fuera del modelo Sendable.
// 中文：UIKit 专属的 Section renderer 保证 supplementary view 不进入 Sendable 表单模型。

#if canImport(UIKit)
import UIKit
#if SWIFT_PACKAGE
import ptools
#endif

@MainActor
public struct PTFormSectionRenderContext {
    public let sectionID: String
    public let theme: PTFormThemeAdapter
    public let environment: PTFormEnvironment

    public init(sectionID: String,
                theme: PTFormThemeAdapter,
                environment: PTFormEnvironment = .init()) {
        self.sectionID = sectionID
        self.theme = theme
        self.environment = environment
    }
}

@MainActor
public protocol PTFormSectionSupplementaryRenderer: AnyObject {
    var identifier: String { get }
    var reuseID: String { get }
    var viewClass: UICollectionReusableView.Type? { get }

    func makeView(content: PTFormSupplementaryContent,
                  context: PTFormSectionRenderContext) -> UICollectionReusableView
    func configure(view: UICollectionReusableView,
                   content: PTFormSupplementaryContent,
                   context: PTFormSectionRenderContext)
}

public extension PTFormSectionSupplementaryRenderer {
    var reuseID: String { identifier }
    var viewClass: UICollectionReusableView.Type? { nil }

    func configure(view: UICollectionReusableView,
                   content: PTFormSupplementaryContent,
                   context: PTFormSectionRenderContext) {
        // English: Legacy renderers may keep makeView; new renderers should configure dequeued views.
        // Español: Los renderizadores heredados pueden conservar makeView; los nuevos deben configurar vistas extraídas.
        // 中文：旧 renderer 可以继续提供 makeView；新 renderer 应配置 dequeue 出来的复用视图。
    }
}

@MainActor
public final class PTFormSectionRendererRegistry {
    private var renderers: [String: any PTFormSectionSupplementaryRenderer] = [:]

    public init() {}

    public func register(_ renderer: any PTFormSectionSupplementaryRenderer) {
        renderers[renderer.identifier] = renderer
    }

    public func renderer(for identifier: String) -> (any PTFormSectionSupplementaryRenderer)? {
        renderers[identifier]
    }

    public func makeView(content: PTFormSupplementaryContent,
                         context: PTFormSectionRenderContext,
                         kind: String) -> UICollectionReusableView {
        switch content {
        case .text(let text):
            let view = kind == UICollectionView.elementKindSectionHeader
                ? PTFormDefaultSectionHeader(frame: .zero)
                : PTFormDefaultSectionFooter(frame: .zero)
            view.configure(text: text, theme: context.theme)
            return view
        case .custom(let identifier):
            return renderers[identifier]?.makeView(content: content, context: context)
                ?? PTFormMissingSectionView(identifier: identifier)
        }
    }

    public func dequeueView(content: PTFormSupplementaryContent,
                            context: PTFormSectionRenderContext,
                            kind: String,
                            collectionView: UICollectionView,
                            indexPath: IndexPath) -> UICollectionReusableView? {
        switch content {
        case .text(let text):
            let reuseID = kind == UICollectionView.elementKindSectionHeader
                ? PTFormDefaultSectionHeader.reuseID
                : PTFormDefaultSectionFooter.reuseID
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                         withReuseIdentifier: reuseID,
                                                                         for: indexPath)
            if let header = view as? PTFormDefaultSectionHeader {
                header.configure(text: text, theme: context.theme)
            } else if let footer = view as? PTFormDefaultSectionFooter {
                footer.configure(text: text, theme: context.theme)
            }
            return view
        case .custom(let identifier):
            guard let renderer = renderers[identifier],
                  let viewClass = renderer.viewClass else {
                let fallbackID = kind == UICollectionView.elementKindSectionHeader
                    ? PTFormDefaultSectionHeader.reuseID
                    : PTFormDefaultSectionFooter.reuseID
                let fallback = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                                  withReuseIdentifier: fallbackID,
                                                                                  for: indexPath)
                let text = PTFormSupplementaryText(title: "Missing renderer: \(identifier)")
                if let header = fallback as? PTFormDefaultSectionHeader {
                    header.configure(text: text, theme: context.theme)
                } else if let footer = fallback as? PTFormDefaultSectionFooter {
                    footer.configure(text: text, theme: context.theme)
                }
                return fallback
            }
            collectionView.register(viewClass,
                                    forSupplementaryViewOfKind: kind,
                                    withReuseIdentifier: renderer.reuseID)
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                         withReuseIdentifier: renderer.reuseID,
                                                                         for: indexPath)
            renderer.configure(view: view, content: content, context: context)
            return view
        }
    }
}

@MainActor
public final class PTFormDefaultSectionHeader: PTBaseCollectionReusableView {
    public static let reuseID = "PTFormDefaultSectionHeader"
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.spacing = 2
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6)
        ])
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        titleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.numberOfLines = 0
    }

    public func configure(text: PTFormSupplementaryText, theme: PTFormThemeAdapter) {
        titleLabel.text = text.title
        subtitleLabel.text = text.subtitle
        titleLabel.textColor = theme.primaryTextColor()
        subtitleLabel.textColor = theme.secondaryTextColor()
        isAccessibilityElement = true
        accessibilityLabel = [text.title, text.subtitle].compactMap { $0 }.joined(separator: ", ")
    }
}

@MainActor
public final class PTFormDefaultSectionFooter: PTBaseCollectionReusableView {
    public static let reuseID = "PTFormDefaultSectionFooter"
    private let label = UILabel()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)
        ])
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.font = .preferredFont(forTextStyle: .footnote)
    }

    public func configure(text: PTFormSupplementaryText, theme: PTFormThemeAdapter) {
        label.text = [text.title, text.subtitle].compactMap { $0 }.joined(separator: "\n")
        label.textColor = theme.secondaryTextColor()
        isAccessibilityElement = true
        accessibilityLabel = label.text
    }
}

@MainActor
private final class PTFormMissingSectionView: PTBaseCollectionReusableView {
    private let label = UILabel()

    init(identifier: String) {
        super.init(frame: .zero)
        label.text = "Missing Form section renderer: \(identifier)"
        label.textColor = .systemRed
        label.numberOfLines = 0
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }
}
#endif
