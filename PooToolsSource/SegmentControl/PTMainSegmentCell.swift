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
                          font: UIFont,
                          titleScale: CGFloat = 1) -> CGFloat {
        let safeScale = titleScale.isFinite && titleScale > 0 ? titleScale : 1
        switch item.content {
        case .title(let title):
            return textWidth(title, font: font) * safeScale
        case .attributed(let attributed):
            return attributedWidth(attributed) * safeScale
        case .image, .imageSource:
            return renderedImageSide(style: style)
        case .titleImage(let title, _, _):
            return textWidth(title, font: font) * safeScale + renderedImageSide(style: style) + style.imageSpacing
        case .titleImageSource(let title, _, _, _):
            return textWidth(title, font: font) * safeScale + renderedImageSide(style: style) + style.imageSpacing
        case .custom:
            return 44
        }
    }

    static func badgeWidth(item: PTSegmentItem, style: PTSegmentStyle) -> CGFloat {
        guard let descriptor = item.resolvedBadgeDescriptor else { return 0 }
        let configuration = descriptor.configuration ?? style.badgeConfiguration
        return PTBadgeLayoutMetrics.size(for: descriptor.content, configuration: configuration).width
    }

    static func contentWidth(item: PTSegmentItem, style: PTSegmentStyle) -> CGFloat {
        let normalBodyWidth = bodyWidth(item: item, style: style, font: style.normalFont)
        let selectedBodyWidth = bodyWidth(item: item,
                                          style: style,
                                          font: style.selectedFont,
                                          titleScale: style.titleZoomTransition == .selectedScale || abs(style.selectedScale - 1) > .ulpOfOne
                                              ? safeSelectedScale(style.selectedScale)
                                              : 1)
        let badgeWidth = badgeWidth(item: item, style: style)
        let badgeSpacing = badgeWidth > 0 && max(normalBodyWidth, selectedBodyWidth) > 0 ? style.imageSpacing : 0
        return ceil(max(normalBodyWidth, selectedBodyWidth) + badgeWidth + badgeSpacing)
    }

    static func measuredWidth(item: PTSegmentItem, style: PTSegmentStyle) -> CGFloat {
        let normalBodyWidth = bodyWidth(item: item, style: style, font: style.normalFont)
        let selectedBodyWidth = bodyWidth(item: item,
                                          style: style,
                                          font: style.selectedFont,
                                          titleScale: style.titleZoomTransition == .selectedScale || abs(style.selectedScale - 1) > .ulpOfOne
                                              ? safeSelectedScale(style.selectedScale)
                                              : 1)
        let badgeWidth = badgeWidth(item: item, style: style)
        let badgeSpacing = badgeWidth > 0 && normalBodyWidth > 0 ? style.imageSpacing : 0
        let normalWidth = normalBodyWidth + badgeWidth + badgeSpacing
        let selectedWidth = selectedBodyWidth + badgeWidth + badgeSpacing
        return max(1, ceil(max(normalWidth, selectedWidth) + style.itemInsets.left + style.itemInsets.right))
    }

    static func badgeAccessibilityValue(item: PTSegmentItem, style: PTSegmentStyle) -> String? {
        guard let descriptor = item.resolvedBadgeDescriptor else { return nil }
        return PTBadgeLayoutMetrics.displayText(for: descriptor.content,
                                                configuration: descriptor.configuration ?? style.badgeConfiguration)
    }

    private static func safeSelectedScale(_ value: CGFloat) -> CGFloat {
        value.isFinite && value > 0 ? value : 1
    }
}

// English: Interpolates resolved colors so dynamic system colors work in light and dark mode.
// Español: Interpola colores resueltos para que los colores dinámicos funcionen en ambos modos.
// 中文：先解析动态颜色再插值，确保浅色和深色模式都正确。
@MainActor
internal enum PTSegmentColorInterpolator {
    static func interpolate(from: UIColor,
                            to: UIColor,
                            progress: CGFloat,
                            traitCollection: UITraitCollection) -> UIColor {
        let value = min(max(progress, 0), 1)
        let resolvedFrom = from.resolvedColor(with: traitCollection)
        let resolvedTo = to.resolvedColor(with: traitCollection)
        var fromRed: CGFloat = 0
        var fromGreen: CGFloat = 0
        var fromBlue: CGFloat = 0
        var fromAlpha: CGFloat = 0
        var toRed: CGFloat = 0
        var toGreen: CGFloat = 0
        var toBlue: CGFloat = 0
        var toAlpha: CGFloat = 0
        guard resolvedFrom.getRed(&fromRed, green: &fromGreen, blue: &fromBlue, alpha: &fromAlpha),
              resolvedTo.getRed(&toRed, green: &toGreen, blue: &toBlue, alpha: &toAlpha) else {
            return value < 0.5 ? from : to
        }
        return UIColor(red: fromRed + (toRed - fromRed) * value,
                       green: fromGreen + (toGreen - fromGreen) * value,
                       blue: fromBlue + (toBlue - fromBlue) * value,
                       alpha: fromAlpha + (toAlpha - fromAlpha) * value)
    }
}

// English: Keeps first/last-item knowledge in the renderer instead of the business item model.
// Español: Mantiene la posición inicial/final en el renderizador y no en el modelo de negocio.
// 中文：将首尾位置保留在渲染器中，不污染业务分段模型。
internal struct PTSegmentCellLayoutContext {
    let index: Int
    let itemCount: Int
}

@MainActor
public class PTMainSegmentCell: UICollectionViewCell {
    public static let reuseIdentifier = "PTMainSegmentCell"
    /// English: Legacy separator view kept for 5.x source compatibility.
    /// Español: Vista separadora heredada conservada para la compatibilidad de código fuente 5.x.
    /// 中文：保留旧版分隔线 View，维持 5.x 源码兼容。
    @available(*, deprecated, message: "Configure item separators through PTSegmentStyle.itemSeparatorStyle.")
    public let lineView: UIView
    public let titleLabel = UILabel()
    public let subTitleLabel = UILabel()
    public let imageIcon = UIImageView()
    public private(set) var representedID: AnyHashable?
    internal private(set) var indicatorContentFrame = CGRect.zero
    internal var onBadgeRemoved: ((AnyHashable) -> Void)?

    private let separatorView: UIView
    private let contentStack = UIStackView()
    private let badgeView = PTInlineBadgeView()
    private var imageTask: Task<Void, Never>?
    private var imageWidthConstraint: NSLayoutConstraint?
    private var imageHeightConstraint: NSLayoutConstraint?
    private var contentLeadingConstraint: NSLayoutConstraint?
    private var contentTrailingConstraint: NSLayoutConstraint?
    private var contentTopConstraint: NSLayoutConstraint?
    private var contentBottomConstraint: NSLayoutConstraint?
    private var separatorLeadingConstraint: NSLayoutConstraint?
    private var separatorTrailingConstraint: NSLayoutConstraint?
    private var separatorTopConstraint: NSLayoutConstraint?
    private var separatorBottomConstraint: NSLayoutConstraint?
    private var separatorWidthConstraint: NSLayoutConstraint?
    private var separatorHeightConstraint: NSLayoutConstraint?
    private var separatorStyle: PTSegmentItemSeparatorStyle = .legacyDefault
    private var separatorLayoutContext = PTSegmentCellLayoutContext(index: 0, itemCount: 1)

    public override init(frame: CGRect) {
        let separator = UIView()
        lineView = separator
        separatorView = separator
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder: NSCoder) {
        let separator = UIView()
        lineView = separator
        separatorView = separator
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
        separatorView.backgroundColor = .separator
        separatorView.isAccessibilityElement = false
        separatorView.accessibilityElementsHidden = true
        separatorView.isUserInteractionEnabled = false
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separatorView)
        separatorLeadingConstraint = separatorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
        separatorTrailingConstraint = separatorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        separatorTopConstraint = separatorView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10)
        separatorBottomConstraint = separatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        separatorWidthConstraint = separatorView.widthAnchor.constraint(equalToConstant: 1)
        separatorHeightConstraint = separatorView.heightAnchor.constraint(equalToConstant: 0)
        separatorBottomConstraint?.priority = .defaultHigh
        NSLayoutConstraint.activate([
            separatorLeadingConstraint,
            separatorTopConstraint,
            separatorBottomConstraint,
            separatorWidthConstraint,
            separatorHeightConstraint
        ].compactMap { $0 })
        applySeparator(style: separatorStyle, context: separatorLayoutContext)
        badgeView.setContentHuggingPriority(.required, for: .horizontal)
        badgeView.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    /// English: Configures content, badge and image loading from one value model.
    /// Español: Configura contenido, insignia y carga de imagen desde un único modelo de valores.
    /// 中文：使用一个值模型统一配置内容、徽标和图片加载。
    public func configure(item: PTSegmentItem, style: PTSegmentStyle, selected: Bool) {
        configure(item: item,
                  style: style,
                  selected: selected,
                  layoutContext: PTSegmentCellLayoutContext(index: 0, itemCount: 1))
    }

    /// English: Configures a cell with snapshot-local position context for separator visibility.
    /// Español: Configura la celda con la posición local del snapshot para decidir la visibilidad del separador.
    /// 中文：使用当前 Snapshot 的位置上下文配置 Cell，从而正确判断分隔线是否显示。
    internal func configure(item: PTSegmentItem,
                            style: PTSegmentStyle,
                            selected: Bool,
                            layoutContext: PTSegmentCellLayoutContext) {
        imageTask?.cancel()
        imageTask = nil
        representedID = item.id
        applySeparator(style: style.itemSeparatorStyle, context: layoutContext)
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
        configureBadge(item.resolvedBadgeDescriptor, style: style)
        accessibilityLabel = item.accessibilityLabel ?? accessibilityText(for: item.content)
        accessibilityValue = PTSegmentMeasurement.badgeAccessibilityValue(item: item, style: style)
        accessibilityTraits = selected ? [.button, .selected] : [.button]
    }

    public func applySelection(_ selected: Bool, style: PTSegmentStyle) {
        applyTransition(selectedProgress: selected ? 1 : 0, style: style)
        accessibilityTraits = selected ? [.button, .selected] : [.button]
    }

    /// English: Applies the page-driven visual progress without scaling the badge or cell.
    /// Español: Aplica el progreso visual de página sin escalar la insignia ni la celda.
    /// 中文：应用页面驱动的视觉进度，但不缩放角标或整个 Cell。
    internal func applyTransition(selectedProgress: CGFloat, style: PTSegmentStyle) {
        let progress = min(max(selectedProgress, 0), 1)
        let titleColor: UIColor
        if style.titleColorTransition == .gradient {
            titleColor = PTSegmentColorInterpolator.interpolate(from: style.normalColor,
                                                                to: style.selectedColor,
                                                                progress: progress,
                                                                traitCollection: traitCollection)
        } else {
            titleColor = progress >= 1 ? style.selectedColor : style.normalColor
        }
        let backgroundColor = PTSegmentColorInterpolator.interpolate(from: style.normalBackgroundColor,
                                                                      to: style.selectedBackgroundColor,
                                                                      progress: progress,
                                                                      traitCollection: traitCollection)
        let titleScale = style.titleZoomTransition == .selectedScale || abs(style.selectedScale - 1) > .ulpOfOne
            ? 1 + (safeSelectedScale(style.selectedScale) - 1) * progress
            : 1
        titleLabel.font = progress >= 0.5 ? style.selectedFont : style.normalFont
        titleLabel.textColor = titleColor
        titleLabel.transform = CGAffineTransform(scaleX: titleScale, y: titleScale)
        subTitleLabel.font = progress >= 0.5 ? style.selectedFont : style.normalFont
        subTitleLabel.textColor = titleColor
        contentView.backgroundColor = backgroundColor
    }

    private func safeSelectedScale(_ value: CGFloat) -> CGFloat {
        value.isFinite && value > 0 ? value : 1
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
        badgeView.reset()
        badgeView.removeFromSuperview()
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

    private func configureBadge(_ descriptor: PTSegmentBadgeDescriptor?, style: PTSegmentStyle) {
        guard let descriptor else { return }
        let configuration = descriptor.configuration ?? style.badgeConfiguration
        badgeView.apply(content: descriptor.content,
                        configuration: configuration) { [weak self] in
            guard let self, let id = self.representedID else { return }
            self.onBadgeRemoved?(id)
        }
        contentStack.addArrangedSubview(badgeView)
    }

    /// English: Resolves separator visibility once from the current snapshot position.
    /// Español: Resuelve una sola vez la visibilidad según la posición del snapshot actual.
    /// 中文：根据当前 Snapshot 位置集中计算分隔线可见性。
    private func resolveSeparatorVisibility(style: PTSegmentItemSeparatorStyle,
                                            context: PTSegmentCellLayoutContext) -> Bool {
        guard case .line(let configuration) = style,
              context.itemCount > 0,
              context.index >= 0,
              context.index < context.itemCount else {
            return false
        }
        switch configuration.visibility {
        case .allItems:
            return true
        case .betweenItems:
            switch configuration.placement {
            case .leading:
                return context.index > 0
            case .trailing:
                return context.index < context.itemCount - 1
            }
        }
    }

    /// English: Applies one reusable separator view and one reusable constraint set.
    /// Español: Aplica una sola vista separadora reutilizable y un único conjunto de restricciones.
    /// 中文：复用一个分隔线 View 和一组约束，避免 Cell 重用时不断创建对象。
    private func applySeparator(style: PTSegmentItemSeparatorStyle,
                                context: PTSegmentCellLayoutContext) {
        separatorStyle = style
        separatorLayoutContext = context
        guard case .line(let rawConfiguration) = style else {
            separatorView.isHidden = true
            separatorView.backgroundColor = .clear
            separatorLeadingConstraint?.isActive = true
            separatorTrailingConstraint?.isActive = false
            separatorTopConstraint?.constant = 0
            separatorBottomConstraint?.constant = 0
            separatorWidthConstraint?.constant = 1
            separatorHeightConstraint?.constant = 0
            return
        }

        let configuration = rawConfiguration.normalized
        separatorView.isHidden = !resolveSeparatorVisibility(style: .line(configuration), context: context)
        separatorView.backgroundColor = configuration.color
        separatorTopConstraint?.constant = configuration.topInset
        separatorBottomConstraint?.constant = -configuration.bottomInset
        separatorWidthConstraint?.constant = configuration.thickness
        switch configuration.placement {
        case .leading:
            separatorLeadingConstraint?.isActive = true
            separatorTrailingConstraint?.isActive = false
        case .trailing:
            separatorLeadingConstraint?.isActive = false
            separatorTrailingConstraint?.isActive = true
        }
        updateSeparatorHeight(configuration: configuration)
    }

    /// English: Clamps the rendered height so oversized insets never create a negative constraint.
    /// Español: Limita la altura para que unos insets excesivos nunca creen una restricción negativa.
    /// 中文：限制分隔线高度，避免上下内边距过大时生成负高度约束。
    private func updateSeparatorHeight(configuration: PTSegmentItemSeparatorConfiguration? = nil) {
        guard case .line(let rawConfiguration) = separatorStyle else {
            separatorHeightConstraint?.constant = 0
            return
        }
        let value = (configuration ?? rawConfiguration).normalized
        separatorHeightConstraint?.constant = max(0, bounds.height - value.topInset - value.bottomInset)
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
        if case .line(let configuration) = separatorStyle {
            updateSeparatorHeight(configuration: configuration)
        }
        contentStack.layoutIfNeeded()
        let contentViews = contentStack.arrangedSubviews.filter { $0 !== badgeView }
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
        onBadgeRemoved = nil
        applySeparator(style: .none, context: PTSegmentCellLayoutContext(index: 0, itemCount: 0))
        removeStackContent()
    }
}
