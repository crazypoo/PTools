// English: Native reusable segment cell replacing the old third-party cell hierarchy.
// Español: Celda de segmento reutilizable nativa que sustituye la jerarquía de terceros.
// 中文：替换旧第三方 Cell 继承体系的原生可复用分段 Cell。

import UIKit

#if canImport(ptools)
import ptools
#endif

// English: Centralizes the rendered width contract shared by cells and layouts.
// Español: Centraliza el contrato de anchura renderizada compartido por celdas y diseños.
// 中文：集中维护 Cell 与布局共用的实际渲染宽度契约。
@MainActor
internal enum PTSegmentMeasurement {
    static let badgeHorizontalPadding: CGFloat = 6
    static let badgeVerticalPadding: CGFloat = 2
    static let badgeMinimumHeight: CGFloat = 18
    static let badgeMinimumWidth: CGFloat = 18
    static let badgeDotDiameter: CGFloat = 8

    static func renderedImageSide(style: PTSegmentStyle) -> CGFloat {
        max(1, style.itemHeight - 12)
    }

    static func textWidth(_ value: String, font: UIFont) -> CGFloat {
        ceil(value.size(withAttributes: [.font: font]).width)
    }

    static func attributedWidth(_ value: NSAttributedString) -> CGFloat {
        ceil(value.size().width)
    }

    static func bodyWidth(item: PTSegmentItem,
                          style: PTSegmentStyle,
                          font: UIFont) -> CGFloat {
        switch item.content {
        case .title(let title):
            return textWidth(title, font: font)
        case .attributed(let attributed):
            return attributedWidth(attributed)
        case .image, .imageSource:
            return renderedImageSide(style: style)
        case .titleImage(let title, _, _):
            return textWidth(title, font: font) + renderedImageSide(style: style) + style.imageSpacing
        case .titleImageSource(let title, _, _, _):
            return textWidth(title, font: font) + renderedImageSide(style: style) + style.imageSpacing
        case .custom:
            return 44
        }
    }

    static func badgeWidth(_ badge: PTSegmentBadge?) -> CGFloat? {
        guard let badge else { return nil }
        if let text = badge.text, !text.isEmpty {
            let textWidth = textWidth(text, font: badge.font)
            return max(badgeMinimumWidth, textWidth + badgeHorizontalPadding * 2)
        }
        return badge.showsDotWhenEmpty ? badgeDotDiameter : nil
    }

    static func contentWidth(item: PTSegmentItem, style: PTSegmentStyle) -> CGFloat {
        let normalWidth = bodyWidth(item: item, style: style, font: style.normalFont)
        let selectedWidth = bodyWidth(item: item, style: style, font: style.selectedFont)
        return ceil(max(normalWidth, selectedWidth * max(1, style.selectedScale)))
    }

    static func measuredWidth(item: PTSegmentItem, style: PTSegmentStyle) -> CGFloat {
        let normalBodyWidth = bodyWidth(item: item, style: style, font: style.normalFont)
        let selectedBodyWidth = bodyWidth(item: item, style: style, font: style.selectedFont)
        let badgeWidth = badgeWidth(item.badge) ?? 0
        let badgeSpacing = badgeWidth > 0 && normalBodyWidth > 0 ? style.imageSpacing : 0
        let normalWidth = normalBodyWidth + badgeWidth + badgeSpacing
        let selectedWidth = (selectedBodyWidth + badgeWidth + badgeSpacing) * max(1, style.selectedScale)
        return max(1, ceil(max(normalWidth, selectedWidth) + style.itemInsets.left + style.itemInsets.right))
    }

    static func badgeAccessibilityValue(_ badge: PTSegmentBadge?) -> String? {
        guard let badge, let text = badge.text, !text.isEmpty else { return nil }
        return text
    }
}

// English: Adds stable padding and minimum dimensions to a badge label.
// Español: Añade relleno estable y dimensiones mínimas a una etiqueta de insignia.
// 中文：为徽标文本提供稳定内边距和最小尺寸。
@MainActor
private final class PTSegmentBadgeLabel: UILabel {
    var contentInsets = UIEdgeInsets(top: PTSegmentMeasurement.badgeVerticalPadding,
                                      left: PTSegmentMeasurement.badgeHorizontalPadding,
                                      bottom: PTSegmentMeasurement.badgeVerticalPadding,
                                      right: PTSegmentMeasurement.badgeHorizontalPadding) {
        didSet { invalidateIntrinsicContentSize() }
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: max(PTSegmentMeasurement.badgeMinimumWidth,
                                 size.width + contentInsets.left + contentInsets.right),
                      height: max(PTSegmentMeasurement.badgeMinimumHeight,
                                  size.height + contentInsets.top + contentInsets.bottom))
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: contentInsets))
    }
}

@MainActor
public class PTMainSegmentCell: UICollectionViewCell {
    public static let reuseIdentifier = "PTMainSegmentCell"
    public let lineView = UIView()
    public let titleLabel = UILabel()
    public let subTitleLabel = UILabel()
    public let imageIcon = UIImageView()
    public private(set) var representedID: AnyHashable?
    internal private(set) var indicatorContentFrame = CGRect.zero

    private let contentStack = UIStackView()
    private let badgeLabel = PTSegmentBadgeLabel()
    private let badgeDot = UIView()
    private var imageTask: Task<Void, Never>?
    private var imageWidthConstraint: NSLayoutConstraint?
    private var imageHeightConstraint: NSLayoutConstraint?
    private var contentLeadingConstraint: NSLayoutConstraint?
    private var contentTrailingConstraint: NSLayoutConstraint?
    private var contentTopConstraint: NSLayoutConstraint?
    private var contentBottomConstraint: NSLayoutConstraint?
    private var badgeDotWidthConstraint: NSLayoutConstraint?
    private var badgeDotHeightConstraint: NSLayoutConstraint?

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
        contentLeadingConstraint = contentStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
        contentTrailingConstraint = contentStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        contentTopConstraint = contentStack.topAnchor.constraint(equalTo: contentView.topAnchor)
        contentBottomConstraint = contentStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        NSLayoutConstraint.activate([
            contentLeadingConstraint,
            contentTrailingConstraint,
            contentTopConstraint,
            contentBottomConstraint
        ].compactMap { $0 })
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
        badgeDotWidthConstraint = badgeDot.widthAnchor.constraint(equalToConstant: PTSegmentMeasurement.badgeDotDiameter)
        badgeDotHeightConstraint = badgeDot.heightAnchor.constraint(equalToConstant: PTSegmentMeasurement.badgeDotDiameter)
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
        contentLeadingConstraint?.constant = style.itemInsets.left
        contentTrailingConstraint?.constant = -style.itemInsets.right
        contentTopConstraint?.constant = style.itemInsets.top
        contentBottomConstraint?.constant = -style.itemInsets.bottom
        contentStack.spacing = style.imageSpacing
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
            addImage(placeholder, style: style, reservesSpace: true)
            loadImage(source: source, placeholder: placeholder, identifier: item.id, style: style)
        case .titleImageSource(let title, let source, let placement, let placeholder):
            addTitleImage(title: title,
                          image: placeholder,
                          placement: placement,
                          style: style,
                          selected: selected,
                          reservesImageSpace: true)
            loadImage(source: source, placeholder: placeholder, identifier: item.id, style: style)
        case .custom(let custom):
            contentStack.addArrangedSubview(custom.makeView())
        }
        configureBadge(item.badge)
        accessibilityLabel = item.accessibilityLabel ?? accessibilityText(for: item.content)
        accessibilityValue = PTSegmentMeasurement.badgeAccessibilityValue(item.badge)
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
        titleLabel.numberOfLines = 1
        imageIcon.image = nil
        subTitleLabel.isHidden = true
        badgeLabel.removeFromSuperview()
        badgeDot.removeFromSuperview()
        badgeDotWidthConstraint?.isActive = false
        badgeDotHeightConstraint?.isActive = false
        contentStack.axis = .horizontal
        imageWidthConstraint?.isActive = false
        imageHeightConstraint?.isActive = false
        indicatorContentFrame = .zero
    }

    private func addTitle(_ title: String, style: PTSegmentStyle, selected: Bool) {
        titleLabel.text = title
        titleLabel.font = selected ? style.selectedFont : style.normalFont
        contentStack.addArrangedSubview(titleLabel)
    }

    private func addImage(_ image: UIImage?, style: PTSegmentStyle, reservesSpace: Bool = false) {
        imageIcon.image = image
        if image != nil || reservesSpace {
            contentStack.addArrangedSubview(imageIcon)
            updateImageSizeConstraints(style: style)
        }
    }

    private func addTitleImage(title: String,
                               image: UIImage?,
                               placement: PTImagePlacement,
                               style: PTSegmentStyle,
                               selected: Bool,
                               reservesImageSpace: Bool = false) {
        titleLabel.text = title
        titleLabel.font = selected ? style.selectedFont : style.normalFont
        imageIcon.image = image
        contentStack.axis = (placement == .top || placement == .bottom) ? .vertical : .horizontal
        if placement == .trailing || placement == .bottom {
            contentStack.addArrangedSubview(titleLabel)
            if image != nil || reservesImageSpace { contentStack.addArrangedSubview(imageIcon) }
        } else {
            if image != nil || reservesImageSpace { contentStack.addArrangedSubview(imageIcon) }
            contentStack.addArrangedSubview(titleLabel)
        }
        if image != nil || reservesImageSpace {
            updateImageSizeConstraints(style: style)
        }
    }

    /// English: Reuses one width and height pair so cell reuse never accumulates conflicting constraints.
    /// Español: Reutiliza un único par de restricciones para que la reutilización no acumule conflictos.
    /// 中文：复用同一组宽高约束，避免 Cell 重用时不断累积冲突约束。
    private func updateImageSizeConstraints(style: PTSegmentStyle) {
        if imageWidthConstraint == nil {
            imageWidthConstraint = imageIcon.widthAnchor.constraint(equalToConstant: 1)
        }
        if imageHeightConstraint == nil {
            imageHeightConstraint = imageIcon.heightAnchor.constraint(equalToConstant: 1)
        }
        let size = PTSegmentMeasurement.renderedImageSide(style: style)
        imageWidthConstraint?.constant = size
        imageHeightConstraint?.constant = size
        imageWidthConstraint?.isActive = true
        imageHeightConstraint?.isActive = true
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
            badgeDot.layer.cornerRadius = PTSegmentMeasurement.badgeDotDiameter / 2
            contentStack.addArrangedSubview(badgeDot)
            badgeDotWidthConstraint?.isActive = true
            badgeDotHeightConstraint?.isActive = true
        }
    }

    private func accessibilityText(for content: PTSegmentContent) -> String? {
        switch content {
        case .title(let value), .titleImage(let value, _, _), .titleImageSource(let value, _, _, _): return value
        case .attributed(let value): return value.string
        default: return nil
        }
    }

    public static func measuredWidth(item: PTSegmentItem, style: PTSegmentStyle) -> CGFloat {
        PTSegmentMeasurement.measuredWidth(item: item, style: style)
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        contentStack.layoutIfNeeded()
        badgeLabel.layer.cornerRadius = badgeLabel.bounds.height / 2
        let contentViews = contentStack.arrangedSubviews.filter { $0 !== badgeLabel && $0 !== badgeDot }
        guard let firstFrame = contentViews.first?.frame else {
            indicatorContentFrame = .zero
            return
        }
        let contentFrame = contentViews.dropFirst().reduce(firstFrame) { $0.union($1.frame) }
        indicatorContentFrame = contentStack.convert(contentFrame, to: self)
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
