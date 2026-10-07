//
//  PTCollectionView.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 15/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
#if canImport(PToolsUIFoundation)
import PToolsUIFoundation
#endif
import Photos

private let kPTCollectionIndexViewAnimationDuration: Double = 0.25


//MARK: 界面展示
@objcMembers
@MainActor
public class PTCollectionView: UIView {
    private var boundsChangeTask: Task<Void, Never>?
    
    // 声明一个节流任务
    private var scrollDebounceTask: Task<Void, Never>?
    // English: The native Diffable data source stores stable section and row IDs only.
    // Español: La fuente Diffable nativa solo almacena IDs estables de sección y fila.
    // 中文：原生 Diffable 数据源只保存稳定的 Section/Row ID。
    var diffableDataSource: PTCollectionIDDataSource!

    // English: Expose lightweight refresh diagnostics for the in-app Refresh Lab.
    // Español: Expone diagnósticos ligeros de actualización para el laboratorio integrado.
    // 中文：为内置 Refresh Lab 提供轻量级刷新诊断数据。
    public private(set) var snapshotApplyCount = 0

    public var pendingUpdateCount: Int {
        updateCoordinator.pendingOperationCount
    }
    ///Photos
    let photoPrefetchCoordinator = PTCollectionPhotoPrefetchCoordinator()
    var photoAssets: [PHAsset] = []

    lazy var skeletonOverlayView = PTSkeletonOverlayView()
    var activeSkeletonItemCount: Int?
    public internal(set) var isSkeletonVisible = false
    
    ///索引
    lazy var indicator: UIView = {
        let indicatorRadius = viewConfig.indexConfig?.indicatorRadius ?? 0
        let indicator = UIView()
        indicator.frame = CGRect(x: 0, y: 0, width: indicatorRadius * 3, height: indicatorRadius * 2)
        indicator.backgroundColor = viewConfig.indexConfig?.indicatorBackgroundColor ?? .clear
        indicator.alpha = 0
        indicator.addSubview(bigTextLabel)
        
        let maskLayer = CAShapeLayer()
        maskLayer.frame = indicator.frame
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 2.414 * indicatorRadius, y: indicatorRadius))
        path.addLine(to: CGPoint(x: 1.707 * indicatorRadius, y: 1.707 * indicatorRadius))
        path.addArc(withCenter: CGPoint(x: indicatorRadius, y: indicatorRadius), radius: indicatorRadius, startAngle: 0.25 * CGFloat.pi, endAngle: 1.75 * CGFloat.pi, clockwise: true)
        path.close()
        maskLayer.path = path.cgPath
        maskLayer.fillColor = UIColor.red.cgColor
        maskLayer.backgroundColor = UIColor.clear.cgColor
        indicator.layer.mask = maskLayer
        return indicator
    }()
    
    /// CATextLayer的内容默认是上对齐的，不如用label方便
    lazy var bigTextLabel: UILabel = {
        let indicatorRadius = viewConfig.indexConfig?.indicatorRadius ?? 0
        let label = UILabel()
        label.frame = CGRect(x: 0, y: 0, width: indicatorRadius * 2, height: indicatorRadius * 2)
        label.backgroundColor = viewConfig.indexConfig?.indicatorBackgroundColor ?? .clear
        PTUIAccessibility.applyDynamicType(to: label,
                                           font: UIFont.appCustomFont(size: ceil(indicatorRadius * 1.414),
                                                                      customFont: viewConfig.indexConfig?.indexViewHudFont.fontName ?? UIFont.appfont(size: 18).fontName))
        label.textAlignment = .center
        label.layer.cornerRadius = indicatorRadius
        label.layer.masksToBounds = true
        label.textColor = viewConfig.indexConfig?.indicatorTextColor ?? .clear
        return label
    }()
    
    var layerTopSpacing: CGFloat {
        let count = CGFloat(viewConfig.sideIndexTitles?.count ?? 0)
        let floorValue = bounds.height - count * (viewConfig.indexConfig?.itemSize.height ?? 0) - (viewConfig.indexConfig?.itemSpacing ?? 0) * (count - 1)
        return max(0, floor(floorValue) / 2)
    }
    
    var isTouched: Bool = false
    
    var touchedIndex: Int = 0 {
        didSet {
            if touchedIndex != oldValue {
                PTFeedbackCenter.shared.emit(.selectionChanged)
            }
        }
    }
        
    // 使用 NSKeyValueObservation 替代手动 KVO
    private var lastUpdateTime: CFTimeInterval = 0
    private let scrollThrottleInterval: CFTimeInterval = 0.1 // 10fps
    var lastPrefetchItemCount: Int?
    var indexPanGesture: UIPanGestureRecognizer?
    private var lastLayoutBoundsSize: CGSize = .zero
    
    let layoutCacheCoordinator = PTCollectionLayoutCacheCoordinator()
    var heightCache: PTLRUCache<HeightCacheKey, NSNumber> { layoutCacheCoordinator.height }
    var waterfallCache: [PTCollectionWaterfallCacheKey: PTCollectionWaterfallCache] = [:]
    var layoutCache: PTLRUCache<LayoutCacheKey, NSCollectionLayoutSection> { layoutCacheCoordinator.sections }
    // English: Centralize snapshot validation without changing PTCollectionView's public facade.
    // Español: Centraliza la validación del snapshot sin cambiar la fachada pública de PTCollectionView.
    // 中文：集中快照校验，同时不改变 PTCollectionView 的公开门面。
    let dataCoordinator = PTCollectionDataCoordinator()
    // English: Keep the latest mutable models outside the legacy Diffable identifiers.
    // Español: Mantiene los modelos mutables más recientes fuera de los identificadores Diffable heredados.
    // 中文：将最新可变模型保存在旧版 Diffable 标识之外。
    let modelStore = PTCollectionModelStore()
    // English: Record whether content refresh reaches the Provider and Configure stages.
    // Español: Registra si el refresco de contenido alcanza las etapas Provider y Configure.
    // 中文：记录内容刷新是否真正进入 Provider 和 Configure 阶段。
    let cellConfigurationDiagnostics = PTCollectionCellConfigurationDiagnostics()
    // English: Queue update operations instead of dropping overlapping snapshots.
    // Español: Encola operaciones de actualización en lugar de descartar snapshots solapados.
    // 中文：排队处理更新操作，不再丢弃重叠快照。
    private lazy var updateDiagnostics = PTCollectionUpdateDiagnostics { [weak self] in
        guard let self, let dataSource = self.diffableDataSource else {
            return (sections: 0, items: 0)
        }
        let snapshot = dataSource.snapshot()
        return (sections: snapshot.numberOfSections, items: snapshot.numberOfItems)
    }
    lazy var updateCoordinator = PTCollectionUpdateCoordinator(diagnostics: updateDiagnostics)
    let scrollObserverMultiplexer = PTCollectionScrollObserverMultiplexer()
    
    private var fallbackLayouts: [Int: NSCollectionLayoutSection] = [:]
    private var didReportFallbackLayout = false
    private var memoryWarningRegistration: UUID?
    private let waterfallCacheLimit = 50
    private let refreshCoordinator = PTCollectionRefreshCoordinator()
    
    lazy var collectionView : PTBaseCollectionView = {
        var view = PTBaseCollectionView(frame: .zero, collectionViewLayout: self.comboLayout())
        view.backgroundColor = .clear
        view.delegate = self
        view.isUserInteractionEnabled = true
        view.isPrefetchingEnabled = true
        // 1. 在初始化 collectionView 时启用 Drag & Drop
        view.dragInteractionEnabled = self.viewConfig.canMoveItem
        view.dragDelegate = self
        view.dropDelegate = self
        view.contentOffSetZero = self.viewConfig.contentOffSetZero
        switch self.viewConfig.viewType {
        case .Normal,.Gird,.WaterFall,.Tag:
            view.alwaysBounceHorizontal = false
            view.alwaysBounceVertical = true
        case .Custom:
            view.alwaysBounceHorizontal = self.viewConfig.alwaysBounceHorizontal
            view.alwaysBounceVertical = self.viewConfig.alwaysBounceVertical
        case .HorizontalLayoutSystem,.Horizontal:
            view.alwaysBounceHorizontal = true
            view.alwaysBounceVertical = false
        }
        view.showsVerticalScrollIndicator = self.viewConfig.showsVerticalScrollIndicator
        view.showsHorizontalScrollIndicator = self.viewConfig.showsHorizontalScrollIndicator
        view.contentInsetAdjustmentBehavior = self.viewConfig.contentInsetAdjustmentBehavior
        
        refreshCoordinator.configure(view,
                                     config: self.viewConfig,
                                     onHeader: { [weak self] in
            PTGCDManager.shared.runOnMain {
                self?.headerRefreshTask?()
            }
                                     },
                                     onFooter: { [weak self] in
            PTGCDManager.shared.runOnMain {
                self?.footRefreshTask?()
            }
                                     })

        view.registerSupplementaryView(classs: [NSStringFromClass(PTBaseCollectionReusableView.self):PTBaseCollectionReusableView.self], kind: UICollectionView.elementKindSectionHeader)
        view.registerSupplementaryView(classs: [NSStringFromClass(PTBaseCollectionReusableView.self):PTBaseCollectionReusableView.self], kind: UICollectionView.elementKindSectionFooter)
        if self.viewConfig.viewForPhoto {
            view.prefetchDataSource = self
        }
        return view
    }()
    
    lazy var indexContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = viewConfig.indexConfig?.indexViewBackgroundColor
        return view
    }()
    
    let topSpacer = UIView()
    let bottomSpacer = UIView()

    lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.distribution = .equalSpacing
        stack.spacing = viewConfig.indexConfig?.itemSpacing ?? 0
        return stack
    }()
    
    //MARK: Cell datasource handler
    open var headerInCollection: PTReusableViewHandler?
    open var footerInCollection: PTReusableViewHandler?
    open var cellInCollection: PTCellInCollectionHandler?
    open var cellInCollectionV2: PTCellInCollectionV2Handler?
    open var configureCell: PTCellConfigurationHandler?
    
    //MARK: Cell delegate handler
    open var collectionDidSelect: PTCellDidSelectedHandler?
    open var collectionWillDisplay: PTCellDisplayHandler?
    open var collectionDidEndDisplay: PTCellDisplayHandler?
    
    //MARK: UIScrollView call back
    open var collectionWillBeginDecelerating: PTCollectionViewScrollHandler?
    open var collectionViewDidScroll: PTCollectionViewScrollHandler?
    open var collectionWillBeginDragging: PTCollectionViewScrollHandler?
    open var collectionDidEndDragging: ((UICollectionView,Bool) -> Void)?
    open var collectionDidEndDecelerating: PTCollectionViewScrollHandler?
    open var collectionDidEndScrollingAnimation: PTCollectionViewScrollHandler?
    open var collectionDidScrolltoTop: PTCollectionViewScrollHandler?
    open var collectionWillEndDraging: ((_ scrollView: UIScrollView, _ velocity: CGPoint, _ targetContentOffset: UnsafeMutablePointer<CGPoint>) -> Void)?

    // English: Internal controller observers keep PTCollectionView's delegate ownership intact.
    // Español: Los observadores internos conservan la propiedad del delegate de PTCollectionView.
    // 中文：内部控制器观察通道保留 PTCollectionView 对 delegate 的所有权。
    var listControllerDidScroll: PTCollectionViewScrollHandler?
    var listControllerDidEndDragging: (@MainActor (UICollectionView, Bool) -> Void)?
    
    //MARK: Orthogonal Scroll handler (正交滚动专用)
    /// 正交滚动 (横向滑动) 的实时偏移量回调: (SectionIndex, CGPoint)
    open var orthogonalDidScroll:  ((Int, CGPoint) -> Void)?
    /// 正交滚动 (横向滑动) 翻页改变时的回调: (SectionIndex, 当前页码 CurrentPage)
    open var orthogonalPageDidChange: ((Int, Int) -> Void)?
    
    // 🌟 新增：无感知触底预加载回调
    /// 无感知触底预加载事件触发回调
    /// ⚠️ 注意：外部收到此回调后，务必自行进行 isLoading 状态拦截，防止重复触发请求
    open var collectionWillReachBottomTask: PTActionTask?
    
    ///头部刷新事件
    open var headerRefreshTask: PTActionTask?
    ///底部刷新事件
    open var footRefreshTask: PTActionTask?
    
    //MARK: Cell layout (仅仅限于在瀑布流或者自定义的情况下使用)
    open var waterFallLayout: ((Int, AnyObject) -> CGFloat)?
    open var customerLayout: ((Int,PTSection) -> NSCollectionLayoutGroup)?
    open var customerReuseViews: ((Int,PTSection) -> [NSCollectionLayoutBoundarySupplementaryItem])?

    ///当空数据View展示的时候,点击回调
    open var emptyTap: ((UIView?) -> Void)?
    open var emptyButtonTap: ((UIView?) -> Void)?

    ///CollectionView的DecorationItem囘調(自定義模式下使用)
    open var decorationInCollectionView: PTDecorationInCollectionHandler?
    
    ///CollectionView的DecorationItem重新設置囘調(自定義模式下使用)
    open var decorationViewReset: PTViewInDecorationResetHandler?
    
    ///CollectionView的DecorationItem内的Item与Header&Footer重新設置囘調(自定義模式下使用)
    open var decorationCustomLayoutInsetReset: ((Int,PTSection) -> NSDirectionalEdgeInsets)?
    
    public var contentCollectionView:UICollectionView { collectionView }
    public var collectionSectionDatas:[PTSection] {
        modelStore.resolvedSections(diffableDataSource.snapshot().sectionIdentifiers)
    }
    
    //MARK: Swipe handler
    open var indexPathSwipe: PTCollectionViewCanSwipeHandler?
    open var swipeLeftHandler :PTCollectionViewSwipeHandler?
    open var swipeRightHandler: PTCollectionViewSwipeHandler?
    
    open var itemMoveTo: ((_ cView:UICollectionView,_ move:IndexPath,_ to:IndexPath) -> Void)?
    
    open var forceController: ((_ collectionView:UICollectionView,_ indexPath:IndexPath,_ sectionModel:PTSection) -> UIViewController?)?
    open var forceActions: ((_ collectionView:UICollectionView,_ indexPath:IndexPath,_ sectionModel:PTSection) -> [UIAction]?)?
    /// 数据输入无法用于创建合法快照时的错误回调。
    open var collectionUpdateError: PTCollectionViewUpdateErrorHandler?

    public var viewConfig: PTCollectionViewConfig! {
        didSet {
            guard let config = viewConfig else { return }
            // 配置对象被替换后，滚动方向和交互能力必须同步到内部列表。
            let view = collectionView
            view.showsVerticalScrollIndicator = config.showsVerticalScrollIndicator
            view.showsHorizontalScrollIndicator = config.showsHorizontalScrollIndicator
            view.contentInsetAdjustmentBehavior = config.contentInsetAdjustmentBehavior
            view.contentOffSetZero = config.contentOffSetZero
            view.dragInteractionEnabled = config.canMoveItem
            view.prefetchDataSource = config.viewForPhoto ? self : nil

            switch config.viewType {
            case .Normal, .Gird, .WaterFall, .Tag:
                view.alwaysBounceHorizontal = false
                view.alwaysBounceVertical = true
            case .Custom:
                view.alwaysBounceHorizontal = config.alwaysBounceHorizontal
                view.alwaysBounceVertical = config.alwaysBounceVertical
            case .Horizontal, .HorizontalLayoutSystem:
                view.alwaysBounceHorizontal = true
                view.alwaysBounceVertical = false
            }

            if config.canMoveItem {
                view.allowsMoveItem()
            }
            
            if config.sideIndexTitles?.isEmpty == false && config.indexConfig != nil {
                if view.superview == nil {
                    addSubview(view)
                    view.snp.makeConstraints { make in
                        make.edges.equalToSuperview()
                    }
                }
                setIndexViews()
            } else {
                indicator.removeFromSuperview()
                indexContainerView.removeFromSuperview()
            }
            
            if view.superview != nil {
                view.collectionViewLayout.invalidateLayout()
            }

            if isSkeletonVisible {
                updateSkeletonLayout()
            }
        }
    }
    
    var registeredCells: Set<String> = []
    var registeredSupplementary: Set<String> = []
    
    //MARK: 界面展示
    public init(viewConfig: PTCollectionViewConfig!) {
        super.init(frame: .zero)
        self.viewConfig = viewConfig ?? PTCollectionViewConfig()
        setupCollectionView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.viewConfig = PTCollectionViewConfig()
        setupCollectionView()
    }

    private func setupCollectionView() {
        isUserInteractionEnabled = true
        self.registerClassCells(classs: ["CELL":UICollectionViewCell.self])

        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        if viewConfig.canMoveItem {
            collectionView.allowsMoveItem()
        }
        setIndexViews()

        scrollObserverMultiplexer.add { [weak self] collectionView in
            self?.listControllerDidScroll?(collectionView)
            self?.collectionViewDidScroll?(collectionView)
        }
        
        // English: Use one Core-level memory warning fan-out instead of one NotificationCenter observer per list.
        // Español: Usa una distribución de advertencias de memoria de Core en lugar de un observador por lista.
        // 中文：使用 Core 统一的内存警告分发，避免每个列表单独注册 NotificationCenter 观察者。
        memoryWarningRegistration = PTMemoryWarningCoordinator.shared.register { [weak self] in
            self?.didReceiveMemoryWarning()
        }
        
        setupDiffableDataSource()
        setiOS17EmptyDataView()

        skeletonOverlayView.isHidden = true
        addSubview(skeletonOverlayView)
        skeletonOverlayView.snp.makeConstraints { make in
            make.edges.equalTo(collectionView)
        }
    }

    // English: Stop PhotoKit prefetching when the list leaves the active view hierarchy.
    // Español: Detiene la precarga de PhotoKit cuando la lista abandona la jerarquía de vistas activa.
    // 中文：列表离开当前视图层级时停止 PhotoKit 预取。
    public override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil {
            photoPrefetchCoordinator.removeAll()
        }
    }
    
    deinit {
        if let memoryWarningRegistration {
            MainActor.gcdRunUnsafely {
                PTMemoryWarningCoordinator.shared.unregister(memoryWarningRegistration)
            }
        }
    }
    
    private func didReceiveMemoryWarning() {
        layoutCache.removeAll()
        heightCache.removeAll()
        waterfallCache.removeAll()
        fallbackLayouts.removeAll()
        photoPrefetchCoordinator.removeAll()
    }
    
    ///展示界面
    public override func layoutIfNeeded() {
        super.layoutIfNeeded()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        let layoutSize = collectionView.bounds.size
        if layoutSize != .zero, layoutSize != lastLayoutBoundsSize {
            lastLayoutBoundsSize = layoutSize
            // English: Rebuild custom groups only when the real container size changes.
            // Español: Reconstruye los grupos personalizados solo cuando cambia el tamaño real del contenedor.
            // 中文：仅在真实容器尺寸变化时重新生成自定义布局分组。
            collectionView.collectionViewLayout.invalidateLayout()
        }
        updateSkeletonLayout()
    }


}

extension PTCollectionView {
    func reportUpdateError(_ error: PTCollectionViewUpdateError) {
        collectionUpdateError?(error)
    }

    func validateSections(_ sections: [PTSection], against snapshot: PTCollectionIDSnapshot? = nil) -> Bool {
        let error: PTCollectionViewUpdateError?
        if let snapshot {
            error = dataCoordinator.validationError(for: sections, against: snapshot)
        } else {
            error = dataCoordinator.validationError(for: sections)
        }
        if let error {
            reportUpdateError(error)
            return false
        }
        return true
    }

    func validateRows(_ rows: [PTRows], against snapshot: PTCollectionIDSnapshot) -> Bool {
        if let error = dataCoordinator.validationError(for: rows, against: snapshot) {
            reportUpdateError(error)
            return false
        }
        return true
    }

    // English: Resolve models by stable identity so content callbacks never depend on stale snapshot objects.
    // Español: Resuelve los modelos por identidad estable para que los callbacks no dependan de objetos obsoletos del snapshot.
    // 中文：通过稳定身份解析模型，避免内容回调依赖旧快照对象。
    func resolvedSection(_ section: PTSection) -> PTSection {
        modelStore.resolvedSection(section)
    }

    func resolvedSection(_ identifier: PTSectionIdentifier) -> PTSection {
        modelStore.resolvedSection(identifier) ?? PTSection(identifier: identifier.rawValue)
    }

    func resolvedRow(_ row: PTRows) -> PTRows {
        modelStore.resolvedRow(row)
    }

    func resolvedRow(_ identifier: PTRowIdentifier) -> PTRows {
        modelStore.resolvedRow(identifier) ?? PTRows(diffId: identifier.rawValue)
    }

    // English: Replace the compatibility store after a structural mutation.
    // Español: Reemplaza el almacén compatible después de una mutación estructural.
    // 中文：结构发生变化后同步兼容模型仓库。
    func synchronizeModelStore(with snapshot: PTCollectionIDSnapshot) {
        modelStore.synchronize(with: snapshot)
    }

}

extension PTCollectionView {
    // English: Apply a snapshot only from the MainActor update coordinator.
    // Español: Aplica un snapshot solo desde el coordinador de actualizaciones de MainActor.
    // 中文：只允许 MainActor 更新协调器提交快照。
    func applySnapshot(_ snapshot: PTCollectionIDSnapshot,
                       animatingDifferences: Bool,
                       completion: (() -> Void)? = nil) {
        snapshotApplyCount += 1
        diffableDataSource.apply(
            snapshot,
            animatingDifferences: animatingDifferences
        ) { [weak self] in
            self?.setiOS17EmptyDataView()
            if let self {
                self.cellConfigurationDiagnostics.finish(operationID: self.updateCoordinator.activeOperationID,
                                                         kind: self.updateCoordinator.activeOperationKind ?? .structure)
            }
            completion?()
        }
    }

    // English: Keep structural and content animations independently configurable.
    // Español: Mantiene configurables por separado las animaciones estructurales y de contenido.
    // 中文：让结构更新和内容刷新分别控制动画。
    private var structureAnimationEnabled: Bool {
        viewConfig.structureUpdateAnimationEnabled && !viewConfig.refreshWithoutAnimation
    }

    private var contentAnimationEnabled: Bool {
        viewConfig.contentUpdateAnimationEnabled && !viewConfig.refreshWithoutAnimation
    }

    // English: Resolve requested index paths to stable IDs without reading mutable model objects from Diffable.
    // Español: Resuelve los index paths solicitados a IDs estables sin leer modelos mutables desde Diffable.
    // 中文：将请求的 IndexPath 解析成稳定 ID，不从 Diffable 读取可变模型对象。
    private func rowIdentifiers(for indexPaths: Set<IndexPath>,
                                in snapshot: PTCollectionIDSnapshot) -> [PTRowIdentifier] {
        var result: [PTRowIdentifier] = []
        var seen = Set<PTRowIdentifier>()
        for indexPath in indexPaths {
            guard snapshot.sectionIdentifiers.indices.contains(indexPath.section) else { continue }
            let section = snapshot.sectionIdentifiers[indexPath.section]
            let rows = snapshot.itemIdentifiers(inSection: section)
            guard rows.indices.contains(indexPath.item) else { continue }
            let row = rows[indexPath.item]
            if seen.insert(row).inserted {
                result.append(row)
            }
        }
        return result
    }

    private func rowIdentifiers(for sectionIndexes: Set<Int>,
                                in snapshot: PTCollectionIDSnapshot) -> [PTRowIdentifier] {
        var result: [PTRowIdentifier] = []
        var seen = Set<PTRowIdentifier>()
        for index in sectionIndexes {
            guard snapshot.sectionIdentifiers.indices.contains(index) else { continue }
            let section = snapshot.sectionIdentifiers[index]
            for row in snapshot.itemIdentifiers(inSection: section) where seen.insert(row).inserted {
                result.append(row)
            }
        }
        return result
    }

    // English: Update visible cells in place and let Diffable handle only cells without a direct fast path.
    // Español: Actualiza las celdas visibles en sitio y deja que Diffable procese las restantes.
    // 中文：原地更新可见 Cell，其余 Cell 才交给 Diffable 处理。
    @discardableResult
    private func reconfigureVisibleCells(for rowIdentifiers: [PTRowIdentifier]) -> Set<PTRowIdentifier> {
        var configured = Set<PTRowIdentifier>()
        for rowIdentifier in rowIdentifiers {
            guard let indexPath = diffableDataSource.indexPath(for: rowIdentifier),
                  let cell = collectionView.cellForItem(at: indexPath),
                  snapshotSection(at: indexPath.section) != nil else {
                continue
            }

            let section = resolvedSection(diffableDataSource.snapshot().sectionIdentifiers[indexPath.section])
            let row = resolvedRow(rowIdentifier)
            let context = PTCollectionCellContext(section: section, row: row, indexPath: indexPath)
            cellConfigurationDiagnostics.fingerprint(operationID: updateCoordinator.activeOperationID,
                                                     row: row,
                                                     indexPath: indexPath,
                                                     phase: "visible-read")
            var didConfigure = false

            if let normalCell = cell as? PTBaseNormalCell {
                didConfigure = normalCell.reconfigureContent(with: context)
            }
            if !didConfigure,
               let fusionCell = cell as? PTFusionCellProtocol,
               let fusionModel = row.dataModel as? PTFusionCellModel {
                fusionCell.cellModel = fusionModel
                didConfigure = true
            }
            if !didConfigure,
               let bindableCell = cell as? PTAnyCellBindable,
               let dataModel = row.dataModel {
                bindableCell.pt_bindAny(dataModel)
                didConfigure = true
            }
            if !didConfigure, let configureCell {
                configureCell(collectionView, cell, context)
                didConfigure = true
            }

            if didConfigure {
                configured.insert(rowIdentifier)
                cellConfigurationDiagnostics.configure(operationID: updateCoordinator.activeOperationID,
                                                        rowID: rowIdentifier,
                                                        indexPath: indexPath,
                                                        cell: cell,
                                                        visible: true)
            }
        }
        return configured
    }

    private func snapshotSection(at index: Int) -> PTSectionIdentifier? {
        let identifiers = diffableDataSource.snapshot().sectionIdentifiers
        guard identifiers.indices.contains(index) else { return nil }
        return identifiers[index]
    }

    // English: Apply one coalesced content batch without changing Diffable identities.
    // Español: Aplica un único lote de contenido combinado sin cambiar las identidades Diffable.
    // 中文：合并执行内容刷新，不改变 Diffable 身份。
    private func performContentRefresh(sectionIndexes: Set<Int>,
                                       itemIndexPaths: Set<IndexPath>,
                                       invalidateLayout: Bool,
                                       finish: @escaping @MainActor () -> Void) {
        let snapshot = diffableDataSource.snapshot()
        let rowIDs = Array(Set(rowIdentifiers(for: itemIndexPaths, in: snapshot)
                               + rowIdentifiers(for: sectionIndexes, in: snapshot)))
        let visibleRowIDs = rowIDs.filter { rowID in
            guard let indexPath = diffableDataSource.indexPath(for: rowID) else { return false }
            return collectionView.cellForItem(at: indexPath) != nil
        }
        cellConfigurationDiagnostics.request(rowIDs, visible: visibleRowIDs)

        var invalidatedSections = sectionIndexes
        invalidatedSections.formUnion(itemIndexPaths.map(\.section))
        if invalidateLayout {
            for section in invalidatedSections where snapshot.sectionIdentifiers.indices.contains(section) {
                clearWaterfallCache(section: section)
                markSectionDirty(section)
            }
            layoutCache.removeAll()
            heightCache.removeAll()
            collectionView.collectionViewLayout.invalidateLayout()
        }

        guard !rowIDs.isEmpty else {
            cellConfigurationDiagnostics.finish(operationID: updateCoordinator.activeOperationID, kind: .content)
            finish()
            return
        }

        let directlyConfigured = reconfigureVisibleCells(for: rowIDs)
        let remainingIDs = rowIDs.filter { !directlyConfigured.contains($0) }
        guard !remainingIDs.isEmpty else {
            if invalidateLayout {
                collectionView.collectionViewLayout.invalidateLayout()
            }
            cellConfigurationDiagnostics.finish(operationID: updateCoordinator.activeOperationID, kind: .content)
            finish()
            return
        }

        var contentSnapshot = snapshot
        contentSnapshot.reconfigureItems(remainingIDs)
        applySnapshot(contentSnapshot, animatingDifferences: contentAnimationEnabled) { [weak self] in
            guard let self else {
                finish()
                return
            }
            if invalidateLayout {
                self.collectionView.collectionViewLayout.invalidateLayout()
            }
            finish()
        }
    }
    
    public func cornerPosition(row: Int, count: Int) -> CornerPosition {
        if count == 1 { return .single }
        if row == 0 { return .top }
        if row == count - 1 { return .bottom }
        return .middle
    }
    
    public func hideIndicator() {
        UIView.animate(withDuration: PTUIAccessibility.animationDuration(0.2)) {
            self.indicator.alpha = 0
        }
    }
    
    public func clearLayoutCaches() {
        self.layoutCache.removeAll()
        self.heightCache.removeAll()
        self.waterfallCache.removeAll()
        self.fallbackLayouts.removeAll()
    }
}

//MARK: 触摸事件
extension PTCollectionView {
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)

        if view == self {
            if let indexConfig = viewConfig.indexConfig {
                let rect = CGRect(x: self.frame.size.width - indexConfig.itemSize.width, y: layerTopSpacing, width: indexConfig.itemSize.width, height: self.frame.size.height - layerTopSpacing * 2)
                if rect.contains(point) {
                    return self
                } else {
                    return nil
                }
            }
            return view
        } else {
            return view
        }
    }
}

//MARK: KVO相关
extension PTCollectionView {
    private func handleScrollUpdate() {
        guard let section = findCurrentSectionFast(),
              let config = viewConfig.indexConfig else { return }
        
        for case let view as PTIndexItemView in stackView.arrangedSubviews {
            view.update(selected: view.index == section, config: config)
        }
        
        showIndicator(at: section)
    }
    
    private func findCurrentSectionFast() -> Int? {
        let indexPaths = collectionView.indexPathsForVisibleItems
        guard !indexPaths.isEmpty else { return nil }
        return indexPaths.min()?.section
    }
    
    func throttleScrollUpdate() {
        guard isTouched == false else { return }
        
        // 取消之前的任务
        scrollDebounceTask?.cancel()
        
        // 创建新的 Task
        scrollDebounceTask = Task { @MainActor [weak self] in
            do {
                // 延迟 0.05 秒 (50 毫秒 = 50,000,000 纳秒)
                try await Task.sleep(nanoseconds: 50_000_000)
                guard !Task.isCancelled else { return }
                self?.handleScrollUpdate()
            } catch {
                // 任务被取消会抛出 CancellationError，直接忽略
            }
        }
    }
}

//MARK: Waterfall相关
extension PTCollectionView {
    private func cachedHeight(for indexPath: IndexPath,
                              model: AnyObject,
                              calculator: (Int, AnyObject) -> CGFloat) -> CGFloat {
        guard let row = diffableDataSource.itemIdentifier(for: indexPath) else {
            return calculator(indexPath.section, model)
        }

        let key = HeightCacheKey(id: row.diffId, width: collectionView.bounds.width)
        
        if let cache = heightCache.get(forKey: key) {
            return cache.doubleValue
        }
        
        let height = calculator(indexPath.section, model)
        heightCache.set(NSNumber(floatLiteral: height), forKey: key)
        return height
    }
}

//MARK: DIFF
extension PTCollectionView {

    private func markSectionDirty(_ section: Int) {
        let snapshot = self.diffableDataSource.snapshot()
        guard section >= 0, section < snapshot.sectionIdentifiers.count else { return }
        resolvedSection(snapshot.sectionIdentifiers[section]).layoutVersion += 1
    }
            
    @MainActor public func showCollectionDetail(collectionData:[PTSection],
                                                animated: Bool = true,
                                                animation: PTDiffAnimation = .default,
                                                finishTask:PTCollectionCallback? = nil) {
        guard validateSections(collectionData) else {
            finishTask?(collectionView)
            return
        }

        updateCoordinator.enqueue(name: "replaceData") { [weak self] finish in
            guard let self else {
                finish()
                return
            }

            self.autoRegisterIfNeeded(sections: collectionData)
            let previousSnapshot = self.diffableDataSource.snapshot()
            let previousSectionIdentifiers = Set(previousSnapshot.sectionIdentifiers.map(\.identifier))
            let previousRowIdentifiers = Set(previousSnapshot.itemIdentifiers.map(\.diffId))
            #if DEBUG
            let nextSectionIdentifiers = Set(collectionData.map(\.identifier))
            let nextRowIdentifiers = Set(collectionData.flatMap { $0.rows ?? [] }.map(\.diffId))
            if !previousSectionIdentifiers.isEmpty,
               previousSectionIdentifiers.isDisjoint(with: nextSectionIdentifiers),
               previousRowIdentifiers.isDisjoint(with: nextRowIdentifiers) {
                // English: Stable identity churn disables predictable Diffable animations and content refreshes.
                // Español: Cambiar todas las identidades impide animaciones y refrescos Diffable predecibles.
                // 中文：连续替换全部身份会破坏可预测的 Diffable 动画和内容刷新。
                PTNSLogConsole("[PTCollection] identity churn warning: all section and row identities changed")
            }
            #endif
            self.modelStore.replace(collectionData)
            self.lastPrefetchItemCount = nil
            self.photoPrefetchCoordinator.removeAll()
            self.layoutCache.removeAll()
            self.heightCache.removeAll()
            self.waterfallCache.removeAll()
            self.fallbackLayouts.removeAll()

            var snapshot = PTCollectionIDSnapshot()
            snapshot.appendSections(collectionData)

            var rowsToReconfigure: [PTRows] = []
            for section in collectionData {
                if let rows = section.rows, !rows.isEmpty {
                    snapshot.appendItems(rows, toSection: section)
                    rowsToReconfigure.append(contentsOf: rows.filter { previousRowIdentifiers.contains($0.diffId) })
                }
            }

            if !rowsToReconfigure.isEmpty {
                snapshot.reconfigureItems(rowsToReconfigure)
            }

            if !collectionData.isEmpty {
                PTUnavailableManager.render(.content, in: self)
            }

            self.applySnapshot(snapshot,
                               animatingDifferences: animated && self.structureAnimationEnabled) {
                finishTask?(self.collectionView)
                finish()
            }
        }
    }
    
    public func clearAllData(finishTask:PTCollectionCallback? = nil) {
        updateCoordinator.enqueue(name: "clearData") { [weak self] finish in
            guard let self else {
                finish()
                return
            }

            self.lastPrefetchItemCount = nil
            self.photoPrefetchCoordinator.removeAll()
            self.layoutCache.removeAll()
            self.heightCache.removeAll()
            self.waterfallCache.removeAll()
            self.fallbackLayouts.removeAll()
            self.modelStore.replace([])

            var snapshot = PTCollectionIDSnapshot()
            snapshot.deleteAllItems()
            let animated = self.structureAnimationEnabled
            self.applySnapshot(snapshot, animatingDifferences: animated) {
                finishTask?(self.collectionView)
                finish()
            }
        }
    }

    /// 在指定的 IndexPath 插入新行
    /// - Parameters:
    ///   - rows: 需要插入的新数据数组
    ///   - indexPath: 目标位置 (会自动容错处理越界问题)
    ///   - completion: 动画完成后的回调
    public func insertRows(_ rows: [PTRows], at indexPath: IndexPath, completion: PTActionTask? = nil) {
        updateCoordinator.enqueue(name: "insertRows") { [weak self] finish in
            guard let self else {
                finish()
                return
            }

            var snapshot = self.diffableDataSource.snapshot()
            guard !rows.isEmpty, self.validateRows(rows, against: snapshot) else {
                completion?()
                finish()
                return
            }
            guard indexPath.section >= 0, indexPath.section < snapshot.sectionIdentifiers.count else {
                completion?()
                finish()
                return
            }

            let sectionSnapshot = snapshot.sectionIdentifiers[indexPath.section]
            let sectionModel = self.resolvedSection(sectionSnapshot)
            if sectionModel.rows == nil { sectionModel.rows = [] }

            let currentRowsCount = snapshot.itemIdentifiers(inSection: sectionSnapshot).count
            let isAppend = indexPath.item >= currentRowsCount
            let currentRows = snapshot.itemIdentifiers(inSection: sectionSnapshot)
            let anchorItem = isAppend ? nil : currentRows[indexPath.item]
            let insertIndex = min(max(0, indexPath.item), sectionModel.rows?.count ?? 0)
            sectionModel.rows?.insert(contentsOf: rows, at: insertIndex)
            sectionModel.layoutVersion += 1

            self.layoutCache.removeAll()
            if self.viewConfig.viewType == .WaterFall, self.waterFallLayout != nil {
                self.clearWaterfallCache(section: indexPath.section)
            }

            if let anchor = anchorItem {
                snapshot.insertItems(rows, beforeItem: anchor)
            } else {
                snapshot.appendItems(rows, toSection: sectionSnapshot)
            }
            self.synchronizeModelStore(with: snapshot)

            let animated = self.structureAnimationEnabled
            self.applySnapshot(snapshot, animatingDifferences: animated) {
                completion?()
                finish()
            }
        }
    }

    public func insertRows(_ rows:[PTRows],section:Int,completion:PTActionTask? = nil) {
        updateCoordinator.enqueue(name: "appendRows") { [weak self] finish in
            guard let self else {
                finish()
                return
            }

            var snapshot = self.diffableDataSource.snapshot()
            guard !rows.isEmpty, self.validateRows(rows, against: snapshot),
                  section >= 0, section < snapshot.sectionIdentifiers.count else {
                completion?()
                finish()
                return
            }

            let sectionSnapshot = snapshot.sectionIdentifiers[section]
            let sectionModel = self.resolvedSection(sectionSnapshot)
            if sectionModel.rows == nil { sectionModel.rows = [] }
            sectionModel.rows?.append(contentsOf: rows)
            sectionModel.layoutVersion += 1

            self.layoutCache.removeAll()
            if self.viewConfig.viewType == .WaterFall, self.waterFallLayout != nil {
                self.clearWaterfallCache(section: section)
            }
            snapshot.appendItems(rows, toSection: sectionSnapshot)
            self.synchronizeModelStore(with: snapshot)

            let animated = self.structureAnimationEnabled
            self.applySnapshot(snapshot, animatingDifferences: animated) {
                completion?()
                finish()
            }
        }
    }

    public func insertSection(_ sections:[PTSection], afterIndex:Int? = nil,completion:PTActionTask? = nil) {
        updateCoordinator.enqueue(name: "insertSections") { [weak self] finish in
            guard let self else {
                finish()
                return
            }
            guard !sections.isEmpty else {
                completion?()
                finish()
                return
            }

            var snapshot = self.diffableDataSource.snapshot()
            guard self.validateSections(sections, against: snapshot) else {
                completion?()
                finish()
                return
            }
            if let index = afterIndex, index < 0 {
                self.reportUpdateError(.invalidSectionIndex(index))
                completion?()
                finish()
                return
            }

            self.layoutCache.removeAll()
            self.heightCache.removeAll()
            var insertIndex = snapshot.sectionIdentifiers.count
            if let index = afterIndex, index < snapshot.sectionIdentifiers.count {
                insertIndex = index + 1
                snapshot.insertSections(sections, afterSection: snapshot.sectionIdentifiers[index])
            } else {
                snapshot.appendSections(sections)
            }

            for i in 0..<sections.count {
                let targetIndex = insertIndex + i
                if self.viewConfig.viewType == .WaterFall, self.waterFallLayout != nil {
                    self.clearWaterfallCache(section: targetIndex)
                }
                sections[i].layoutVersion += 1
                if let rows = sections[i].rows, !rows.isEmpty {
                    snapshot.appendItems(rows, toSection: sections[i])
                }
            }
            self.synchronizeModelStore(with: snapshot)

            let animated = self.structureAnimationEnabled
            self.applySnapshot(snapshot, animatingDifferences: animated) {
                completion?()
                finish()
            }
        }
    }
    
    public func deleteRows(_ rows: [PTRows], from section: Int, completion: PTActionTask? = nil) {
        updateCoordinator.enqueue(name: "deleteRows") { [weak self] finish in
            guard let self else {
                finish()
                return
            }
            var snapshot = self.diffableDataSource.snapshot()
            guard section >= 0, section < snapshot.sectionIdentifiers.count else {
                completion?()
                finish()
                return
            }

            self.layoutCache.removeAll()
            if self.viewConfig.viewType == .WaterFall, self.waterFallLayout != nil {
                self.clearWaterfallCache(section: section)
            }

            let sectionSnapshot = snapshot.sectionIdentifiers[section]
            let sectionModel = self.resolvedSection(sectionSnapshot)
            let sectionRowIDs = Set(snapshot.itemIdentifiers(inSection: sectionSnapshot).map(\.diffId))
            let existingRows = rows.filter { sectionRowIDs.contains($0.diffId) }
            guard !existingRows.isEmpty else {
                completion?()
                finish()
                return
            }

            sectionModel.layoutVersion += 1
            sectionModel.rows?.removeAll(where: { existingRows.contains($0) })
            snapshot.deleteItems(existingRows)
            if sectionModel.rows?.isEmpty ?? true {
                snapshot.deleteSections([sectionSnapshot])
            }
            self.synchronizeModelStore(with: snapshot)

            let animated = self.structureAnimationEnabled
            self.applySnapshot(snapshot, animatingDifferences: animated) {
                completion?()
                finish()
            }
        }
    }

    public func deleteSectionsRows(_ rowsMap: [Int: [PTRows]], completion: PTActionTask? = nil) {
        updateCoordinator.enqueue(name: "deleteSectionRows") { [weak self] finish in
            guard let self else {
                finish()
                return
            }
            self.layoutCache.removeAll()
            self.heightCache.removeAll()
            var allRowsToDelete: [PTRows] = []
            var sectionsToDelete: [PTSection] = []
            var snapshot = self.diffableDataSource.snapshot()

            for (sectionIndex, rows) in rowsMap {
                guard sectionIndex >= 0, sectionIndex < snapshot.sectionIdentifiers.count else { continue }
                let sectionSnapshot = snapshot.sectionIdentifiers[sectionIndex]
                let sectionModel = self.resolvedSection(sectionSnapshot)
                if self.viewConfig.viewType == .WaterFall, self.waterFallLayout != nil {
                    self.clearWaterfallCache(section: sectionIndex)
                }
                sectionModel.layoutVersion += 1
                let sectionRowIDs = Set(snapshot.itemIdentifiers(inSection: sectionSnapshot).map(\.diffId))
                let existingRows = rows.filter { sectionRowIDs.contains($0.diffId) }
                sectionModel.rows?.removeAll(where: { existingRows.contains($0) })
                allRowsToDelete.append(contentsOf: existingRows)
                if sectionModel.rows?.isEmpty ?? true {
                    sectionsToDelete.append(sectionModel)
                }
            }

            guard !allRowsToDelete.isEmpty else {
                completion?()
                finish()
                return
            }

            let uniqueRows = Dictionary(grouping: allRowsToDelete, by: \.diffId).compactMap { $0.value.first }
            snapshot.deleteItems(uniqueRows)
            if !sectionsToDelete.isEmpty {
                snapshot.deleteSections(sectionsToDelete)
            }
            self.synchronizeModelStore(with: snapshot)

            let animated = self.structureAnimationEnabled
            self.applySnapshot(snapshot, animatingDifferences: animated) {
                if self.viewConfig.viewType == .WaterFall, self.waterFallLayout != nil {
                    self.collectionView.collectionViewLayout.invalidateLayout()
                }
                completion?()
                finish()
            }
        }
    }
    
    public func deleteSections(_ sections: [PTSection], completion: PTActionTask? = nil) {
        updateCoordinator.enqueue(name: "deleteSections") { [weak self] finish in
            guard let self else {
                finish()
                return
            }
            var snapshot = self.diffableDataSource.snapshot()
            let existingSections = sections.filter { snapshot.indexOfSection($0) != nil }
            guard !existingSections.isEmpty else {
                completion?()
                finish()
                return
            }

            for section in existingSections {
                if let index = snapshot.indexOfSection(section) {
                    if self.viewConfig.viewType == .WaterFall, self.waterFallLayout != nil {
                        self.clearWaterfallCache(section: index)
                    }
                    self.resolvedSection(section).layoutVersion += 1
                }
            }
            self.layoutCache.removeAll()
            self.heightCache.removeAll()
            snapshot.deleteSections(existingSections)
            self.synchronizeModelStore(with: snapshot)

            let animated = self.structureAnimationEnabled
            self.applySnapshot(snapshot, animatingDifferences: animated) {
                completion?()
                finish()
            }
        }
    }
}

//MARK: Layout
extension PTCollectionView {
    fileprivate func comboLayout() -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout { section, environment in
            self.generateSection(section: section,environment:environment)
        }
        switch viewConfig.decorationItemsType {
        case .Custom:
            viewConfig.decorationModel?.forEach { value in
                guard let decorationClass = value.decorationClass,
                      let decorationID = value.decorationID,
                      !decorationID.isEmpty else { return }
                layout.register(decorationClass, forDecorationViewOfKind: decorationID)
            }
        case .Normal,.Corner:
            layout.register(PTBaseDecorationView.self, forDecorationViewOfKind: PTBaseDecorationView.ID)
        default:break
        }
        return layout
    }
    
    private func buildSection(sectionModel: PTSection,sectionIndex: NSInteger, environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let screenWidth = environment.container.contentSize.width
        let behavior = viewConfig.collectionViewBehavior
        let sectionLayout = sectionModel.layoutConfiguration
        let itemHeight = sectionLayout?.itemHeight.flatMap { value -> CGFloat? in
            switch value {
            case .fixed(let height), .estimated(let height): return max(1, height)
            }
        } ?? viewConfig.itemHeight
        let usesEstimatedItemHeight: Bool = {
            guard let value = sectionLayout?.itemHeight else { return false }
            if case .estimated = value { return true }
            return false
        }()
        let topContentSpace = sectionLayout?.topSpacing ?? viewConfig.contentTopSpace
        let bottomContentSpace = sectionLayout?.bottomSpacing ?? viewConfig.contentBottomSpace
        let itemLeadingSpace = sectionLayout?.contentInsets?.leading ?? viewConfig.cellLeadingSpace
        let itemTrailingSpace = sectionLayout?.interGroupSpacing ?? viewConfig.cellTrailingSpace
        let group: NSCollectionLayoutGroup
        
        switch viewConfig.viewType {
        case .Gird:
            group = UICollectionView.girdCollectionLayout(
                data: sectionModel.rows,
                groupWidth: screenWidth,
                itemHeight: itemHeight,
                cellRowCount: max(1, viewConfig.rowCount),
                originalX: viewConfig.itemOriginalX,
                topContentSpace: topContentSpace,
                bottomContentSpace: bottomContentSpace,
                cellLeadingSpace: itemLeadingSpace,
                cellTrailingSpace: itemTrailingSpace
            )
        case .Normal:
            if usesEstimatedItemHeight {
                let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                  heightDimension: .estimated(itemHeight))
                let item = NSCollectionLayoutItem(layoutSize: size)
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                       heightDimension: .estimated(itemHeight))
                let estimatedGroup = NSCollectionLayoutGroup.vertical(layoutSize: groupSize,
                                                                       subitems: [item])
                estimatedGroup.interItemSpacing = .fixed(itemTrailingSpace)
                group = estimatedGroup
            } else {
                group = UICollectionView.girdCollectionLayout(
                    data: sectionModel.rows,
                    groupWidth: screenWidth,
                    itemHeight: itemHeight,
                    cellRowCount: 1,
                    originalX: viewConfig.itemOriginalX,
                    topContentSpace: topContentSpace,
                    bottomContentSpace: bottomContentSpace,
                    cellTrailingSpace: itemTrailingSpace
                )
            }
        case .WaterFall:
            if let waterFall = waterFallLayout {
                let result = buildWaterfallItems(
                    section: sectionIndex,
                    data: sectionModel.rows?.compactMap { $0.dataModel } ?? [],
                    width: screenWidth,
                    config: viewConfig,
                    version: sectionModel.layoutVersion,
                    itemHeight: waterFall
                )

                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .absolute(screenWidth),
                    heightDimension: .absolute(result.height)
                )

                group = NSCollectionLayoutGroup.custom(layoutSize: groupSize) { _ in
                    result.items
                }
            } else {
                group = oneSquareGroup()
            }
        case .Horizontal:
                group = UICollectionView.horizontalLayout(
                    data: sectionModel.rows,
                    itemOriginalX: viewConfig.itemOriginalX,
                    itemWidth: viewConfig.itemWidth,
                    itemHeight: itemHeight,
                    topContentSpace: topContentSpace,
                    bottomContentSpace: bottomContentSpace,
                    itemLeadingSpace: itemLeadingSpace
                )
        case .HorizontalLayoutSystem:
                group = UICollectionView.horizontalLayoutSystem(
                    data: sectionModel.rows,
                    itemOriginalX: viewConfig.itemOriginalX,
                    itemWidth: viewConfig.itemWidth,
                    itemHeight: itemHeight,
                    topContentSpace: topContentSpace,
                    bottomContentSpace: bottomContentSpace,
                    itemLeadingSpace: itemLeadingSpace
                )
        case .Tag:
            let tagDatas = sectionModel.rows?.compactMap { $0.dataModel }
            if let tags = tagDatas as? [PTTagLayoutModel] {
                // English: Use the layout environment width so tags recalculate after rotation or split view changes.
                // Español: Usa el ancho del entorno de diseño para recalcular las etiquetas tras rotación o cambios de Split View.
                // 中文：使用布局环境宽度，确保旋转或分屏尺寸变化后标签重新计算。
                group = UICollectionView.tagShowLayout(
                    data: tags,
                    screenWidth: screenWidth,
                    itemOriginalX: viewConfig.itemOriginalX,
                    itemHeight: itemHeight,
                    topContentSpace: topContentSpace,
                    bottomContentSpace: bottomContentSpace,
                    itemLeadingSpace: itemLeadingSpace,
                    itemTrailingSpace: itemTrailingSpace,
                    itemContentSpace: viewConfig.tagCellContentSpace
                )
            } else {
                group = oneSquareGroup()
            }
        case .Custom:
            if let customerLayout {
                group = customerLayout(sectionIndex, sectionModel)
            } else {
                group = oneSquareGroup()
            }
        }
        
        var sectionInsets = sectionLayout?.contentInsets ?? viewConfig.sectionEdges
        let sectionWidth: CGFloat
        switch viewConfig.decorationItemsType {
        case .Normal,.Corner,.NoItems:
            if sectionLayout == nil {
                sectionInsets = NSDirectionalEdgeInsets(top: (sectionModel.headerHeight ?? .leastNormalMagnitude) + viewConfig.contentTopSpace + viewConfig.decorationItemsEdges.top,
                                                         leading: sectionInsets.leading,
                                                         bottom: viewConfig.contentBottomSpace,
                                                         trailing: sectionInsets.trailing)
            } else {
                sectionInsets.top += (sectionModel.headerHeight ?? 0) + viewConfig.decorationItemsEdges.top
                sectionInsets.bottom += bottomContentSpace
            }
        default:
            sectionInsets = decorationCustomLayoutInsetReset?(sectionIndex, sectionModel) ?? .zero
        }
        
        switch viewConfig.decorationItemsType {
        case .Normal,.Corner:
            sectionWidth = viewConfig.decorationItemsEdges.leading + viewConfig.decorationItemsEdges.trailing
        case .NoItems,.Custom:
            sectionWidth = 0
        }
                
        let laySection = NSCollectionLayoutSection(group: group)
        laySection.orthogonalScrollingBehavior = behavior
        laySection.contentInsets = sectionInsets
        
        if viewConfig.customReuseViews,let items = customerReuseViews?(sectionIndex,sectionModel) {
            laySection.boundarySupplementaryItems = items
        } else {
            laySection.boundarySupplementaryItems = generateSupplementaryItems(section: sectionIndex, sectionModel: sectionModel, sectionWidth: sectionWidth, screenWidth: screenWidth)
        }
        
        laySection.decorationItems = generateDecorationItems(section: sectionIndex, sectionModel: sectionModel)
        
        // 🌟 修复注入：监听正交滚动 (Orthogonal Scrolling)
        if behavior != .none {
            laySection.visibleItemsInvalidationHandler = { [weak self] visibleItems, offset, env in
                guard let self = self else { return }
                Task { @MainActor in
                    self.orthogonalDidScroll?(sectionIndex, offset)
                    let pageWidth = env.container.contentSize.width
                    if pageWidth > 0 {
                        let currentPage = Int(round(offset.x / pageWidth))
                        self.orthogonalPageDidChange?(sectionIndex, currentPage)
                    }
                }
            }
        }
        return laySection
    }
    
    fileprivate func generateSection(section: NSInteger, environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let snapshot = self.diffableDataSource.snapshot()
        guard section >= 0, section < snapshot.sectionIdentifiers.count else {
            if let fallback = fallbackLayouts[section] {
                return fallback
            }
            return NSCollectionLayoutSection(group: oneSquareGroup())
        }

        let sectionModel = resolvedSection(snapshot.sectionIdentifiers[section])
        let key = LayoutCacheKey(section: section,
                                 width: environment.container.contentSize.width,
                                 version: sectionModel.layoutVersion)
        if let cache = layoutCache.get(forKey: key) {
            return cache
        }

        let sectionLayout = buildSection(sectionModel: sectionModel,sectionIndex: section, environment: environment)
        layoutCache.set(sectionLayout, forKey: key)
        fallbackLayouts[section] = sectionLayout
        return sectionLayout
    }
    
    private func oneSquareGroup() -> NSCollectionLayoutGroup {
        if !didReportFallbackLayout {
            didReportFallbackLayout = true
            // English: Report the fallback once to avoid logging during every layout pass.
            // Español: Informa del fallback una sola vez para evitar registros en cada pasada de diseño.
            // 中文：只记录一次兜底布局，避免每次布局都重复输出日志。
            PTNSLogConsole("Warning: CustomerLayout is nil. Fallback to 1x1 group.")
        }
        let size = NSCollectionLayoutSize(widthDimension: .absolute(1), heightDimension: .absolute(1))
        return NSCollectionLayoutGroup(layoutSize: size)
    }

    private func generateSupplementaryItems(section: NSInteger, sectionModel: PTSection, sectionWidth: CGFloat, screenWidth: CGFloat) -> [NSCollectionLayoutBoundarySupplementaryItem] {
        var supplementaryItems = [NSCollectionLayoutBoundarySupplementaryItem]()
        let headerSpacing = sectionModel.layoutConfiguration?.headerSpacing ?? 0
        let footerSpacing = sectionModel.layoutConfiguration?.footerSpacing ?? 0
        
        if !(sectionModel.headerReuseID ?? "").stringIsEmpty() {
            let headerWidth = max(1, screenWidth - viewConfig.headerWidthOffset - sectionWidth)
            let headerSize = NSCollectionLayoutSize(
                widthDimension: .absolute(headerWidth),
                heightDimension: .absolute(sectionModel.headerHeight ?? .leastNormalMagnitude)
            )
            
            let headerItem = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .topTrailing,
                absoluteOffset: CGPoint(x: -viewConfig.decorationItemsEdges.leading,
                                        y: viewConfig.decorationItemsEdges.top + headerSpacing + (sectionModel.headerHeight ?? .leastNormalMagnitude))
            )
            headerItem.contentInsets = .zero
            headerItem.pinToVisibleBounds = viewConfig.pinHeaderToVisibleBounds
            supplementaryItems.append(headerItem)
        }
        
        if !(sectionModel.footerReuseID ?? "").stringIsEmpty() {
            let footerWidth = max(1, screenWidth - viewConfig.footerWidthOffset - sectionWidth)
            let footerSize = NSCollectionLayoutSize(
                widthDimension: .absolute(footerWidth),
                heightDimension: .absolute(sectionModel.footerHeight ?? .leastNormalMagnitude)
            )

            let footerItem = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: footerSize,
                elementKind: UICollectionView.elementKindSectionFooter,
                alignment: .bottom,
                absoluteOffset: CGPoint(x: -viewConfig.decorationItemsEdges.leading, y: footerSpacing)
            )
            footerItem.pinToVisibleBounds = viewConfig.pinFooterToVisibleBounds
            supplementaryItems.append(footerItem)
        }
        
        return supplementaryItems
    }

    private func generateDecorationItems(section: NSInteger, sectionModel: PTSection) -> [NSCollectionLayoutDecorationItem] {
        switch viewConfig.decorationItemsType {
        case .Custom:
            let snapshot = self.diffableDataSource.snapshot()
            guard !snapshot.sectionIdentifiers.isEmpty else { return [] }
            if let decorationInCollectionView = decorationInCollectionView?(section, sectionModel) {
                return decorationInCollectionView
            } else {
                return []
            }
        case .Normal,.Corner:
            let backItem = NSCollectionLayoutDecorationItem.background(elementKind: PTBaseDecorationView.ID)
            backItem.contentInsets = viewConfig.decorationItemsEdges
            return [backItem]
        default:
            return []
        }
    }

    func buildWaterfallItems(section: Int,
                             data: [AnyObject],
                             width: CGFloat,
                             config: PTCollectionViewConfig,
                             version: Int,
                             itemHeight: (Int, AnyObject) -> CGFloat) -> (items: [NSCollectionLayoutGroupCustomItem], height: CGFloat) {
        
        let key = PTCollectionWaterfallCacheKey(section: section, width: width, version: version)
        
        if let cache = waterfallCache[key] {
            return (cache.items, cache.contentHeight)
        }
        
        let result = PTCollectionLayoutGeometry.waterfall(data: data,
                                                          width: width,
                                                          rowCount: max(1, config.rowCount),
                                                          itemOriginalX: config.itemOriginalX,
                                                          topContentSpace: config.contentTopSpace,
                                                          bottomContentSpace: config.contentBottomSpace,
                                                          itemSpace: config.cellLeadingSpace,
                                                          itemTrailingSpace: config.cellTrailingSpace,
                                                          itemHeight: itemHeight)
        let items = result.frames.map { NSCollectionLayoutGroupCustomItem(frame: $0) }
        if waterfallCache.count >= waterfallCacheLimit,
           waterfallCache[key] == nil,
           let oldestKey = waterfallCache.keys.first {
            waterfallCache.removeValue(forKey: oldestKey)
        }
        waterfallCache[key] = PTCollectionWaterfallCache(items: items,
                                             contentHeight: result.contentHeight)
        return (items, result.contentHeight)
    }
    
    func clearWaterfallCache(section: Int) {
        // 🌟 修复提升：原地过滤移除优化
        waterfallCache = waterfallCache.filter { $0.key.section != section }
    }
}

//MARK: EmptyDataView
extension PTCollectionView {
    fileprivate func setiOS17EmptyDataView() {
        switch self.viewConfig.emptyShowType {
        case .Auto:
            self.showEmptyConfig()
        case .ThirtyParty:
            self.below17EmptyDataSet()
        case .System:
            self.showEmptyConfig()
        }
    }
    
    private func showEmptyConfig() {
        let snapshot = self.diffableDataSource.snapshot()
        let isEmpty = snapshot.numberOfItems == 0
        guard viewConfig.showEmptyAlert, isEmpty, let config = viewConfig.emptyViewConfig else {
            PTUnavailableManager.render(.content, in: self)
            return
        }

        PTUnavailableManager.render(.empty, in: self, config: config) { [weak self = self] in
            self?.showEmptyLoading()
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(100))
                guard !Task.isCancelled else { return }
                self?.emptyTap?(nil)
            }
        }
    }
    
    public func hideEmptyLoading(task: PTActionTask?) {
        PTUnavailableManager.hideUnavailableView(in: self, task: task)
    }
    
    public func showEmptyLoading() {
        PTUnavailableManager.render(.loading, in: self)
    }
    
    private func below17EmptyDataSet() {
        let snapshot = self.diffableDataSource.snapshot()
        let isEmpty = snapshot.numberOfItems == 0
        if self.viewConfig.showEmptyAlert {
            if isEmpty {
                if let empty = self.viewConfig.emptyViewConfig {
                    if let emptyCuston = empty.customerView {
                        collectionView.emptyDataSetView { view in
                            view.backgroundColor = empty.backgroundColor
                            view.customView(emptyCuston)
                                .verticalOffset(empty.verticalOffSet)
                                .isTouchAllowed(true)
                        }
                    } else {
                        let buttonAtt:PTRichText = """
                                    \(wrap: .embedding("""
                                    \(empty.buttonTitle,.font(empty.buttonFont),.paragraph(.alignment(.center),.lineSpacing(7.5)),.foreground(empty.buttonTextColor))
                                    """))
                                    """
                        
                        collectionView.emptyDataSetView { view in
                            view.backgroundColor = empty.backgroundColor
                            view.titleLabelString(empty.mainTitleAtt?.value)
                                .detailLabelString(empty.secondaryEmptyAtt?.value)
                                .image(empty.image)
                                .buttonTitle(buttonAtt.value, for: .normal)
                                .verticalOffset(empty.verticalOffSet)
                                .verticalSpace(empty.imageToTextPadding)
                                .didTapContentView {
                                    self.emptyTap?(view)
                                }
                                .didTapDataButton {
                                    self.emptyButtonTap?(view)
                                }
                        }
                    }
                    self.collectionView.reloadEmptyDataSet()
                }
            } else {
                self.reloadEmptyConfig()
            }
        } else {
            self.reloadEmptyConfig()
        }
    }
    
    public func reloadEmptyConfig() {
        if self.viewConfig.showEmptyAlert {
            collectionView.reloadEmptyDataSet()
        }
    }
}

//MARK: Refresh
extension PTCollectionView {
    public func endRefresh() {
        self.collectionView.pt_endMJRefresh()
    }
    
    public func footerRefreshNoMore () {
        collectionView.pt.footer?.endRefreshingWithNoMoreData()
        collectionView.pt.autoFooter?.endRefreshingWithNoMoreData()
    }
    
    public func footerRefreshReset() {
        collectionView.pt.footer?.resetNoMoreData()
        collectionView.pt.autoFooter?.resetNoMoreData()
    }
}

//MARK: Register
extension PTCollectionView {
    public func registerHeaderIdsNClasss(ids:[String],viewClass:AnyClass,kind:String) {
        collectionView.registerSupplementaryView(ids: ids, viewClass: viewClass, kind: kind)
    }
    
    public func registerClassCells(classs:[String:AnyClass]) {
        collectionView.registerClassCells(classs: classs)
    }
    
    public func registerNibCells(nib:[String:String]) {
        collectionView.registerNibCells(nib: nib)
    }
    
    public func registerSupplementaryView(classs:[String:AnyClass],kind:String) {
        collectionView.registerSupplementaryView(classs: classs, kind: kind)
    }
}

extension PTCollectionView {
    public func reloadSections(at indexes: [Int],
                               animated: Bool = true,
                               completion: PTActionTask? = nil) {
        updateCoordinator.enqueue(name: "reloadSections", sections: indexes) { [weak self] finish in
            guard let self else {
                completion?()
                finish()
                return
            }

            var snapshot = self.diffableDataSource.snapshot()

            var seenIndexes = Set<Int>()

            let validIndexes = indexes.filter { index in
                index >= 0 &&
                index < snapshot.sectionIdentifiers.count &&
                seenIndexes.insert(index).inserted
            }

            let validSections = validIndexes.map {
                snapshot.sectionIdentifiers[$0]
            }

            guard !validSections.isEmpty else {
                completion?()
                finish()
                return
            }

            for index in validIndexes {
                if self.viewConfig.viewType == .WaterFall,
                   self.waterFallLayout != nil {
                    self.clearWaterfallCache(section: index)
                }

                self.markSectionDirty(index)
            }

            snapshot.reloadSections(validSections)

            self.applySnapshot(
                snapshot,
                animatingDifferences: animated && self.structureAnimationEnabled
            ) {
                completion?()
                finish()
            }
        }
    }
    
    public func reloadRows(_ rows: [PTRows],
                           in section: Int,
                           completion: PTActionTask? = nil) {
        updateCoordinator.enqueue(name: "reloadRows", kind: .content) { [weak self] finish in
            guard let self else {
                completion?()
                finish()
                return
            }

            var snapshot = self.diffableDataSource.snapshot()

            guard section >= 0,
                  section < snapshot.sectionIdentifiers.count else {
                completion?()
                finish()
                return
            }

            let sectionSnapshot = snapshot.sectionIdentifiers[section]
            let sectionModel = self.resolvedSection(sectionSnapshot)

            let sectionRowIDs = Set(
                snapshot
                    .itemIdentifiers(inSection: sectionSnapshot)
                    .map(\.diffId)
            )

            var seenRows = Set<String>()

            let existingRows = rows.filter {
                sectionRowIDs.contains($0.diffId) &&
                seenRows.insert($0.diffId).inserted
            }

            guard !existingRows.isEmpty else {
                completion?()
                finish()
                return
            }

            self.modelStore.update(rows: existingRows)

            let width = self.collectionView.bounds.width

            for row in existingRows {
                self.heightCache.remove(
                    forKey: HeightCacheKey(
                        id: row.diffId,
                        width: width
                    )
                )
            }

            self.layoutCache.remove(
                forKey: LayoutCacheKey(
                    section: section,
                    width: width,
                    version: sectionModel.layoutVersion
                )
            )

            if self.viewConfig.viewType == .WaterFall,
               self.waterFallLayout != nil {
                self.clearWaterfallCache(section: section)
            }

            self.markSectionDirty(section)

            self.cellConfigurationDiagnostics.request(existingRows.map { PTRowIdentifier($0.diffId) })
            snapshot.reconfigureItems(existingRows)

            let animated = self.contentAnimationEnabled

            self.applySnapshot(
                snapshot,
                animatingDifferences: animated
            ) {
                completion?()
                finish()
            }
        }
    }
    
    public func reloadSectionsRows(_ rowsMap: [Int: [PTRows]],
                                   completion: PTActionTask? = nil) {
        updateCoordinator.enqueue(name: "reloadSectionRows",
                                  kind: .content,
                                  sections: Array(rowsMap.keys)) { [weak self] finish in
            guard let self else {
                completion?()
                finish()
                return
            }

            var snapshot = self.diffableDataSource.snapshot()
            let containerWidth = self.collectionView.bounds.width

            var allRowsToReload: [PTRows] = []
            var seenRows = Set<String>()

            for (sectionIndex, rows) in rowsMap {

                guard sectionIndex >= 0,
                      sectionIndex < snapshot.sectionIdentifiers.count else {
                    continue
                }

                let sectionModel =
                    self.resolvedSection(snapshot.sectionIdentifiers[sectionIndex])
                let sectionSnapshot = snapshot.sectionIdentifiers[sectionIndex]

                let sectionRowIDs = Set(
                    snapshot
                        .itemIdentifiers(inSection: sectionSnapshot)
                        .map(\.diffId)
                )

                let existingRows = rows.filter {
                    sectionRowIDs.contains($0.diffId) &&
                    seenRows.insert($0.diffId).inserted
                }

                guard !existingRows.isEmpty else {
                    continue
                }

                for row in existingRows {
                    self.heightCache.remove(
                        forKey: HeightCacheKey(
                            id: row.diffId,
                            width: containerWidth
                        )
                    )
                }

                self.layoutCache.remove(
                    forKey: LayoutCacheKey(
                        section: sectionIndex,
                        width: containerWidth,
                        version: sectionModel.layoutVersion
                    )
                )

                if self.viewConfig.viewType == .WaterFall,
                   self.waterFallLayout != nil {
                    self.clearWaterfallCache(
                        section: sectionIndex
                    )
                }

                sectionModel.layoutVersion += 1

                allRowsToReload.append(
                    contentsOf: existingRows
                )
            }

            guard !allRowsToReload.isEmpty else {
                completion?()
                finish()
                return
            }

            self.modelStore.update(rows: allRowsToReload)
            self.cellConfigurationDiagnostics.request(allRowsToReload.map { PTRowIdentifier($0.diffId) })
            snapshot.reconfigureItems(allRowsToReload)

            let animated = self.contentAnimationEnabled

            self.applySnapshot(
                snapshot,
                animatingDifferences: animated
            ) { [weak self] in

                guard let self else {
                    completion?()
                    finish()
                    return
                }

                if self.viewConfig.viewType == .WaterFall,
                   self.waterFallLayout != nil {
                    self.collectionView
                        .collectionViewLayout
                        .invalidateLayout()
                }

                completion?()
                finish()
            }
        }
    }
    
    public func reloadAllData(animated: Bool = true,
                              completion: PTActionTask? = nil) {
        updateCoordinator.enqueue(name: "reloadAllData") { [weak self] finish in
            guard let self else {
                completion?()
                finish()
                return
            }

            self.layoutCache.removeAll()
            self.heightCache.removeAll()
            self.waterfallCache.removeAll()
            self.fallbackLayouts.removeAll()

            var snapshot =
                self.diffableDataSource.snapshot()

            let allSections =
                snapshot.sectionIdentifiers

            guard !allSections.isEmpty else {
                completion?()
                finish()
                return
            }

            for section in allSections {
                self.resolvedSection(section).layoutVersion += 1
            }

            snapshot.reloadSections(allSections)

            let allExistingItems =
                snapshot.itemIdentifiers

            if !allExistingItems.isEmpty {
                snapshot.reloadItems(
                    allExistingItems
                )
            }

            self.applySnapshot(
                snapshot,
                animatingDifferences: animated && self.structureAnimationEnabled
            ) { [weak self] in

                guard let self else {
                    completion?()
                    finish()
                    return
                }

                if self.viewConfig.viewType == .WaterFall,
                   self.waterFallLayout != nil {
                    self.collectionView
                        .collectionViewLayout
                        .invalidateLayout()
                }

                completion?()
                finish()
            }
        }
    }
    
    public func softReloadAllData(animated: Bool = false,
                                  completion: PTActionTask? = nil) {
        updateCoordinator.enqueue(name: "softReloadAllData", kind: .content) { [weak self] finish in
            guard let self else {
                completion?()
                finish()
                return
            }

            var snapshot =
                self.diffableDataSource.snapshot()

            let allItems =
                snapshot.itemIdentifiers

            self.cellConfigurationDiagnostics.request(allItems)

            guard !allItems.isEmpty else {
                completion?()
                finish()
                return
            }

            snapshot.reconfigureItems(allItems)

            self.applySnapshot(
                snapshot,
                animatingDifferences: animated && self.contentAnimationEnabled
            ) {
                completion?()
                finish()
            }
        }
    }

    // English: Reload only the cells whose models changed while keeping Diffable structure intact.
    // Español: Recarga solo las celdas cuyos modelos cambiaron y conserva intacta la estructura Diffable.
    // 中文：只刷新模型发生变化的 Cell，不改变 Diffable 结构。
    public func reloadItemContent(at indexPaths: [IndexPath], completion: PTActionTask? = nil) {
        enqueueContentRefresh(name: "reloadItemContent",
                              sections: [],
                              indexPaths: indexPaths,
                              invalidateLayout: false,
                              completion: completion)
    }

    // English: Reload every item in selected sections without rebuilding their identities.
    // Español: Recarga todos los elementos de las secciones seleccionadas sin reconstruir sus identidades.
    // 中文：刷新指定 Section 的全部内容，但不重建身份和结构。
    public func reloadSectionContent(at indexes: [Int],
                                     invalidateLayout: Bool = false,
                                     completion: PTActionTask? = nil) {
        enqueueContentRefresh(name: "reloadSectionContent",
                              sections: indexes,
                              indexPaths: [],
                              invalidateLayout: invalidateLayout,
                              completion: completion)
    }

    // English: Reconfigure lightweight content using the native Diffable path.
    // Español: Reconfigura contenido ligero usando la ruta Diffable nativa.
    // 中文：使用系统 Diffable 路径重新配置轻量内容。
    public func reconfigureSections(at indexes: [Int], completion: PTActionTask? = nil) {
        enqueueContentRefresh(name: "reconfigureSections",
                              sections: indexes,
                              indexPaths: [],
                              invalidateLayout: false,
                              completion: completion)
    }

    // English: Replace selected cells explicitly when the cell class or reuse path changed.
    // Español: Reemplaza explícitamente las celdas seleccionadas cuando cambió su clase o ruta de reuse.
    // 中文：当 Cell 类型或复用路径变化时，显式替换指定 Cell。
    public func reloadItemCell(at indexPaths: [IndexPath], completion: PTActionTask? = nil) {
        updateCoordinator.enqueue(name: "reloadItemCell",
                                 kind: .structure,
                                 items: indexPaths) { [weak self] finish in
            guard let self else {
                completion?()
                finish()
                return
            }
            let snapshot = self.diffableDataSource.snapshot()
            let rowIDs = self.rowIdentifiers(for: Set(indexPaths), in: snapshot)
            guard !rowIDs.isEmpty else {
                completion?()
                finish()
                return
            }
            var replacementSnapshot = snapshot
            replacementSnapshot.reloadItems(rowIDs)
            self.applySnapshot(replacementSnapshot,
                               animatingDifferences: self.structureAnimationEnabled) {
                completion?()
                finish()
            }
        }
    }

    // English: Replace all cells in selected sections without rebuilding section identities.
    // Español: Reemplaza todas las celdas de las secciones seleccionadas sin reconstruir sus identidades.
    // 中文：替换指定 Section 中的所有 Cell，不重建 Section 身份。
    public func reloadSectionCells(at indexes: [Int], completion: PTActionTask? = nil) {
        updateCoordinator.enqueue(name: "reloadSectionCells",
                                 kind: .structure,
                                 sections: indexes) { [weak self] finish in
            guard let self else {
                completion?()
                finish()
                return
            }
            let snapshot = self.diffableDataSource.snapshot()
            let rowIDs = self.rowIdentifiers(for: Set(indexes), in: snapshot)
            guard !rowIDs.isEmpty else {
                completion?()
                finish()
                return
            }
            var replacementSnapshot = snapshot
            replacementSnapshot.reloadItems(rowIDs)
            self.applySnapshot(replacementSnapshot,
                               animatingDifferences: self.structureAnimationEnabled) {
                completion?()
                finish()
            }
        }
    }

    // English: Update the ModelStore first, then refresh only the affected item.
    // Español: Actualiza primero el ModelStore y después refresca solo el elemento afectado.
    // 中文：先更新 ModelStore，再只刷新受影响的 Item。
    public func updateRow(_ row: PTRows, completion: PTActionTask? = nil) {
        modelStore.update(row: row)
        guard let indexPath = diffableDataSource.indexPath(for: PTRowIdentifier(row.diffId)) else {
            completion?()
            return
        }
        reloadItemContent(at: [indexPath], completion: completion)
    }

    public func updateRows(_ rows: [PTRows],
                           reload: Bool = true,
                           completion: PTActionTask? = nil) {
        modelStore.update(rows: rows)
        guard reload else {
            completion?()
            return
        }
        let indexPaths = rows.compactMap {
            diffableDataSource.indexPath(for: PTRowIdentifier($0.diffId))
        }
        reloadItemContent(at: indexPaths, completion: completion)
    }

    public func updateItemContent(at indexPath: IndexPath,
                                  using row: PTRows,
                                  invalidateLayout: Bool = false,
                                  completion: PTActionTask? = nil) {
        modelStore.updateItemContent(at: indexPath, using: row)
        enqueueContentRefresh(name: "updateItemContent",
                              sections: [],
                              indexPaths: [indexPath],
                              invalidateLayout: invalidateLayout,
                              completion: completion)
    }

    private func enqueueContentRefresh(name: String,
                                       sections: [Int],
                                       indexPaths: [IndexPath],
                                       invalidateLayout: Bool,
                                       completion: PTActionTask?) {
        let completionHandler: PTCollectionUpdateCoordinator.Completion?
        if let completion {
            completionHandler = { @MainActor in completion() }
        } else {
            completionHandler = nil
        }
        updateCoordinator.enqueueContent(name: name,
                                         sections: sections,
                                         items: indexPaths,
                                         invalidateLayout: invalidateLayout,
                                         body: { [weak self] sectionSet, itemSet, invalidatesLayout, finish in
            guard let self else {
                finish()
                return
            }
            self.performContentRefresh(sectionIndexes: sectionSet,
                                       itemIndexPaths: itemSet,
                                       invalidateLayout: invalidatesLayout,
                                       finish: finish)
        },
                                         completion: completionHandler)
    }

    // English: Reconfigure visible cells for theme, language and presentation-only changes.
    // Español: Reconfigura las celdas visibles para cambios de tema, idioma y presentación.
    // 中文：用于主题、语言等展示变化，只重新配置当前可见 Cell。
    public func reloadVisibleContent(completion: PTActionTask? = nil) {
        reloadItemContent(at: collectionView.indexPathsForVisibleItems, completion: completion)
    }

    // English: Invalidate section geometry without pretending that content changed.
    // Español: Invalida la geometría de la sección sin fingir que cambió el contenido.
    // 中文：只使 Section 几何失效，不伪造内容变化。
    public func invalidateSectionLayout(at indexes: [Int], completion: PTActionTask? = nil) {
        updateCoordinator.enqueue(name: "invalidateSectionLayout",
                                  kind: .layout,
                                  sections: indexes) { [weak self] finish in
            guard let self else {
                completion?()
                finish()
                return
            }
            let snapshot = self.diffableDataSource.snapshot()
            for index in indexes where snapshot.sectionIdentifiers.indices.contains(index) {
                self.clearWaterfallCache(section: index)
                self.markSectionDirty(index)
            }
            self.layoutCache.removeAll()
            self.heightCache.removeAll()
            self.collectionView.collectionViewLayout.invalidateLayout()
            completion?()
            finish()
        }
    }

    // English: Invalidate only the geometry cache for the requested rows.
    // Español: Invalida solo la caché geométrica de las filas solicitadas.
    // 中文：只清理指定 Row 的几何缓存。
    public func invalidateItemLayout(at indexPaths: [IndexPath], completion: PTActionTask? = nil) {
        updateCoordinator.enqueue(name: "invalidateItemLayout",
                                  kind: .layout,
                                  items: indexPaths) { [weak self] finish in
            guard let self else {
                completion?()
                finish()
                return
            }
            var sections = Set<Int>()
            let width = self.collectionView.bounds.width
            for indexPath in indexPaths {
                guard let row = self.diffableDataSource.itemIdentifier(for: indexPath) else { continue }
                self.heightCache.remove(forKey: HeightCacheKey(id: row.diffId, width: width))
                sections.insert(indexPath.section)
            }
            for section in sections {
                self.clearWaterfallCache(section: section)
                self.markSectionDirty(section)
            }
            self.collectionView.collectionViewLayout.invalidateLayout()
            completion?()
            finish()
        }
    }
}

//MARK: Get Models (Data Query)
extension PTCollectionView {
    
    public func getRow(at indexPath: IndexPath) -> PTRows? {
        guard let row = diffableDataSource.itemIdentifier(for: indexPath) else { return nil }
        return resolvedRow(row)
    }
    
    public func getRows(at indexPaths: [IndexPath]) -> [PTRows] {
        return indexPaths.compactMap { getRow(at: $0) }
    }
    
    public func getRow(by diffId: String) -> PTRows? {
        let snapshot = diffableDataSource.snapshot()
        guard let row = snapshot.itemIdentifiers.first(where: { $0.diffId == diffId }) else { return nil }
        return resolvedRow(row)
    }
    
    public func getAllRows(in section: Int) -> [PTRows] {
        let snapshot = diffableDataSource.snapshot()
        let sectionIdentifiers = snapshot.sectionIdentifiers
        guard section >= 0 && section < sectionIdentifiers.count else { return [] }
        let targetSection = sectionIdentifiers[section]
        return snapshot.itemIdentifiers(inSection: targetSection).map(resolvedRow)
    }
    
    public func getSectionRowsMap(from indexPaths: [IndexPath]) -> [Int: [PTRows]] {
        var rowsMap: [Int: [PTRows]] = [:]
        for indexPath in indexPaths {
            if let row = self.getRow(at: indexPath) {
                rowsMap[indexPath.section, default: []].append(row)
            }
        }
        return rowsMap
    }
    
    public func getSectionIndex(byHeaderID headerID: String) -> Int? {
        let snapshot = self.diffableDataSource.snapshot()
        let index = snapshot.sectionIdentifiers.firstIndex { sectionModel in
            return resolvedSection(sectionModel).headerReuseID == headerID
        }
        return index
    }
}
