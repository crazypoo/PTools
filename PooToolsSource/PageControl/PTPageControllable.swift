//
//  PTPageControllable.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 5/14/25.
//  Copyright © 2025 crazypoo. All rights reserved.
//

import UIKit

import UIKit

@objcMembers
open class PTBasePageControl: UIControl {
    
    // MARK: - 核心数据属性
    open var pageCount: Int = 0 {
        didSet { updateNumberOfPages(pageCount) }
    }
    
    open var progress: CGFloat = 0 {
        didSet {
            guard pageCount > 0 else { return }
            let safeProgress = max(0, min(progress, CGFloat(pageCount - 1)))
            updateProgress(safeProgress)
        }
    }
    
    open var currentPage: Int {
        Int(round(progress))
    }
    
    // MARK: - 核心外观属性
    open var activeTint: UIColor = .white {
        didSet { updateAppearance() }
    }
    
    open var inactiveTint: UIColor = UIColor(white: 1, alpha: 0.3) {
        didSet { updateAppearance() }
    }
    
    open var indicatorPadding: CGFloat = 8 {
        didSet { updateLayout() }
    }
    
    open var indicatorRadius: CGFloat = 4 {
        didSet { updateLayout() }
    }
    
    public var indicatorDiameter: CGFloat {
        indicatorRadius * 2
    }
    
    // MARK: - 生命周期
    override public init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
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
        guard pageCount > 1 else { return currentPage }
        let startX = getStartX(totalWidth: totalWidth)
        let relativeX = touchLocation.x - startX
        let target = Int(round(relativeX / unitWidth))
        return max(0, min(target, pageCount - 1))
    }
}

public protocol PTPageControllable : AnyObject {
    var currentPage: Int { get }
    func setCurrentPage(index: Int)
    func update(currentPage: Int, totalPages: Int)
}

extension UIPageControl: PTPageControllable {
    public func setCurrentPage(index: Int) {
        self.currentPage = index
    }
    
    public func update(currentPage: Int, totalPages: Int) {
        self.currentPage = currentPage
        self.numberOfPages = totalPages
    }
}

extension PTImagePageControl: PTPageControllable {
    public func setCurrentPage(index: Int) {
        self.progress = CGFloat(index)
    }
    
    public func update(currentPage: Int, totalPages: Int) {
        self.progress = CGFloat(currentPage)
        self.pageCount = totalPages
    }
}

extension PTFilledPageControl: PTPageControllable {
    public func setCurrentPage(index: Int) {
        self.progress = CGFloat(index)
    }
    
    public func update(currentPage: Int, totalPages: Int) {
        self.progress = CGFloat(currentPage)
        self.pageCount = totalPages
    }
}

extension PTPillPageControl: PTPageControllable {
    public func setCurrentPage(index: Int) {
        self.setProgress(CGFloat(index), animated: true)
    }
    
    public func update(currentPage: Int, totalPages: Int) {
        self.setProgress(CGFloat(currentPage), animated: true)
        self.pageCount = totalPages
    }
}

extension PTSnakePageControl: PTPageControllable {
    public func setCurrentPage(index: Int) {
        self.setProgress(CGFloat(index), animated: true)
    }
    
    public func update(currentPage: Int, totalPages: Int) {
        self.setProgress(CGFloat(currentPage), animated: true)
        self.pageCount = totalPages
    }
}

extension PTScrollingPageControl: PTPageControllable {
    public func setCurrentPage(index: Int) {
        self.setProgress(CGFloat(index), animated: true)
    }
    
    public func update(currentPage: Int, totalPages: Int) {
        self.setProgress(CGFloat(currentPage), animated: true)
        self.pageCount = totalPages
    }
}
