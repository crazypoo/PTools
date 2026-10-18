//
//  PTGuidePageHUD.swift
//  Diou
//
//  Created by ken lam on 2021/10/16.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit
#if canImport(PToolsConstraintLayout)
import PToolsConstraintLayout
#endif
import AVKit
import SnapKit
import Kingfisher
#if SWIFT_PACKAGE
import ptools
import PooToolsPageControl
#endif

public enum PTGuidePageControlSelection {
    case none
    case pageControl(type: PTGuidePageControlOption)
    
    public enum PTGuidePageControlOption {
        case system, fill, pill, snake, image, scrolling
    }
}

/*
 Guide初始配置
 */
@MainActor
@objcMembers
public class PTGuidePageModel: NSObject {
    
    /// 是否显示开始体验
    public var tapHidden: Bool = false
    /// 图片数组
    public var imageArrays: [Any] = []
    /// 展示在哪个View上
    public var mainView: UIView = UIView()
    /// 是否显示Pagecontrol
    public var pageControl: PTGuidePageControlSelection = .pageControl(type: .system)
    /// 是否显示跳过按钮
    public var skipShow: Bool = false
    /// 上一张按钮图片
    public var forwardImage: Any?
    /// 下一张按钮图片
    public var backImage: Any?
    /// 开始体验按钮背景
    public var startBackgroundImage: UIImage = UIColor.randomColor.createImageWithColor()
    /// 开始体验按钮字体颜色
    public var startTextColor: UIColor = UIColor.randomColor
    /// iCloud文件夹名字
    public var iCloudDocumentName: String = ""
    /// 未选中颜色
    public var pageControlTintColor: UIColor = UIColor.lightGray
    /// 选中颜色
    public var pageControlCurrentPageColor: UIColor = UIColor.white
    /// 圆角(.fill, .snake)
    public var fillPageControlIndicatorRadius: CGFloat = 4
    /// 选中颜色(.pill, .snake)
    public var customPageControlInActiveTintColor: UIColor = UIColor(white: 1, alpha: 0.3)
    
    // 🌟 修复 2：移除了单独的 @MainActor，因为整个类已经是主线程隔离的了
    
    /// 普通图片(.system)
    public var pageControlActiveImage: Any = Bundle.podBundleImage(bundleName: CorePodBundleName, imageName: "lldotActive")
    /// 选中图片(.system)
    public var pageControlInActiveImage: Any = Bundle.podBundleImage(bundleName: CorePodBundleName, imageName: "lldotInActive")
    
    /// 自定义Pagecontrol普通颜色
    public var customPageControlTintColor: UIColor = UIColor.white
    /// 自定义Pagecontrol点阵边距
    public var customPageControlIndicatorPadding: CGFloat = 8
    
    // 🌟 修复 3：同样移除了这里单独的 @MainActor
    public var skipName: String = "PT Button skip".localized()
    public var skipFont: UIFont = .appfont(size: 14)
    public var startString: String = "PT Guide start".localized()
    public var startFont: UIFont = .appfont(size: 21)
}

@objcMembers
public class PTGuidePageHUD: UIView {
    fileprivate var imageArray: [Any]?
    fileprivate var imagePageControl: UIView?
    fileprivate var player = AVPlayerViewController()
    private var contentImageViews: [UIImageView] = []
    private var pageLayoutSignature: String?
    private var isUpdatingPageLayout = false
    
    // 记录右滑跳过的状态
    fileprivate var isSlidingOut: Bool = false
    
    public var slideInto: Bool = false // 优化：去除可选类型，提供默认值 false
    public var animationTime: CGFloat = 3.0
    public var adHadRemove: PTActionTask?
        
    lazy var forwardButton: UIButton = {
        let btn = UIButton(type: .custom)
        if #available(iOS 26.0, *) {
            btn.configuration = UIButton.Configuration.clearGlass()
        }
        return btn
    }()
    
    lazy var nextButton: UIButton = {
        let btn = UIButton(type: .custom)
        if #available(iOS 26.0, *) {
            btn.configuration = UIButton.Configuration.clearGlass()
        }
        return btn
    }()
    
    fileprivate var viewModel = PTGuidePageModel()
    
    lazy var guidePageView: UIScrollView = {
        let view = UIScrollView()
        view.backgroundColor = .lightGray
        view.bounces = true // 优化：为了实现滑出效果，需要允许 bounce
        view.isPagingEnabled = true
        view.showsHorizontalScrollIndicator = false
        view.delegate = self
        return view
    }()
    
    lazy var skipButton: UIButton = {
        let view = UIButton(type: .custom)
        if #available(iOS 26.0, *) {
            view.configuration = UIButton.Configuration.clearGlass()
        } else {
            view.backgroundColor = .gray
        }
        view.setTitleColor(.white, for: .normal)
        view.addActionHandlers { [weak self] sender in // 修复：弱引用 self
            self?.buttonClick(sender: sender)
        }
        return view
    }()
    
    public init(viewModel: PTGuidePageModel) {
        super.init(frame: viewModel.mainView.frame)
        self.viewModel = viewModel
        
        if viewModel.tapHidden {
            imageArray = viewModel.imageArrays
        } else {
            imageArray = viewModel.imageArrays
        }
        
        setupViews()
    }
    
    public init(mainView: UIView, videlURL: URL) {
        super.init(frame: mainView.frame)
        setupVideoView(videlURL: videlURL)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Setup UI
fileprivate extension PTGuidePageHUD {
    
    func setupViews() {
        guidePageView.contentSize = .zero
        addSubviews([guidePageView, skipButton])
        
        guidePageView.ptLayout.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        setupSkipButton()
        setupPageControl()
        setupContentImages()
        setupBottomButtons()
    }
    
    func setupVideoView(videlURL: URL) {
        player.player = AVPlayer(url: videlURL)
        player.showsPlaybackControls = false
        player.entersFullScreenWhenPlaybackBegins = true
        addSubview(player.view)
        
        player.view.ptLayout.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        player.player?.play()
        
        let movieStartButton = UIButton(type: .custom)
        movieStartButton.layer.borderWidth = 1
        movieStartButton.layer.cornerRadius = 20
        movieStartButton.layer.borderColor = UIColor.white.cgColor
        movieStartButton.setTitle(viewModel.startString, for: .normal)
        movieStartButton.titleLabel?.font = viewModel.startFont
        movieStartButton.alpha = 0
        
        player.view.addSubview(movieStartButton)
        movieStartButton.addActionHandlers { [weak self] sender in // 修复：弱引用 self
            self?.buttonClick(sender: sender)
        }
        
        UIView.animate(withDuration: animationTime) {
            movieStartButton.alpha = 1
        }
        
        movieStartButton.ptLayout.makeConstraints { make in
            make.width.equalTo(movieStartButton.sizeFor(height: 50).width + 10)
            make.height.equalTo(50)
            make.centerX.equalTo(self.player.view)
            make.bottom.equalTo(self.player.view.safeAreaLayoutGuide.ptLayout.bottom).offset(-20)
        }
    }
    
    func setupSkipButton() {
        skipButton.setTitle(viewModel.skipName, for: .normal)
        skipButton.titleLabel?.font = viewModel.skipFont
        
        let skipButtonWidthOffset: CGFloat = 15
        
        let skipButtonWidth = UIView.sizeFor(string: viewModel.skipName, font: viewModel.skipFont, height: 44).width + 10 + skipButtonWidthOffset
        
        skipButton.ptLayout.makeConstraints { make in
            make.width.equalTo(skipButtonWidth)
            make.height.equalTo(44)
            make.left.top.equalToSuperview()
        }
        
        skipButton.isHidden = !viewModel.skipShow
        skipButton.isUserInteractionEnabled = viewModel.skipShow
        skipButton.viewCorner(radius: 22)
    }
    
    func setupPageControl() {
        switch viewModel.pageControl {
        case .none: break
        case .pageControl(let type):
            imagePageControl = setPageControlView(type: type)
        }
        
        var pageViews = [UIView]()
        if let control = imagePageControl {
            switch viewModel.pageControl {
            case .none:
                control.isHidden = true
            default:
                control.isHidden = false
            }
            pageViews = [forwardButton, nextButton, control]
        } else {
            pageViews = [forwardButton, nextButton]
        }
        addSubviews(pageViews)
        
        forwardButton.ptLayout.makeConstraints { make in
            make.width.height.equalTo(44)
            make.bottom.equalTo(self.safeAreaLayoutGuide.ptLayout.bottom).offset(-10)
            make.left.equalTo(self.safeAreaLayoutGuide.ptLayout.left).offset(PTAppBaseConfig.share.defaultViewSpace)
        }
        
        nextButton.ptLayout.makeConstraints { make in
            make.width.height.bottom.equalTo(self.forwardButton)
            make.right.equalTo(self.safeAreaLayoutGuide.ptLayout.right).inset(PTAppBaseConfig.share.defaultViewSpace)
        }

        if let control = imagePageControl {
            control.ptLayout.makeConstraints { make in
                make.height.equalTo(20)
                make.centerY.equalTo(self.forwardButton)
                make.left.equalTo(self.forwardButton.ptLayout.right).offset(10)
                make.right.equalTo(self.nextButton.ptLayout.left).offset(-10)
            }
        }
    }
    
    func setupContentImages() {
        viewModel.imageArrays.enumerated().forEach { (index, value) in
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFit
            imageView.loadImage(contentData: value, iCloudDocumentName: viewModel.iCloudDocumentName)
            guidePageView.addSubview(imageView)
            contentImageViews.append(imageView)
            
            imageView.ptLayout.makeConstraints { make in
                make.top.equalToSuperview()
                make.width.equalTo(1)
                make.height.equalTo(1)
                make.left.equalToSuperview()
            }
            
            if index == (viewModel.imageArrays.count - 1) && !viewModel.tapHidden {
                imageView.isUserInteractionEnabled = true
                
                let startButton = UIButton(type: .custom)
                startButton.setTitle(viewModel.startString, for: .normal)
                startButton.setTitleColor(viewModel.startTextColor, for: .normal)
                startButton.titleLabel?.font = viewModel.startFont
                startButton.setBackgroundImage(viewModel.startBackgroundImage, for: .normal)
                startButton.addActionHandlers { [weak self] sender in // 修复：弱引用 self
                    self?.buttonClick(sender: sender)
                }
                
                imageView.addSubview(startButton)
                startButton.ptLayout.makeConstraints { make in
                    make.width.equalTo(startButton.sizeFor(height: 44).width + 10)
                    make.height.equalTo(44)
                    make.centerX.equalTo(imageView)
                    
                    if let control = self.imagePageControl, case .pageControl = viewModel.pageControl {
                        make.bottom.equalTo(control.ptLayout.top).offset(-10)
                    } else {
                        make.centerY.equalTo(self.forwardButton)
                    }
                }
            }
        }
    }
    
    func setupBottomButtons() {
        forwardButton.isHidden = true
        forwardButton.isUserInteractionEnabled = false
        forwardButton.addActionHandlers { [weak self] _ in // 修复：弱引用 self
            guard let self = self else { return }
            if case .pageControl = self.viewModel.pageControl {
                let currentCount = max(self.getPageControlCurrentValue() - 1, 0)
                self.pageControlProgressSet(currentIndex: currentCount)
                if currentCount == 0 {
                    forwardButton.isHidden = true
                    forwardButton.isUserInteractionEnabled = false
                }
            }
            let targetX = max(self.guidePageView.contentOffset.x - self.guidePageView.frame.size.width, 0)
            self.guidePageView.setContentOffset(CGPoint(x: targetX, y: 0), animated: true)
        }
        
        nextButton.addActionHandlers { [weak self] sender in // 修复：弱引用 self
            guard let self = self else { return }
            if case .pageControl = self.viewModel.pageControl {
                let currentCount = self.getPageControlCurrentValue() + 1
                if self.viewModel.imageArrays.count == currentCount {
                    self.buttonClick(sender: sender)
                } else {
                    self.pageControlProgressSet(currentIndex: currentCount)
                    let targetX = self.guidePageView.contentOffset.x + self.guidePageView.frame.size.width
                    self.guidePageView.setContentOffset(CGPoint(x: targetX, y: 0), animated: true)
                }
                self.forwardButton.isHidden = false
                self.forwardButton.isUserInteractionEnabled = true
            }
        }
        
        if let forwardImage = viewModel.forwardImage, let backImage = viewModel.backImage {
            let isMultiPage = viewModel.imageArrays.count > 1
            nextButton.isHidden = !isMultiPage
            nextButton.isUserInteractionEnabled = isMultiPage
            
            nextButton.loadImage(contentData: backImage, iCloudDocumentName: viewModel.iCloudDocumentName)
            forwardButton.loadImage(contentData: forwardImage, iCloudDocumentName: viewModel.iCloudDocumentName)
        } else {
            nextButton.isHidden = true
            nextButton.isUserInteractionEnabled = false
            forwardButton.isHidden = true
            forwardButton.isUserInteractionEnabled = false
        }
    }

    // English: Recalculate pages and controls from the actual HUD bounds after folding, rotation, or safe-area changes.
    // Español: Recalcula páginas y controles usando los bounds reales tras plegado, rotación o cambios del área segura.
    // 中文：在折叠、旋转或安全区变化后，根据 HUD 实际 bounds 重新计算页面和控件。
    private func updatePageLayoutIfNeeded() {
        guard !isUpdatingPageLayout,
              bounds.width > 0,
              bounds.height > 0 else { return }

        let pageWidth = guidePageView.bounds.width
        let pageHeight = guidePageView.bounds.height
        guard pageWidth > 0, pageHeight > 0 else { return }

        let region = PTAdaptiveVisibleRegionResolver.region(for: self, minimumMargin: 4)
        let signature = region.signature + "|\(pageWidth)|\(pageHeight)|\(contentImageViews.count)"
        guard signature != pageLayoutSignature else { return }

        isUpdatingPageLayout = true
        let currentPage = pageWidth > 0
            ? min(max(Int((guidePageView.contentOffset.x / pageWidth).rounded()), 0), max(0, contentImageViews.count - 1))
            : 0
        guidePageView.contentSize = CGSize(width: pageWidth * CGFloat(contentImageViews.count), height: pageHeight)
        for (index, imageView) in contentImageViews.enumerated() {
            imageView.ptLayout.updateConstraints { make in
                make.top.equalToSuperview()
                make.left.equalToSuperview().offset(pageWidth * CGFloat(index))
                make.width.equalTo(pageWidth)
                make.height.equalTo(pageHeight)
            }
        }

        let visibleRect = region.visibleRect
        skipButton.ptLayout.remakeConstraints { make in
            let frame = PTAdaptiveVisibleRegionResolver.controlFrame(size: CGSize(width: skipButtonWidth(), height: 44),
                                                                     in: region,
                                                                     preferred: .trailing,
                                                                     margin: 10)
            make.left.equalToSuperview().offset(frame.minX)
            make.top.equalToSuperview().offset(frame.minY)
            make.width.equalTo(frame.width)
            make.height.equalTo(frame.height)
        }
        forwardButton.ptLayout.remakeConstraints { make in
            make.width.height.equalTo(44)
            make.left.equalToSuperview().offset(visibleRect.minX + PTAppBaseConfig.share.defaultViewSpace)
            make.bottom.equalToSuperview().offset(-(bounds.height - visibleRect.maxY + 10))
        }
        nextButton.ptLayout.remakeConstraints { make in
            make.width.height.equalTo(44)
            make.right.equalToSuperview().offset(-(bounds.width - visibleRect.maxX + PTAppBaseConfig.share.defaultViewSpace))
            make.bottom.equalTo(forwardButton)
        }
        if let control = imagePageControl {
            control.ptLayout.remakeConstraints { make in
                make.height.equalTo(20)
                make.centerY.equalTo(forwardButton)
                make.left.equalTo(forwardButton.ptLayout.right).offset(10)
                make.right.equalTo(nextButton.ptLayout.left).offset(-10)
            }
        }
        guidePageView.layoutIfNeeded()
        guidePageView.setContentOffset(CGPoint(x: pageWidth * CGFloat(currentPage), y: 0), animated: false)
        pageLayoutSignature = signature
        isUpdatingPageLayout = false
    }

    private func skipButtonWidth() -> CGFloat {
        max(44, UIView.sizeFor(string: viewModel.skipName, font: viewModel.skipFont, height: 44).width + 25)
    }
}

// MARK: - Actions & Public Methods
extension PTGuidePageHUD {
    func buttonClick(sender: UIButton?) {
        UIView.animate(withDuration: animationTime) {
            self.alpha = 0
        } completion: { [weak self] _ in // 优化：使用 UIView.animate completion 回调替代 GCD
            self?.removeGuidePageHUD()
        }
    }
    
    public func removeGuidePageHUD() {
        removeFromSuperview()
        adHadRemove?()
    }
    
    public func guideShow() {
        viewModel.mainView.addSubview(self)
        self.ptLayout.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        #if POOTOOLS_DEBUG
        if let windows = viewModel.mainView as? UIWindow {
            let share = LocalConsole.shared
            if share.isVisiable {
                windows.bringSubviewToFront(share.terminal!)
            }
        }
        #endif
    }
    
    fileprivate func pageControlAction(page: Int) {
        guard let images = imageArray else { return }
        
        if images.count > 0 && page == (images.count - 1) && !slideInto {
            // 到达最后一页，但不支持滑动进入，通常不直接 dismiss，由按钮控制
        }
        
        if case .pageControl = viewModel.pageControl {
            self.pageControlProgressSet(currentIndex: page)
        }
        
        if page >= 1 {
            forwardButton.isHidden = false
            forwardButton.isUserInteractionEnabled = true
        } else {
            forwardButton.isHidden = true
            forwardButton.isUserInteractionEnabled = false
        }
    }
}

extension PTGuidePageHUD {
    public override func layoutSubviews() {
        super.layoutSubviews()
        updatePageLayoutIfNeeded()
    }

    public override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        pageLayoutSignature = nil
        setNeedsLayout()
    }
}

// MARK: - UIScrollViewDelegate
extension PTGuidePageHUD: UIScrollViewDelegate {
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let page: Int = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
        pageControlAction(page: page)
    }
    
    // 优化：在此处监听滑动偏移量，修复 slideInto 滑动消失的功能
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard slideInto, let images = imageArray, images.count > 0 else { return }
        
        let maxOffsetX = CGFloat(images.count - 1) * scrollView.frame.size.width
        // 当用户在最后一页继续向右滑动超过一个阈值（例如 30 像素）时，触发跳过
        if scrollView.contentOffset.x > maxOffsetX + 30 {
            if !isSlidingOut {
                isSlidingOut = true
                buttonClick(sender: nil)
            }
        }
    }
}

// MAKR: - PageControl
fileprivate extension PTGuidePageHUD {
    func setPageControlView(type: PTGuidePageControlSelection.PTGuidePageControlOption) -> UIView {
        switch type {
        case .system:
            let view = UIPageControl()
            view.pageIndicatorTintColor = viewModel.pageControlTintColor
            view.currentPageIndicatorTintColor = viewModel.pageControlCurrentPageColor
            view.numberOfPages = viewModel.imageArrays.count // 修正：原生 UIPageControl 是 numberOfPages
            view.currentPage = 0
            view.addPageControlAction(handler: { [weak self] sender in
                guard let self = self else { return }
                self.pageControlTap(currentControl:sender)
            })
            return view
        case .fill:
            let view = PTFilledPageControl(frame: CGRect.zero)
            view.tintColor = viewModel.customPageControlTintColor
            view.indicatorPadding = viewModel.customPageControlIndicatorPadding
            view.indicatorRadius = viewModel.fillPageControlIndicatorRadius
            view.update(currentPage: 0, totalPages: viewModel.imageArrays.count)
            view.addPageControlAction(handler: { [weak self] sender in
                guard let self = self else { return }
                self.pageControlTap(currentControl:sender)
            })
            return view
        case .pill:
            let view = PTPillPageControl(frame: CGRect.zero)
            view.indicatorPadding = viewModel.customPageControlIndicatorPadding
            view.activeTint = viewModel.customPageControlTintColor
            view.inactiveTint = viewModel.customPageControlInActiveTintColor
            view.update(currentPage: 0, totalPages: viewModel.imageArrays.count)
            view.addPageControlAction(handler: { [weak self] sender in
                guard let self = self else { return }
                self.pageControlTap(currentControl:sender)
            })
            return view
        case .snake:
            let view = PTSnakePageControl(frame: CGRect.zero)
            view.activeTint = viewModel.customPageControlTintColor
            view.indicatorPadding = viewModel.customPageControlIndicatorPadding
            view.indicatorRadius = viewModel.fillPageControlIndicatorRadius
            view.inactiveTint = viewModel.customPageControlInActiveTintColor
            view.update(currentPage: 0, totalPages: viewModel.imageArrays.count)
            view.addPageControlAction(handler: { [weak self] sender in
                guard let self = self else { return }
                self.pageControlTap(currentControl:sender)
            })
            return view
        case .image:
            let view = PTImagePageControl()
            view.pageImage = viewModel.pageControlActiveImage
            view.currentPageImage = viewModel.pageControlInActiveImage
            view.update(currentPage: 0, totalPages: viewModel.imageArrays.count)
            view.addPageControlAction(handler: { [weak self] sender in
                guard let self = self else { return }
                self.pageControlTap(currentControl:sender)
            })
            return view
        case .scrolling:
            let view = PTScrollingPageControl()
            view.activeTint = .white
            view.update(currentPage: 0, totalPages: viewModel.imageArrays.count)
            view.addPageControlAction(handler: { [weak self] sender in
                guard let self = self else { return }
                self.pageControlTap(currentControl:sender)
            })
            return view
        }
    }
        
    func pageControlProgressSet(currentIndex: Int) {
        guard let controllable = imagePageControl as? PTPageControllable else {
            // 处理原生的 UIPageControl
            if let sysPageControl = imagePageControl as? UIPageControl {
                sysPageControl.currentPage = currentIndex
            }
            return
        }
        controllable.setCurrentPage(index: currentIndex)
    }
    
    func getPageControlCurrentValue() -> Int {
        if let controllable = imagePageControl as? PTPageControllable {
            return controllable.currentPage
        }
        if let sysPageControl = imagePageControl as? UIPageControl {
            return sysPageControl.currentPage
        }
        return 0
    }
    
    func setPageControlValue(_ value: Int) {
        if let control = imagePageControl as? PTPageControllable {
            control.update(currentPage: value, totalPages: self.viewModel.imageArrays.count)
        } else if let sysPageControl = imagePageControl as? UIPageControl {
            sysPageControl.currentPage = value
        }
    }
    
    func pageControlTap(currentControl:UIControl) {
        var currentPage:CGFloat = 0
        switch currentControl {
        case let system as UIPageControl:
            currentPage = CGFloat(system.currentPage)
        case let fill as PTFilledPageControl:
            currentPage = fill.progress
        case let pill as PTPillPageControl:
            currentPage = pill.progress
        case let snake as PTSnakePageControl:
            currentPage = snake.progress
        case let image as PTImagePageControl:
            currentPage = image.progress
        case let scrol as PTScrollingPageControl:
            currentPage = scrol.progress
        default:break
        }
        let targetX = currentPage * self.guidePageView.bounds.width
        self.guidePageView.setContentOffset(CGPoint(x: targetX, y: 0), animated: true)
        if currentPage >= 1 {
            self.forwardButton.isHidden = false
            self.forwardButton.isUserInteractionEnabled = true
        } else {
            self.forwardButton.isHidden = true
            self.forwardButton.isUserInteractionEnabled = false
        }
    }
}
