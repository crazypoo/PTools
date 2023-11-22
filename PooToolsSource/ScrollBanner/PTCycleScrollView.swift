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

/// Style
@objc public enum PageControlStyle:Int {
    case none
    case system
    case fill
    case pill
    case snake
    case image
    case scrolling
}

/// Position
@objc public enum PageControlPosition:Int {
    case center
    case left
    case right
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

@objcMembers
public class PTCycleScrollView: UIView {
    // MAKR: DataSource
    /// Image Paths
    open var imagePaths: Array<String> = [] {
        didSet {
            self.setTotalItemsMinItems(count: infiniteLoop ? imagePaths.count * 100 : imagePaths.count)
            if imagePaths.count > 1 {
                collectionView.isScrollEnabled = true
                if autoScroll {
                    setupTimer()
                }
            } else {
                collectionView.isScrollEnabled = false
                invalidateTimer()
            }
            
            collectionView.reloadData()
            
            setupPageControl()
        }
    }
    
    /// Titles
    open var titles: Array<String> = [] {
        didSet {
            if titles.count > 0 {
                if imagePaths.count == 0 {
                    imagePaths = titles
                }
            }
        }
    }
    
    // MARK:- Closure
    /// 点击后回调
    open var didSelectItemAtIndexClosure : PTCycleIndexClosure? = nil
    /// 滚动页内偏移量
    open var scrollViewDidScrollClosure : PTScrollViewDidScrollClosure? = nil
    /// 从哪儿滚动
    open var scrollFromClosure : PTCycleIndexClosure? = nil
    /// 滚动到哪儿
    open var scrollToClosure : PTCycleIndexClosure? = nil
    
    // MARK:- Config
    /// 自动轮播- 默认true
    open var autoScroll: Bool = true {
        didSet {
            invalidateTimer()
            // 如果关闭的无限循环，则不进行计时器的操作，否则每次滚动到最后一张就不在进行了。
            if autoScroll && infiniteLoop {
                setupTimer()
            }
        }
    }
    
    /// 无限循环- 默认true，此属性修改了就不存在轮播的意义了
    open var infiniteLoop: Bool = true {
        didSet {
            if imagePaths.count > 0 {
                let temp = imagePaths
                imagePaths = temp
            }
        }
    }
    
    /// 滚动方向，默认horizontal
    open var scrollDirection: UICollectionView.ScrollDirection? = .horizontal {
        didSet {
            flowLayout?.scrollDirection = scrollDirection!
            if scrollDirection == .horizontal {
                position = .centeredHorizontally
            } else {
                position = .centeredVertically
            }
        }
    }
    
    /// 滚动间隔时间,默认2秒
    open var autoScrollTimeInterval: Double = 2.0 {
        didSet {
            autoScroll = true
        }
    }
    
    // MARK:- Style
    /// Background Color
    open var collectionViewBackgroundColor: UIColor! = UIColor.clear
    
    /// Load Placeholder Image
    open var placeHolderImage: UIImage? = nil {
        didSet {
            if placeHolderImage != nil {
                placeHolderViewImage = placeHolderImage
            }
        }
    }
    
    /// No Data Placeholder Image
    open var coverImage: UIImage? = nil {
        didSet {
            if coverImage != nil {
                coverViewImage = coverImage
            }
        }
    }
    
    // MARK: ImageView
    /// Content Mode
    open var imageViewContentMode: UIView.ContentMode? {
        didSet {
            collectionView.reloadData()
        }
    }
    
    // MARK: Title
    /// Color
    open var textColor: UIColor = UIColor.white
    
    /// Number Lines
    open var numberOfLines: NSInteger = 2
    
    /// Title Leading
    open var titleLeading: CGFloat = 15
    
    /// Font
    open var font: UIFont = UIFont.systemFont(ofSize: 15)
    
    /// Background
    open var titleBackgroundColor: UIColor = UIColor.black.withAlphaComponent(0.3)
    
    // MARK: Arrow Icon
    /// Icon - [LeftIcon, RightIcon]
    open var arrowLRIcon: [UIImage]?
    
    /// Icon Frame - [LeftIconFrame, RightIconFrame]
    open var arrowLRFrame: [CGRect]?
    
    // MARK: PageControl
    /// 注意： 由于属性较多，所以请使用style对应的属性，如果没有标明则通用
    /// PageControl
    open var pageControl: UIPageControl?
    
    /// Tint Color
    open var pageControlTintColor: UIColor = UIColor.lightGray {
        didSet {
            setupPageControl()
        }
    }
    // InActive Color
    open var pageControlCurrentPageColor: UIColor = UIColor.white {
        didSet {
            setupPageControl()
        }
    }
    
    /// Radius [PageControlStyle == .fill]
    open var FillPageControlIndicatorRadius: CGFloat = 4 {
        didSet {
            setupPageControl()
        }
    }
    
    /// Active Tint Color [PageControlStyle == .pill || PageControlStyle == .snake]
    open var customPageControlInActiveTintColor: UIColor = UIColor(white: 1, alpha: 0.3) {
        didSet {
            setupPageControl()
        }
    }
    
    /// Active Image [PageControlStyle == .system]
    open var pageControlActiveImage: UIImage? = nil {
        didSet {
            setupPageControl()
        }
    }
    
    /// In Active Image [PageControlStyle == .system]
    open var pageControlInActiveImage: UIImage? = nil {
        didSet {
            setupPageControl()
        }
    }
    
    // MARK: CustomPageControl
    /// Custom PageControl
    open var customPageControl: UIView?
    
    /// Style [.fill, .pill, .snake]
    open var customPageControlStyle: PageControlStyle = .system {
        didSet {
            setupPageControl()
        }
    }
    /// Tint Color
    open var customPageControlTintColor: UIColor = UIColor.white {
        didSet {
            setupPageControl()
        }
    }
    /// Indicator Padding
    open var customPageControlIndicatorPadding: CGFloat = 8 {
        didSet {
            setupPageControl()
        }
    }
    
    /// Position
    open var pageControlPosition: PageControlPosition = .center {
        didSet {
            setupPageControl()
        }
    }
    
    /// Leading
    open var pageControlLeadingOrTrialingContact: CGFloat = 28 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// Bottom
    open var pageControlBottom: CGFloat = 5 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// 开启/关闭URL特殊字符处理
    open var isAddingPercentEncodingForURLString: Bool = false
    
    
    // MARK:- Private
    /// 总数量
    fileprivate var totalItemsCount: NSInteger! = 1
    func setTotalItemsMinItems(@PTClampedProperyWrapper(range:1...(.max)) count:NSInteger) {
        self.totalItemsCount = count
    }
    
    /// 最大伸展空间(防止出现问题，可外部设置)
    /// 用于反方向滑动的时候，需要知道最大的contentSize
    fileprivate var maxSwipeSize: CGFloat = 0
    
    /// 是否纯文本
    fileprivate var isOnlyTitle: Bool = false
    
    /// 高度
    fileprivate var cellHeight: CGFloat = 56
    
    /// Collection滚动方向
    fileprivate var position: UICollectionView.ScrollPosition! = .centeredHorizontally
    
    /// 加载状态图
    fileprivate var placeHolderViewImage: UIImage! = Bundle.podBundleImage(bundleName: CorePodBundleName, imageName: "llplaceholder")
    
    /// 空数据占位图
    fileprivate var coverViewImage: UIImage! = Bundle.podBundleImage(bundleName: CorePodBundleName, imageName: "llplaceholder")
    
    /// 计时器
    fileprivate var dtimer: DispatchSourceTimer?
    
    /// 容器组件 UICollectionView
    open var collectionView: UICollectionView!
        
    /// UICollectionViewFlowLayout
    lazy fileprivate var flowLayout: UICollectionViewFlowLayout? = {
        let tempFlowLayout = UICollectionViewFlowLayout.init()
        tempFlowLayout.minimumLineSpacing = 0
        tempFlowLayout.scrollDirection = .horizontal
        return tempFlowLayout
    }()
    
    /// Init
    /// - Parameter frame: CGRect
    override internal init(frame: CGRect) {
        super.init(frame: frame)
        setupMainView()
    }
    
    /// Init
    /// - Parameter aDecoder: NSCoder
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupMainView()
    }
}

// MARK: 类初始化
extension PTCycleScrollView {
    /// 默认初始化
    /// - Parameters:
    ///   - imageURLPaths: URL Path Array
    ///   - titles: Title Array
    ///   - didSelectItemAtIndex: Closure
    /// - Returns: PTCycleScrollView
    public class func cycleScrollViewCreate(imageURLPaths: Array<String>? = [], titles:Array<String>? = [], didSelectItemAtIndex: PTCycleIndexClosure? = nil) -> PTCycleScrollView {
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
        
        if let backImage = backImage {
            // 异步加载数据时候，第一个页面会出现placeholder image，可以用backImage来设置纯色图片等其他方式
            cycleScrollView.coverImage = backImage
        }
        
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
    public class func cycleScrollViewWithArrow(arrowLRImages: [UIImage], arrowLRFrame: [CGRect]? = nil, imageURLPaths: Array<String>? = [], titles:Array<String>? = [], didSelectItemAtIndex: PTCycleIndexClosure? = nil) -> PTCycleScrollView {
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
    
    func scrollViewReloadData() {
        invalidateTimer()
        collectionView.reloadData()
        setupTimer()
    }
}

// MARK: UI
extension PTCycleScrollView {
    // MARK: 添加UICollectionView
    private func setupMainView() {
        collectionView = UICollectionView.init(frame: CGRect.zero, collectionViewLayout: flowLayout!)
        collectionView.register(PTCycleScrollViewCell.self, forCellWithReuseIdentifier: PTCycleScrollViewCell.ID)
        collectionView.backgroundColor = collectionViewBackgroundColor
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.scrollsToTop = false
        addSubview(collectionView)
    }
    
    // MARK: 添加自定义箭头
    private func setupArrowIcon() {
        if !infiniteLoop {
            assertionFailure("当前未开启无限轮播`infiniteLoop`，请设置后使用此模式.")
            return
        }
        
        guard let ali = arrowLRIcon else {
            assertionFailure("初始化方向图片`arrowLRIcon`数据为空.")
            return
        }
        
        /// 添加默认Frame
        if arrowLRFrame?.count ?? 0 < 2 {
            let w = frame.size.width * 0.25
            let h = frame.size.height
            
            arrowLRFrame = [CGRect.init(x: 5, y: 0, width: w, height: h),
                            CGRect.init(x: frame.size.width - w - 5, y: 0, width: w, height: h)]
        }
        
        guard let alf = arrowLRFrame else {
            assertionFailure("初始化方向图片`arrowLRFrame`数据为空.")
            return
        }
        
        let leftImageView = UIImageView.init(frame: alf.first!)
        leftImageView.contentMode = .left
        leftImageView.tag = 0
        leftImageView.isUserInteractionEnabled = true
        leftImageView.image = ali.first!
        leftImageView.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(scrollByDirection(_:))))
        addSubview(leftImageView)
        
        let rightImageView = UIImageView.init(frame: alf.last!)
        rightImageView.contentMode = .right
        rightImageView.tag = 1
        rightImageView.isUserInteractionEnabled = true
        rightImageView.image = ali.last!
        rightImageView.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(scrollByDirection(_:))))
        addSubview(rightImageView)
    }
    
    // MARK: 添加PageControl
    func setupPageControl() {
        
        // 重新添加
        if pageControl != nil {
            pageControl?.removeFromSuperview()
        }
        
        if customPageControl != nil {
            customPageControl?.removeFromSuperview()
        }
        
        if imagePaths.count <= 1 {
            return
        }
        
        switch customPageControlStyle {
        case .none:
            pageControl = UIPageControl.init()
            pageControl?.numberOfPages = imagePaths.count
        case .system:
            pageControl = UIPageControl.init()
            pageControl?.pageIndicatorTintColor = pageControlTintColor
            pageControl?.currentPageIndicatorTintColor = pageControlCurrentPageColor
            pageControl?.numberOfPages = imagePaths.count
            addSubview(pageControl!)
            pageControl?.isHidden = false
        case .fill:
            customPageControl = PTFilledPageControl.init(frame: CGRect.zero)
            customPageControl?.tintColor = customPageControlTintColor
            (customPageControl as! PTFilledPageControl).indicatorPadding = customPageControlIndicatorPadding
            (customPageControl as! PTFilledPageControl).indicatorRadius = FillPageControlIndicatorRadius
            (customPageControl as! PTFilledPageControl).pageCount = imagePaths.count
            addSubview(customPageControl!)
        case .pill:
            customPageControl = PTPillPageControl.init(frame: CGRect.zero)
            (customPageControl as! PTPillPageControl).indicatorPadding = customPageControlIndicatorPadding
            (customPageControl as! PTPillPageControl).activeTint = customPageControlTintColor
            (customPageControl as! PTPillPageControl).inactiveTint = customPageControlInActiveTintColor
            (customPageControl as! PTPillPageControl).pageCount = imagePaths.count
            addSubview(customPageControl!)
        case .snake:
            customPageControl = PTSnakePageControl.init(frame: CGRect.zero)
            (customPageControl as! PTSnakePageControl).activeTint = customPageControlTintColor
            (customPageControl as! PTSnakePageControl).indicatorPadding = customPageControlIndicatorPadding
            (customPageControl as! PTSnakePageControl).indicatorRadius = FillPageControlIndicatorRadius
            (customPageControl as! PTSnakePageControl).inactiveTint = customPageControlInActiveTintColor
            (customPageControl as! PTSnakePageControl).pageCount = imagePaths.count
            addSubview(customPageControl!)
        case .image:
            pageControl = PTImagePageControl()
            pageControl?.pageIndicatorTintColor = UIColor.clear
            pageControl?.currentPageIndicatorTintColor = UIColor.clear
            
            if let activeImage = pageControlActiveImage {
                (pageControl as? PTImagePageControl)?.dotActiveImage = activeImage
            }
            if let inActiveImage = pageControlInActiveImage {
                (pageControl as? PTImagePageControl)?.dotInActiveImage = inActiveImage
            }
            
            pageControl?.numberOfPages = imagePaths.count
            addSubview(pageControl!)
            pageControl?.isHidden = false
        case .scrolling:
            customPageControl = PTScrollingPageControl()
                        
            (customPageControl as? PTScrollingPageControl)?.pageCount = imagePaths.count

            addSubview(customPageControl!)
            customPageControl?.isHidden = false
        }
        
        calcScrollViewToScroll(collectionView)
    }
}

// MARK: UIViewHierarchy | LayoutSubviews
extension PTCycleScrollView {
    /// 将要添加到 window 上时
    ///
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
        
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        PTGCDManager.gcdAfter(time: 0.1) {
            
            // Cell Height
            self.cellHeight = self.collectionView.frame.height
            
            // 计算最大扩展区大小
            if self.scrollDirection == .horizontal {
                self.maxSwipeSize = CGFloat(self.imagePaths.count) * self.collectionView.frame.width
            } else {
                self.maxSwipeSize = CGFloat(self.imagePaths.count) * self.collectionView.frame.height
            }
            
            // Cell Size
            self.flowLayout?.itemSize = self.frame.size
            // Page Frame
            switch self.customPageControlStyle {
            case .none,.system,.image:
                let pointSize = self.pageControl?.size(forNumberOfPages: self.imagePaths.count)
                switch self.pageControlPosition {
                case .center:
                    self.pageControl?.snp.makeConstraints { make in
                        make.left.right.equalToSuperview().inset((self.pageControlLeadingOrTrialingContact * 0.5))
                        make.height.equalTo(10)
                        make.bottom.equalToSuperview().inset(self.pageControlBottom)
                    }
                case .left:
                    self.pageControl?.snp.makeConstraints { make in
                        make.height.equalTo(10)
                        make.width.equalTo(pointSize?.width ?? 0)
                        make.left.equalToSuperview().inset((self.pageControlLeadingOrTrialingContact * 0.5))
                        make.bottom.equalToSuperview().inset(self.pageControlBottom)
                    }
                case .right:
                    self.pageControl?.snp.makeConstraints { make in
                        make.height.equalTo(10)
                        make.width.equalTo(pointSize?.width ?? 0)
                        make.right.equalToSuperview().inset((self.pageControlLeadingOrTrialingContact * 0.5))
                        make.bottom.equalToSuperview().inset(self.pageControlBottom)
                    }
                default:
                    break
                }
            default:
                var heights:CGFloat = 10
                // pill
                switch self.customPageControlStyle {
                case .scrolling:
                    heights = 20
                default:
                    heights = 10
                }
                
                switch self.pageControlPosition {
                case .left:
                    self.customPageControl?.snp.makeConstraints { make in
                        make.height.equalTo(heights)
                        make.left.equalToSuperview().inset((self.pageControlLeadingOrTrialingContact * 0.5))
                        make.bottom.equalToSuperview().inset(self.pageControlBottom)
                    }
                case.right:
                    self.customPageControl?.snp.makeConstraints { make in
                        make.height.equalTo(heights)
                        make.right.equalToSuperview().inset((self.pageControlLeadingOrTrialingContact * 0.5))
                        make.bottom.equalToSuperview().inset(self.pageControlBottom)
                    }
                default:
                    self.customPageControl?.snp.makeConstraints { make in
                        make.height.equalTo(heights)
                        make.centerX.equalToSuperview()
                        make.left.right.equalToSuperview().inset((self.pageControlLeadingOrTrialingContact * 0.5))
                        make.bottom.equalToSuperview().inset(self.pageControlBottom)
                    }
                }
            }
            
            if self.collectionView.contentOffset.x == 0 && self.imagePaths.count > 0 {
                var targetIndex = 0
                if self.infiniteLoop {
                    targetIndex = self.totalItemsCount/2
                }
                self.collectionView.scrollToItem(at: IndexPath.init(item: targetIndex, section: 0), at: self.position, animated: false)
            }

            self.collectionView.reloadData()
        }
    }
}

// MARK: 定时器模块
extension PTCycleScrollView {
    /// 添加DTimer
    func setupTimer() {
        // 仅一张图不进行滚动操纵
        if imagePaths.count <= 1 { return }
        
        invalidateTimer()
        
        let l_dtimer = DispatchSource.makeTimerSource()
        l_dtimer.schedule(deadline: .now()+autoScrollTimeInterval, repeating: autoScrollTimeInterval)
        l_dtimer.setEventHandler { [weak self] in
            PTGCDManager.gcdGobal(qosCls: .background) {
                PTGCDManager.gcdMain {
                    self?.automaticScroll()
                }
            }
        }
        // 继续
        l_dtimer.resume()
        
        dtimer = l_dtimer
    }
    
    /// 关闭倒计时
    func invalidateTimer() {
        dtimer?.cancel()
        dtimer = nil
    }
}

// MARK: Events
extension PTCycleScrollView {
    /// 自动轮播
    @objc func automaticScroll() {
        if imagePaths.count == 0 { return }
        let targetIndex = currentIndex() + 1
        scollToIndex(targetIndex: targetIndex)
    }
    
    /// 滚动到指定位置
    ///
    /// - Parameter targetIndex: 下标-Index
    func scollToIndex(targetIndex: Int) {
        if targetIndex >= totalItemsCount {
            if infiniteLoop {
                collectionView.scrollToItem(at: IndexPath.init(item: Int(totalItemsCount/2), section: 0), at: position, animated: false)
            }
            return
        }
        collectionView.scrollToItem(at: IndexPath.init(item: targetIndex, section: 0), at: position, animated: true)
    }
    
    /// 当前位置
    ///
    /// - Returns: 下标-Index
    func currentIndex() -> NSInteger {
        if collectionView.pt.jx_width == 0 || collectionView.pt.jx_height == 0 {
            return 0
        }
        var index = 0
        if flowLayout?.scrollDirection == UICollectionView.ScrollDirection.horizontal {
            index = NSInteger(collectionView.contentOffset.x / (flowLayout?.itemSize.width)!) < 0 ? 0 :NSInteger(collectionView.contentOffset.x / (flowLayout?.itemSize.width)!)
        } else {
            index = NSInteger(collectionView.contentOffset.y / (flowLayout?.itemSize.height)!) < 0 ? 0 :NSInteger(collectionView.contentOffset.y / (flowLayout?.itemSize.height)!)
        }
        return index
    }
    
    /// PageControl当前下标对应的Cell位置
    ///
    /// - Parameter index: PageControl Index
    /// - Returns: Cell Index
    func pageControlIndexWithCurrentCellIndex(index: NSInteger) -> Int {
        imagePaths.count == 0 ? 0 : Int(index % imagePaths.count)
    }
    
    /// 滚动上一个/下一个
    ///
    /// - Parameter gestureRecognizer: 手势
    @objc open func scrollByDirection(_ gestureRecognizer: UITapGestureRecognizer) {
        if let index = gestureRecognizer.view?.tag {
            if autoScroll {
                invalidateTimer()
            }
            
            scollToIndex(targetIndex: currentIndex() + (index == 0 ? -1 : 1))
        }
    }
}

// MARK: UICollectionViewDelegate, UICollectionViewDataSource
extension PTCycleScrollView: UICollectionViewDelegate, UICollectionViewDataSource {
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        totalItemsCount
    }
    
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: PTCycleScrollViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: PTCycleScrollViewCell.ID, for: indexPath) as! PTCycleScrollViewCell
        // Setting
        cell.titleFont = font
        cell.titleLabelTextColor = textColor
        cell.titleBackViewBackgroundColor = titleBackgroundColor
        cell.titleLines = numberOfLines
        
        // Leading
        cell.titleLabelLeading = titleLeading
        
        // Only Title
        if isOnlyTitle && titles.count > 0 {
            cell.titleLabelHeight = cellHeight
            
            let itemIndex = pageControlIndexWithCurrentCellIndex(index: indexPath.item)
            cell.title = titles[itemIndex]
        } else {
            cell.titleLabelHeight = cellHeight
            // Mode
            if let imageViewContentMode = imageViewContentMode {
                cell.imageView.contentMode = imageViewContentMode
            }
            
            // 0==count 占位图
            if imagePaths.count == 0 {
                cell.imageView.image = coverViewImage
            } else {
                let itemIndex = pageControlIndexWithCurrentCellIndex(index: indexPath.item)
                let imagePath = imagePaths[itemIndex]
                
                // 根据imagePath，来判断是网络图片还是本地图
                PTLoadImageFunction.loadImage(contentData: imagePath) { images, image in
                    if (images?.count ?? 0) > 1 {
                        cell.imageView.image = UIImage.animatedImage(with: images!, duration: 2)
                    } else if (images?.count ?? 0) == 1 {
                        cell.imageView.image = image
                    } else {
                        cell.imageView.image = self.coverViewImage
                    }
                }
                
                // 对冲数据判断
                if itemIndex <= titles.count-1 {
                    cell.title = titles[itemIndex]
                } else {
                    cell.title = ""
                }
            }
        }
        return cell
    }
    
    open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if didSelectItemAtIndexClosure != nil {
            didSelectItemAtIndexClosure!(pageControlIndexWithCurrentCellIndex(index: indexPath.item))
        }
    }
}

// MARK: UIScrollViewDelegate
extension PTCycleScrollView: UIScrollViewDelegate {
    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if imagePaths.count == 0 { return }
        calcScrollViewToScroll(scrollView)
        
        if scrollViewDidScrollClosure != nil {
            var offSet: CGFloat = 0
            var index: NSInteger = 1
            if flowLayout?.scrollDirection == UICollectionView.ScrollDirection.horizontal {
                index = NSInteger(collectionView.contentOffset.x / flowLayout!.itemSize.width)
                offSet = collectionView.contentOffset.x -  flowLayout!.itemSize.width * CGFloat(index)
            } else {
                index = NSInteger(collectionView.contentOffset.y / flowLayout!.itemSize.height)
                offSet = collectionView.contentOffset.y - flowLayout!.itemSize.height * CGFloat(index)
            }
            
            let currentIndex = pageControlIndexWithCurrentCellIndex(index: NSInteger(index))
            scrollViewDidScrollClosure!(currentIndex,offSet)
        }
    }
    
    open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        cycleScrollViewScrollToIndex()
        if autoScroll {
            invalidateTimer()
        }
        
        let indexOnPageControl = pageControlIndexWithCurrentCellIndex(index: currentIndex())
        if scrollFromClosure != nil {
            scrollFromClosure!(indexOnPageControl)
        }
    }
    
    open func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if imagePaths.count == 0 { return }
        
        // 滚动后的回调协议
        if !decelerate { cycleScrollViewScrollToIndex() }
        
        if autoScroll {
            setupTimer()
        }
    }
    
    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        cycleScrollViewScrollToIndex()
    }
    
    open func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if imagePaths.count == 0 { return }
        
        cycleScrollViewScrollToIndex()
        
        if dtimer == nil && autoScroll {
            setupTimer()
        }
    }
    
    fileprivate func cycleScrollViewScrollToIndex() {
        let indexOnPageControl = pageControlIndexWithCurrentCellIndex(index: currentIndex())
        if scrollToClosure != nil {
            scrollToClosure!(indexOnPageControl)
        }
    }
    
    fileprivate func calcScrollViewToScroll(_ scrollView: UIScrollView) {
        let indexOnPageControl = pageControlIndexWithCurrentCellIndex(index: currentIndex())
        
        switch customPageControlStyle {
        case .none,.system,.image:
            pageControl?.currentPage = indexOnPageControl
        default:
            var progress: CGFloat = 999
            // Direction
            switch scrollDirection {
            case .horizontal:
                var currentOffsetX = scrollView.contentOffset.x - (CGFloat(totalItemsCount) * scrollView.frame.size.width) / 2
                if currentOffsetX < 0 {
                    if currentOffsetX >= -scrollView.frame.size.width{
                        currentOffsetX = CGFloat(indexOnPageControl) * scrollView.frame.size.width
                    } else if currentOffsetX <= -maxSwipeSize{
                        collectionView.scrollToItem(at: IndexPath.init(item: Int(totalItemsCount/2), section: 0), at: position, animated: false)
                    } else {
                        currentOffsetX = maxSwipeSize + currentOffsetX
                    }
                }
                if currentOffsetX >= CGFloat(imagePaths.count) * scrollView.frame.size.width && infiniteLoop{
                    collectionView.scrollToItem(at: IndexPath.init(item: Int(totalItemsCount/2), section: 0), at: position, animated: false)
                }
                progress = currentOffsetX / scrollView.frame.size.width
            case .vertical:
                var currentOffsetY = scrollView.contentOffset.y - (CGFloat(totalItemsCount) * scrollView.frame.size.height) / 2
                if currentOffsetY < 0 {
                    if currentOffsetY >= -scrollView.frame.size.height{
                        currentOffsetY = CGFloat(indexOnPageControl) * scrollView.frame.size.height
                    } else if currentOffsetY <= -maxSwipeSize{
                        collectionView.scrollToItem(at: IndexPath.init(item: Int(totalItemsCount/2), section: 0), at: position, animated: false)
                    } else {
                        currentOffsetY = maxSwipeSize + currentOffsetY
                    }
                }
                if currentOffsetY >= CGFloat(imagePaths.count) * scrollView.frame.size.height && infiniteLoop{
                    collectionView.scrollToItem(at: IndexPath.init(item: Int(totalItemsCount/2), section: 0), at: position, animated: false)
                }
                progress = currentOffsetY / scrollView.frame.size.height
            default:
                break
            }
            
            if progress == 999 {
                progress = CGFloat(indexOnPageControl)
            }
            // progress
            
            switch customPageControlStyle {
            case .fill:
                (customPageControl as? PTFilledPageControl)?.progress = progress
            case .pill:
                (customPageControl as? PTPillPageControl)?.progress = progress
            case .snake:
                (customPageControl as? PTSnakePageControl)?.progress = progress
            case .scrolling:
                (customPageControl as? PTScrollingPageControl)?.progress = progress
            default:
                break
            }
        }
    }
}
