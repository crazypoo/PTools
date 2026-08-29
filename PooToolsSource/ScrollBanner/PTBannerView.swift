//
//  PTBannerView.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 30/3/2026.
//  Copyright © 2026 crazypoo. All rights reserved.
//

import UIKit
import AVFoundation
import SwifterSwift
import SnapKit
import AttributedString

@MainActor
public final class PTBannerScheduler {

    public static let shared = PTBannerScheduler()
    public var autoScrollInterval: TimeInterval = 2 {
        didSet {
            restartTimerIfNeeded()
        }
    }

    private var banners = NSHashTable<PTBannerView>.weakObjects()
    private var timer: DispatchSourceTimer?

    func add(_ banner: PTBannerView) {
        let alreadyRegistered = banners.allObjects.contains { $0 === banner }
        banners.add(banner)
        if timer == nil {
            startIfNeeded()
        } else if !alreadyRegistered {
            restartTimerIfNeeded()
        }
    }

    func remove(_ banner: PTBannerView) {
        let wasRegistered = banners.allObjects.contains { $0 === banner }
        banners.remove(banner)
        guard wasRegistered else { return }

        if banners.allObjects.isEmpty {
            stopTimer()
        } else {
            restartTimerIfNeeded()
        }
    }

    private func startIfNeeded() {
        guard timer == nil, !banners.allObjects.isEmpty else { return }

        let t = DispatchSource.makeTimerSource(queue: .main)
        let interval = DispatchTimeInterval.milliseconds(Int(effectiveInterval * 1_000))
        t.schedule(deadline: .now() + interval, repeating: interval, leeway: .milliseconds(50))

        t.setEventHandler { [weak self] in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }

        t.resume()
        timer = t
    }

    private var effectiveInterval: TimeInterval {
        // Keep the timer interval finite and away from a busy loop.
        // Mantiene el intervalo finito y evita un bucle de temporizador demasiado intenso.
        // 保证计时间隔为有限值，避免形成高频空转。
        let candidate = autoScrollInterval.isFinite ? autoScrollInterval : 2
        let bannerInterval = banners.allObjects
            .filter(\.canScheduleAutoScroll)
            .map(\.autoScrollSchedulingInterval)
            .min() ?? candidate
        return min(max(min(candidate, bannerInterval), 0.1), 86_400)
    }

    private func restartTimerIfNeeded() {
        guard timer != nil else { return }
        stopTimer()
        startIfNeeded()
    }

    private func stopTimer() {
        timer?.cancel()
        timer = nil
    }

    private func tick() {
        let activeBanners = banners.allObjects
        guard !activeBanners.isEmpty else {
            stopTimer()
            return
        }
        for banner in activeBanners {
            banner.autoScrollTick()
        }
    }
}

public class PTBannerConfiguration:NSObject {
    public var playButtonImage:UIImage = "▶️".emojiToImage(emojiFont: .appfont(size: 44))
    public var pauseButtonImage:UIImage = "⏬️".emojiToImage(emojiFont: .appfont(size: 44))
    /// 设置行数
    public var numberOfLines: Int = 0
    /// 标题的左间距
    public var titleLeading: CGFloat = 15
    /// title & page control spacing
    public var titleNPageControlSpacing: CGFloat = 4
    /// 背景颜色
    public var titleBackgroundColor: UIColor = UIColor.black.withAlphaComponent(0.3)
    /// pagecontrol的底部间距
    public var pageControlBottom: CGFloat = 5
    public var pageControlTintColor: UIColor = UIColor.lightGray
    /// 选中颜色
    public var pageControlCurrentPageColor: UIColor = UIColor.white
    ///  圆角(.fill,.snake)
    public var fillPageControlIndicatorRadius: CGFloat = 4
    /// 选中颜色(.pill,.snake)
    public var customPageControlInActiveTintColor: UIColor = UIColor(white: 1, alpha: 0.3)
    /// 普通图片(.system)
    public var pageControlActiveImage: UIImage? = nil
    /// 选中图片(.system)
    public var pageControlInActiveImage: UIImage? = nil
    public var dotSpacing:CGFloat = 8
    /// 自定义Pagecontrol风格(.fill,.pill,.snake)
    public var customPageControlStyle: PageControlStyle = .system
    /// 自定义Pagecontrol普通颜色
    public var customPageControlTintColor: UIColor = UIColor.white
    /// 自定义Pagecontrol点阵边距
    public var customPageControlIndicatorPadding: CGFloat = 8
    /// pagecontrol的展示方位(左,中,右)
    public var pageControlPosition: PageControlPosition = .center
    public var scrollDirection: UICollectionView.ScrollDirection? = .horizontal
    public var autoScroll = true
    public var infiniteLoop = true
    public var autoPlayMedia: Bool = false
    /// English: An optional per-banner interval; nil inherits the shared scheduler interval.
    /// Español: Un intervalo opcional por banner; nil hereda el intervalo del programador compartido.
    /// 中文：可选的单个 Banner 轮播间隔；nil 时继承共享调度器间隔。
    public var autoScrollInterval: TimeInterval?
    /// English: Image used while a media item is unavailable or still loading.
    /// Español: Imagen mostrada mientras el contenido multimedia no está disponible o sigue cargando.
    /// 中文：媒体不可用或仍在加载时显示的占位图。
    public var placeholderImage: UIImage?
    /// English: Optional native arrow controls for legacy arrow-based banners.
    /// Español: Controles de flecha nativos opcionales para banners heredados con flechas.
    /// 中文：为旧箭头轮播提供的可选原生箭头控件。
    public var showsNavigationButtons = false
    public var previousButtonImage: UIImage?
    public var nextButtonImage: UIImage?
    /// English: Legacy remote-arrow loading options retained for compatibility.
    /// Español: Opciones heredadas de carga de flechas remotas conservadas por compatibilidad.
    /// 中文：为兼容旧版远程箭头资源而保留的加载配置。
    public var iCloudDocumentName = ""
    public var loadingProgressWidth: CGFloat = 1.5
    public var loadingProgressColor: DynamicColor = .purple
    /// English: Optional background image for title-only banners.
    /// Español: Imagen de fondo opcional para banners que solo contienen texto.
    /// 中文：纯文本 Banner 使用的可选背景图。
    public var backgroundImage: UIImage?
    public var showPlayButton = true
    public var collectionViewBackgroundColor: UIColor = .clear
    /// pagecontrol的左右间距
    public var pageControlLeadingOrTrialingContact: CGFloat = 28
}

@MainActor
public class PTBannerView: UIView {

    public var bannerModel: [PTBannerModel] = [] {
        didSet {
            reloadBanner()
        }
    }
    public var didSelectIndex:PTCycleIndexClosure? = nil
    public var scrollViewDidScrollClosure: PTScrollViewDidScrollClosure?
    public var scrollFromClosure: PTCycleIndexClosure?
    public var scrollToClosure: PTCycleIndexClosure?
    public var playEndCallback: PTActionTask?
        
    private var isUserDragging = false
    private var isDecelerating = false
    
    internal var viewConfig:PTBannerConfiguration = PTBannerConfiguration()
    
    // MARK: CustomPageControl
    internal var pageControlHeight: CGFloat = 0
                
    // MARK: - Private
    private var totalItemsCount = 0
    private var resumeTask: Task<Void, Never>?
    private var lastAutoScrollDate: Date?
    private var lastReportedPage = -1
    private var lastLayoutSize: CGSize = .zero
    private var reloadGeneration: UInt = 0
    private var navigationButtonsInstalled = false
    private var navigationButtonImageGeneration: UInt = 0
    private var appliedNavigationButtonImageGeneration: UInt = 0
    private var navigationButtonSources: (previous: Any?, next: Any?) = (nil, nil)
    private var navigationButtonFrames: [CGRect]?
    private var appliedNavigationButtonFrames: [CGRect]?
    
    fileprivate lazy var customPageControl: UIView = {
        return UIView()
    }()

    private lazy var previousButton: UIButton = {
        let button = UIButton(type: .system)
        button.addActionHandlers { [weak self] _ in
            self?.scrollToPrevious()
        }
        return button
    }()

    private lazy var nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.addActionHandlers { [weak self] _ in
            self?.scrollNext()
        }
        return button
    }()
    
    private lazy var layout: UICollectionViewFlowLayout = {
        let l = UICollectionViewFlowLayout()
        l.scrollDirection = viewConfig.scrollDirection ?? .horizontal
        l.minimumLineSpacing = 0
        return l
    }()
    
    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.isPagingEnabled = true
        cv.showsHorizontalScrollIndicator = false
        cv.showsVerticalScrollIndicator = false
        cv.delegate = self
        cv.dataSource = self
        cv.register(PTBannerCell.self, forCellWithReuseIdentifier: PTBannerCell.ID)
        return cv
    }()
    
    private lazy var titleBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = viewConfig.titleBackgroundColor
        return view
    }()
    
    private lazy var descTitleView:UILabel = {
        let view = UILabel()
        view.numberOfLines = viewConfig.numberOfLines
        return view
    }()

    private func setupViewHierarchy() {
        addSubviews([collectionView,titleBackgroundView])
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        updatePageControlHeight()
        titleBackgroundView.snp.makeConstraints { make in
            make.height.equalTo(pageControlHeight + viewConfig.pageControlBottom * 2)
            make.bottom.left.right.equalToSuperview()
        }
        collectionView.backgroundColor = viewConfig.collectionViewBackgroundColor
        setupNavigationButtonsIfNeeded()
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupViewHierarchy()
    }

    public init(viewConfig:PTBannerConfiguration = PTBannerConfiguration()) {
        self.viewConfig = viewConfig
        super.init(frame: .zero)
        setupViewHierarchy()
    }

    /// English: Exposes the canonical configuration to the compatibility adapter without exposing private state.
    /// Español: Expone la configuración canónica al adaptador de compatibilidad sin exponer el estado privado.
    /// 中文：向兼容适配器提供统一配置，但不暴露私有状态。
    internal var bannerConfiguration: PTBannerConfiguration {
        viewConfig
    }

    /// English: Applies a complete configuration and refreshes only the affected UI layers.
    /// Español: Aplica una configuración completa y actualiza solo las capas de UI afectadas.
    /// 中文：应用完整配置，并只刷新受影响的 UI 层。
    internal func applyBannerConfiguration(_ configuration: PTBannerConfiguration) {
        viewConfig = configuration
        refreshBannerConfiguration()
        reloadBanner()
    }

    internal func refreshBannerConfiguration() {
        updatePageControlHeight()
        layout.scrollDirection = effectiveScrollDirection
        titleBackgroundView.backgroundColor = viewConfig.titleBackgroundColor
        descTitleView.numberOfLines = viewConfig.numberOfLines
        collectionView.backgroundColor = viewConfig.collectionViewBackgroundColor
        titleBackgroundView.snp.updateConstraints { make in
            make.height.equalTo(pageControlHeight + viewConfig.pageControlBottom * 2)
        }
        setupNavigationButtonsIfNeeded()
        if !bannerModel.isEmpty {
            setupPageControl()
        }
    }

    /// English: Applies legacy button sources without exposing dynamic values in the canonical public configuration.
    /// Español: Aplica fuentes heredadas de botones sin exponer valores dinámicos en la configuración pública canónica.
    /// 中文：应用旧版按钮资源，但不把动态值暴露到统一的公开配置中。
    internal func setNavigationButtonSources(previous: Any?, next: Any?) {
        navigationButtonSources = (previous, next)
        navigationButtonImageGeneration &+= 1
        updateNavigationButtonFrames()
    }

    /// English: Keeps legacy arrow frames while using constraints for the canonical button hierarchy.
    /// Español: Conserva los marcos heredados de las flechas y usa restricciones en la jerarquía canónica.
    /// 中文：保留旧版箭头 frame，同时在统一按钮层级中使用约束。
    internal func setNavigationButtonFrames(_ frames: [CGRect]?) {
        navigationButtonFrames = frames
        appliedNavigationButtonFrames = nil
        updateNavigationButtonConstraintsIfNeeded()
    }
        
    public override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            if canScheduleAutoScroll {
                PTBannerScheduler.shared.add(self)
            } else {
                PTBannerScheduler.shared.remove(self)
            }
        } else {
            PTBannerScheduler.shared.remove(self)
            resumeTask?.cancel()
            resumeTask = nil
            PTBannerPlayerManager.shared.stopIfContainerBelongs(to: self)
        }
    }
    
    required public init?(coder: NSCoder) {
        self.viewConfig = PTBannerConfiguration()
        super.init(coder: coder)
        setupViewHierarchy()
    }

    deinit {
        resumeTask?.cancel()
    }

    fileprivate var canScheduleAutoScroll: Bool {
        viewConfig.autoScroll && bannerModel.count > 1
    }

    fileprivate var autoScrollSchedulingInterval: TimeInterval {
        let interval = viewConfig.autoScrollInterval ?? PTBannerScheduler.shared.autoScrollInterval
        guard interval.isFinite else { return 2 }
        return max(interval, 0.1)
    }

    private var effectiveScrollDirection: UICollectionView.ScrollDirection {
        viewConfig.scrollDirection ?? .horizontal
    }

    private var currentPageExtent: CGFloat {
        switch effectiveScrollDirection {
        case .vertical:
            return collectionView.bounds.height
        default:
            return collectionView.bounds.width
        }
    }

    private var pageScrollPosition: UICollectionView.ScrollPosition {
        switch effectiveScrollDirection {
        case .vertical:
            return .centeredVertically
        default:
            return .centeredHorizontally
        }
    }

    private func updatePageControlHeight() {
        pageControlHeight = viewConfig.customPageControlStyle == .scrolling ? 20 : 10
    }

    private func setupNavigationButtonsIfNeeded() {
        guard !navigationButtonsInstalled else {
            updateNavigationButtonFrames()
            return
        }

        insertSubview(previousButton, aboveSubview: collectionView)
        insertSubview(nextButton, aboveSubview: collectionView)
        navigationButtonsInstalled = true
        updateNavigationButtonConstraintsIfNeeded()
        updateNavigationButtonFrames()
    }

    private func updateNavigationButtonFrames() {
        let previousImage = viewConfig.previousButtonImage ?? (navigationButtonSources.previous as? UIImage)
        let nextImage = viewConfig.nextButtonImage ?? (navigationButtonSources.next as? UIImage)
        let hasDynamicPreviousImage = navigationButtonSources.previous != nil && previousImage == nil
        let hasDynamicNextImage = navigationButtonSources.next != nil && nextImage == nil
        if !hasDynamicPreviousImage || appliedNavigationButtonImageGeneration != navigationButtonImageGeneration {
            previousButton.setImage(previousImage, for: .normal)
        }
        if !hasDynamicNextImage || appliedNavigationButtonImageGeneration != navigationButtonImageGeneration {
            nextButton.setImage(nextImage, for: .normal)
        }
        if appliedNavigationButtonImageGeneration != navigationButtonImageGeneration {
            appliedNavigationButtonImageGeneration = navigationButtonImageGeneration
            previousButton.cancelImageLoad()
            nextButton.cancelImageLoad()
            loadNavigationButtonImage(source: navigationButtonSources.previous,
                                      button: previousButton)
            loadNavigationButtonImage(source: navigationButtonSources.next,
                                      button: nextButton)
        }
        let visible = viewConfig.showsNavigationButtons && bannerModel.count > 1
        previousButton.isHidden = !visible || (previousImage == nil && navigationButtonSources.previous == nil)
        nextButton.isHidden = !visible || (nextImage == nil && navigationButtonSources.next == nil)
    }

    private func updateNavigationButtonConstraintsIfNeeded() {
        guard navigationButtonsInstalled,
              appliedNavigationButtonFrames != navigationButtonFrames else { return }
        appliedNavigationButtonFrames = navigationButtonFrames

        let previousFrame = navigationButtonFrames?.first.flatMap(validNavigationButtonFrame)
        let nextFrame = navigationButtonFrames?.dropFirst().first.flatMap(validNavigationButtonFrame)
        previousButton.snp.remakeConstraints { make in
            if let previousFrame {
                make.leading.equalToSuperview().offset(previousFrame.minX)
                make.top.equalToSuperview().offset(previousFrame.minY)
                make.size.equalTo(previousFrame.size)
            } else {
                make.leading.equalToSuperview().offset(8)
                make.centerY.equalToSuperview()
                make.size.equalTo(CGSize(width: 36, height: 36))
            }
        }
        nextButton.snp.remakeConstraints { make in
            if let nextFrame {
                make.leading.equalToSuperview().offset(nextFrame.minX)
                make.top.equalToSuperview().offset(nextFrame.minY)
                make.size.equalTo(nextFrame.size)
            } else {
                make.trailing.equalToSuperview().inset(8)
                make.centerY.equalToSuperview()
                make.size.equalTo(CGSize(width: 36, height: 36))
            }
        }
    }

    private func validNavigationButtonFrame(_ frame: CGRect) -> CGRect? {
        guard frame.origin.x.isFinite,
              frame.origin.y.isFinite,
              frame.size.width.isFinite,
              frame.size.height.isFinite,
              frame.size.width > 0,
              frame.size.height > 0 else { return nil }
        return frame
    }

    private func loadNavigationButtonImage(source: Any?, button: UIButton) {
        guard let source,
              !(source is UIImage) else { return }
        let generation = navigationButtonImageGeneration
        button.setImage(viewConfig.placeholderImage, for: .normal)
        button.loadImage(contentData: source,
                         iCloudDocumentName: viewConfig.iCloudDocumentName,
                         borderWidth: viewConfig.loadingProgressWidth,
                         borderColor: viewConfig.loadingProgressColor,
                         emptyImage: viewConfig.placeholderImage,
                         loadFinish: { [weak self, weak button] _ in
            guard let self,
                  button != nil,
                  self.navigationButtonImageGeneration == generation else { return }
        })
    }

    public func reloadData() {
        reloadBanner()
    }

    public func startAutoScroll() {
        guard window != nil, canScheduleAutoScroll else { return }
        PTBannerScheduler.shared.add(self)
    }

    public func stopAutoScroll() {
        PTBannerScheduler.shared.remove(self)
    }

    public func setupTimer() {
        startAutoScroll()
    }

    public func invalidateTimer() {
        stopAutoScroll()
    }

    public func currentIndex() -> NSInteger {
        guard let index = currentVirtualIndex() else { return 0 }
        return realIndex(index)
    }

    public func scrollToPage(index: Int, animated: Bool = true) {
        guard bannerModel.indices.contains(index), totalItemsCount > 0 else { return }
        let current = currentVirtualIndex() ?? 0
        let target: Int
        if viewConfig.infiniteLoop {
            let currentReal = realIndex(current)
            let candidate = current + (index - currentReal)
            if candidate >= 0, candidate < totalItemsCount {
                target = candidate
            } else {
                let middleBase = totalItemsCount / 2
                target = middleBase - (middleBase % bannerModel.count) + index
            }
        } else {
            target = index
        }
        collectionView.scrollToItem(at: IndexPath(item: target, section: 0),
                                     at: pageScrollPosition,
                                     animated: animated)
    }

    public func scrollByDirection(_ gestureRecognizer: UITapGestureRecognizer) {
        guard gestureRecognizer.view?.tag != nil else { return }
        PTBannerScheduler.shared.remove(self)
        if gestureRecognizer.view?.tag == 0 {
            scrollToPrevious()
        } else {
            scrollNext()
        }
    }
    
    private func resumeAfterScroll() {
        isUserDragging = false
        
        if viewConfig.autoPlayMedia {
            // 播放当前可见视频
            playVisibleVideo()
        }
        if canScheduleAutoScroll {
            PTBannerScheduler.shared.add(self)
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        let sizeChanged = lastLayoutSize != bounds.size
        lastLayoutSize = bounds.size
        layout.scrollDirection = effectiveScrollDirection
        layout.itemSize = bounds.size
        if sizeChanged {
            bannerModel.forEach { $0.cachedDescHeight = nil }
            layout.invalidateLayout()
            if viewConfig.infiniteLoop {
                scrollToMiddleIfNeeded(animated: false)
            }
            if let index = currentVirtualIndex() {
                setDescViewHeight(index: realIndex(index))
            }
        }
        updateNavigationButtonFrames()
    }
    
    func setDescViewHeight(index:Int) {
        guard bannerModel.indices.contains(index) else {
            updateTitleHeight(pageControlHeight + viewConfig.pageControlBottom * 2)
            return
        }

        var descTotalHeight:CGFloat = 0
        let cellModel = bannerModel[index]
        if let cached = cellModel.cachedDescHeight {
            updateTitleHeight(cached)
            return
        }

        let titleMaxWidth = max(0, bounds.size.width - self.viewConfig.titleLeading * 2)
        if let attModel = cellModel.att {
            descTotalHeight = attModel.value.sizeOfAttributedString(width: titleMaxWidth).height
        } else {
            if !cellModel.title.stringIsEmpty() || !cellModel.desc.stringIsEmpty() {
                let titleHeight = UIView.sizeFor(string: cellModel.title, font: cellModel.titleFont,lineSpacing: cellModel.titleLineSpacing, width: titleMaxWidth).height
                let descHeight = UIView.sizeFor(string: cellModel.desc, font: cellModel.descFont,lineSpacing: cellModel.titleLineSpacing,width: titleMaxWidth).height
                descTotalHeight = titleHeight + descHeight
            }
        }
        
        let baseHeight = self.pageControlHeight + self.viewConfig.pageControlBottom * 2 + descTotalHeight + self.viewConfig.titleNPageControlSpacing
        bannerModel[index].cachedDescHeight = baseHeight
        updateTitleHeight(baseHeight)
    }

    func setDescView(index:Int) {
        guard bannerModel.indices.contains(index) else {
            descTitleView.attributed.text = nil
            descTitleView.text = nil
            descTitleView.isHidden = true
            return
        }

        let cellModel = bannerModel[index]

        if let attModel = cellModel.att {
            descTitleView.attributed.text = attModel
            descTitleView.isHidden = false
        } else {
            if !cellModel.title.stringIsEmpty() || !cellModel.desc.stringIsEmpty() {
                if !cellModel.title.stringIsEmpty(),!cellModel.desc.stringIsEmpty() {
                    let att:ASAttributedString = """
                    \(wrap: .embedding("""
                    \(cellModel.title,.foreground(cellModel.titleColor),.font(cellModel.titleFont))
                    \(cellModel.desc,.foreground(cellModel.descColor),.font(cellModel.descFont))
                    """),.paragraph(.alignment(.left),.lineSpacing(cellModel.titleLineSpacing)))
                    """
                    descTitleView.attributed.text = att
                } else if cellModel.title.stringIsEmpty(),!cellModel.desc.stringIsEmpty() {
                    let att:ASAttributedString = """
                    \(wrap: .embedding("""
                    \(cellModel.desc,.foreground(cellModel.descColor),.font(cellModel.descFont))
                    """),.paragraph(.alignment(.left),.lineSpacing(cellModel.titleLineSpacing)))
                    """
                    descTitleView.attributed.text = att
                } else if !cellModel.title.stringIsEmpty(),cellModel.desc.stringIsEmpty() {
                    let att:ASAttributedString = """
                    \(wrap: .embedding("""
                    \(cellModel.title,.foreground(cellModel.titleColor),.font(cellModel.titleFont))
                    """),.paragraph(.alignment(.left),.lineSpacing(cellModel.titleLineSpacing)))
                    """
                    descTitleView.attributed.text = att
                } else {
                    let att:ASAttributedString = """
                    \(wrap: .embedding("""
                    \("",.foreground(cellModel.titleColor),.font(cellModel.titleFont))
                    """),.paragraph(.alignment(.left),.lineSpacing(cellModel.titleLineSpacing)))
                    """
                    descTitleView.attributed.text = att
                }
                descTitleView.isHidden = false
            } else {
                descTitleView.attributed.text = nil
                descTitleView.text = nil
                descTitleView.isHidden = true
            }
        }
    }
    
    func autoScrollTick() {
        guard viewConfig.autoScroll else { return }
        guard bannerModel.count > 1 else { return }
        guard !isUserDragging && !isDecelerating else { return }

        let now = Date()
        if let lastAutoScrollDate,
           now.timeIntervalSince(lastAutoScrollDate) < autoScrollSchedulingInterval {
            return
        }
        lastAutoScrollDate = now

        scrollNext()
    }
    
    private func updateTitleHeight(_ descHeight: CGFloat) {
        let safeHeight = descHeight.isFinite ? max(0, descHeight) : pageControlHeight + viewConfig.pageControlBottom * 2

        titleBackgroundView.snp.updateConstraints {
            $0.height.equalTo(safeHeight)
        }
    }
}

extension PTBannerView: UICollectionViewDataSource, UICollectionViewDelegate {

    public func collectionView(_ cv: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return totalItemsCount
    }

    public func collectionView(_ cv: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = cv.dequeueReusableCell(withReuseIdentifier: PTBannerCell.ID, for: indexPath) as? PTBannerCell,
              bannerModel.indices.contains(realIndex(indexPath.item)) else {
            return UICollectionViewCell()
        }

        let item = bannerModel[realIndex(indexPath.item)]
        cell.configure(item,
                       placeholder: viewConfig.backgroundImage ?? viewConfig.placeholderImage,
                       showPlayButton: viewConfig.showPlayButton)
        cell.playButton.setImage(viewConfig.playButtonImage, for: .normal)
        cell.playButton.setImage(viewConfig.pauseButtonImage, for: .selected)
        cell.playAction = { [weak self, weak cell] in
            guard let self, let cell else { return }
            if cell.playButton.isSelected {
                PTBannerScheduler.shared.add(self)
                PTBannerPlayerManager.shared.pause()
            } else {
                PTBannerScheduler.shared.remove(self)
                self.playVisibleVideo()
            }
        }
        return cell
    }

    public func collectionView(_ cv: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        didSelectIndex?(realIndex(indexPath.item))
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isUserDragging = true
        scrollFromClosure?(currentIndex())
        guard let index = currentVirtualIndex(),let cell = collectionView.cellForItem(at: IndexPath(row: index, section: 0)) as? PTBannerCell else {
            // 暂停视频（⚠️ 不要 stop！）
            PTBannerPlayerManager.shared.pause()
            return
        }
        if cell.playButton.isSelected {
            cell.playButton.isSelected = false
        }
        // 暂停视频（⚠️ 不要 stop！）
        PTBannerPlayerManager.shared.pause()
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {

        if !decelerate {
            // 没有减速，直接恢复
            resumeAfterScroll()
            scrollToClosure?(currentIndex())
        } else {
            isDecelerating = true
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        isDecelerating = false
        resumeAfterScroll()
        scrollToClosure?(currentIndex())
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if !isUserDragging {
            if viewConfig.autoPlayMedia {
                playVisibleVideo()
            }
        }
        if canScheduleAutoScroll {
            PTBannerScheduler.shared.add(self)
        }
        scrollToClosure?(currentIndex())
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updatePageControl()
        let index = currentIndex()
        let extent = currentPageExtent
        let offset = effectiveScrollDirection == .vertical ? scrollView.contentOffset.y : scrollView.contentOffset.x
        let fraction = extent > 0 && offset.isFinite ? max(0, min(1, (offset / extent) - floor(offset / extent))) : 0
        scrollViewDidScrollClosure?(index, fraction)
    }
}

extension PTBannerView {
    func reloadBanner() {
        resumeTask?.cancel()
        resumeTask = nil
        layoutIfNeeded()
        reloadGeneration &+= 1
        let generation = reloadGeneration
        self.totalItemsCount = viewConfig.infiniteLoop ? self.bannerModel.count * 100 : self.bannerModel.count
        lastReportedPage = -1
        lastAutoScrollDate = nil
        updateNavigationButtonFrames()
        if bannerModel.isEmpty {
            collectionView.reloadData()
            customPageControl.removeFromSuperview()
            descTitleView.removeFromSuperview()
            customPageControl.isHidden = true
            descTitleView.attributed.text = nil
            descTitleView.text = nil
            updateTitleHeight(pageControlHeight + viewConfig.pageControlBottom * 2)
            PTBannerPlayerManager.shared.stopIfContainerBelongs(to: self)
            PTBannerScheduler.shared.remove(self)
            return
        }
        collectionView.reloadData()
        collectionView.layoutIfNeeded()

        if window != nil, canScheduleAutoScroll {
            PTBannerScheduler.shared.add(self)
        } else {
            PTBannerScheduler.shared.remove(self)
        }

        // English: Defer post-reload work until UIKit has installed the new cells and ignore stale reloads.
        // Español: Posponemos el trabajo posterior hasta que UIKit instale las celdas nuevas e ignoramos recargas obsoletas.
        // 中文：等 UIKit 完成新 Cell 刷新后再处理后续工作，并忽略过期的刷新任务。
        Task { @MainActor [weak self] in
            guard let self, self.reloadGeneration == generation else { return }
            self.scrollToMiddleIfNeeded(animated: false)
            self.setupPageControl()
            let index = self.realIndex(self.currentVirtualIndex() ?? 0)
            self.setDescViewHeight(index: index)
            self.setDescView(index: index)
            if self.viewConfig.autoPlayMedia {
                self.playVisibleVideo()
            }
        }
    }
}

extension PTBannerView {
    private func realIndex(_ index: Int) -> Int {
        guard bannerModel.count > 0 else { return 0 }
        return index % bannerModel.count
    }
    
    // MARK: - Infinite
    private func scrollToMiddleIfNeeded(animated: Bool) {
        guard viewConfig.infiniteLoop, totalItemsCount > 0 else { return }
        guard bannerModel.count > 0 else { return }
        let middleBase = totalItemsCount / 2
        let target = middleBase - (middleBase % bannerModel.count)
        collectionView.scrollToItem(at: IndexPath(item: target, section: 0),
                                     at: pageScrollPosition,
                                     animated: animated)
    }
}

extension PTBannerView {

    private func scrollToPrevious() {
        guard bannerModel.count > 1,
              let index = currentVirtualIndex() else { return }
        let previous = index - 1
        if previous >= 0 {
            collectionView.scrollToItem(at: IndexPath(item: previous, section: 0),
                                         at: pageScrollPosition,
                                         animated: true)
        } else if viewConfig.infiniteLoop {
            scrollToMiddleIfNeeded(animated: false)
            guard let middle = currentVirtualIndex(), middle > 0 else { return }
            collectionView.scrollToItem(at: IndexPath(item: middle - 1, section: 0),
                                         at: pageScrollPosition,
                                         animated: true)
        }
    }

    private func scrollNext() {
        guard bannerModel.count > 1,
              let index = currentVirtualIndex() else { return }
        let next = index + 1
        
        // 🛡️ 越界保护检查
        if next >= totalItemsCount {
            if viewConfig.infiniteLoop {
                // 1. 获取当前展示的真实数据索引 (比如 0, 1, 2)
                let realIdx = realIndex(index)
                
                // 2. 计算出靠近 CollectionView 中间段的起始位置
                let middleBase = totalItemsCount / 2
                let resetIndex = middleBase - (middleBase % bannerModel.count) + realIdx
                
                // 3. 无动画静默跳回中间位置 (用户视觉上无感知)
                collectionView.scrollToItem(at: IndexPath(item: resetIndex, section: 0),
                                             at: pageScrollPosition,
                                             animated: false)
                
                // 4. 紧接着带动画滚动到下一页
                let adjustedNext = resetIndex + 1
                if adjustedNext < totalItemsCount { // 确保重置后加 1 不会越界（理论上肯定不会）
                    collectionView.scrollToItem(at: IndexPath(item: adjustedNext, section: 0),
                                                 at: pageScrollPosition,
                                                 animated: true)
                }
            } else {
                // 非无限循环模式：已经到底了，移除定时器停止滚动
                PTBannerScheduler.shared.remove(self)
            }
            return
        }

        // 正常情况：带动画滚向下一页
        guard next < totalItemsCount else { return }
        collectionView.scrollToItem(at: IndexPath(item: next, section: 0),
                                     at: pageScrollPosition,
                                     animated: true)
    }

    private func currentVirtualIndex() -> Int? {
        let extent = currentPageExtent
        guard extent.isFinite, extent > 0 else { return nil }
        let offset: CGFloat
        switch effectiveScrollDirection {
        case .vertical:
            offset = collectionView.contentOffset.y
        default:
            offset = collectionView.contentOffset.x
        }
        guard offset.isFinite else { return nil }
        return max(0, Int(round(offset / extent)))
    }
}

extension PTBannerView {

    func playVisibleVideo() {
        guard let indexPath = collectionView.indexPathsForVisibleItems.sorted().first,
              let cell = collectionView.cellForItem(at: indexPath) as? PTBannerCell else { return }

        guard let url = cell.videoURL else {
            PTBannerPlayerManager.shared.stop()
            return
        }

        PTBannerPlayerManager.shared.playEndCallback = playEndCallback
        PTBannerPlayerManager.shared.play(url: url, in: cell.playerContainer)
    }

    public func playCurrentCellVideo(playCallback: PTBoolTask? = nil) {
        let before = PTBannerPlayerManager.shared.player != nil
        playVisibleVideo()
        playCallback?(PTBannerPlayerManager.shared.player != nil && !before)
    }

    public func pipStar(floatingCallback: @escaping ((AVPlayerLayer?) -> Void)) {
        PTBannerPlayerManager.shared.startPiP()
        floatingCallback(PTBannerPlayerManager.shared.playerLayer)
    }
}

extension PTBannerView {
    func setupPageControl() {
        
        // ✨ 新增：移除旧的视图，防止重复叠加
        customPageControl.removeFromSuperview()
        descTitleView.removeFromSuperview()

        switch self.viewConfig.customPageControlStyle {
        case .none:
            customPageControl = UIView()
            titleBackgroundView.addSubview(customPageControl)
            customPageControl.isHidden = true
        case .system:
            let control = UIPageControl()
            control.pageIndicatorTintColor = self.viewConfig.pageControlTintColor
            control.currentPageIndicatorTintColor = self.viewConfig.pageControlCurrentPageColor
            control.numberOfPages = bannerModel.count
            control.addPageControlAction(handler: { [weak self] sender in
                guard let self = self else { return }
                self.pageControlTap(index: sender.currentPage)
            })
            control.backgroundColor = .clear
            customPageControl = control
            titleBackgroundView.addSubview(customPageControl)
            customPageControl.isHidden = false
        case .fill:
            let control = PTFilledPageControl()
            control.tintColor = self.viewConfig.customPageControlTintColor
            control.indicatorPadding = self.viewConfig.customPageControlIndicatorPadding
            control.indicatorRadius = self.viewConfig.fillPageControlIndicatorRadius
            control.pageCount = bannerModel.count
            control.addPageControlAction(handler: { [weak self] sender in
                guard let self = self else { return }
                self.pageControlTap(index: sender.currentPage)
            })
            control.backgroundColor = .clear
            customPageControl = control
            titleBackgroundView.addSubview(customPageControl)
            customPageControl.isHidden = false
        case .pill:
            let control = PTPillPageControl()
            control.indicatorPadding = self.viewConfig.customPageControlIndicatorPadding
            control.activeTint = self.viewConfig.customPageControlTintColor
            control.inactiveTint = self.viewConfig.customPageControlInActiveTintColor
            control.pageCount = bannerModel.count
            control.addPageControlAction(handler: { [weak self] sender in
                guard let self = self else { return }
                self.pageControlTap(index: sender.currentPage)
            })
            control.backgroundColor = .clear
            customPageControl = control
            titleBackgroundView.addSubview(customPageControl)
            customPageControl.isHidden = false
        case .snake:
            let control = PTSnakePageControl()
            control.activeTint = self.viewConfig.customPageControlTintColor
            control.indicatorPadding = self.viewConfig.customPageControlIndicatorPadding
            control.indicatorRadius = self.viewConfig.fillPageControlIndicatorRadius
            control.inactiveTint = self.viewConfig.customPageControlInActiveTintColor
            control.pageCount = bannerModel.count
            control.addPageControlAction(handler: { [weak self] sender in
                guard let self = self else { return }
                self.pageControlTap(index: sender.currentPage)
            })
            control.backgroundColor = .clear
            customPageControl = control
            titleBackgroundView.addSubview(customPageControl)
            customPageControl.isHidden = false
        case .image:
            let control = PTImagePageControl()
            if let activeImage = self.viewConfig.pageControlActiveImage {
                control.pageImage = activeImage
            }
            if let inActiveImage = self.viewConfig.pageControlInActiveImage {
                control.currentPageImage = inActiveImage
            }
            control.indicatorPadding = self.viewConfig.dotSpacing
            control.pageCount = bannerModel.count
            control.addPageControlAction(handler: { [weak self] sender in
                guard let self = self else { return }
                self.pageControlTap(index: sender.currentPage)
            })
            control.backgroundColor = .clear
            customPageControl = control
            titleBackgroundView.addSubview(customPageControl)
            customPageControl.isHidden = false
        case .scrolling:
            let control = PTScrollingPageControl()
            control.activeTint = self.viewConfig.customPageControlTintColor
            control.inactiveTint = self.viewConfig.customPageControlInActiveTintColor
            control.indicatorPadding = self.viewConfig.customPageControlIndicatorPadding
            control.pageCount = bannerModel.count
            control.addPageControlAction(handler: { [weak self] sender in
                guard let self = self else { return }
                self.pageControlTap(index: sender.currentPage)
            })
            control.backgroundColor = .clear
            customPageControl = control
            titleBackgroundView.addSubview(customPageControl)
            customPageControl.isHidden = false
        }

        customPageControl.isHidden = bannerModel.count <= 1 || viewConfig.customPageControlStyle == .none
        
        let trialingContact = viewConfig.pageControlLeadingOrTrialingContact * 0.5

        switch self.viewConfig.customPageControlStyle {
        case .none,.system,.image:
            if let pageControl = self.customPageControl as? UIPageControl {
                let pointSize = pageControl.size(forNumberOfPages: self.bannerModel.count)
                pageControl.snp.makeConstraints { make in
                    make.height.equalTo(self.pageControlHeight)
                    make.bottom.equalToSuperview().inset(self.viewConfig.pageControlBottom)
                    switch self.viewConfig.pageControlPosition {
                    case .center:
                        make.left.right.equalToSuperview().inset(trialingContact)
                    case .left:
                        make.width.equalTo(pointSize.width)
                        make.left.equalToSuperview().inset(trialingContact)
                    case .right:
                        make.width.equalTo(pointSize.width)
                        make.right.equalToSuperview().inset(trialingContact)
                    default:
                        break
                    }
                }
            } else {
                self.customPageControl.snp.makeConstraints { make in
                    make.height.equalTo(self.pageControlHeight)
                    make.bottom.equalToSuperview().inset(self.viewConfig.pageControlBottom)
                    switch self.viewConfig.pageControlPosition {
                    case .left:
                        make.left.equalToSuperview().inset(trialingContact)
                    case.right:
                        make.right.equalToSuperview().inset(trialingContact)
                    default:
                        make.left.right.equalToSuperview().inset(trialingContact)
                    }
                }
            }
        default:
            self.customPageControl.snp.makeConstraints { make in
                make.height.equalTo(self.pageControlHeight)
                make.bottom.equalToSuperview().inset(self.viewConfig.pageControlBottom)
                switch self.viewConfig.pageControlPosition {
                case .left:
                    make.left.equalToSuperview().inset(trialingContact)
                case.right:
                    make.right.equalToSuperview().inset(trialingContact)
                default:
                    make.left.right.equalToSuperview().inset(trialingContact)
                }
            }
        }
        
        titleBackgroundView.addSubviews([descTitleView])
        descTitleView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(self.viewConfig.titleLeading)
            make.bottom.equalTo(self.customPageControl.snp.top).offset(-self.viewConfig.titleNPageControlSpacing)
            make.top.equalToSuperview().inset(self.viewConfig.pageControlBottom)
        }
    }
    
    func pageControlTap(index:Int) {
        guard bannerModel.indices.contains(index), bannerModel.count > 1 else { return }
        PTBannerScheduler.shared.remove(self)
        resumeTask?.cancel()

        let current = currentVirtualIndex() ?? 0
        let currentReal = realIndex(current)
        var target = current + (index - currentReal)
        if viewConfig.infiniteLoop {
            let middleBase = totalItemsCount / 2
            if target < 0 || target >= totalItemsCount {
                target = middleBase - (middleBase % bannerModel.count) + index
            }
        } else {
            target = max(0, min(target, totalItemsCount - 1))
        }

        collectionView.scrollToItem(at: IndexPath(item: target, section: 0),
                                     at: pageScrollPosition,
                                     animated: true)
        self.setDescView(index: index)
        self.setDescViewHeight(index: index)
        resumeTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard let self, !Task.isCancelled, self.canScheduleAutoScroll else { return }
            PTBannerScheduler.shared.add(self)
            self.resumeTask = nil
        }
    }

    private func updatePageControl() {
        guard !bannerModel.isEmpty else { return }
        let virtualIndex = currentVirtualIndex() ?? 0
        let page = realIndex(virtualIndex)
        let extent = currentPageExtent
        let offset: CGFloat = effectiveScrollDirection == .vertical
            ? collectionView.contentOffset.y
            : collectionView.contentOffset.x
        let rawPage = extent > 0 && offset.isFinite ? max(0, offset / extent) : CGFloat(virtualIndex)
        let fraction = rawPage - floor(rawPage)
        let realProgress = min(CGFloat(bannerModel.count - 1), CGFloat(page) + max(0, min(1, fraction)))
        if let control = customPageControl as? UIPageControl {
            control.currentPage = page
        }

        if let control = customPageControl as? PTPageProgressControllable {
            control.setProgress(realProgress, animated: false)
        } else if let control = customPageControl as? PTPageControllable {
            control.setCurrentPage(index: page)
        }
        
        guard page != lastReportedPage else { return }
        lastReportedPage = page
        setDescView(index: page)
        setDescViewHeight(index: page)
    }
}
