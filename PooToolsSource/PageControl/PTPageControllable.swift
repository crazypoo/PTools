//
//  PTPageControllable.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 5/14/25.
//  Copyright © 2025 crazypoo. All rights reserved.
//

import UIKit

@MainActor
private final class PTPageControlDisplayLinkProxy: NSObject {
    weak var owner: PTBasePageControl?

    init(owner: PTBasePageControl) {
        self.owner = owner
    }

    @objc func tick() {
        owner?.updateDisplayLink()
    }
}

@MainActor
@objcMembers
open class PTBasePageControl: UIControl {
    
    // MARK: - 核心数据属性
    open var pageCount: Int = 0 {
        didSet {
            let safeCount = max(0, pageCount)
            if pageCount != safeCount {
                pageCount = safeCount
                return
            }

            stopProgressAnimation()
            if pageCount == 0 {
                setProgressStorage(0)
            } else {
                setProgressStorage(normalizedProgress(progress))
            }
            updateNumberOfPages(pageCount)
            applyVisualProgress(normalizedProgress(progress))
            updateAccessibilityValue()
        }
    }
    
    open var progress: CGFloat = 0 {
        didSet {
            let safeProgress = normalizedProgress(progress)
            if progress != safeProgress {
                setProgressStorage(safeProgress)
                return
            }
            guard !isUpdatingProgressStorage else { return }
            stopProgressAnimation()
            applyVisualProgress(safeProgress)
        }
    }
    
    open var currentPage: Int {
        guard pageCount > 0, progress.isFinite else { return 0 }
        return max(0, min(Int(round(progress)), pageCount - 1))
    }
    
    // MARK: - 核心外观属性
    open var activeTint: UIColor = .white {
        didSet { updateAppearance() }
    }
    
    open var inactiveTint: UIColor = UIColor(white: 1, alpha: 0.3) {
        didSet { updateAppearance() }
    }
    
    open var indicatorPadding: CGFloat = 8 {
        didSet {
            guard indicatorPadding.isFinite, indicatorPadding >= 0 else {
                indicatorPadding = oldValue
                return
            }
            updateLayout()
        }
    }
    
    open var indicatorRadius: CGFloat = 4 {
        didSet {
            guard indicatorRadius.isFinite, indicatorRadius >= 0 else {
                indicatorRadius = oldValue
                return
            }
            updateLayout()
        }
    }
    
    public var indicatorDiameter: CGFloat {
        indicatorRadius * 2
    }

    private var visualProgress: CGFloat = 0
    private var startProgress: CGFloat = 0
    private var targetProgress: CGFloat = 0
    private var progressStartTime: CFTimeInterval = 0
    private var displayLink: CADisplayLink?
    private var displayLinkProxy: PTPageControlDisplayLinkProxy?
    private var isUpdatingProgressStorage = false

    /// English: Shared progress animation and lifecycle boundary for every custom page control.
    /// Español: Límite compartido de animación y ciclo de vida para cada control de páginas personalizado.
    /// 中文：为所有自定义 PageControl 统一提供进度动画和生命周期边界。
    open var progressAnimationDuration: CFTimeInterval { 0.3 }
    
    // MARK: - 生命周期
    override public init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
        setupBaseAccessibility()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
        setupBaseAccessibility()
    }
    
    open func commonInit() {
        // 供子类重写：初始化配置
    }
    
    // MARK: - 模板方法 (坑位，供子类重写具体逻辑)
    open func updateNumberOfPages(_ count: Int) {}
    open func updateProgress(_ safeProgress: CGFloat) {}
    open func updateAppearance() {}
    open func updateLayout() {}
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        updateLayout()
    }

    open override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil {
            stopProgressAnimation()
        }
    }

    /// English: Keep accessibility state and Reduce Motion changes in one shared boundary.
    /// Español: Mantiene el estado de accesibilidad y los cambios de Reducir movimiento en un único límite compartido.
    /// 中文：在统一边界内维护无障碍状态和“减弱动态效果”变化。
    private func setupBaseAccessibility() {
        isAccessibilityElement = true
        accessibilityTraits.insert(.adjustable)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleReduceMotionChange),
                                               name: UIAccessibility.reduceMotionStatusDidChangeNotification,
                                               object: nil)
        updateAccessibilityValue()
    }

    @objc private func handleReduceMotionChange() {
        guard UIAccessibility.isReduceMotionEnabled else { return }
        stopProgressAnimation()
        applyVisualProgress(normalizedProgress(progress))
    }

    open func setProgress(_ newProgress: CGFloat, animated: Bool) {
        guard pageCount > 0 else {
            setProgressStorage(0)
            return
        }

        let safeProgress = normalizedProgress(newProgress)
        if !animated || UIAccessibility.isReduceMotionEnabled || abs(safeProgress - visualProgress) < CGFloat.ulpOfOne {
            stopProgressAnimation()
            setProgressStorage(safeProgress)
            applyVisualProgress(safeProgress)
            return
        }

        startProgress = visualProgress
        targetProgress = safeProgress
        progressStartTime = CACurrentMediaTime()
        setProgressStorage(safeProgress, preservingAnimation: true)
        startProgressAnimation()
    }

    @objc fileprivate func updateDisplayLink() {
        guard progressAnimationDuration > 0, progressAnimationDuration.isFinite else {
            stopProgressAnimation()
            applyVisualProgress(targetProgress)
            return
        }

        let elapsed = CACurrentMediaTime() - progressStartTime
        let percent = max(0, min(1, CGFloat(elapsed / progressAnimationDuration)))
        let easePercent = percent < 0.5
            ? 2 * percent * percent
            : -1 + (4 - 2 * percent) * percent
        applyVisualProgress(startProgress + (targetProgress - startProgress) * easePercent)

        if percent >= 1 {
            stopProgressAnimation()
        }
    }

    private func normalizedProgress(_ value: CGFloat) -> CGFloat {
        guard pageCount > 0, value.isFinite else { return 0 }
        return max(0, min(value, CGFloat(pageCount - 1)))
    }

    private func setProgressStorage(_ value: CGFloat, preservingAnimation: Bool = false) {
        isUpdatingProgressStorage = true
        progress = normalizedProgress(value)
        isUpdatingProgressStorage = false
        if !preservingAnimation {
            visualProgress = normalizedProgress(value)
        }
    }

    private func applyVisualProgress(_ value: CGFloat) {
        visualProgress = normalizedProgress(value)
        updateProgress(visualProgress)
        updateAccessibilityValue()
    }

    private func startProgressAnimation() {
        stopProgressAnimation()
        let proxy = PTPageControlDisplayLinkProxy(owner: self)
        displayLinkProxy = proxy
        let link = CADisplayLink(target: proxy, selector: #selector(PTPageControlDisplayLinkProxy.tick))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    fileprivate func stopProgressAnimation() {
        displayLink?.invalidate()
        displayLink = nil
        displayLinkProxy = nil
    }

    private func updateAccessibilityValue() {
        guard pageCount > 0 else {
            accessibilityValue = nil
            return
        }
        accessibilityValue = "\(currentPage + 1)/\(pageCount)"
    }

    open override func accessibilityIncrement() {
        guard pageCount > 0 else { return }
        let nextPage = min(currentPage + 1, pageCount - 1)
        guard nextPage != currentPage else { return }
        setProgress(CGFloat(nextPage), animated: true)
        sendActions(for: .valueChanged)
    }

    open override func accessibilityDecrement() {
        guard pageCount > 0 else { return }
        let previousPage = max(currentPage - 1, 0)
        guard previousPage != currentPage else { return }
        setProgress(CGFloat(previousPage), animated: true)
        sendActions(for: .valueChanged)
    }

    deinit {
        NotificationCenter.default.removeObserver(self,
                                                   name: UIAccessibility.reduceMotionStatusDidChangeNotification,
                                                   object: nil)
        MainActor.gcdRunUnsafely {
            self.displayLink?.invalidate()
        }
    }
    
    // MARK: - 🚀 高频数学工具箱 (基类赋能)
    
    /// 计算水平居中的起点 X
    public func getStartX(totalWidth: CGFloat) -> CGFloat {
        return max(0, (bounds.width - totalWidth) / 2)
    }
    
    /// 计算垂直居中的起点 Y
    public func getYCenter(itemHeight: CGFloat) -> CGFloat {
        return max(0, (bounds.height - itemHeight) / 2)
    }
    
    /// 统一的点击页码推算逻辑
    public func getTargetPage(for touchLocation: CGPoint, totalWidth: CGFloat, unitWidth: CGFloat) -> Int {
        guard pageCount > 1,
              totalWidth.isFinite,
              unitWidth.isFinite,
              unitWidth > 0 else { return currentPage }
        let startX = getStartX(totalWidth: totalWidth)
        let relativeX = touchLocation.x - startX
        let target = Int(round(relativeX / unitWidth))
        return max(0, min(target, pageCount - 1))
    }
}

@MainActor
public protocol PTPageControllable : AnyObject {
    var currentPage: Int { get }
    func setCurrentPage(index: Int)
    func update(currentPage: Int, totalPages: Int)
}

@MainActor
public protocol PTPageProgressControllable: PTPageControllable {
    func setProgress(_ progress: CGFloat, animated: Bool)
}

extension UIPageControl: @MainActor PTPageControllable {
    public func setCurrentPage(index: Int) {
        self.currentPage = max(0, min(index, max(0, numberOfPages - 1)))
    }
    
    public func update(currentPage: Int, totalPages: Int) {
        self.numberOfPages = max(0, totalPages)
        self.currentPage = max(0, min(currentPage, max(0, self.numberOfPages - 1)))
    }
}

extension PTImagePageControl: @MainActor PTPageControllable {
    public func setCurrentPage(index: Int) {
        self.progress = CGFloat(index)
    }
    
    public func update(currentPage: Int, totalPages: Int) {
        self.pageCount = totalPages
        self.progress = CGFloat(currentPage)
    }
}

extension PTFilledPageControl: @MainActor PTPageProgressControllable {
    public func setCurrentPage(index: Int) {
        self.progress = CGFloat(index)
    }
    
    public func update(currentPage: Int, totalPages: Int) {
        self.pageCount = totalPages
        self.progress = CGFloat(currentPage)
    }
}

extension PTPillPageControl: @MainActor PTPageProgressControllable {
    public func setCurrentPage(index: Int) {
        self.setProgress(CGFloat(index), animated: true)
    }
    
    public func update(currentPage: Int, totalPages: Int) {
        self.pageCount = totalPages
        self.setProgress(CGFloat(currentPage), animated: true)
    }
}

extension PTSnakePageControl: @MainActor PTPageProgressControllable {
    public func setCurrentPage(index: Int) {
        self.setProgress(CGFloat(index), animated: true)
    }
    
    public func update(currentPage: Int, totalPages: Int) {
        self.pageCount = totalPages
        self.setProgress(CGFloat(currentPage), animated: true)
    }
}

extension PTScrollingPageControl: @MainActor PTPageProgressControllable {
    public func setCurrentPage(index: Int) {
        self.setProgress(CGFloat(index), animated: true)
    }
    
    public func update(currentPage: Int, totalPages: Int) {
        self.pageCount = totalPages
        self.setProgress(CGFloat(currentPage), animated: true)
    }
}
