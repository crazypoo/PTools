//
//  PTBannerView.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 30/3/2026.
//  Copyright © 2026 crazypoo. All rights reserved.
//

import UIKit
import SwifterSwift
import SnapKit
import AttributedString

public final class PTBannerScheduler {

    public static let shared = PTBannerScheduler()
    public var autoScrollInterval: TimeInterval = 2

    private var banners = NSHashTable<PTBannerView>.weakObjects()
    private var timer: DispatchSourceTimer?

    func add(_ banner: PTBannerView) {
        banners.add(banner)
        startIfNeeded()
    }

    func remove(_ banner: PTBannerView) {
        banners.remove(banner)
        
        // ✨ 新增：当没有 banner 存在时，销毁定时器节省资源
        if banners.allObjects.isEmpty {
            timer?.cancel()
            timer = nil
        }
    }

    private func startIfNeeded() {
        guard timer == nil else { return }

        let t = DispatchSource.makeTimerSource(queue: .main)
        t.schedule(deadline: .now() + PTBannerScheduler.shared.autoScrollInterval, repeating: 2)

        t.setEventHandler { [weak self] in
            self?.tick()
        }

        t.resume()
        timer = t
    }

    private func tick() {
        for banner in banners.allObjects {
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
    /// pagecontrol的左右间距
    public var pageControlLeadingOrTrialingContact: CGFloat = 28
}

public class PTBannerView: UIView {
    
    public var bannerModel: [PTBannerModel]! {
        didSet {
            if !bannerModel.isEmpty {
                reloadBanner()
            }
        }
    }
    public var didSelectIndex:PTCycleIndexClosure? = nil
        
    private var isUserDragging = false
    private var isDecelerating = false
    
    fileprivate var viewConfig:PTBannerConfiguration = PTBannerConfiguration()
    
    // MARK: CustomPageControl
    fileprivate var pageControlHeight: CGFloat = 0
                
    // MARK: - Private
    private var totalItemsCount = 0
    private var timer: DispatchSourceTimer?
    
    fileprivate lazy var customPageControl: UIView = {
        return UIView()
    }()
    
    private lazy var layout: UICollectionViewFlowLayout = {
        let l = UICollectionViewFlowLayout()
        l.scrollDirection = .horizontal
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
    
    public init(viewConfig:PTBannerConfiguration = PTBannerConfiguration()) {
        self.viewConfig = viewConfig
        super.init(frame: .zero)
        addSubviews([collectionView,titleBackgroundView])
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        switch self.viewConfig.customPageControlStyle {
        case .none,.system,.image:
            pageControlHeight = 10
        case .scrolling:
            pageControlHeight = 20
        default:
            pageControlHeight = 10
        }

        titleBackgroundView.snp.makeConstraints { make in
            make.height.equalTo(self.pageControlHeight + self.viewConfig.pageControlBottom * 2)
            make.bottom.left.right.equalToSuperview()
        }
    }
        
    public override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            PTBannerScheduler.shared.add(self)
        } else {
            PTBannerScheduler.shared.remove(self)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func resumeAfterScroll() {
        isUserDragging = false
        
        if viewConfig.autoPlayMedia {
            // 播放当前可见视频
            playVisibleVideo()
        }
        PTBannerScheduler.shared.add(self)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        layout.itemSize = bounds.size
        collectionView.frame = bounds
    }
    
    func setDescViewHeight(index:Int) {
        var descTotalHeight:CGFloat = 0
        let cellModel = bannerModel[index]
        if let cached = cellModel.cachedDescHeight {
            updateTitleHeight(cached)
            return
        }

        let titleMaxWidth = bounds.size.width - self.viewConfig.titleLeading * 2
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
        let cellModel = bannerModel[index]

        if let attModel = cellModel.att {
            descTitleView.attributed.text = attModel
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
            }
        }
    }
    
    func autoScrollTick() {
        guard viewConfig.autoScroll else { return }
        guard bannerModel.count > 1 else { return }
        guard !isUserDragging && !isDecelerating else { return }

        scrollNext()
    }
    
    private func updateTitleHeight(_ descHeight: CGFloat) {
        let base = pageControlHeight + viewConfig.pageControlBottom * 2 + descHeight + viewConfig.titleNPageControlSpacing

        titleBackgroundView.snp.updateConstraints {
            $0.height.equalTo(base)
        }
    }
}

extension PTBannerView: UICollectionViewDataSource, UICollectionViewDelegate {

    public func collectionView(_ cv: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return totalItemsCount
    }

    public func collectionView(_ cv: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = cv.dequeueReusableCell(withReuseIdentifier: PTBannerCell.ID, for: indexPath) as! PTBannerCell

        let item = bannerModel[realIndex(indexPath.item)]
        cell.configure(item)
        cell.playButton.setImage(viewConfig.playButtonImage, for: .normal)
        cell.playButton.setImage(viewConfig.pauseButtonImage, for: .selected)
        cell.playButton.addActionHandlers { sender in
            if sender.isSelected {
                PTBannerScheduler.shared.add(self)
                PTBannerPlayerManager.shared.pause()
            } else {
                PTBannerScheduler.shared.remove(self)
                self.playVisibleVideo()
            }
            sender.isSelected.toggle()
        }
        return cell
    }

    public func collectionView(_ cv: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        didSelectIndex?(realIndex(indexPath.item))
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isUserDragging = true
        guard let index = currentIndex(),let cell = collectionView.cellForItem(at: IndexPath(row: index, section: 0)) as? PTBannerCell else {
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
        } else {
            isDecelerating = true
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        isDecelerating = false
        resumeAfterScroll()
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if !isUserDragging {
            if viewConfig.autoPlayMedia {
                playVisibleVideo()
            }
        }
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updatePageControl()
    }
}

extension PTBannerView {
    func reloadBanner() {
        layoutIfNeeded()
        self.totalItemsCount = viewConfig.infiniteLoop ? self.bannerModel.count * 100 : self.bannerModel.count
        self.collectionView.reloadData {
            self.scrollToMiddleIfNeeded()
            self.setupPageControl()
            self.setDescViewHeight(index: self.realIndex(self.currentIndex() ?? 0))
            self.setDescView(index: self.realIndex(self.currentIndex() ?? 0))
        }
    }
}

extension PTBannerView {
    private func realIndex(_ index: Int) -> Int {
        guard bannerModel.count > 0 else { return 0 }
        return index % bannerModel.count
    }
    
    // MARK: - Infinite
    private func scrollToMiddleIfNeeded() {
        guard viewConfig.infiniteLoop, totalItemsCount > 0 else { return }
        let target = totalItemsCount / 2
        collectionView.scrollToItem(at: IndexPath(item: target, section: 0), at: .centeredHorizontally, animated: true)
    }
}

extension PTBannerView {

    private func scrollNext() {
        guard let index = currentIndex() else { return }
        let next = index + 1
        collectionView.scrollToItem(at: IndexPath(item: next, section: 0), at: .centeredHorizontally, animated: true)
    }

    private func currentIndex() -> Int? {
        let page = Int(collectionView.contentOffset.x / collectionView.bounds.width)
        return page
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

        PTBannerPlayerManager.shared.play(url: url, in: cell.playerContainer)
    }
}

extension PTBannerView {
    func setupPageControl() {
        
        // ✨ 新增：移除旧的视图，防止重复叠加
        customPageControl.removeFromSuperview()
        descTitleView.removeFromSuperview()

        if bannerModel.count <= 1 {
            customPageControl.isHidden = true
            return
        }
        
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
            customPageControl = control
            titleBackgroundView.addSubview(customPageControl)
            customPageControl.isHidden = false
        case .fill:
            let control = PTFilledPageControl()
            control.tintColor = self.viewConfig.customPageControlTintColor
            control.indicatorPadding = self.viewConfig.customPageControlIndicatorPadding
            control.indicatorRadius = self.viewConfig.fillPageControlIndicatorRadius
            control.pageCount = bannerModel.count
            customPageControl = control
            titleBackgroundView.addSubview(customPageControl)
            customPageControl.isHidden = false
        case .pill:
            let control = PTPillPageControl()
            control.indicatorPadding = self.viewConfig.customPageControlIndicatorPadding
            control.activeTint = self.viewConfig.customPageControlTintColor
            control.inactiveTint = self.viewConfig.customPageControlInActiveTintColor
            control.pageCount = bannerModel.count
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
            customPageControl = control
            titleBackgroundView.addSubview(customPageControl)
            customPageControl.isHidden = false
        case .image:
            let control = PTImagePageControl()
            control.pageIndicatorTintColor = UIColor.clear
            control.currentPageIndicatorTintColor = UIColor.clear
            if let activeImage = self.viewConfig.pageControlActiveImage {
                control.pageImage = activeImage
            }
            if let inActiveImage = self.viewConfig.pageControlInActiveImage {
                control.currentPageImage = inActiveImage
            }
            control.dotSpacing = self.viewConfig.dotSpacing
            control.numberOfPages = bannerModel.count
            customPageControl = control
            titleBackgroundView.addSubview(customPageControl)
            customPageControl.isHidden = false
        case .scrolling:
            let control = PTScrollingPageControl()
            control.pageCount = bannerModel.count
            customPageControl = control
            titleBackgroundView.addSubview(customPageControl)
            customPageControl.isHidden = false
        }
        
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

    private func updatePageControl() {
        let progress = currentIndex() ?? 0
        let realIndex = realIndex(progress)
        let realProgress = realIndex % bannerModel.count
        if let control = customPageControl as? UIPageControl {
            control.currentPage = realProgress
        }

        // 如果是自定义（snake / pill）
        if let control = customPageControl as? PTPageControllable {
            control.setCurrentPage(index: realProgress)
        }
        
        // ✨ 新增：滑动时实时更新对应的标题内容和容器高度
        setDescView(index: realProgress)
        setDescViewHeight(index: realProgress)
    }
}
