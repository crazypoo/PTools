// English: Diffable, stable-ID segmented control with composable native indicators.
// Español: Control segmentado nativo con Diffable, identificadores estables e indicadores componibles.
// 中文：基于 Diffable、稳定 ID 和可组合原生指示器的分段控件。

import UIKit

@MainActor
private enum PTIndicatorLayout {
    static func frame(for id: AnyHashable,
                      context: PTSegmentIndicatorContext,
                      height: CGFloat,
                      defaultWidth: CGFloat? = nil) -> CGRect {
        guard let itemFrame = context.itemFrames[id] else { return .zero }
        let width: CGFloat
        switch context.widthPolicy {
        case .fixed(let value):
            width = value
        case .item:
            width = itemFrame.width
        case .content:
            width = defaultWidth ?? min(itemFrame.width, max(1, itemFrame.width - 12))
        }
        let x = itemFrame.midX - width / 2
        let y: CGFloat
        switch context.placement {
        case .top:
            y = itemFrame.minY
        case .center:
            y = itemFrame.midY - height / 2
        case .bottom:
            y = itemFrame.maxY - height
        case .custom(let resolver):
            return resolver(itemFrame, context.bounds)
        }
        return CGRect(x: x, y: y, width: width, height: height)
    }

    static func interpolated(from: CGRect, to: CGRect, progress: CGFloat) -> CGRect {
        let value = min(max(progress, 0), 1)
        return CGRect(x: from.origin.x + (to.origin.x - from.origin.x) * value,
                      y: from.origin.y + (to.origin.y - from.origin.y) * value,
                      width: from.width + (to.width - from.width) * value,
                      height: from.height + (to.height - from.height) * value)
    }
}

/// English: Base implementation for simple indicator views.
/// Español: Implementación base para indicadores sencillos.
/// 中文：简单指示器 View 的基础实现。
@MainActor
open class PTBaseSegmentIndicator: UIView, PTSegmentIndicator {
    public var view: UIView { self }
    open var color: UIColor = .systemBlue
    open var height: CGFloat = 2
    open var placement: PTSegmentIndicatorPlacement = .bottom
    open var widthPolicy: PTIndicatorWidthPolicy = .content
    fileprivate var context: PTSegmentIndicatorContext?
    fileprivate var selectedID: AnyHashable?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        isUserInteractionEnabled = false
    }

    open func prepare(context: PTSegmentIndicatorContext) {
        self.context = context
        guard let selectedID = context.selectedID else {
            frame = .zero
            return
        }
        frame = PTIndicatorLayout.frame(for: selectedID,
                                        context: context,
                                        height: height)
        backgroundColor = color
    }

    open func update(transition: PTSegmentTransition) {
        guard let context else { return }
        let from = PTIndicatorLayout.frame(for: transition.fromID,
                                           context: context,
                                           height: height)
        let to = PTIndicatorLayout.frame(for: transition.toID,
                                         context: context,
                                         height: height)
        frame = PTIndicatorLayout.interpolated(from: from, to: to, progress: transition.progress)
    }

    open func select(item: PTSegmentSelectionState) {
        selectedID = item.selectedID
        guard let context, let selectedID = item.selectedID else { return }
        frame = PTIndicatorLayout.frame(for: selectedID,
                                        context: context,
                                        height: height)
    }
}

/// English: Standard content-width line indicator.
/// Español: Indicador de línea estándar con anchura del contenido.
/// 中文：标准内容宽度线条指示器。
@MainActor
open class PTLineIndicator: PTBaseSegmentIndicator {
    public init(color: UIColor = .systemBlue,
                height: CGFloat = 2,
                widthPolicy: PTIndicatorWidthPolicy = .content,
                placement: PTSegmentIndicatorPlacement = .bottom) {
        super.init(frame: .zero)
        self.color = color
        self.height = height
        self.widthPolicy = widthPolicy
        self.placement = placement
        backgroundColor = color
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { nil }
}

/// English: Line indicator that grows and shrinks during interactive transitions.
/// Español: Indicador de línea que crece y se reduce durante transiciones interactivas.
/// 中文：交互过渡期间伸缩宽度的线条指示器。
@MainActor
public final class PTStretchLineIndicator: PTLineIndicator {
    public override func update(transition: PTSegmentTransition) {
        super.update(transition: transition)
        let scale = 1 + sin(transition.progress * .pi) * 0.25
        transform = CGAffineTransform(scaleX: scale, y: 1)
    }
}

/// English: Dot indicator with a configurable diameter.
/// Español: Indicador de punto con diámetro configurable.
/// 中文：支持自定义直径的圆点指示器。
@MainActor
public final class PTDotIndicator: PTBaseSegmentIndicator {
    public init(color: UIColor = .systemBlue,
                diameter: CGFloat = 6,
                placement: PTSegmentIndicatorPlacement = .bottom) {
        super.init(frame: .zero)
        self.color = color
        self.height = diameter
        self.widthPolicy = .fixed(diameter)
        self.placement = placement
        backgroundColor = color
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = min(bounds.width, bounds.height) / 2
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { nil }
}

/// English: Two-line indicator for compact title and subtitle designs.
/// Español: Indicador de dos líneas para diseños compactos de título y subtítulo.
/// 中文：适合标题和副标题布局的双线指示器。
@MainActor
public final class PTDoubleLineIndicator: PTBaseSegmentIndicator {
    private let secondaryLine = UIView()

    public init(color: UIColor = .systemBlue,
                secondaryColor: UIColor = .secondaryLabel,
                height: CGFloat = 2,
                widthPolicy: PTIndicatorWidthPolicy = .content) {
        super.init(frame: .zero)
        self.color = color
        self.height = height
        self.widthPolicy = widthPolicy
        backgroundColor = color
        secondaryLine.backgroundColor = secondaryColor
        secondaryLine.isUserInteractionEnabled = false
        addSubview(secondaryLine)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        secondaryLine.frame = CGRect(x: 0,
                                     y: bounds.height + 3,
                                     width: bounds.width,
                                     height: max(1, bounds.height / 2))
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { nil }
}

/// English: Triangle indicator positioned below the selected item.
/// Español: Indicador triangular situado debajo del elemento seleccionado.
/// 中文：位于选中项下方的三角形指示器。
@MainActor
public final class PTTriangleIndicator: PTBaseSegmentIndicator {
    private let shapeLayer = CAShapeLayer()

    public init(color: UIColor = .systemBlue, size: CGSize = .init(width: 12, height: 6)) {
        super.init(frame: .zero)
        self.color = color
        self.height = size.height
        self.widthPolicy = .fixed(size.width)
        shapeLayer.fillColor = color.cgColor
        layer.addSublayer(shapeLayer)
        backgroundColor = .clear
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        shapeLayer.frame = bounds
        let path = UIBezierPath()
        path.move(to: CGPoint(x: bounds.midX, y: bounds.maxY))
        path.addLine(to: CGPoint(x: bounds.minX, y: bounds.minY))
        path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.minY))
        path.close()
        shapeLayer.path = path.cgPath
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { nil }
}

/// English: Background indicator that highlights the selected item.
/// Español: Indicador de fondo que resalta el elemento seleccionado.
/// 中文：高亮选中项背景的指示器。
@MainActor
open class PTBackgroundIndicator: PTBaseSegmentIndicator {
    private let inset: UIEdgeInsets

    public init(color: UIColor = .secondarySystemBackground,
                cornerRadius: CGFloat = 8,
                inset: UIEdgeInsets = .zero) {
        self.inset = inset
        super.init(frame: .zero)
        self.color = color
        self.height = 0
        self.widthPolicy = .item
        backgroundColor = color
        layer.cornerRadius = cornerRadius
        layer.masksToBounds = true
    }

    public override func prepare(context: PTSegmentIndicatorContext) {
        self.context = context
        guard let id = context.selectedID, let itemFrame = context.itemFrames[id] else {
            frame = .zero
            return
        }
        frame = itemFrame.inset(by: inset)
    }

    public override func select(item: PTSegmentSelectionState) {
        guard let context, let id = item.selectedID, let itemFrame = context.itemFrames[id] else { return }
        frame = itemFrame.inset(by: inset)
    }

    public override func update(transition: PTSegmentTransition) {
        guard let context,
              let from = context.itemFrames[transition.fromID],
              let to = context.itemFrames[transition.toID] else { return }
        frame = PTIndicatorLayout.interpolated(from: from.inset(by: inset),
                                               to: to.inset(by: inset),
                                               progress: transition.progress)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { nil }
}

/// English: Gradient background indicator with a single reusable gradient layer.
/// Español: Indicador de fondo degradado con una única capa reutilizable.
/// 中文：使用单个可复用渐变层的背景指示器。
@MainActor
public final class PTGradientIndicator: PTBackgroundIndicator {
    private let gradientLayer = CAGradientLayer()

    public init(colors: [UIColor], cornerRadius: CGFloat = 8, inset: UIEdgeInsets = .zero) {
        super.init(color: .clear, cornerRadius: cornerRadius, inset: inset)
        gradientLayer.colors = colors.map(\.cgColor)
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        layer.insertSublayer(gradientLayer, at: 0)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        gradientLayer.cornerRadius = layer.cornerRadius
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { nil }
}

/// English: Image-backed indicator for custom branded navigation.
/// Español: Indicador basado en imagen para navegación de marca personalizada.
/// 中文：用于品牌化导航的图片指示器。
@MainActor
public final class PTImageIndicator: PTBaseSegmentIndicator {
    private let imageView = UIImageView()

    public init(image: UIImage,
                size: CGSize? = nil,
                placement: PTSegmentIndicatorPlacement = .bottom) {
        super.init(frame: .zero)
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)
        self.height = size?.height ?? image.size.height
        self.widthPolicy = .fixed(size?.width ?? image.size.width)
        self.placement = placement
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { nil }
}

/// English: A stable-ID segmented view backed by UICollectionViewDiffableDataSource.
/// Español: Vista segmentada basada en UICollectionViewDiffableDataSource e identificadores estables.
/// 中文：基于 UICollectionViewDiffableDataSource 和稳定 ID 的分段 View。
@MainActor
open class PTSegmentedView: UIView, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate {
    private enum Section { case main }
    private struct SnapshotID: Hashable, Sendable {
        let raw: String
    }

    public let collectionView: UICollectionView
    public var style = PTSegmentStyle() {
        didSet {
            collectionView.collectionViewLayout.invalidateLayout()
            collectionView.reloadData()
            setNeedsLayout()
        }
    }
    public var indicators: [any PTSegmentIndicator] = [] {
        didSet { rebuildIndicators() }
    }
    public private(set) var items: [PTSegmentItem] = []
    public private(set) var selectionState = PTSegmentSelectionState()
    public var onSelectionChanged: ((PTSegmentSelectionEvent) -> Void)?
    public var onTransition: ((PTSegmentTransition) -> Void)?
    public var allowsReselect = true
    public var automaticallyScrollsToSelectedItem = true
    public var selectionAnimationDuration: TimeInterval = 0.25

    private let indicatorHost = UIView()
    private var dataSource: UICollectionViewDiffableDataSource<Section, SnapshotID>!
    private var snapshotItems = [SnapshotID: PTSegmentItem]()
    private var isApplyingSnapshot = false

    public override init(frame: CGRect) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = .zero
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(frame: frame)
        configureView()
    }

    public required init?(coder: NSCoder) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(coder: coder)
        configureView()
    }

    private func configureView() {
        backgroundColor = .clear
        indicatorHost.isUserInteractionEnabled = false
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = true
        collectionView.delegate = self
        collectionView.register(PTMainSegmentCell.self, forCellWithReuseIdentifier: PTMainSegmentCell.reuseIdentifier)
        addSubview(indicatorHost)
        addSubview(collectionView)
        dataSource = UICollectionViewDiffableDataSource<Section, SnapshotID>(collectionView: collectionView) { [weak self] collectionView, indexPath, identifier in
            guard let self,
                  let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PTMainSegmentCell.reuseIdentifier,
                                                                 for: indexPath) as? PTMainSegmentCell,
                  let item = self.snapshotItems[identifier] else {
                return nil
            }
            cell.configure(item: item,
                           style: self.style,
                           selected: item.id == self.selectionState.selectedID)
            return cell
        }
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        indicatorHost.frame = bounds
        collectionView.frame = bounds
        collectionView.collectionViewLayout.invalidateLayout()
        updateIndicatorContext()
    }

    /// English: Applies a new stable-ID snapshot without touching business page state.
    /// Español: Aplica un nuevo snapshot de identificadores estables sin tocar el estado de las páginas.
    /// 中文：应用新的稳定 ID 快照，不修改业务页面状态。
    public func apply(items newItems: [PTSegmentItem],
                      animatingDifferences: Bool = true,
                      completion: (() -> Void)? = nil) {
        var seen = Set<AnyHashable>()
        items = newItems.filter { seen.insert($0.id).inserted }
        let oldSelection = selectionState
        if let selectedID = selectionState.selectedID,
           let index = items.firstIndex(where: { $0.id == selectedID }) {
            selectionState = PTSegmentSelectionState(selectedID: selectedID, selectedIndex: index)
        } else if let first = items.first {
            selectionState = PTSegmentSelectionState(selectedID: first.id, selectedIndex: 0)
        } else {
            selectionState = PTSegmentSelectionState()
        }

        snapshotItems.removeAll(keepingCapacity: true)
        var usedKeys = Set<SnapshotID>()
        let snapshotIDs: [SnapshotID] = items.map { item in
            let base = String(reflecting: item.id.base)
            var candidate = SnapshotID(raw: base)
            var suffix = 1
            while usedKeys.contains(candidate) {
                candidate = SnapshotID(raw: "\(base)#\(suffix)")
                suffix += 1
            }
            usedKeys.insert(candidate)
            snapshotItems[candidate] = item
            return candidate
        }
        var snapshot = NSDiffableDataSourceSnapshot<Section, SnapshotID>()
        snapshot.appendSections([.main])
        snapshot.appendItems(snapshotIDs, toSection: .main)
        isApplyingSnapshot = true
        dataSource.apply(snapshot, animatingDifferences: animatingDifferences) { [weak self] in
            guard let self else { return }
            self.isApplyingSnapshot = false
            self.updateVisibleCells()
            self.updateIndicatorContext()
            if oldSelection.selectedID != self.selectionState.selectedID,
               let selectedID = self.selectionState.selectedID {
                self.emitSelectionChange(from: oldSelection,
                                         to: self.selectionState,
                                         origin: .restoration)
                self.scrollTo(id: selectedID, animated: false)
            }
            completion?()
        }
    }

    /// English: Selects a segment by stable identifier.
    /// Español: Selecciona un segmento mediante su identificador estable.
    /// 中文：通过稳定 ID 选择分段项。
    public func select(id: AnyHashable,
                       animated: Bool = true,
                       origin: PTSegmentSelectionOrigin = .programmatic) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        let oldSelection = selectionState
        if oldSelection.selectedID == id, !allowsReselect { return }
        selectionState = PTSegmentSelectionState(selectedID: id, selectedIndex: index)
        updateVisibleCells()
        if automaticallyScrollsToSelectedItem { scrollTo(id: id, animated: animated) }
        updateIndicatorContext()
        emitSelectionChange(from: oldSelection, to: selectionState, origin: origin)
    }

    /// English: Selects a segment by index while preserving the stable-ID source of truth.
    /// Español: Selecciona un segmento por índice conservando el identificador estable como fuente de verdad.
    /// 中文：按索引选择分段，但仍以稳定 ID 作为唯一状态来源。
    public func select(index: Int,
                       animated: Bool = true,
                       origin: PTSegmentSelectionOrigin = .programmatic) {
        guard items.indices.contains(index) else { return }
        select(id: items[index].id, animated: animated, origin: origin)
    }

    /// English: Updates indicators while a page container is interactively scrolling.
    /// Español: Actualiza los indicadores mientras un contenedor de páginas se desplaza de forma interactiva.
    /// 中文：页面容器交互滚动时更新指示器。
    public func update(transition: PTSegmentTransition) {
        indicators.forEach { $0.update(transition: transition) }
        onTransition?(transition)
    }

    private func emitSelectionChange(from old: PTSegmentSelectionState,
                                     to new: PTSegmentSelectionState,
                                     origin: PTSegmentSelectionOrigin) {
        let event = PTSegmentSelectionEvent(oldSelection: old, newSelection: new, origin: origin)
        onSelectionChanged?(event)
        indicators.forEach { $0.select(item: new) }
    }

    private func scrollTo(id: AnyHashable, animated: Bool) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        guard collectionView.numberOfItems(inSection: 0) > index else { return }
        collectionView.scrollToItem(at: IndexPath(item: index, section: 0),
                                     at: .centeredHorizontally,
                                     animated: animated)
    }

    private func updateVisibleCells() {
        for cell in collectionView.visibleCells.compactMap({ $0 as? PTMainSegmentCell }) {
            guard let id = cell.representedID,
                  let item = items.first(where: { $0.id == id }) else { continue }
            cell.applySelection(id == selectionState.selectedID, style: style)
            cell.configure(item: item, style: style, selected: id == selectionState.selectedID)
        }
    }

    private func rebuildIndicators() {
        indicatorHost.subviews.forEach { $0.removeFromSuperview() }
        indicators.forEach { indicatorHost.addSubview($0.view) }
        setNeedsLayout()
    }

    private func updateIndicatorContext() {
        guard !bounds.isEmpty else { return }
        let attributes = collectionView.collectionViewLayout.layoutAttributesForElements(in: collectionView.bounds) ?? []
        let frames = Dictionary(uniqueKeysWithValues: attributes.compactMap { attribute -> (AnyHashable, CGRect)? in
            guard attribute.representedElementCategory == .cell,
                  items.indices.contains(attribute.indexPath.item) else { return nil }
            return (items[attribute.indexPath.item].id, attribute.frame)
        })
        let context = PTSegmentIndicatorContext(bounds: bounds,
                                                 itemFrames: frames,
                                                 selectedID: selectionState.selectedID)
        indicators.forEach { $0.prepare(context: context) }
        if let selectedID = selectionState.selectedID {
            indicators.forEach { $0.select(item: PTSegmentSelectionState(selectedID: selectedID,
                                                                          selectedIndex: selectionState.selectedIndex)) }
        }
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard items.indices.contains(indexPath.item) else { return }
        select(index: indexPath.item, animated: true, origin: .tap)
    }

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard items.indices.contains(indexPath.item) else { return CGSize(width: 1, height: style.itemHeight) }
        let width: CGFloat
        if let itemWidths = style.itemWidths, itemWidths.indices.contains(indexPath.item) {
            width = itemWidths[indexPath.item]
        } else {
            let intrinsic = PTMainSegmentCell.measuredWidth(item: items[indexPath.item], style: style)
            switch style.distribution {
            case .intrinsic:
                width = intrinsic
            case .equal:
                width = bounds.width / CGFloat(max(items.count, 1))
            case .adaptive:
                let total = items.reduce(CGFloat.zero) { $0 + PTMainSegmentCell.measuredWidth(item: $1, style: style) }
                width = total <= bounds.width ? bounds.width / CGFloat(max(items.count, 1)) : intrinsic
            }
        }
        return CGSize(width: max(1, width), height: max(1, style.itemHeight))
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !isApplyingSnapshot, items.count > 1 else { return }
        let center = scrollView.bounds.midX + scrollView.contentOffset.x
        let attributes = collectionView.collectionViewLayout.layoutAttributesForElements(in: scrollView.bounds.insetBy(dx: -bounds.width, dy: 0)) ?? []
        let sorted = attributes.filter { $0.representedElementCategory == .cell }.sorted { abs($0.center.x - center) < abs($1.center.x - center) }
        guard let nearest = sorted.first,
              let currentIndex = selectionState.selectedIndex,
              nearest.indexPath.item != currentIndex,
              items.indices.contains(currentIndex),
              items.indices.contains(nearest.indexPath.item) else { return }
        let direction: PTPageDirection = nearest.indexPath.item > currentIndex ? .forward : .backward
        let distance = max(1, abs(nearest.center.x - (attributes.first(where: { $0.indexPath.item == currentIndex })?.center.x ?? nearest.center.x)))
        let progress = min(1, abs(center - (attributes.first(where: { $0.indexPath.item == currentIndex })?.center.x ?? center)) / distance)
        update(transition: PTSegmentTransition(fromID: items[currentIndex].id,
                                                toID: items[nearest.indexPath.item].id,
                                                progress: progress,
                                                direction: direction))
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        commitCenteredItem(origin: .swipe)
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        commitCenteredItem(origin: .programmatic)
    }

    private func commitCenteredItem(origin: PTSegmentSelectionOrigin) {
        let center = collectionView.bounds.midX + collectionView.contentOffset.x
        guard let attribute = collectionView.collectionViewLayout.layoutAttributesForElements(in: collectionView.bounds.insetBy(dx: -bounds.width, dy: 0))?
            .filter({ $0.representedElementCategory == .cell })
            .min(by: { abs($0.center.x - center) < abs($1.center.x - center) }),
              items.indices.contains(attribute.indexPath.item) else { return }
        select(index: attribute.indexPath.item, animated: false, origin: origin)
    }
}
