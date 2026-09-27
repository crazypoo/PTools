// English: Native reusable segment cell replacing the old third-party cell hierarchy.
// Español: Celda de segmento reutilizable nativa que sustituye la jerarquía de terceros.
// 中文：替换旧第三方 Cell 继承体系的原生可复用分段 Cell。

import UIKit

#if canImport(ptools)
import ptools
#endif

@MainActor
public class PTMainSegmentCell: UICollectionViewCell {
    public static let reuseIdentifier = "PTMainSegmentCell"
    public let lineView = UIView()
    public let titleLabel = UILabel()
    public let subTitleLabel = UILabel()
    public let imageIcon = UIImageView()
    public private(set) var representedID: AnyHashable?

    private let contentStack = UIStackView()
    private let badgeLabel = UILabel()
    private let badgeDot = UIView()
    private var imageTask: Task<Void, Never>?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    /// English: Builds the cell once; subsequent reuse only updates values and constraints.
    /// Español: Construye la celda una sola vez; las reutilizaciones solo actualizan valores y restricciones.
    /// 中文：只创建一次 Cell；复用时只更新内容和约束。
    open func commonInit() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1
        subTitleLabel.textAlignment = .center
        subTitleLabel.numberOfLines = 1
        imageIcon.contentMode = .scaleAspectFit
        imageIcon.clipsToBounds = true
        contentStack.axis = .horizontal
        contentStack.alignment = .center
        contentStack.spacing = 6
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(contentStack)
        NSLayoutConstraint.activate([
            contentStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            contentStack.topAnchor.constraint(equalTo: contentView.topAnchor),
            contentStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        lineView.backgroundColor = .separator
        lineView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(lineView)
        NSLayoutConstraint.activate([
            lineView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            lineView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            lineView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            lineView.widthAnchor.constraint(equalToConstant: 1)
        ])
        badgeLabel.textAlignment = .center
        badgeLabel.setContentHuggingPriority(.required, for: .horizontal)
        badgeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    /// English: Configures content, badge and image loading from one value model.
    /// Español: Configura contenido, insignia y carga de imagen desde un único modelo de valores.
    /// 中文：使用一个值模型统一配置内容、徽标和图片加载。
    public func configure(item: PTSegmentItem, style: PTSegmentStyle, selected: Bool) {
        imageTask?.cancel()
        imageTask = nil
        representedID = item.id
        removeStackContent()
        applySelection(selected, style: style)
        switch item.content {
        case .title(let title):
            addTitle(title, style: style, selected: selected)
        case .attributed(let attributed):
            titleLabel.attributedText = attributed
            titleLabel.numberOfLines = 0
            contentStack.addArrangedSubview(titleLabel)
        case .image(let image):
            addImage(image, style: style)
        case .titleImage(let title, let image, let placement):
            addTitleImage(title: title, image: image, placement: placement, style: style, selected: selected)
        case .imageSource(let source, let placeholder):
            addImage(placeholder, style: style)
            loadImage(source: source, placeholder: placeholder, identifier: item.id, style: style)
        case .titleImageSource(let title, let source, let placement, let placeholder):
            addTitleImage(title: title, image: placeholder, placement: placement, style: style, selected: selected)
            loadImage(source: source, placeholder: placeholder, identifier: item.id, style: style)
        case .custom(let custom):
            contentStack.addArrangedSubview(custom.makeView())
        }
        configureBadge(item.badge)
        accessibilityLabel = item.accessibilityLabel ?? accessibilityText(for: item.content)
        accessibilityTraits = selected ? [.button, .selected] : [.button]
    }

    public func applySelection(_ selected: Bool, style: PTSegmentStyle) {
        titleLabel.font = selected ? style.selectedFont : style.normalFont
        titleLabel.textColor = selected ? style.selectedColor : style.normalColor
        subTitleLabel.font = selected ? style.selectedFont : style.normalFont
        subTitleLabel.textColor = selected ? style.selectedColor : style.normalColor
        contentView.backgroundColor = selected ? style.selectedBackgroundColor : style.normalBackgroundColor
        transform = CGAffineTransform(scaleX: selected ? style.selectedScale : 1,
                                      y: selected ? style.selectedScale : 1)
        accessibilityTraits = selected ? [.button, .selected] : [.button]
    }

    private func removeStackContent() {
        for view in contentStack.arrangedSubviews {
            contentStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        titleLabel.text = nil
        titleLabel.attributedText = nil
        imageIcon.image = nil
        subTitleLabel.isHidden = true
        badgeLabel.removeFromSuperview()
        badgeDot.removeFromSuperview()
        contentStack.axis = .horizontal
    }

    private func addTitle(_ title: String, style: PTSegmentStyle, selected: Bool) {
        titleLabel.text = title
        titleLabel.font = selected ? style.selectedFont : style.normalFont
        contentStack.addArrangedSubview(titleLabel)
    }

    private func addImage(_ image: UIImage?, style: PTSegmentStyle) {
        imageIcon.image = image
        if image != nil {
            contentStack.addArrangedSubview(imageIcon)
            imageIcon.widthAnchor.constraint(equalToConstant: max(1, style.itemHeight - 12)).isActive = true
            imageIcon.heightAnchor.constraint(equalToConstant: max(1, style.itemHeight - 12)).isActive = true
        }
    }

    private func addTitleImage(title: String,
                               image: UIImage?,
                               placement: PTImagePlacement,
                               style: PTSegmentStyle,
                               selected: Bool) {
        titleLabel.text = title
        titleLabel.font = selected ? style.selectedFont : style.normalFont
        imageIcon.image = image
        contentStack.axis = (placement == .top || placement == .bottom) ? .vertical : .horizontal
        if placement == .trailing || placement == .bottom {
            contentStack.addArrangedSubview(titleLabel)
            if image != nil { contentStack.addArrangedSubview(imageIcon) }
        } else {
            if image != nil { contentStack.addArrangedSubview(imageIcon) }
            contentStack.addArrangedSubview(titleLabel)
        }
        if image != nil {
            imageIcon.widthAnchor.constraint(equalToConstant: max(1, style.itemHeight - 12)).isActive = true
            imageIcon.heightAnchor.constraint(equalToConstant: max(1, style.itemHeight - 12)).isActive = true
        }
    }

    private func loadImage(source: PTImageSource,
                           placeholder: UIImage?,
                           identifier: AnyHashable,
                           style: PTSegmentStyle) {
        imageTask = Task { @MainActor [weak self] in
            let result = await PTLoadImageFunction.loadImage(source: source,
                                                             targetSize: CGSize(width: style.itemHeight,
                                                                                height: style.itemHeight))
            guard !Task.isCancelled,
                  let self,
                  self.representedID == identifier else { return }
            self.imageIcon.image = result.firstImage ?? placeholder
        }
    }

    private func configureBadge(_ badge: PTSegmentBadge?) {
        guard let badge else { return }
        if let text = badge.text, !text.isEmpty {
            badgeLabel.text = text
            badgeLabel.font = badge.font
            badgeLabel.textColor = badge.textColor
            badgeLabel.backgroundColor = badge.backgroundColor
            badgeLabel.layer.cornerRadius = 9
            badgeLabel.layer.masksToBounds = true
            contentStack.addArrangedSubview(badgeLabel)
        } else if badge.showsDotWhenEmpty {
            badgeDot.backgroundColor = badge.backgroundColor
            badgeDot.layer.cornerRadius = 4
            contentStack.addArrangedSubview(badgeDot)
            badgeDot.widthAnchor.constraint(equalToConstant: 8).isActive = true
            badgeDot.heightAnchor.constraint(equalToConstant: 8).isActive = true
        }
    }

    private func accessibilityText(for content: PTSegmentContent) -> String? {
        switch content {
        case .title(let value), .titleImage(let value, _, _), .titleImageSource(let value, _, _, _): return value
        case .attributed(let value): return value.string
        default: return nil
        }
    }

    private func estimatedContentWidth(item: PTSegmentItem, style: PTSegmentStyle) -> CGFloat {
        switch item.content {
        case .title(let title): return title.size(withAttributes: [.font: style.normalFont]).width
        case .attributed(let value): return value.size().width
        case .image(let image): return image.size.width
        case .titleImage(let title, let image, _):
            return title.size(withAttributes: [.font: style.normalFont]).width + image.size.width + style.imageSpacing
        case .titleImageSource(let title, _, _, let image):
            return title.size(withAttributes: [.font: style.normalFont]).width + (image?.size.width ?? 20) + style.imageSpacing
        case .imageSource: return max(20, style.itemHeight - 12)
        case .custom: return 44
        }
    }

    public static func measuredWidth(item: PTSegmentItem, style: PTSegmentStyle) -> CGFloat {
        let cell = PTMainSegmentCell(frame: .zero)
        return max(1, cell.estimatedContentWidth(item: item, style: style) + style.itemInsets.left + style.itemInsets.right)
    }

    /// English: Compatibility entry for callers that still build the legacy model.
    /// Español: Entrada de compatibilidad para llamadas que todavía crean el modelo antiguo.
    /// 中文：兼容仍然使用旧模型的调用方。
    @available(*, deprecated, message: "Use configure(item:style:selected:) instead.")
    public func reloadData(model: PTMainSegmentModel, selected: Bool) {
        let content: PTSegmentContent
        switch model.onlyShowTitle ?? .OnlyTitle(type: .Normal) {
        case .OnlyImage:
            content = URL(string: model.imageURL).map { .imageSource(.url($0)) } ?? .title(model.title)
        case .ImageTitle:
            if let url = URL(string: model.imageURL), !model.imageURL.isEmpty {
                content = .titleImageSource(title: model.title, source: .url(url), placement: .leading)
            } else {
                content = .title(model.title)
            }
        case .OnlyTitle:
            content = .title(model.title)
        }
        configure(item: PTSegmentItem(id: model.index, content: content),
                  style: PTSegmentStyle(normalFont: model.titleNormalFont,
                                        selectedFont: model.titleSelectedFont,
                                        normalColor: model.titleNormalColor,
                                        selectedColor: model.titleSelectedColor,
                                        itemHeight: 44,
                                        itemWidths: [model.itemWidth]),
                  selected: selected)
    }

    open override func prepareForReuse() {
        super.prepareForReuse()
        imageTask?.cancel()
        imageTask = nil
        representedID = nil
        removeStackContent()
    }
}
