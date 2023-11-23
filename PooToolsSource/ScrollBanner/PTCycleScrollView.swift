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
    // MARK: DataSource
    
    /// 图片地址
    open var imagePaths: Array<Any> = [] {
        didSet {
            self.setTotalItemsMinItems(count:imagePaths.count)
            if imagePaths.count > 1 {
                collectionView.contentCollectionView.isScrollEnabled = true
                if autoScroll {
                    setupTimer()
                }
            } else {
                collectionView.contentCollectionView.isScrollEnabled = false
                invalidateTimer()
            }
            
            collectionViewSetData()

            setupPageControl()
        }
    }
    
    /// 标题
    open var titles: Array<String> = [] {
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
    
    /// 加载图片时的Placeholder
    open var placeHolderImage: UIImage? = nil {
        didSet {
            if placeHolderImage != nil {
                placeHolderViewImage = placeHolderImage
            }
        }
    }
    
    // MARK: ImageView

    /// 没图片时的图片
    open var coverImage: UIImage? = nil {
        didSet {
            if coverImage != nil {
                coverViewImage = coverImage
            }
        }
    }
    
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
            setupPageControl()
        }
    }
    /// 选中颜色
    open var pageControlCurrentPageColor: UIColor = UIColor.white {
        didSet {
            setupPageControl()
        }
    }
    
    ///  圆角(.fill,.snake)
    open var fillPageControlIndicatorRadius: CGFloat = 4 {
        didSet {
            setupPageControl()
        }
    }
    
    /// 选中颜色(.pill,.snake)
    open var customPageControlInActiveTintColor: UIColor = UIColor(white: 1, alpha: 0.3) {
        didSet {
            setupPageControl()
        }
    }
    
    /// 普通图片(.system)
    open var pageControlActiveImage: UIImage? = nil {
        didSet {
            setupPageControl()
        }
    }
    
    /// 选中图片(.system)
    open var pageControlInActiveImage: UIImage? = nil {
        didSet {
            setupPageControl()
        }
    }
    
    // MARK: CustomPageControl
        
    /// 自定义Pagecontrol风格(.fill,.pill,.snake)
    open var customPageControlStyle: PageControlStyle = .system {
        didSet {
            setupPageControl()
        }
    }
    
    /// 自定义Pagecontrol普通颜色
    open var customPageControlTintColor: UIColor = UIColor.white {
        didSet {
            setupPageControl()
        }
    }
    /// 自定义Pagecontrol点阵边距
    open var customPageControlIndicatorPadding: CGFloat = 8 {
        didSet {
            setupPageControl()
        }
    }
    
    /// pagecontrol的展示方位(左,中,右)
    open var pageControlPosition: PageControlPosition = .center {
        didSet {
            setupPageControl()
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
    
    /// 开启/关闭URL特殊字符处理
    open var isAddingPercentEncodingForURLString: Bool = false
    
    open var iCloudDocument:String = ""
    
    // MARK: - Private
    
    /// 注意： 由于属性较多，所以请使用style对应的属性，如果没有标明则通用
    /// PageControl
    fileprivate var pageControl: UIPageControl?

    /// Custom PageControl
    fileprivate var customPageControl: UIView?

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
    open lazy var collectionView: PTCollectionView = {
        
        let cConfig = PTCollectionViewConfig()
        cConfig.viewType = .Custom
        cConfig.collectionViewBehavior = .paging
        cConfig.showsVerticalScrollIndicator = false
        cConfig.showsHorizontalScrollIndicator = false

        let view = PTCollectionView(viewConfig: cConfig)
        view.customerLayout = { sectionModel in
            switch self.scrollDirection {
            case .horizontal:
                var bannerGroupSize : NSCollectionLayoutSize
                var customers = [NSCollectionLayoutGroupCustomItem]()
                var groupW:CGFloat = 0
                let screenW:CGFloat = self.frame.size.width
                var cellHeight:CGFloat = self.frame.size.height
                sectionModel.rows.enumerated().forEach { (index,model) in
                    let customItem = NSCollectionLayoutGroupCustomItem.init(frame: CGRect.init(x: CGFloat(index) * screenW, y: 0, width: screenW, height: cellHeight), zIndex: 1000+index)
                    customers.append(customItem)
                    groupW += screenW
                }
                bannerGroupSize = NSCollectionLayoutSize.init(widthDimension: NSCollectionLayoutDimension.absolute(groupW), heightDimension: NSCollectionLayoutDimension.absolute(cellHeight))
                return NSCollectionLayoutGroup.custom(layoutSize: bannerGroupSize, itemProvider: { layoutEnvironment in
                    customers
                })
            case .vertical:
                var bannerGroupSize : NSCollectionLayoutSize
                var customers = [NSCollectionLayoutGroupCustomItem]()
                var groupH:CGFloat = 0
                let screenW:CGFloat = self.frame.size.width
                var cellHeight:CGFloat = self.frame.size.height
                sectionModel.rows.enumerated().forEach { (index,model) in
                    let customItem = NSCollectionLayoutGroupCustomItem.init(frame: CGRect.init(x: 0, y: groupH, width: screenW, height: cellHeight), zIndex: 1000+index)
                    customers.append(customItem)
                    groupH += cellHeight
                }
                bannerGroupSize = NSCollectionLayoutSize.init(widthDimension: NSCollectionLayoutDimension.absolute(screenW), heightDimension: NSCollectionLayoutDimension.absolute(groupH))
                return NSCollectionLayoutGroup.custom(layoutSize: bannerGroupSize, itemProvider: { layoutEnvironment in
                    customers
                })
            default:
                return NSCollectionLayoutGroup.init(layoutSize: NSCollectionLayoutSize.init(widthDimension: NSCollectionLayoutDimension.absolute(0), heightDimension: NSCollectionLayoutDimension.absolute(0)))
            }
        }
        view.cellInCollection = { collection,sectionModel,indexPath in
            let cell: PTCycleScrollViewCell = collection.dequeueReusableCell(withReuseIdentifier: PTCycleScrollViewCell.ID, for: indexPath) as! PTCycleScrollViewCell
            // Setting
            cell.titleFont = self.font
            cell.titleLabelTextColor = self.textColor
            cell.titleBackViewBackgroundColor = self.titleBackgroundColor
            cell.titleLines = self.numberOfLines
            
            // Leading
            cell.titleLabelLeading = self.titleLeading
            
            // Only Title
            if self.isOnlyTitle && self.titles.count > 0 {
                cell.titleLabelHeight = self.cellHeight
                
                let itemIndex = self.pageControlIndexWithCurrentCellIndex(index: indexPath.item)
                cell.title = self.titles[itemIndex]
            } else {
                // Mode
                if let imageViewContentMode = self.imageViewContentMode {
                    cell.imageView.contentMode = imageViewContentMode
                }
                
                // 0==count 占位图
                if self.imagePaths.count == 0 {
                    cell.imageView.image = self.coverViewImage
                } else {
                    let itemIndex = self.pageControlIndexWithCurrentCellIndex(index: indexPath.item)
                    let imagePath = self.imagePaths[itemIndex]
                    
                    cell.imageView.loadImage(contentData: imagePath,iCloudDocumentName: self.iCloudDocument,emptyImage: self.coverViewImage)
                    
                    // 对冲数据判断
                    if itemIndex <= self.titles.count-1 {
                        cell.title = self.titles[itemIndex]
                    } else {
                        cell.title = ""
                    }
                }
            }
            return cell
        }
        view.collectionDidSelect = { collection,sectionModel,indexPath in
            if self.didSelectItemAtIndexClosure != nil {
                self.didSelectItemAtIndexClosure!(self.pageControlIndexWithCurrentCellIndex(index: indexPath.item))
            }
        }
        view.collectionViewDidScroll = { collection in
            if self.imagePaths.count == 0 { return }
            self.calcScrollViewToScroll(collection)
            
            if self.scrollViewDidScrollClosure != nil {
                var offSet: CGFloat = 0
                var index: NSInteger = 1
                switch self.scrollDirection {
                case .horizontal:
                    index = self.collectionView.contentCollectionView.indexPath(for: self.collectionView.contentCollectionView.visibleCells.first!)!.row
                    offSet = self.collectionView.contentCollectionView.contentOffset.x -  self.frame.size.width * CGFloat(index)
                case .vertical:
                    index = self.collectionView.contentCollectionView.indexPath(for: self.collectionView.contentCollectionView.visibleCells.first!)!.row
                    offSet = self.collectionView.contentCollectionView.contentOffset.y - self.frame.size.height * CGFloat(index)
                default:
                    break
                }
                
                let currentIndex = self.pageControlIndexWithCurrentCellIndex(index: NSInteger(index))
                self.scrollViewDidScrollClosure!(currentIndex,offSet)
            }
        }
        
        view.collectionWillBeginDragging = { collection in
            self.cycleScrollViewScrollToIndex()
            if self.autoScroll {
                self.invalidateTimer()
            }
            
            let indexOnPageControl = self.pageControlIndexWithCurrentCellIndex(index: self.currentIndex())
            if self.scrollFromClosure != nil {
                self.scrollFromClosure!(indexOnPageControl)
            }
        }
        view.collectionDidEndDragging = { collection,decelerate in
            if self.imagePaths.count == 0 { return }
            
            // 滚动后的回调协议
            if !decelerate { self.cycleScrollViewScrollToIndex() }
            
            if self.autoScroll {
                self.setupTimer()
            }
        }
        view.collectionDidEndDecelerating = { collection in
            self.cycleScrollViewScrollToIndex()
        }
        view.collectionDidEndScrollingAnimation = { collection in
            if self.imagePaths.count == 0 { return }
            
            self.cycleScrollViewScrollToIndex()
            
            if self.dtimer == nil && self.autoScroll {
                self.setupTimer()
            }
        }
        return view
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
        addSubview(collectionView)
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
            leftImageView.loadImage(contentData: ali.first!,iCloudDocumentName: self.iCloudDocument,emptyImage: self.coverViewImage)
            leftImageView.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(self.scrollByDirection(_:))))
            self.addSubview(leftImageView)
            
            let rightImageView = UIImageView.init(frame: alf.last!)
            rightImageView.contentMode = .right
            rightImageView.tag = 1
            rightImageView.isUserInteractionEnabled = true
            rightImageView.loadImage(contentData: ali.last!,iCloudDocumentName: self.iCloudDocument,emptyImage: self.coverViewImage)
            rightImageView.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(self.scrollByDirection(_:))))
            self.addSubview(rightImageView)
        }
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
            (customPageControl as! PTFilledPageControl).indicatorRadius = fillPageControlIndicatorRadius
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
            (customPageControl as! PTSnakePageControl).indicatorRadius = fillPageControlIndicatorRadius
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
        
        calcScrollViewToScroll(collectionView.contentCollectionView)
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
            
            self.collectionViewSetData() { collection in
                PTGCDManager.gcdAfter(time: 0.5, block: {
                    let index = self.collectionView.contentCollectionView.indexPath(for: self.collectionView.contentCollectionView.visibleCells.first!)!.row
                    if index == 0 && self.imagePaths.count > 0 {
                        self.collectionView.contentCollectionView.scrollToItem(at: IndexPath.init(item: 0, section: 0), at: self.position, animated: false)
                    }
                })
            }
        }
    }
    
    func collectionViewSetData(finishTask:((UICollectionView)->Void)? = nil) {
        var rows = [PTRows]()
        for _ in 0..<totalItemsCount {
            let row = PTRows(cls:PTCycleScrollViewCell.self,ID: PTCycleScrollViewCell.ID)
            rows.append(row)
        }
        let section = PTSection(rows:rows)
        collectionView.showCollectionDetail(collectionData: [section],finishTask: finishTask)
    }
}

// MARK: 定时器模块
extension PTCycleScrollView {
    /// 添加DTimer
    func setupTimer() {
        // 仅一张图不进行滚动操纵
        if imagePaths.count <= 1 { return }
        
        invalidateTimer()
        
        let p_dtimer = DispatchSource.makeTimerSource()
        p_dtimer.schedule(deadline: .now()+autoScrollTimeInterval, repeating: autoScrollTimeInterval)
        p_dtimer.setEventHandler {
            PTGCDManager.gcdGobal(qosCls: .background) {
                PTGCDManager.gcdMain {
                    self.automaticScroll()
                }
            }
        }
        // 继续
        p_dtimer.resume()
        
        dtimer = p_dtimer
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
    /// - Parameter targetIndex: 下标-Index
    func scollToIndex(targetIndex: Int) {
        if targetIndex >= totalItemsCount {
            if infiniteLoop {
                collectionView.contentCollectionView.scrollToItem(at: IndexPath.init(item: Int(0), section: 0), at: position, animated: true)
            }
            return
        }
        collectionView.contentCollectionView.scrollToItem(at: IndexPath.init(item: targetIndex, section: 0), at: position, animated: true)
    }
    
    /// 当前位置
    /// - Returns: 下标-Index
    func currentIndex() -> NSInteger {
        if collectionView.pt.jx_width == 0 || collectionView.pt.jx_height == 0 {
            return 0
        }
        let index = collectionView.contentCollectionView.indexPath(for: collectionView.contentCollectionView.visibleCells.first!)!.row
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
    @objc open func scrollByDirection(_ gestureRecognizer: UITapGestureRecognizer) {
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
                        collectionView.contentCollectionView.scrollToItem(at: IndexPath.init(item: Int(totalItemsCount/2), section: 0), at: position, animated: false)
                    } else {
                        currentOffsetX = maxSwipeSize + currentOffsetX
                    }
                }
                if currentOffsetX >= CGFloat(imagePaths.count) * scrollView.frame.size.width && infiniteLoop{
                    collectionView.contentCollectionView.scrollToItem(at: IndexPath.init(item: Int(totalItemsCount/2), section: 0), at: position, animated: false)
                }
                progress = currentOffsetX / scrollView.frame.size.width
            case .vertical:
                var currentOffsetY = scrollView.contentOffset.y - (CGFloat(totalItemsCount) * scrollView.frame.size.height) / 2
                if currentOffsetY < 0 {
                    if currentOffsetY >= -scrollView.frame.size.height{
                        currentOffsetY = CGFloat(indexOnPageControl) * scrollView.frame.size.height
                    } else if currentOffsetY <= -maxSwipeSize{
                        collectionView.contentCollectionView.scrollToItem(at: IndexPath.init(item: Int(totalItemsCount/2), section: 0), at: position, animated: false)
                    } else {
                        currentOffsetY = maxSwipeSize + currentOffsetY
                    }
                }
                if currentOffsetY >= CGFloat(imagePaths.count) * scrollView.frame.size.height && infiniteLoop{
                    collectionView.contentCollectionView.scrollToItem(at: IndexPath.init(item: Int(totalItemsCount/2), section: 0), at: position, animated: false)
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