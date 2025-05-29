//
//  PTCycleScrollView.swift
//  PTCycleScrollView
//
//  Created by LvJianfeng on 2016/11/22.
//  Copyright © 2016年 LvJianfeng. All rights reserved.
//

import UIKit
import SnapKit
import Kingfisher
import SwifterSwift
import AVFoundation

/// Style
@objc public enum PageControlStyle:Int {
    case none, system, fill, pill, snake, image, scrolling
}

/// Position
@objc public enum PageControlPosition:Int {
    case center, left, right
}

/// 点击回调
/// - Parameters:
///   - index: 须要展示的index
public typealias PTCycleIndexClosure = (_ index:NSInteger) -> Void
/// 滚动页内偏移量
/// - Parameters:
///   - index: 左边页面
///   - offSet: 偏移量大小
public typealias PTScrollViewDidScrollClosure = (_ index:NSInteger,_ offSet:CGFloat) -> Void

// MARK: 类初始化
extension PTCycleScrollView {
    /// 默认初始化
    /// - Parameters:
    ///   - imageURLPaths: URL Path Array
    ///   - titles: Title Array
    ///   - didSelectItemAtIndex: Closure
    /// - Returns: PTCycleScrollView
    public class func cycleScrollViewCreate(imageURLPaths: Array<Any>? = [], titles:Array<String>? = [], didSelectItemAtIndex: PTCycleIndexClosure? = nil) -> PTCycleScrollView {
        let cycleScrollView: PTCycleScrollView = PTCycleScrollView()
        // Nil
        cycleScrollView.imagePaths = []
        cycleScrollView.titles = []
        
        if let imageURLPathList = imageURLPaths, imageURLPathList.count > 0 {
            cycleScrollView.imagePaths = imageURLPathList
        }
        
        if let titleList = titles, titleList.count > 0 {
            cycleScrollView.titles = titleList
        }
        
        cycleScrollView.didSelectItemAtIndexClosure = didSelectItemAtIndex
        return cycleScrollView
    }
    
    /// 纯文本
    /// - Parameters:
    ///   - backImage: Background Image
    ///   - titles: Title Array
    ///   - didSelectItemAtIndex: Closure
    /// - Returns: PTCycleScrollView
    public class func cycleScrollViewWithTitles(backImage: UIImage? = nil, titles: Array<String>? = [], didSelectItemAtIndex: PTCycleIndexClosure? = nil) -> PTCycleScrollView {
        let cycleScrollView: PTCycleScrollView = PTCycleScrollView()
        // Nil
        cycleScrollView.titles = []
        // Set isOnlyTitle
        cycleScrollView.isOnlyTitle = true
        
        // Titles Data
        if let titleList = titles, titleList.count > 0 {
            cycleScrollView.titles = titleList
        }
        
        cycleScrollView.didSelectItemAtIndexClosure = didSelectItemAtIndex
        return cycleScrollView
    }
    
    /// 支持箭头初始化
    /// - Parameters:
    ///   - arrowLRImages: [LeftImage, RightImage]
    ///   - arrowLRPoint: [LeffImage.CGPoint, RightImage.CGPoint], default nil (center)
    ///   - arrowLRFrame:
    ///   - imageURLPaths: URL Path Array
    ///   - titles: Title Array
    ///   - didSelectItemAtIndex: Closure
    ///   - arrowLRFrame:
    /// - Returns: PTCycleScrollView
    public class func cycleScrollViewWithArrow(arrowLRImages: [Any], arrowLRFrame: [CGRect]? = nil, imageURLPaths: Array<Any>? = [], titles:Array<String>? = [], didSelectItemAtIndex: PTCycleIndexClosure? = nil) -> PTCycleScrollView {
        let cycleScrollView: PTCycleScrollView = PTCycleScrollView()
        // Nil
        cycleScrollView.imagePaths = []
        cycleScrollView.titles = []
        
        // Images
        cycleScrollView.arrowLRIcon = arrowLRImages
        cycleScrollView.arrowLRFrame = arrowLRFrame
        
        // Setup
        cycleScrollView.setupArrowIcon()
        
        if let imageURLPathList = imageURLPaths, imageURLPathList.count > 0 {
            cycleScrollView.imagePaths = imageURLPathList
        }
        
        if let titleList = titles, titleList.count > 0 {
            cycleScrollView.titles = titleList
        }
        
        cycleScrollView.didSelectItemAtIndexClosure = didSelectItemAtIndex
        return cycleScrollView
    }
}

@objcMembers
public class PTCycleScrollView: UIView {
    // MARK: DataSource
    fileprivate var clearSubs:Bool = false
    
    public static var playButtonImage:UIImage = "▶️".emojiToImage(emojiFont: .appfont(size: 44))
    
    /// 图片地址
    public var imagePaths: Array<Any> = [] {
        willSet {
            clearSubs = !imagePaths.elementsEqual(newValue, by: { ($0 as AnyObject).isEqual($1) })
        }
        didSet {
            setTotalItemsMinItems(count: imagePaths.count)
            pageScrollerView.isScrollEnabled = imagePaths.count > 1
            if imagePaths.count > 1 {
                if autoScroll {
                    setupTimer()
                } else {
                    invalidateTimer()
                }
            } else {
                invalidateTimer()
            }
            if clearSubs {
                PTGCDManager.gcdAfter(time: 0.01) { [weak self] in
                    self?.layoutSubviews()
                }
            }
        }
    }
    
    /// 标题
    public var titles: Array<Any> = [] {
        didSet {
            if titles.count > 0 {
                if imagePaths.count == 0 {
                    imagePaths = titles
                }
            }
        }
    }
    
    // MARK: - Closure
    /// 点击后回调
    public var didSelectItemAtIndexClosure : PTCycleIndexClosure? = nil
    /// 滚动页内偏移量
    public var scrollViewDidScrollClosure : PTScrollViewDidScrollClosure? = nil
    /// 从哪儿滚动
    public var scrollFromClosure : PTCycleIndexClosure? = nil
    /// 滚动到哪儿
    public var scrollToClosure : PTCycleIndexClosure? = nil
    
    // MARK: - Config
    
    /// 自动轮播- 默认true
    public var autoScroll: Bool = true {
        didSet {
            invalidateTimer()
            // 如果关闭的无限循环，则不进行计时器的操作，否则每次滚动到最后一张就不在进行了。
            if autoScroll && infiniteLoop {
                setupTimer()
            }
        }
    }
    
    /// 无限循环- 默认true，此属性修改了就不存在轮播的意义了
    public var infiniteLoop: Bool = true {
        didSet {
            if imagePaths.count > 0 {
                let temp = imagePaths
                imagePaths = temp
            }
        }
    }
    
    /// 滚动方向，默认horizontal
    public var scrollDirection: UICollectionView.ScrollDirection? = .horizontal {
        didSet {
            switch scrollDirection {
            case .horizontal:
                position = .centeredHorizontally
            default:
                position = .centeredVertically
            }
        }
    }
    
    /// 滚动间隔时间,默认2秒
    public var autoScrollTimeInterval: Double = 2.0
    
    // MARK: - Style
    /// 背景颜色
    public var collectionViewBackgroundColor: UIColor! = UIColor.clear
        
    // MARK: ImageView
    /// 图片的展示模式
    public var imageViewContentMode: UIView.ContentMode? {
        didSet {
            layoutSubviews()
        }
    }
    
    // MARK: Title
    /// 字体颜色
    public var textColor: UIColor = UIColor.white
    
    /// 设置行数
    public var numberOfLines: NSInteger = 2
    
    /// 标题的左间距
    public var titleLeading: CGFloat = 15
    
    /// 字体
    public var font: UIFont = UIFont.systemFont(ofSize: 15)
    
    /// 背景颜色
    public var titleBackgroundColor: UIColor = UIColor.black.withAlphaComponent(0.3)
    
    // MARK: 箭头标签
    /// Icon - [LeftIcon, RightIcon]
    public var arrowLRIcon: [Any]?
    
    /// Icon Frame - [LeftIconFrame, RightIconFrame]
    public var arrowLRFrame: [CGRect]?
    
    // MARK: PageControl
    /// 未选中颜色
    public var pageControlTintColor: UIColor = UIColor.lightGray {
        didSet {
            // 重新添加
            cleanPageControl()
            layoutSubviews()
        }
    }
    /// 选中颜色
    public var pageControlCurrentPageColor: UIColor = UIColor.white {
        didSet {
            cleanPageControl()
            layoutSubviews()
        }
    }
    
    ///  圆角(.fill,.snake)
    public var fillPageControlIndicatorRadius: CGFloat = 4 {
        didSet {
            cleanPageControl()
            layoutSubviews()
        }
    }
    
    /// 选中颜色(.pill,.snake)
    public var customPageControlInActiveTintColor: UIColor = UIColor(white: 1, alpha: 0.3) {
        didSet {
            cleanPageControl()
            layoutSubviews()
        }
    }
    
    /// 普通图片(.system)
    public var pageControlActiveImage: UIImage? = nil {
        didSet {
            cleanPageControl()
            layoutSubviews()
        }
    }
    
    /// 选中图片(.system)
    public var pageControlInActiveImage: UIImage? = nil {
        didSet {
            cleanPageControl()
            layoutSubviews()
        }
    }
    
    public var dotSpacing:CGFloat = 8 {
        didSet {
            cleanPageControl()
            layoutSubviews()
        }
    }
    
    // MARK: CustomPageControl
    /// 自定义Pagecontrol风格(.fill,.pill,.snake)
    public var customPageControlStyle: PageControlStyle = .system {
        didSet {
            cleanPageControl()
            layoutSubviews()
        }
    }
    
    /// 自定义Pagecontrol普通颜色
    public var customPageControlTintColor: UIColor = UIColor.white {
        didSet {
            cleanPageControl()
            layoutSubviews()
        }
    }
    /// 自定义Pagecontrol点阵边距
    public var customPageControlIndicatorPadding: CGFloat = 8 {
        didSet {
            cleanPageControl()
            layoutSubviews()
        }
    }
    
    /// pagecontrol的展示方位(左,中,右)
    public var pageControlPosition: PageControlPosition = .center {
        didSet {
            cleanPageControl()
            layoutSubviews()
        }
    }
    
    func cleanPageControl() {
        if let control = customPageControl {
            control.removeFromSuperview()
            customPageControl = nil
        }
    }
    
    /// pagecontrol的左右间距
    public var pageControlLeadingOrTrialingContact: CGFloat = 28 {
        didSet {
            layoutSubviews()
        }
    }
    
    /// pagecontrol的底部间距
    public var pageControlBottom: CGFloat = 5 {
        didSet {
            layoutSubviews()
        }
    }
        
    /*
     Loading image
     */
    /// iCloudDocument
    public var iCloudDocument:String = ""
    /// DefaultPlaceholderImage
    public var defaultPlaceholderImage:UIImage = PTAppBaseConfig.share.defaultPlaceholderImage
    /// Loading progress width
    public var loadingProgressWidth:CGFloat = 1.5
    /// Loading progress color
    public var loadingProgressColor:DynamicColor = .purple

    // MARK: - Private
    /// 注意： 由于属性较多，所以请使用style对应的属性，如果没有标明则通用
    /// PageControl
    fileprivate var customPageControl: UIView?

    /// 总数量
    fileprivate var totalItemsCount: NSInteger! = 1
    func setTotalItemsMinItems(@PTClampedProperyWrapper(range:1...(.max)) count:NSInteger) {
        totalItemsCount = count
    }
    
    /// 最大伸展空间(防止出现问题，可外部设置)
    /// 用于反方向滑动的时候，需要知道最大的contentSize
    fileprivate var maxSwipeSize: CGFloat = 0
    
    /// 是否纯文本
    fileprivate var isOnlyTitle: Bool = false
    
    /// 高度
    fileprivate var cellHeight: CGFloat = 56
    fileprivate var pageControlHeight: CGFloat = 0

    /// Collection滚动方向
    fileprivate var position: UICollectionView.ScrollPosition! = .centeredHorizontally
            
    /// 计时器
    fileprivate weak var timer: Timer?

    fileprivate lazy var pageScrollerView:UIScrollView = {
        let view = UIScrollView()
        view.isPagingEnabled = true
        view.showsHorizontalScrollIndicator = false
        view.showsVerticalScrollIndicator = false
        view.delegate = self
        return view
    }()
            
    fileprivate var videoFrameCache = NSCache<NSString, UIImage>()

    deinit {
        invalidateTimer()
    }
    
    /// Init
    /// - Parameter frame: CGRect
    override internal init(frame: CGRect) {
        super.init(frame: frame)
        self.setupMainView()
    }
    
    /// Init
    /// - Parameter aDecoder: NSCoder
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupMainView()
    }
    
    public override func willMove(toSuperview newSuperview: UIView?) {
        if newSuperview == nil {
            invalidateTimer()
        }
    }
    
    public func pipStar(floatingCallback:@escaping ((AVPlayerLayer?)->Void)) {
        guard let cell = viewWithTag(100 + currentIndex()) as? PTCycleScrollViewCell else {
            floatingCallback(nil)
            return
        }
        let imagePath = self.imagePaths[currentIndex()]
        if let videoPath = imagePath as? String, ["mp4", "mov"].contains(videoPath.pathExtension.lowercased()),let player = cell.player {
            if player.rate != 0 {
                floatingCallback(cell.playerLayer)
            } else {
                floatingCallback(nil)
            }
        } else {
            floatingCallback(nil)
        }
    }
}

// MARK: Datas
extension PTCycleScrollView {
    func scrollViewReloadData() {
        invalidateTimer()
        collectionViewSetData()
        if autoScroll {
            setupTimer()
        }
    }
}

// MARK: UI
extension PTCycleScrollView {
    // MARK: 添加UICollectionView
    private func setupMainView() {
        addSubview(pageScrollerView)
        pageScrollerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    // MARK: 添加自定义箭头
    private func setupArrowIcon() {
        PTGCDManager.gcdAfter(time: 0.1) { [weak self] in
            guard let self = self else { return }

            // 验证无限轮播开启
            guard self.infiniteLoop else {
                assertionFailure("当前未开启无限轮播 `infiniteLoop`，请设置后使用此模式。")
                return
            }

            // 验证方向图标资源存在
            guard let arrowIcons = self.arrowLRIcon else {
                assertionFailure("初始化方向图片 `arrowLRIcon` 数据为空。")
                return
            }

            // 默认 Frame 初始化
            if self.arrowLRFrame?.count ?? 0 < 2 {
                let width = self.frame.width * 0.25
                let height = self.frame.height
                self.arrowLRFrame = [
                    CGRect(x: 5, y: 0, width: width, height: height),
                    CGRect(x: self.frame.width - width - 5, y: 0, width: width, height: height)
                ]
            }

            guard let arrowFrames = self.arrowLRFrame, arrowFrames.count >= 2 else {
                assertionFailure("初始化方向图片 `arrowLRFrame` 数据为空或数量不足。")
                return
            }

            // 添加左右箭头图标
            self.addArrowImageView(
                frame: arrowFrames[0],
                image: arrowIcons.first,
                tag: 0,
                contentMode: .left
            )
            self.addArrowImageView(
                frame: arrowFrames[1],
                image: arrowIcons.last,
                tag: 1,
                contentMode: .right
            )
        }
    }

    private func addArrowImageView(frame: CGRect, image: Any?, tag: Int, contentMode: UIView.ContentMode) {
        let imageView = UIImageView(frame: frame)
        imageView.contentMode = contentMode
        imageView.tag = tag
        imageView.isUserInteractionEnabled = true

        if let imageData = image {
            imageView.loadImage(contentData: imageData,iCloudDocumentName: self.iCloudDocument,borderWidth: loadingProgressWidth,borderColor: loadingProgressColor,emptyImage: self.defaultPlaceholderImage)
        } else {
            imageView.image = self.defaultPlaceholderImage
        }

        let tap = UITapGestureRecognizer { [weak self] sender in
            guard let self = self, let gesture = sender as? UITapGestureRecognizer else { return }
            self.scrollByDirection(gesture)
        }
        imageView.addGestureRecognizer(tap)
        self.addSubview(imageView)
    }
    
    // MARK: 添加PageControl
    func setupPageControl() {
        
        if imagePaths.count <= 1 {
            return
        }
        
        if customPageControl == nil {
            switch customPageControlStyle {
            case .none:
                customPageControl = UIView()
                addSubview(customPageControl!)
                customPageControl?.isHidden = true
            case .system:
                let control = UIPageControl()
                control.pageIndicatorTintColor = pageControlTintColor
                control.currentPageIndicatorTintColor = pageControlCurrentPageColor
                control.numberOfPages = imagePaths.count
                customPageControl = control
                addSubview(customPageControl!)
                customPageControl?.isHidden = false
            case .fill:
                let control = PTFilledPageControl()
                control.tintColor = customPageControlTintColor
                control.indicatorPadding = customPageControlIndicatorPadding
                control.indicatorRadius = fillPageControlIndicatorRadius
                control.pageCount = imagePaths.count
                customPageControl = control
                addSubview(customPageControl!)
                customPageControl?.isHidden = false
            case .pill:
                let control = PTPillPageControl()
                control.indicatorPadding = customPageControlIndicatorPadding
                control.activeTint = customPageControlTintColor
                control.inactiveTint = customPageControlInActiveTintColor
                control.pageCount = imagePaths.count
                customPageControl = control
                addSubview(customPageControl!)
                customPageControl?.isHidden = false
            case .snake:
                let control = PTSnakePageControl()
                control.activeTint = customPageControlTintColor
                control.indicatorPadding = customPageControlIndicatorPadding
                control.indicatorRadius = fillPageControlIndicatorRadius
                control.inactiveTint = customPageControlInActiveTintColor
                control.pageCount = imagePaths.count
                customPageControl = control
                addSubview(customPageControl!)
                customPageControl?.isHidden = false
            case .image:
                let control = PTImagePageControl()
                control.pageIndicatorTintColor = UIColor.clear
                control.currentPageIndicatorTintColor = UIColor.clear
                if let activeImage = pageControlActiveImage {
                    control.pageImage = activeImage
                }
                if let inActiveImage = pageControlInActiveImage {
                    control.currentPageImage = inActiveImage
                }
                control.dotSpacing = dotSpacing
                control.numberOfPages = imagePaths.count
                customPageControl = control
                addSubview(customPageControl!)
                customPageControl?.isHidden = false
            case .scrolling:
                let control = PTScrollingPageControl()
                control.pageCount = imagePaths.count
                customPageControl = control
                addSubview(customPageControl!)
                customPageControl?.isHidden = false
            }
            bringSubviewToFront(customPageControl!)
        }
    }
}

// MARK: UIViewHierarchy | LayoutSubviews
extension PTCycleScrollView {
    /// 将要添加到 window 上时
    /// - Parameter newWindow: 新的 window
    /// 添加到window 上时 开启 timer, 从 window 上移除时, 移除 timer
    override open func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        if newWindow != nil {
            if autoScroll && infiniteLoop {
                setupTimer()
            }
        } else {
            invalidateTimer()
        }
    }
    
    // MARK: layoutSubviews
    override open func layoutSubviews() {
        super.layoutSubviews()
        // CollectionView
        // Cell Height
        self.cellHeight = self.frame.height
        
        switch self.customPageControlStyle {
        case .none,.system,.image:
            pageControlHeight = 10
        case .scrolling:
            pageControlHeight = 20
        default:
            pageControlHeight = 10
        }
        
        self.collectionViewSetData()

        // 计算最大扩展区大小
        switch self.scrollDirection {
        case .horizontal:
            self.maxSwipeSize = CGFloat(self.imagePaths.count) * self.frame.width
        default:
            self.maxSwipeSize = CGFloat(self.imagePaths.count) * self.frame.height
        }
        
        let trialingContact = self.pageControlLeadingOrTrialingContact * 0.5

        setupPageControl()
        // Page Frame
        switch self.customPageControlStyle {
        case .none,.system,.image:
            if let pageControl = self.customPageControl as? UIPageControl {
                let pointSize = pageControl.size(forNumberOfPages: self.imagePaths.count)
                pageControl.snp.makeConstraints { make in
                    make.height.equalTo(self.pageControlHeight)
                    make.bottom.equalToSuperview().inset(self.pageControlBottom)
                    switch self.pageControlPosition {
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
            self.customPageControl?.snp.makeConstraints { make in
                make.height.equalTo(self.pageControlHeight)
                make.bottom.equalToSuperview().inset(self.pageControlBottom)
                switch self.pageControlPosition {
                case .left:
                    make.left.equalToSuperview().inset(trialingContact)
                case.right:
                    make.right.equalToSuperview().inset(trialingContact)
                default:
                    make.left.right.equalToSuperview().inset(trialingContact)
                }
            }
        }
    }
    
    func getVideoFrame(for url: String, completion: @escaping (UIImage?) -> Void) {
        if let cachedImage = videoFrameCache.object(forKey: url as NSString) {
            completion(cachedImage)
            return
        }
        
        PTGCDManager.gcdMain {
            UIImage.pt.getVideoFirstImage(videoUrl: url) { image in
                if let image = image {
                    self.videoFrameCache.setObject(image, forKey: url as NSString)
                    completion(image)
                } else {
                    completion(self.defaultPlaceholderImage)
                }
            }
        }
    }
        
    func loadImageWithAny(imagePath:Any,cell:PTCycleScrollViewCell,itemIndex:Int) {
        cell.imageView.loadImage(contentData: imagePath,iCloudDocumentName: self.iCloudDocument,borderWidth: loadingProgressWidth,borderColor: loadingProgressColor,emptyImage: self.defaultPlaceholderImage)
        setBannerAttTitle(cell: cell, itemIndex: itemIndex)
    }
    
    func collectionViewSetData() {
        pageScrollerView.removeSubviews()

        for i in 0..<totalItemsCount {
            let cell = createConfiguredCell(at: i)
            pageScrollerView.addSubview(cell)

            setupCellConstraints(cell: cell, index: i)

            if isOnlyTitle && !titles.isEmpty {
                configureTitleOnly(cell: cell, index: i)
            } else {
                configureImageOrVideo(cell: cell, index: i)
            }
        }

        updateContentSize()
    }
    
    private func createConfiguredCell(at index: Int) -> PTCycleScrollViewCell {
        let cell = PTCycleScrollViewCell()
        cell.pageControlHeight = pageControlHeight
        cell.titleFont = font
        cell.titleLabelTextColor = textColor
        cell.titleBackViewBackgroundColor = titleBackgroundColor
        cell.titleLines = numberOfLines
        cell.titleLabelLeading = titleLeading
        cell.tag = 100 + index

        let tap = UITapGestureRecognizer { [weak self] _ in
            guard let self else { return }
            self.didSelectItemAtIndexClosure?(self.pageControlIndexWithCurrentCellIndex(index: self.currentIndex()))
        }
        cell.addGestureRecognizer(tap)

        return cell
    }

    private func setupCellConstraints(cell: PTCycleScrollViewCell, index: Int) {
        switch scrollDirection {
        case .horizontal:
            cell.snp.makeConstraints { make in
                make.left.equalTo(CGFloat(index) * bounds.width)
                make.top.equalToSuperview()
                make.size.equalTo(bounds.size)
            }
        default:
            cell.snp.makeConstraints { make in
                make.top.equalTo(CGFloat(index) * bounds.height)
                make.left.equalToSuperview()
                make.size.equalTo(bounds.size)
            }
            maxSwipeSize = CGFloat(imagePaths.count) * bounds.height
        }
    }

    private func configureTitleOnly(cell: PTCycleScrollViewCell, index: Int) {
        cell.titleLabelHeight = cellHeight
        let itemIndex = pageControlIndexWithCurrentCellIndex(index: index)
        cell.title = titles[itemIndex]
    }

    private func configureImageOrVideo(cell: PTCycleScrollViewCell, index: Int) {
        if let imageViewContentMode = imageViewContentMode {
            cell.imageView.contentMode = imageViewContentMode
        }

        guard !imagePaths.isEmpty else {
            cell.imageView.image = self.defaultPlaceholderImage
            return
        }

        let itemIndex = pageControlIndexWithCurrentCellIndex(index: index)
        let imagePath = imagePaths[itemIndex]

        if let videoPath = imagePath as? String,
           ["mp4", "mov"].contains(videoPath.pathExtension.lowercased()) {
            getVideoFrame(for: videoPath) { [weak self] image in
                guard self != nil else { return }
                cell.imageView.image = image ?? self?.defaultPlaceholderImage
                cell.videoLink = videoPath

                if itemIndex == 0, let url = URL(string: videoPath) {
                    PTGCDManager.gcdAfter(time: 0.1) {
                        cell.setPlayer(videoQ: url)
                    }
                } else {
                    cell.playButton.isHidden = false
                }
            }
        } else {
            loadImageWithAny(imagePath: imagePath, cell: cell, itemIndex: itemIndex)
        }
        
        // 对冲数据判断
        setBannerAttTitle(cell: cell, itemIndex: itemIndex)
    }
    
    private func setBannerAttTitle(cell:PTCycleScrollViewCell,itemIndex:Int) {
        // 对冲数据判断
        if itemIndex <= (self.titles.count - 1) {
            cell.title = self.titles[itemIndex]
        } else {
            cell.title = ""
        }
    }

    private func updateContentSize() {
        switch scrollDirection {
        case .horizontal:
            pageScrollerView.contentSize = CGSize(width: maxSwipeSize, height: bounds.height)
        default:
            pageScrollerView.contentSize = CGSize(width: bounds.width, height: maxSwipeSize)
        }
    }
}

// MARK: 定时器模块
extension PTCycleScrollView {
    /// 添加Timer
    public func setupTimer() {
        // 仅一张图不进行滚动操纵
        if imagePaths.count <= 1 { return }
        
        invalidateTimer()
        
        timer = Timer.scheduledTimer(withTimeInterval: autoScrollTimeInterval, repeats: true, block: { newTimer in
            PTGCDManager.gcdGobal(qosCls: .background) {
                PTGCDManager.gcdMain {
                    self.automaticScroll()
                }
            }
        })
    }
    
    /// 关闭倒计时
    public func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: Events
extension PTCycleScrollView {
    /// 自动轮播
    func automaticScroll() {
        if imagePaths.count == 0 { return }
        let targetIndex = currentIndex() + 1
        scollToIndex(targetIndex: targetIndex)
    }
    
    /// 滚动到指定位置
    /// - Parameter targetIndex: 下标-Index
    func scollToIndex(targetIndex: Int) {
        if targetIndex >= totalItemsCount {
            if infiniteLoop {
                pageScrollerView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
                setProgressIndex(index: 0)
            }
            return
        }
        
        switch self.scrollDirection {
        case .horizontal:
            pageScrollerView.setContentOffset(CGPoint(x: CGFloat(targetIndex) * self.frame.width, y: 0), animated: true)
        default:
            pageScrollerView.setContentOffset(CGPoint(x: 0, y: CGFloat(targetIndex) * self.frame.height), animated: true)
        }

        setProgressIndex(index: CGFloat(targetIndex))
    }
    
    func setProgressIndex(index:CGFloat) {
        var newIndex = currentIndex()
        if index == 1 {
            newIndex = 0
        }
        
        guard let controllable = customPageControl as? PTPageControllable else { return }
        controllable.setCurrentPage(index: newIndex)
    }
    
    /// 当前位置
    /// - Returns: 下标-Index
    func currentIndex() -> NSInteger {
        if pageScrollerView.pt.jx_width == 0 || pageScrollerView.pt.jx_height == 0 {
            return 0
        }
        
        var index:Int = 0
        switch scrollDirection {
        case .horizontal:
            let less = pageScrollerView.contentSize.width - pageScrollerView.contentOffset.x
            index = pageScrollerView.contentOffset.x == 0 ? 0 : (totalItemsCount - Int(less == 0 ? 0 : (less / self.frame.width)))
        default:
            let less = pageScrollerView.contentSize.height - pageScrollerView.contentOffset.y
            index = pageScrollerView.contentOffset.y == 0 ? 0 : (totalItemsCount - Int(less == 0 ? 0 : (less / self.frame.height)))
        }
        return index
    }
    
    /// PageControl当前下标对应的Cell位置
    /// - Parameter index: PageControl Index
    /// - Returns: Cell Index
    func pageControlIndexWithCurrentCellIndex(index: NSInteger) -> Int {
        imagePaths.count == 0 ? 0 : Int(index % imagePaths.count)
    }
    
    /// 滚动上一个/下一个
    /// - Parameter gestureRecognizer: 手势
    public func scrollByDirection(_ gestureRecognizer: UITapGestureRecognizer) {
        if let index = gestureRecognizer.view?.tag {
            if autoScroll {
                invalidateTimer()
            }
            
            scollToIndex(targetIndex: currentIndex() + (index == 0 ? -1 : 1))
        }
    }
}

// MARK: Scroll control
extension PTCycleScrollView {
    fileprivate func cycleScrollViewScrollToIndex() {
        let indexOnPageControl = pageControlIndexWithCurrentCellIndex(index: currentIndex())
        scrollToClosure?(indexOnPageControl)
    }
}

extension PTCycleScrollView : UIScrollViewDelegate {
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.cycleScrollViewScrollToIndex()

        if let cell = viewWithTag(100 + currentIndex()) as? PTCycleScrollViewCell {
            if let player = cell.player {
                player.pause()
            }
        }
        
        if self.autoScroll {
            self.invalidateTimer()
        }
        
        let indexOnPageControl = self.pageControlIndexWithCurrentCellIndex(index: self.currentIndex())
        self.scrollFromClosure?(indexOnPageControl)
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if self.imagePaths.count == 0 { return }
        
        // 滚动后的回调协议
        if !decelerate { self.cycleScrollViewScrollToIndex() }
        
        if self.autoScroll {
            self.setupTimer()
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.cycleScrollViewScrollToIndex()
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if self.imagePaths.count == 0 { return }
        
        self.cycleScrollViewScrollToIndex()
        
        if self.timer == nil && self.autoScroll {
            self.setupTimer()
        }
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if self.imagePaths.count == 0 { return }
        
        let index:Int = currentIndex()
        self.setProgressIndex(index: 0)
        
        if index == 0 {
            self.scrollViewDidScrollClosure?(0,0)
            return
        }

        if self.scrollViewDidScrollClosure != nil {
            var offSet: CGFloat = 0
            switch self.scrollDirection {
            case .horizontal:
                offSet = scrollView.contentOffset.x -  self.frame.size.width * CGFloat(index)
            case .vertical:
                offSet = scrollView.contentOffset.y - self.frame.size.height * CGFloat(index)
            default:
                break
            }
            
            let currentIndex = self.pageControlIndexWithCurrentCellIndex(index: NSInteger(index))
            self.scrollViewDidScrollClosure!(currentIndex,offSet)
        }
        
        if self.autoScroll {
            self.setupTimer()
        }
    }
}
