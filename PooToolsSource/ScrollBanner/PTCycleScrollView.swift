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

@objcMembers
public class PTCycleScrollView: UIView {
    // MARK: DataSource
    
    fileprivate var clearSubs:Bool = false
    
    public static var playButtonImage:UIImage = "▶️".emojiToImage(emojiFont: .appfont(size: 44))
    
    /// 图片地址
    open var imagePaths: Array<Any> = [] {
        willSet {
            clearSubs = !imagePaths.elementsEqual(newValue, by: { ($0 as AnyObject).isEqual($1) })
        }
        didSet {
            setTotalItemsMinItems(count: imagePaths.count)
            pageScrollerView.isScrollEnabled = imagePaths.count > 1
            imagePaths.count > 1 ? setupTimer() : invalidateTimer()
            if clearSubs {
                PTGCDManager.gcdAfter(time: 0.01) { [weak self] in
                    self?.collectionViewSetData()
                }
            }
        }
    }
    
    /// 标题
    open var titles: Array<Any> = [] {
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
    open var didSelectItemAtIndexClosure : PTCycleIndexClosure? = nil
    /// 滚动页内偏移量
    open var scrollViewDidScrollClosure : PTScrollViewDidScrollClosure? = nil
    /// 从哪儿滚动
    open var scrollFromClosure : PTCycleIndexClosure? = nil
    /// 滚动到哪儿
    open var scrollToClosure : PTCycleIndexClosure? = nil
    
    // MARK: - Config
    
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
            switch scrollDirection {
            case .horizontal:
                position = .centeredHorizontally
            default:
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
    
    // MARK: - Style
    
    /// 背景颜色
    open var collectionViewBackgroundColor: UIColor! = UIColor.clear
        
    // MARK: ImageView
    /// 图片的展示模式
    open var imageViewContentMode: UIView.ContentMode? {
        didSet {
            collectionViewSetData()
        }
    }
    
    // MARK: Title
    
    /// 字体颜色
    open var textColor: UIColor = UIColor.white
    
    /// 设置行数
    open var numberOfLines: NSInteger = 2
    
    /// 标题的左间距
    open var titleLeading: CGFloat = 15
    
    /// 字体
    open var font: UIFont = UIFont.systemFont(ofSize: 15)
    
    /// 背景颜色
    open var titleBackgroundColor: UIColor = UIColor.black.withAlphaComponent(0.3)
    
    // MARK: 箭头标签
    
    /// Icon - [LeftIcon, RightIcon]
    open var arrowLRIcon: [Any]?
    
    /// Icon Frame - [LeftIconFrame, RightIconFrame]
    open var arrowLRFrame: [CGRect]?
    
    // MARK: PageControl
        
    /// 未选中颜色
    open var pageControlTintColor: UIColor = UIColor.lightGray {
        didSet {
            // 重新添加
            if customPageControl != nil {
                customPageControl?.removeFromSuperview()
            }
            setupPageControl()
        }
    }
    /// 选中颜色
    open var pageControlCurrentPageColor: UIColor = UIColor.white {
        didSet {
            if customPageControl != nil {
                customPageControl?.removeFromSuperview()
            }
            setupPageControl()
        }
    }
    
    ///  圆角(.fill,.snake)
    open var fillPageControlIndicatorRadius: CGFloat = 4 {
        didSet {
            if customPageControl != nil {
                customPageControl?.removeFromSuperview()
            }
            setupPageControl()
        }
    }
    
    /// 选中颜色(.pill,.snake)
    open var customPageControlInActiveTintColor: UIColor = UIColor(white: 1, alpha: 0.3) {
        didSet {
            if customPageControl != nil {
                customPageControl?.removeFromSuperview()
            }
            setupPageControl()
        }
    }
    
    /// 普通图片(.system)
    open var pageControlActiveImage: UIImage? = nil {
        didSet {
            if customPageControl != nil {
                customPageControl?.removeFromSuperview()
            }
            setupPageControl()
        }
    }
    
    /// 选中图片(.system)
    open var pageControlInActiveImage: UIImage? = nil {
        didSet {
            if customPageControl != nil {
                customPageControl?.removeFromSuperview()
            }
            setupPageControl()
        }
    }
    
    open var dotSpacing:CGFloat = 8 {
        didSet {
            if customPageControl != nil {
                customPageControl?.removeFromSuperview()
            }
            setupPageControl()
        }
    }
    
    // MARK: CustomPageControl
        
    /// 自定义Pagecontrol风格(.fill,.pill,.snake)
    open var customPageControlStyle: PageControlStyle = .system {
        didSet {
            if customPageControl != nil {
                customPageControl?.removeFromSuperview()
            }
            setupPageControl()
        }
    }
    
    /// 自定义Pagecontrol普通颜色
    open var customPageControlTintColor: UIColor = UIColor.white {
        didSet {
            if customPageControl != nil {
                customPageControl?.removeFromSuperview()
            }
            setupPageControl()
        }
    }
    /// 自定义Pagecontrol点阵边距
    open var customPageControlIndicatorPadding: CGFloat = 8 {
        didSet {
            if customPageControl != nil {
                customPageControl?.removeFromSuperview()
            }
            setupPageControl()
        }
    }
    
    /// pagecontrol的展示方位(左,中,右)
    open var pageControlPosition: PageControlPosition = .center {
        didSet {
            if customPageControl != nil {
                customPageControl?.removeFromSuperview()
            }
            setupPageControl()
            layoutSubviews()
        }
    }
    
    /// pagecontrol的左右间距
    open var pageControlLeadingOrTrialingContact: CGFloat = 28 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// pagecontrol的底部间距
    open var pageControlBottom: CGFloat = 5 {
        didSet {
            setNeedsDisplay()
        }
    }
        
    open var iCloudDocument:String = ""
    
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
        if let videoPath = imagePath as? String, videoPath.pathExtension.lowercased() == "mp4" || videoPath.pathExtension.lowercased() == "mov",let player = cell.player {
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
    
    func scrollViewReloadData() {
        invalidateTimer()
        collectionViewSetData()
        setupTimer()
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
        
        PTGCDManager.gcdAfter(time: 0.1) {
            self.setupPageControl()
        }
    }
    
    // MARK: 添加自定义箭头
    private func setupArrowIcon() {
        PTGCDManager.gcdAfter(time: 0.1) {
            if !self.infiniteLoop {
                assertionFailure("当前未开启无限轮播`infiniteLoop`，请设置后使用此模式.")
                return
            }
            
            guard let ali = self.arrowLRIcon else {
                assertionFailure("初始化方向图片`arrowLRIcon`数据为空.")
                return
            }
            
            /// 添加默认Frame
            if self.arrowLRFrame?.count ?? 0 < 2 {
                let w = self.frame.size.width * 0.25
                let h = self.frame.size.height
                
                self.arrowLRFrame = [
                    CGRect.init(x: 5, y: 0, width: w, height: h),
                    CGRect.init(x: self.frame.size.width - w - 5, y: 0, width: w, height: h)
                ]
            }
            
            guard let alf = self.arrowLRFrame else {
                assertionFailure("初始化方向图片`arrowLRFrame`数据为空.")
                return
            }
            
            let leftImageView = UIImageView.init(frame: alf.first!)
            leftImageView.contentMode = .left
            leftImageView.tag = 0
            leftImageView.isUserInteractionEnabled = true
            leftImageView.loadImage(contentData: ali.first!,iCloudDocumentName: self.iCloudDocument,emptyImage: PTAppBaseConfig.share.defaultPlaceholderImage)
            leftImageView.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(self.scrollByDirection(_:))))
            self.addSubview(leftImageView)
            
            let rightImageView = UIImageView.init(frame: alf.last!)
            rightImageView.contentMode = .right
            rightImageView.tag = 1
            rightImageView.isUserInteractionEnabled = true
            rightImageView.loadImage(contentData: ali.last!,iCloudDocumentName: self.iCloudDocument,emptyImage: PTAppBaseConfig.share.defaultPlaceholderImage)
            rightImageView.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(self.scrollByDirection(_:))))
            self.addSubview(rightImageView)
        }
    }
    
    // MARK: 添加PageControl
    func setupPageControl() {
        
        if imagePaths.count <= 1 {
            return
        }
        
        switch customPageControlStyle {
        case .none:
            customPageControl = UIView()
            addSubview(customPageControl!)
            customPageControl?.isHidden = true
        case .system:
            customPageControl = UIPageControl()
            (customPageControl as! UIPageControl).pageIndicatorTintColor = pageControlTintColor
            (customPageControl as! UIPageControl).currentPageIndicatorTintColor = pageControlCurrentPageColor
            (customPageControl as! UIPageControl).numberOfPages = imagePaths.count
            addSubview(customPageControl!)
            customPageControl?.isHidden = false
        case .fill:
            customPageControl = PTFilledPageControl()
            customPageControl?.tintColor = customPageControlTintColor
            (customPageControl as! PTFilledPageControl).indicatorPadding = customPageControlIndicatorPadding
            (customPageControl as! PTFilledPageControl).indicatorRadius = fillPageControlIndicatorRadius
            (customPageControl as! PTFilledPageControl).pageCount = imagePaths.count
            addSubview(customPageControl!)
            customPageControl?.isHidden = false
        case .pill:
            customPageControl = PTPillPageControl()
            (customPageControl as! PTPillPageControl).indicatorPadding = customPageControlIndicatorPadding
            (customPageControl as! PTPillPageControl).activeTint = customPageControlTintColor
            (customPageControl as! PTPillPageControl).inactiveTint = customPageControlInActiveTintColor
            (customPageControl as! PTPillPageControl).pageCount = imagePaths.count
            addSubview(customPageControl!)
            customPageControl?.isHidden = false
        case .snake:
            customPageControl = PTSnakePageControl()
            (customPageControl as! PTSnakePageControl).activeTint = customPageControlTintColor
            (customPageControl as! PTSnakePageControl).indicatorPadding = customPageControlIndicatorPadding
            (customPageControl as! PTSnakePageControl).indicatorRadius = fillPageControlIndicatorRadius
            (customPageControl as! PTSnakePageControl).inactiveTint = customPageControlInActiveTintColor
            (customPageControl as! PTSnakePageControl).pageCount = imagePaths.count
            addSubview(customPageControl!)
            customPageControl?.isHidden = false
        case .image:
            customPageControl = PTImagePageControl()
            (customPageControl as! PTImagePageControl).pageIndicatorTintColor = UIColor.clear
            (customPageControl as! PTImagePageControl).currentPageIndicatorTintColor = UIColor.clear
            if let activeImage = pageControlActiveImage {
                (customPageControl as! PTImagePageControl).pageImage = activeImage
            }
            if let inActiveImage = pageControlInActiveImage {
                (customPageControl as! PTImagePageControl).currentPageImage = inActiveImage
            }
            (customPageControl as! PTImagePageControl).dotSpacing = dotSpacing
            (customPageControl as! PTImagePageControl).numberOfPages = imagePaths.count
            addSubview(customPageControl!)
            customPageControl?.isHidden = false
        case .scrolling:
            customPageControl = PTScrollingPageControl()
            (customPageControl as? PTScrollingPageControl)?.pageCount = imagePaths.count
            addSubview(customPageControl!)
            customPageControl?.isHidden = false
        }
        bringSubviewToFront(customPageControl!)
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
        
        // 计算最大扩展区大小
        switch self.scrollDirection {
        case .horizontal:
            self.maxSwipeSize = CGFloat(self.imagePaths.count) * self.frame.width
        default:
            self.maxSwipeSize = CGFloat(self.imagePaths.count) * self.frame.height
        }
        
        // Page Frame
        switch self.customPageControlStyle {
        case .none,.system,.image:
            let pointSize = (self.customPageControl as? UIPageControl)?.size(forNumberOfPages: self.imagePaths.count)
            (self.customPageControl as? UIPageControl)?.snp.makeConstraints { make in
                make.height.equalTo(10)
                make.bottom.equalToSuperview().inset(self.pageControlBottom)
                switch self.pageControlPosition {
                case .center:
                    make.left.right.equalToSuperview().inset((self.pageControlLeadingOrTrialingContact * 0.5))
                case .left:
                    make.width.equalTo(pointSize?.width ?? 0)
                    make.left.equalToSuperview().inset((self.pageControlLeadingOrTrialingContact * 0.5))
                case .right:
                    make.width.equalTo(pointSize?.width ?? 0)
                    make.right.equalToSuperview().inset((self.pageControlLeadingOrTrialingContact * 0.5))
                default:
                    break
                }
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
            
            self.customPageControl?.snp.makeConstraints { make in
                make.height.equalTo(heights)
                make.bottom.equalToSuperview().inset(self.pageControlBottom)
                switch self.pageControlPosition {
                case .left:
                    make.left.equalToSuperview().inset((self.pageControlLeadingOrTrialingContact * 0.5))
                case.right:
                    make.right.equalToSuperview().inset((self.pageControlLeadingOrTrialingContact * 0.5))
                default:
                    make.left.right.equalToSuperview().inset((self.pageControlLeadingOrTrialingContact * 0.5))
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
                    completion(PTAppBaseConfig.share.defaultEmptyImage)
                }
            }
        }
    }
    
    func setCellData() {
        for i in 0..<totalItemsCount {
            guard let cell = viewWithTag(100 + i) as? PTCycleScrollViewCell else { continue }
            
            if self.isOnlyTitle && !self.titles.isEmpty {
                cell.titleLabelHeight = self.cellHeight
                let itemIndex = self.pageControlIndexWithCurrentCellIndex(index: i)
                cell.title = self.titles[itemIndex]
            } else {
                // 配置图片模式
                if let imageViewContentMode = self.imageViewContentMode {
                    cell.imageView.contentMode = imageViewContentMode
                }
                
                if self.imagePaths.isEmpty {
                    cell.imageView.image = PTAppBaseConfig.share.defaultPlaceholderImage
                } else {
                    let itemIndex = self.pageControlIndexWithCurrentCellIndex(index: i)
                    let imagePath = self.imagePaths[itemIndex]
                    
                    if let videoPath = imagePath as? String, videoPath.pathExtension.lowercased() == "mp4" || videoPath.pathExtension.lowercased() == "mov" {
                        self.getVideoFrame(for: videoPath) { image in
                            cell.imageView.image = image ?? PTAppBaseConfig.share.defaultPlaceholderImage
                            cell.videoLink = videoPath
                            if itemIndex == 0, let url = URL(string: videoPath) {
                                PTGCDManager.gcdAfter(time: 0.1) {
                                    cell.setPlayer(videoQ: url)
                                }
                            }
                        }
                    } else {
                        self.loadImageWithAny(imagePath: imagePath, cell: cell, itemIndex: itemIndex)
                    }
                }
            }
        }
    }
    
    func loadImageWithAny(imagePath:Any,cell:PTCycleScrollViewCell,itemIndex:Int) {
        var currentImage: UIImage?
        Task {
            let imageResult = await PTLoadImageFunction.loadImage(contentData: imagePath,iCloudDocumentName: self.iCloudDocument)
            if let images = imageResult.0 {
                if images.count > 1 {
                    currentImage = UIImage.animatedImage(with: images, duration: 2)
                } else {
                    if let singleImage = imageResult.1 {
                        currentImage = singleImage
                    } else {
                        currentImage = PTAppBaseConfig.share.defaultPlaceholderImage
                    }
                }
            } else {
                currentImage = PTAppBaseConfig.share.defaultPlaceholderImage
            }
            cell.imageView.image = currentImage
            // 对冲数据判断
            if itemIndex <= (self.titles.count - 1) {
                cell.title = self.titles[itemIndex]
            } else {
                cell.title = ""
            }
        }
    }
    
    func collectionViewSetData() {
        pageScrollerView.removeSubviews()
        for i in 0..<totalItemsCount {
            let cell = PTCycleScrollViewCell()
            cell.titleFont = self.font
            cell.titleLabelTextColor = self.textColor
            cell.titleBackViewBackgroundColor = self.titleBackgroundColor
            cell.titleLines = self.numberOfLines
            // Leading
            cell.titleLabelLeading = self.titleLeading
            cell.tag = 100 + i
            let tap = UITapGestureRecognizer { sender in
                if self.didSelectItemAtIndexClosure != nil {
                    self.didSelectItemAtIndexClosure!(self.pageControlIndexWithCurrentCellIndex(index: self.currentIndex()))
                }
            }
            cell.addGestureRecognizer(tap)
            // Only Title
            pageScrollerView.addSubview(cell)
            switch self.scrollDirection {
            case .horizontal:
                cell.snp.makeConstraints { make in
                    make.left.equalTo(CGFloat(i) * self.frame.width)
                    make.top.equalTo(0)
                    make.width.equalTo(self.frame.width)
                    make.height.equalTo(self.frame.height)
                }
            default:
                cell.snp.makeConstraints { make in
                    make.left.equalTo(0)
                    make.top.equalTo(CGFloat(i) * self.frame.height)
                    make.width.equalTo(self.frame.width)
                    make.height.equalTo(self.frame.height)
                }
                self.maxSwipeSize = CGFloat(self.imagePaths.count) * self.frame.height
            }
        }
        setCellData()
        switch self.scrollDirection {
        case .horizontal:
            pageScrollerView.contentSize = CGSize(width: self.maxSwipeSize, height: self.frame.height)
        default:
            pageScrollerView.contentSize = CGSize(width: self.frame.width, height: self.maxSwipeSize)
        }
    }
}

// MARK: 定时器模块
extension PTCycleScrollView {
    /// 添加DTimer
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
//        let p_dtimer = DispatchSource.makeTimerSource()
//        p_dtimer.schedule(deadline: .now()+autoScrollTimeInterval, repeating: autoScrollTimeInterval)
//        p_dtimer.setEventHandler {
//            PTGCDManager.gcdGobal(qosCls: .background) {
//                PTGCDManager.gcdMain {
//                    self.automaticScroll()
//                }
//            }
//        }
//        // 继续
//        p_dtimer.resume()
//
//        dtimer = p_dtimer
    }
    
    /// 关闭倒计时
    public func invalidateTimer() {
        timer?.invalidate()
        timer = nil
//        dtimer?.cancel()
//        dtimer = nil
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
        switch customPageControlStyle {
        case .fill:
            (customPageControl as? PTFilledPageControl)?.progress = CGFloat(newIndex)
        case .pill:
            (customPageControl as? PTPillPageControl)?.progress = CGFloat(newIndex)
        case .snake:
            (customPageControl as? PTSnakePageControl)?.progress = CGFloat(newIndex)
        case .scrolling:
            (customPageControl as? PTScrollingPageControl)?.progress = CGFloat(newIndex)
        case .none,.system,.image:
            (customPageControl as? UIPageControl)?.currentPage = newIndex
        default:
            break
        }
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
    open func scrollByDirection(_ gestureRecognizer: UITapGestureRecognizer) {
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
        if scrollToClosure != nil {
            scrollToClosure!(indexOnPageControl)
        }
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
        if self.scrollFromClosure != nil {
            self.scrollFromClosure!(indexOnPageControl)
        }
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
