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
            let contentFrame = context.contentFrames[id] ?? itemFrame
            width = defaultWidth ?? min(itemFrame.width, max(1, contentFrame.width))
        }
        let contentFrame = context.contentFrames[id] ?? itemFrame
        let centerX: CGFloat
        switch context.widthPolicy {
        case .content:
            centerX = contentFrame.midX
        case .fixed, .item:
            centerX = itemFrame.midX
        }
        let x = centerX - width / 2
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

    fileprivate func resolvedContext(from context: PTSegmentIndicatorContext) -> PTSegmentIndicatorContext {
        PTSegmentIndicatorContext(bounds: context.bounds,
                                  itemFrames: context.itemFrames,
                                  selectedID: context.selectedID,
                                  placement: placement,
                                  widthPolicy: widthPolicy,
                                  contentFrames: context.contentFrames)
    }

    open func prepare(context: PTSegmentIndicatorContext) {
        let effectiveContext = resolvedContext(from: context)
        self.context = effectiveContext
        guard let selectedID = effectiveContext.selectedID else {
            frame = .zero
            return
        }
        frame = PTIndicatorLayout.frame(for: selectedID,
                                        context: effectiveContext,
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
        let effectiveContext = resolvedContext(from: context)
        self.context = effectiveContext
        guard let id = effectiveContext.selectedID, let itemFrame = effectiveContext.itemFrames[id] else {
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
    private enum PTSegmentScrollIntent {
        case idle
        case centeringSelectedItem
        case userBrowsingSegments
    }
    private struct SnapshotID: Hashable, Sendable {
        let value: Int
    }

    public let collectionView: UICollectionView
    public var style = PTSegmentStyle() {
        didSet {
            updateFlowLayoutSpacing()
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
    /// English: Optional legacy-style selection callbacks without taking ownership of the data source.
    /// Español: Callbacks opcionales de selección al estilo legado sin apropiarse de la fuente de datos.
    /// 中文：提供类似旧版代理的可选选择回调，但不接管数据源。
    public var onItemSelected: ((Int, PTSegmentSelectionOrigin) -> Void)?
    public var onReselected: ((Int) -> Void)?
    public var onScrolling: ((Int, Int, CGFloat) -> Void)?
    /// English: Reports an inline badge removal so the owner can update its source model.
    /// Español: Informa de la eliminación de una insignia integrada para que el propietario actualice su modelo.
    /// 中文：通知业务方内嵌角标已移除，由业务方更新数据源模型。
    public var onBadgeRemoved: ((AnyHashable) -> Void)?
    public var allowsReselect = true
    public var automaticallyScrollsToSelectedItem = true
    public var selectionAnimationDuration: TimeInterval = 0.25

    private let indicatorHost = UIView()
    private var dataSource: UICollectionViewDiffableDataSource<Section, SnapshotID>!
    private var snapshotItems = [SnapshotID: PTSegmentItem]()
    private var snapshotIDsByBusinessID = [AnyHashable: SnapshotID]()
    private var nextSnapshotID = 0
    private var isApplyingSnapshot = false
    private var selectionObservers = [((PTSegmentSelectionEvent) -> Void)]()
    private var transitionObservers = [((PTSegmentTransition) -> Void)]()
    private var scrollIntent = PTSegmentScrollIntent.idle
    private var selectionAnimator: UIViewPropertyAnimator?
    private var cachedResolvedSpacing: CGFloat?

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
        addSubview(collectionView)
        addSubview(indicatorHost)
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
            cell.onBadgeRemoved = { [weak self] id in
                self?.onBadgeRemoved?(id)
            }
            return cell
        }
        updateFlowLayoutSpacing()
    }

    /// English: Converts a public business ID into a private Sendable diffable-data-source ID.
    /// Español: Convierte un ID público de negocio en un ID privado y Sendable para el origen diffable.
    /// 中文：将公开的业务 ID 转换为私有且满足 Sendable 的 Diffable 数据源 ID。
    private func snapshotID(for businessID: AnyHashable) -> SnapshotID {
        if let existingID = snapshotIDsByBusinessID[businessID] {
            return existingID
        }
        let identifier = SnapshotID(value: nextSnapshotID)
        nextSnapshotID += 1
        snapshotIDsByBusinessID[businessID] = identifier
        return identifier
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        indicatorHost.frame = bounds
        collectionView.frame = bounds
        updateFlowLayoutSpacing()
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
        let snapshotIDs: [SnapshotID] = items.map { item in
            let identifier = snapshotID(for: item.id)
            snapshotItems[identifier] = item
            return identifier
        }
        var snapshot = NSDiffableDataSourceSnapshot<Section, SnapshotID>()
        snapshot.appendSections([.main])
        snapshot.appendItems(snapshotIDs, toSection: .main)
        collectionView.collectionViewLayout.invalidateLayout()
        cachedResolvedSpacing = nil
        updateFlowLayoutSpacing()
        isApplyingSnapshot = true
        dataSource.apply(snapshot, animatingDifferences: animatingDifferences) { [weak self] in
            guard let self else { return }
            self.isApplyingSnapshot = false
            self.collectionView.collectionViewLayout.invalidateLayout()
            self.collectionView.layoutIfNeeded()
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
        selectionAnimator?.stopAnimation(true)
        selectionAnimator = nil
        selectionState = PTSegmentSelectionState(selectedID: id, selectedIndex: index)
        updateVisibleCells()
        let shouldAnimate = oldSelection.selectedID != id
            && animated
            && origin != .swipe
            && style.selectionTransition == .animated
            && !UIAccessibility.isReduceMotionEnabled
        if shouldAnimate {
            animateSelection(from: oldSelection.selectedID, to: id)
        }
        if automaticallyScrollsToSelectedItem {
            scrollTo(id: id, animated: animated && !UIAccessibility.isReduceMotionEnabled)
        }
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
        selectionAnimator?.stopAnimation(true)
        selectionAnimator = nil
        updateIndicatorContext()
        applyInteractiveTransition(transition)
        indicators.forEach { $0.update(transition: transition) }
        onTransition?(transition)
        transitionObservers.forEach { $0(transition) }
        if let fromIndex = items.firstIndex(where: { $0.id == transition.fromID }),
           let toIndex = items.firstIndex(where: { $0.id == transition.toID }) {
            onScrolling?(fromIndex, toIndex, transition.progress)
        }
    }

    private func emitSelectionChange(from old: PTSegmentSelectionState,
                                     to new: PTSegmentSelectionState,
                                     origin: PTSegmentSelectionOrigin) {
        let event = PTSegmentSelectionEvent(oldSelection: old, newSelection: new, origin: origin)
        onSelectionChanged?(event)
        selectionObservers.forEach { $0(event) }
        if let selectedIndex = new.selectedIndex {
            onItemSelected?(selectedIndex, origin)
            if origin == .tap, old.selectedID == new.selectedID {
                onReselected?(selectedIndex)
            }
        }
        indicators.forEach { $0.select(item: new) }
    }

    /// English: Adds an internal observer used by coordinators while preserving the public callback.
    /// Español: Añade un observador interno para coordinadores sin reemplazar el callback público.
    /// 中文：增加供协调器使用的内部观察者，同时保留业务公开回调。
    internal func addSelectionObserver(_ observer: @escaping (PTSegmentSelectionEvent) -> Void) {
        selectionObservers.append(observer)
    }

    /// English: Adds an internal transition observer without replacing the public transition callback.
    /// Español: Añade un observador interno de transición sin reemplazar el callback público。
    /// 中文：增加内部过渡观察者，不覆盖业务公开过渡回调。
    internal func addTransitionObserver(_ observer: @escaping (PTSegmentTransition) -> Void) {
        transitionObservers.append(observer)
    }

    private func scrollTo(id: AnyHashable, animated: Bool) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        guard collectionView.numberOfItems(inSection: 0) > index else { return }
        scrollIntent = animated ? .centeringSelectedItem : .idle
        collectionView.scrollToItem(at: IndexPath(item: index, section: 0),
                                     at: .centeredHorizontally,
                                     animated: animated)
        if !animated { updateIndicatorContext() }
    }

    private func updateVisibleCells() {
        for cell in collectionView.visibleCells.compactMap({ $0 as? PTMainSegmentCell }) {
            guard let id = cell.representedID,
                  let item = items.first(where: { $0.id == id }) else { continue }
            cell.configure(item: item, style: style, selected: id == selectionState.selectedID)
        }
    }

    /// English: Interpolates only the two cells participating in a page transition.
    /// Español: Interpola solo las dos celdas que participan en la transición de página.
    /// 中文：只插值参与页面过渡的两个 Cell。
    private func applyInteractiveTransition(_ transition: PTSegmentTransition) {
        let progress = transition.progress
        for cell in collectionView.visibleCells.compactMap({ $0 as? PTMainSegmentCell }) {
            guard let id = cell.representedID else { continue }
            if id == transition.fromID {
                cell.applyTransition(selectedProgress: 1 - progress, style: style)
            } else if id == transition.toID {
                cell.applyTransition(selectedProgress: progress, style: style)
            } else {
                cell.applySelection(id == selectionState.selectedID, style: style)
            }
        }
    }

    private func animateSelection(from oldID: AnyHashable?, to newID: AnyHashable) {
        let duration = selectionAnimationDuration.isFinite
            ? min(max(selectionAnimationDuration, 0.01), 2)
            : 0.25
        let cells = collectionView.visibleCells.compactMap { $0 as? PTMainSegmentCell }
        for cell in cells {
            guard let id = cell.representedID else { continue }
            if id == oldID {
                cell.applyTransition(selectedProgress: 1, style: style)
            } else if id == newID {
                cell.applyTransition(selectedProgress: 0, style: style)
            }
        }
        let animator = UIViewPropertyAnimator(duration: duration, curve: .easeInOut) {
            for cell in cells {
                guard let id = cell.representedID else { continue }
                if id == oldID {
                    cell.applyTransition(selectedProgress: 0, style: self.style)
                } else if id == newID {
                    cell.applyTransition(selectedProgress: 1, style: self.style)
                }
            }
        }
        selectionAnimator = animator
        animator.addCompletion { [weak self] _ in
            guard let self, self.selectionAnimator === animator else { return }
            self.selectionAnimator = nil
            self.updateVisibleCells()
        }
        animator.startAnimation()
    }

    private func updateFlowLayoutSpacing() {
        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        let resolved = resolvedItemSpacing(availableWidth: availableLayoutWidth(layout: layout))
        guard cachedResolvedSpacing != resolved else { return }
        cachedResolvedSpacing = resolved
        layout.minimumInteritemSpacing = resolved
        layout.minimumLineSpacing = resolved
    }

    /// English: Resolves the width available after flow-layout and safe-area insets.
    /// Español: Resuelve el ancho disponible después de los insets del layout y del área segura.
    /// 中文：计算扣除 Flow Layout 和安全区域内边距后的可用宽度。
    private func availableLayoutWidth(layout: UICollectionViewFlowLayout) -> CGFloat {
        let sectionInsets = layout.sectionInset.left + layout.sectionInset.right
        let contentInsets = collectionView.adjustedContentInset.left + collectionView.adjustedContentInset.right
        return max(0, bounds.width - sectionInsets - contentInsets)
    }

    private func resolvedItemSpacing(availableWidth: CGFloat) -> CGFloat {
        let minimum = style.itemSpacing.isFinite ? max(0, style.itemSpacing) : 0
        guard style.spacingDistribution == .averageWhenPossible,
              style.distribution != .equal,
              items.count > 1,
              availableWidth.isFinite,
              availableWidth > 0 else {
            return minimum
        }

        let widths: [CGFloat]
        if let itemWidths = style.itemWidths {
            widths = items.indices.map { index in
                guard itemWidths.indices.contains(index), itemWidths[index].isFinite else {
                    return PTMainSegmentCell.measuredWidth(item: items[index], style: style)
                }
                return max(1, itemWidths[index])
            }
        } else {
            widths = items.map { PTMainSegmentCell.measuredWidth(item: $0, style: style) }
        }
        let total = widths.reduce(0, +)
        let average = (availableWidth - total) / CGFloat(items.count - 1)
        return average.isFinite && average > minimum ? average : minimum
    }

    private func rebuildIndicators() {
        indicatorHost.subviews.forEach { $0.removeFromSuperview() }
        indicators.forEach { indicatorHost.addSubview($0.view) }
        setNeedsLayout()
    }

    private func updateIndicatorContext() {
        guard !bounds.isEmpty else { return }
        var itemFrames = [AnyHashable: CGRect](minimumCapacity: items.count)
        var contentFrames = [AnyHashable: CGRect](minimumCapacity: items.count)
        for index in items.indices {
            let indexPath = IndexPath(item: index, section: 0)
            guard let attribute = collectionView.collectionViewLayout.layoutAttributesForItem(at: indexPath) else { continue }
            let id = items[index].id
            let itemFrame = collectionView.convert(attribute.frame, to: indicatorHost)
            itemFrames[id] = itemFrame

            if let cell = collectionView.cellForItem(at: indexPath) as? PTMainSegmentCell,
               !cell.indicatorContentFrame.isEmpty {
                contentFrames[id] = cell.convert(cell.indicatorContentFrame, to: indicatorHost)
            } else {
                let width = min(itemFrame.width, PTSegmentMeasurement.contentWidth(item: items[index], style: style))
                contentFrames[id] = CGRect(x: itemFrame.midX - width / 2,
                                           y: itemFrame.minY,
                                           width: max(1, width),
                                           height: itemFrame.height)
            }
        }
        let context = PTSegmentIndicatorContext(bounds: indicatorHost.bounds,
                                                 itemFrames: itemFrames,
                                                 selectedID: selectionState.selectedID,
                                                 contentFrames: contentFrames)
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
        let availableWidth = (collectionViewLayout as? UICollectionViewFlowLayout).map {
            availableLayoutWidth(layout: $0)
        } ?? max(0, bounds.width)
        let width: CGFloat
        if let itemWidths = style.itemWidths, itemWidths.indices.contains(indexPath.item) {
            width = max(1, itemWidths[indexPath.item].isFinite ? itemWidths[indexPath.item] : 1)
        } else if style.spacingDistribution == .averageWhenPossible && style.distribution != .equal {
            width = PTMainSegmentCell.measuredWidth(item: items[indexPath.item], style: style)
        } else {
            let intrinsic = PTMainSegmentCell.measuredWidth(item: items[indexPath.item], style: style)
            switch style.distribution {
            case .intrinsic:
                width = intrinsic
            case .equal:
                width = availableWidth / CGFloat(max(items.count, 1))
            case .adaptive:
                let total = items.reduce(CGFloat.zero) { $0 + PTMainSegmentCell.measuredWidth(item: $1, style: style) }
                width = total <= availableWidth ? availableWidth / CGFloat(max(items.count, 1)) : intrinsic
            }
        }
        return CGSize(width: max(1, width), height: max(1, style.itemHeight))
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === collectionView, !isApplyingSnapshot else { return }
        updateIndicatorContext()
    }

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard scrollView === collectionView else { return }
        if case .centeringSelectedItem = scrollIntent { return }
        scrollIntent = .userBrowsingSegments
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard scrollView === collectionView, !decelerate else { return }
        scrollIntent = .idle
        updateIndicatorContext()
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView === collectionView else { return }
        scrollIntent = .idle
        updateIndicatorContext()
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        guard scrollView === collectionView else { return }
        scrollIntent = .idle
        updateIndicatorContext()
    }
}
