//
//  UIView+PTEX.swift
//  Diou
//
//  Created by ken lam on 2021/10/20.
//  Copyright © 2021 DO. All rights reserved.
//

#if canImport(UIKit) && (os(iOS) || os(tvOS))
import UIKit
import SnapKit
import WebKit
import Photos
import AVFoundation

@objc public enum Imagegradien:Int {
    case LeftToRight
    case TopToBottom
    case RightToLeft
    case BottomToTop
}

var GLOBAL_BORDER_TRACKERS: [BorderManager] = []
extension UIView: PTProtocolCompatible {}
public typealias LayoutSubviewsCallback = (_ view:UIView) -> Void

private class PTCornerTrackerView: UIView {
    var layoutActions: [String: (CGRect) -> Void] = [:]

    override func layoutSubviews() {
        super.layoutSubviews()
        // 确保尺寸有效时才触发重绘
        // 关键：当尺寸变化时，按顺序执行所有注册的任务
        // 建议先执行背景任务，再执行上层覆盖任务
        layoutActions["Gradient"]?(self.bounds)
        layoutActions["Corner"]?(self.bounds)
        layoutActions["Progress"]?(self.bounds)
    }
}

extension CALayer {
    func bringSublayerToFront(_ layer: CALayer) {
        layer.removeFromSuperlayer()
        self.addSublayer(layer)
    }
}

public extension PTPOP where Base:UIView {
    /// 快捷获取/设置 x 坐标
    var jx_x: CGFloat{
        get {
            base.frame.origin.x
        } set {
            base.frame.origin.x = newValue
        }
    }
    
    /// 快捷获取/设置 y 坐标
    var jx_y: CGFloat{
        get {
            base.frame.origin.y
        } set {
            base.frame.origin.y = newValue
        }
    }
    
    /// 快捷获取/设置 宽度
    var jx_width: CGFloat{
        get {
            base.frame.size.width
        } set {
            base.frame.size.width = newValue
        }
    }
    
    /// 快捷获取/设置 高度
    var jx_height: CGFloat{
        get {
            base.frame.size.height
        } set {
            base.frame.size.height = newValue
        }
    }
    
    /// 获取视图自身的中心点 (相对于自身 bounds)
    var jx_viewCenter: CGPoint{
        get {
            CGPoint(x: jx_width * 0.5, y: jx_height * 0.5)
        }
    }
    
    /// 快捷获取/设置 centerX
    var jx_centerX: CGFloat{
        get {
            jx_width * 0.5
        } set{
            base.center.x = newValue
        }
    }
    
    /// 快捷获取/设置 centerY
    var jx_centerY: CGFloat{
        get {
            jx_height * 0.5
        } set{
            base.center.y = newValue
        }
    }
    
    /// 在父视图中的 Y 轴中心坐标
    var inSuperViewCenterY: CGFloat{
        jx_y + jx_centerY
    }
    
    /// 快捷获取/设置 最大 X 值 (MaxX)
    var maxX: CGFloat{
        get {
            jx_x + jx_width
        } set{
            jx_x = newValue - jx_width
        }
    }
    
    /// 快捷获取/设置 最大 Y 值 (MaxY)
    var maxY: CGFloat{
        get{
            jx_y + jx_height
        }
        set{
            jx_y = newValue - jx_height
        }
    }
}

// MARK: - 核心路径生成器 (复用逻辑)
public extension UIView {
    
    // MARK: - 辅助获取/创建 Tracker 的私有方法
    private func getOrCreateTracker() -> PTCornerTrackerView {
        if let tracker = self.subviews.first(where: { $0 is PTCornerTrackerView }) as? PTCornerTrackerView {
            return tracker
        }
        let newTracker = PTCornerTrackerView()
        newTracker.isUserInteractionEnabled = false
        newTracker.backgroundColor = .clear
        newTracker.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        newTracker.frame = self.bounds
        // 插入在最底层
        self.insertSubview(newTracker, at: 0)
        return newTracker
    }

    /// 私有辅助方法：生成支持独立圆角和胶囊形态的 UIBezierPath
    /// - Parameters:
    ///   - bounds: 视图的边界
    ///   - radius: 统一基础圆角
    ///   - topLeft: 独立的左上圆角
    ///   - topRight: 独立的右上圆角
    ///   - bottomLeft: 独立的左下圆角
    ///   - bottomRight: 独立的右下圆角
    ///   - corner: 需要应用圆角的位置
    ///   - capsule: 是否为胶囊形态
    /// - Returns: 计算好的贝塞尔路径
    private func pt_customCornerPath(bounds: CGRect,
                                     radius: CGFloat,
                                     topLeft: CGFloat,
                                     topRight: CGFloat,
                                     bottomLeft: CGFloat,
                                     bottomRight: CGFloat,
                                     corner: UIRectCorner,
                                     capsule: Bool) -> UIBezierPath {
        var finalTL = radius, finalTR = radius, finalBL = radius, finalBR = radius
        if capsule {
            let r = min(bounds.width, bounds.height) / 2.0
            finalTL = r; finalTR = r; finalBL = r; finalBR = r
        } else if corner != .allCorners {
            finalTL = corner.contains(.topLeft) ? topLeft : 0
            finalTR = corner.contains(.topRight) ? topRight : 0
            finalBL = corner.contains(.bottomLeft) ? bottomLeft : 0
            finalBR = corner.contains(.bottomRight) ? bottomRight : 0
        }
        
        let path = UIBezierPath()
        // 关键改动：使用 bounds.minX 和 bounds.minY
        let minX = bounds.minX; let minY = bounds.minY
        let maxX = bounds.maxX; let maxY = bounds.maxY
        
        path.move(to: CGPoint(x: minX + finalTL, y: minY))
        path.addLine(to: CGPoint(x: maxX - finalTR, y: minY))
        if finalTR > 0 { path.addArc(withCenter: CGPoint(x: maxX - finalTR, y: minY + finalTR), radius: finalTR, startAngle: -CGFloat.pi/2, endAngle: 0, clockwise: true) }
        
        path.addLine(to: CGPoint(x: maxX, y: maxY - finalBR))
        if finalBR > 0 { path.addArc(withCenter: CGPoint(x: maxX - finalBR, y: maxY - finalBR), radius: finalBR, startAngle: 0, endAngle: CGFloat.pi/2, clockwise: true) }
        
        path.addLine(to: CGPoint(x: minX + finalBL, y: maxY))
        if finalBL > 0 { path.addArc(withCenter: CGPoint(x: minX + finalBL, y: maxY - finalBL), radius: finalBL, startAngle: CGFloat.pi/2, endAngle: CGFloat.pi, clockwise: true) }
        
        path.addLine(to: CGPoint(x: minX, y: minY + finalTL))
        if finalTL > 0 { path.addArc(withCenter: CGPoint(x: minX + finalTL, y: minY + finalTL), radius: finalTL, startAngle: CGFloat.pi, endAngle: -CGFloat.pi/2, clockwise: true) }
        
        path.close()
        return path
    }
    
    @objc func viewCorner(radius:CGFloat = 0,
                          borderWidth:CGFloat = 0,
                          borderColor:UIColor = UIColor.clear,
                          capsule:Bool = false) {
        self.viewCornerRectCorner(radius: radius,borderWidth: borderWidth,borderColor: borderColor,corner: .allCorners,capsule: capsule)
    }
        
    @objc func viewCornerRectCorner(radius: CGFloat = 5, topLeft: CGFloat = 0, topRight: CGFloat = 0, bottomLeft: CGFloat = 0, bottomRight: CGFloat = 0, borderWidth: CGFloat = 0, borderColor: UIColor = UIColor.clear, corner: UIRectCorner = .allCorners, capsule: Bool = false) {
        
        PTGCDManager.gcdMain {
            let tracker = self.getOrCreateTracker() // 记得用你抽出来的统一获取 tracker 的方法
            
            tracker.layoutActions["PTCornerRectCorner"] = { [weak self] currentBounds in
                guard let self = self else { return }
                
                if #available(iOS 26.0, *) {
                    var finalTL: CGFloat = 0; var finalTR: CGFloat = 0
                    var finalBL: CGFloat = 0; var finalBR: CGFloat = 0
                    
                    if capsule {
                        let capsuleRadius = min(currentBounds.width, currentBounds.height) / 2.0
                        finalTL = capsuleRadius; finalTR = capsuleRadius
                        finalBL = capsuleRadius; finalBR = capsuleRadius
                    } else if corner == .allCorners {
                        finalTL = radius; finalTR = radius
                        finalBL = radius; finalBR = radius
                    } else {
                        if corner.contains(.topLeft) { finalTL = topLeft }
                        if corner.contains(.topRight) { finalTR = topRight }
                        if corner.contains(.bottomLeft) { finalBL = bottomLeft }
                        if corner.contains(.bottomRight) { finalBR = bottomRight }
                    }
                    
                    let tL = (corner == .allCorners || corner.contains(.topLeft) || capsule) ? UICornerRadius(floatLiteral: finalTL) : nil
                    let tR = (corner == .allCorners || corner.contains(.topRight) || capsule) ? UICornerRadius(floatLiteral: finalTR) : nil
                    let bL = (corner == .allCorners || corner.contains(.bottomLeft) || capsule) ? UICornerRadius(floatLiteral: finalBL) : nil
                    let bR = (corner == .allCorners || corner.contains(.bottomRight) || capsule) ? UICornerRadius(floatLiteral: finalBR) : nil
                    
                    self.corner26(tL: tL, tR: tR, bL: bL, bR: bR, capsule: capsule)
                    self.layer.masksToBounds = true
                    self.layer.borderWidth = borderWidth
                    self.layer.borderColor = borderColor.cgColor
                    
                } else {
                    let path = self.pt_customCornerPath(bounds: currentBounds, radius: radius, topLeft: topLeft, topRight: topRight, bottomLeft: bottomLeft, bottomRight: bottomRight, corner: corner, capsule: capsule)
                    
                    let maskLayer = CAShapeLayer()
                    maskLayer.frame = currentBounds
                    maskLayer.path = path.cgPath
                    self.layer.mask = maskLayer
                    self.layer.masksToBounds = true
                    self.layer.borderWidth = 0
                    
                    let borderLayerName = "PTCustomBorderLayer"
                    var borderLayer = self.layer.sublayers?.first(where: { $0.name == borderLayerName }) as? CAShapeLayer
                    
                    if borderWidth > 0 && borderColor != .clear {
                        if borderLayer == nil {
                            borderLayer = CAShapeLayer()
                            borderLayer?.name = borderLayerName
                            self.layer.addSublayer(borderLayer!)
                        }
                        borderLayer?.frame = currentBounds
                        borderLayer?.path = path.cgPath
                        borderLayer?.fillColor = UIColor.clear.cgColor
                        borderLayer?.strokeColor = borderColor.cgColor
                        borderLayer?.lineWidth = borderWidth * 2
                    } else {
                        borderLayer?.removeFromSuperlayer()
                    }
                }
            }
            if self.bounds.width > 0 && self.bounds.height > 0 { tracker.layoutActions["PTCornerRectCorner"]?(self.bounds) }
        }
    }

    @available(iOS 26.0, *)
    func corner26(tL:UICornerRadius? = nil,
                  tR:UICornerRadius? = nil,
                  bL:UICornerRadius? = nil,
                  bR:UICornerRadius? = nil,
                  capsule:Bool = false) {
        if capsule {
            self.cornerConfiguration = .capsule()
        } else {
            let values = [tL, tR, bL, bR]
            let isUniform = values.dropFirst().allSatisfy { $0 == values.first }
            if isUniform {
                self.cornerConfiguration = .uniformCorners(radius: tL!)
            } else {
                self.cornerConfiguration = .corners(topLeftRadius: tL, topRightRadius: tR, bottomLeftRadius: bL, bottomRightRadius: bR)
            }
        }
    }

    //MARK: View的背景渐变
    //MARK: View的背景渐变 (优化版)
    func backgroundGradient(type: Imagegradien,
                            colors: [UIColor],
                            radius: CGFloat = 0,
                            topLeft: CGFloat = 0,
                            topRight: CGFloat = 0,
                            bottomLeft: CGFloat = 0,
                            bottomRight: CGFloat = 0,
                            borderWidth: CGFloat = 0,
                            borderColor: UIColor = UIColor.clear,
                            corner: UIRectCorner = .allCorners,
                            capsule: Bool = false) {
        self.superGradient(bgType: type,
                           bgColors: colors,
                           borderType: .LeftToRight, // 纯色边框什么方向都一样
                           borderColors: [borderColor, borderColor],
                           borderWidth: borderWidth,
                           radius: radius,
                           topLeft: topLeft,
                           topRight: topRight,
                           bottomLeft: bottomLeft,
                           bottomRight: bottomRight,
                           corner: corner,
                           capsule: capsule)
    }
    
    //MARK: border的背景渐变
    ///border的背景渐变
    func borderGradient(type: Imagegradien,
                        colors: [UIColor],
                        radius: CGFloat = 0,
                        topLeft: CGFloat = 0,
                        topRight: CGFloat = 0,
                        bottomLeft: CGFloat = 0,
                        bottomRight: CGFloat = 0,
                        borderWidth: CGFloat = 1,
                        corner: UIRectCorner = .allCorners,
                        capsule: Bool = false) {
        self.superGradient(bgType: nil,
                           bgColors: nil,
                           borderType: type,
                           borderColors: colors,
                           borderWidth: borderWidth,
                           radius: radius,
                           topLeft: topLeft,
                           topRight: topRight,
                           bottomLeft: bottomLeft,
                           bottomRight: bottomRight,
                           corner: corner,
                           capsule: capsule)
    }
    
    // MARK: - 全能混合渐变 (同时支持背景渐变 + 边框渐变)
    /// - Parameters:
    ///   - bgType: 背景渐变方向 (传 nil 表示不需要背景渐变)
    ///   - bgColors: 背景渐变颜色数组
    ///   - borderType: 边框渐变方向 (传 nil 表示不需要边框渐变)
    ///   - borderColors: 边框渐变颜色数组
    // MARK: - 全能混合渐变 (终极合并版)
    func superGradient(bgType: Imagegradien? = nil,
                       bgColors: [UIColor]? = nil,
                       borderType: Imagegradien? = nil,
                       borderColors: [UIColor]? = nil,
                       borderWidth: CGFloat = 1,
                       radius: CGFloat = 0,
                       topLeft: CGFloat = 0,
                       topRight: CGFloat = 0,
                       bottomLeft: CGFloat = 0,
                       bottomRight: CGFloat = 0,
                       corner: UIRectCorner = .allCorners,
                       capsule: Bool = false) {
        
        PTGCDManager.gcdMain {
            let tracker = self.getOrCreateTracker()
            
            tracker.layoutActions["Gradient"] = { [weak self] currentBounds in
                guard let self = self, currentBounds.width > 0, currentBounds.height > 0 else { return }
                let bgPath = self.pt_customCornerPath(bounds: currentBounds, radius: radius, topLeft: topLeft, topRight: topRight, bottomLeft: bottomLeft, bottomRight: bottomRight, corner: corner, capsule: capsule)
                
                let bgName = "PTSuperBg"
                var bgLayer = self.layer.sublayers?.first(where: { $0.name == bgName }) as? CAGradientLayer
                if let bgColors = bgColors, let bgType = bgType {
                    if bgLayer == nil {
                        bgLayer = CAGradientLayer(); bgLayer?.name = bgName
                        self.layer.insertSublayer(bgLayer!, at: 0)
                    }
                    bgLayer?.frame = currentBounds
                    bgLayer?.colors = bgColors.map { $0.cgColor }
                    self.applyGradientType(bgLayer!, type: bgType)
                    let mask = CAShapeLayer(); mask.path = bgPath.cgPath // 背景用原路径
                    bgLayer?.mask = mask
                } else { bgLayer?.removeFromSuperlayer() }
                
                // --- 2. 处理边框层 (关键修复点) ---
                let brdName = "PTSuperBorder"
                var brdLayer = self.layer.sublayers?.first(where: { $0.name == brdName }) as? CAGradientLayer
                if let brdColors = borderColors, let brdType = borderType, borderWidth > 0 {
                    if brdLayer == nil {
                        brdLayer = CAGradientLayer(); brdLayer?.name = brdName
                        self.layer.insertSublayer(brdLayer!, at: (bgLayer != nil ? 1 : 0))
                    }
                    brdLayer?.frame = currentBounds
                    brdLayer?.colors = brdColors.map { $0.cgColor }
                    self.applyGradientType(brdLayer!, type: brdType)
                    
                    // 💡 修复核心：计算向内收缩的 Bounds 和 Radius
                    let halfW = borderWidth / 2.0
                    let insetBounds = currentBounds.insetBy(dx: halfW, dy: halfW)
                    
                    // 保证圆角减去边框宽度后不会变成负数
                    let brdRadius = max(0, radius - halfW)
                    let brdTL = max(0, topLeft - halfW)
                    let brdTR = max(0, topRight - halfW)
                    let brdBL = max(0, bottomLeft - halfW)
                    let brdBR = max(0, bottomRight - halfW)
                    
                    // 用收缩后的数据生成边框专用路径
                    let borderPath = self.pt_customCornerPath(bounds: insetBounds, radius: brdRadius, topLeft: brdTL, topRight: brdTR, bottomLeft: brdBL, bottomRight: brdBR, corner: corner, capsule: capsule)
                    
                    let brdMask = CAShapeLayer()
                    brdMask.path = borderPath.cgPath
                    brdMask.fillColor = UIColor.clear.cgColor
                    brdMask.strokeColor = UIColor.black.cgColor
                    brdMask.lineWidth = borderWidth // 这里不再乘 2，直接使用真实宽度！
                    brdLayer?.mask = brdMask
                } else { brdLayer?.removeFromSuperlayer() }
                
                self.backgroundColor = .clear
            }
            tracker.layoutActions["Gradient"]?(self.bounds)
        }
    }

    private func applyGradientType(_ layer: CAGradientLayer, type: Imagegradien) {
        switch type {
        case .LeftToRight: layer.startPoint = CGPoint(x: 0, y: 0); layer.endPoint = CGPoint(x: 1, y: 0)
        case .TopToBottom: layer.startPoint = CGPoint(x: 0, y: 0); layer.endPoint = CGPoint(x: 0, y: 1)
        case .RightToLeft: layer.startPoint = CGPoint(x: 1, y: 0); layer.endPoint = CGPoint(x: 0, y: 0)
        case .BottomToTop: layer.startPoint = CGPoint(x: 0, y: 1); layer.endPoint = CGPoint(x: 0, y: 0)
        }
    }

    private var viewShapeLayer:CAShapeLayer? {
        set{
            objc_setAssociatedObject(self, &AssociatedKeys.layoutShapeLayerCallback, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        } get {
            let obj =  objc_getAssociatedObject(self, &AssociatedKeys.layoutShapeLayerCallback)
            guard let haveShape = obj as? CAShapeLayer else {
                return nil
            }
            return haveShape
        }
    }
    
    private var viewShapeLayerProgressLabel:UILabel? {
        set{
            objc_setAssociatedObject(self, &AssociatedKeys.layoutShapeLayerProgressLabelCallback, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        } get {
            let obj =  objc_getAssociatedObject(self, &AssociatedKeys.layoutShapeLayerProgressLabelCallback)
            guard let progressLabel = obj as? UILabel else {
                return nil
            }
            return progressLabel
        }
    }
    
    /// 为视图添加并更新进度条遮罩
    /// - Parameters:
    ///   - value: 进度值 (0.0 到 1.0)
    ///   - borderWidth: 边框宽度
    ///   - borderColor: 边框颜色
    ///   - showValueLabel: 是否显示百分比文字
    ///   - uniCount: 小数点保留位数
    func layerProgress(value: CGFloat,
                       radius: CGFloat = 0,
                       topLeft: CGFloat = 0,
                       topRight: CGFloat = 0,
                       bottomLeft: CGFloat = 0,
                       bottomRight: CGFloat = 0,
                       corner: UIRectCorner = .allCorners,
                       capsule: Bool = false,
                       borderWidth: CGFloat = 1,
                       borderColor: UIColor = .systemRed,
                       showValueLabel: Bool = true,
                       valueLabelFont: UIFont = .systemFont(ofSize: 16, weight: .bold),
                       valueLabelColor: UIColor = .white,
                       uniCount: Int = 0) {
        PTGCDManager.gcdMain {
            let tracker = self.getOrCreateTracker() // 确保你保留了之前的 getOrCreateTracker 方法
            
            // 1. 初始化 Layer (如果还没有的话)
            if self.viewShapeLayer == nil {
                let shape = CAShapeLayer()
                shape.fillColor = UIColor.clear.cgColor
                shape.strokeColor = borderColor.cgColor
                // 注意：因为我们做了向内收缩，这里的线宽就用真实传进来的 borderWidth 即可，不用乘 2
                shape.lineWidth = borderWidth
                shape.lineCap = .round
                self.layer.addSublayer(shape)
                self.viewShapeLayer = shape
                
                if showValueLabel && self.viewShapeLayerProgressLabel == nil {
                    let label = UILabel()
                    label.font = valueLabelFont
                    label.textColor = valueLabelColor
                    label.textAlignment = .center
                    self.addSubview(label)
                    label.snp.makeConstraints { $0.center.equalToSuperview() }
                    self.viewShapeLayerProgressLabel = label
                }
            }
            
            // 2. 🌟 注册响应式任务：处理路径收缩
            tracker.layoutActions["Progress"] = { [weak self] currentBounds in
                guard let self = self, let shape = self.viewShapeLayer, currentBounds.width > 0, currentBounds.height > 0 else { return }
                
                // 💡 修复核心：计算向内收缩的 Bounds
                let halfW = borderWidth / 2.0
                let insetBounds = currentBounds.insetBy(dx: halfW, dy: halfW)
                
                // 💡 保证圆角减去边框宽度后不会变成负数
                let prgRadius = max(0, radius - halfW)
                let prgTL = max(0, topLeft - halfW)
                let prgTR = max(0, topRight - halfW)
                let prgBL = max(0, bottomLeft - halfW)
                let prgBR = max(0, bottomRight - halfW)
                
                // 使用收缩后的尺寸和圆角，生成完美贴合在视图内部的路径
                let path = self.pt_customCornerPath(bounds: insetBounds,
                                                    radius: prgRadius,
                                                    topLeft: prgTL,
                                                    topRight: prgTR,
                                                    bottomLeft: prgBL,
                                                    bottomRight: prgBR,
                                                    corner: corner,
                                                    capsule: capsule)
                
                shape.path = path.cgPath
                
                // 确保进度条始终在最顶层，不被背景渐变盖住
                self.layer.bringSublayerToFront(shape)
            }
            
            // 3. 立即执行一次布局刷新
            if self.bounds.width > 0 && self.bounds.height > 0 {
                tracker.layoutActions["Progress"]?(self.bounds)
            }
            
            // 4. 更新当前的进度值和文案
            self.viewShapeLayer?.strokeEnd = value
            self.viewShapeLayerProgressLabel?.text = String(format: "%.\(uniCount)f%%", (100 * value))
            
            // 5. 进度走完，清理现场
            if value >= 0.999 {
                // 延迟 0.2 秒再消失，让用户能看清 "100%"
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    UIView.animate(withDuration: 0.3, animations: {
                        self.viewShapeLayer?.opacity = 0
                        self.viewShapeLayerProgressLabel?.alpha = 0
                    }) { _ in
                        self.clearProgressLayer()
                    }
                }
            }
        }
    }
    
    func clearProgressLayer() {
        viewShapeLayer?.removeFromSuperlayer()
        viewShapeLayer = nil

        viewShapeLayerProgressLabel?.removeFromSuperview()
        viewShapeLayerProgressLabel = nil
        
        // 移除进度条的监听任务，避免后续尺寸变化时还瞎折腾
        if let tracker = self.subviews.first(where: { $0 is PTCornerTrackerView }) as? PTCornerTrackerView {
            tracker.layoutActions.removeValue(forKey: "Progress")
        }
    }
}

public extension UIView {
              
    /// 判断当前系统语言布局是否为从右到左 (RTL, 例如阿拉伯语)
    static func isRTL() -> Bool {
        UIView.userInterfaceLayoutDirection(for: UIView.appearance().semanticContentAttribute) == .rightToLeft
    }
    
    private struct AssociatedKeys {
        static var layoutSubviewsCallback: UInt8 = 0
        static var layoutShapeLayerCallback: UInt8 = 0
        static var layoutShapeLayerProgressLabelCallback: UInt8 = 0
        static var viewCapturing: UInt8 = 0
        static var borderTracker: UInt8 = 0 // 新增用于绑定 Tracker
    }

    private struct PTImageLoadKeys {
        static var ptLoadTask: UInt8 = 0
        static var ptLoadUUID: UInt8 = 0
    }

    // 1. 统一的异步任务管理
    var ptLoadTask: Task<Void, Never>? {
        get { objc_getAssociatedObject(self, &PTImageLoadKeys.ptLoadTask) as? Task<Void, Never> }
        set { objc_setAssociatedObject(self, &PTImageLoadKeys.ptLoadTask, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    var ptLoadUUID: UUID? {
        get { objc_getAssociatedObject(self, &PTImageLoadKeys.ptLoadUUID) as? UUID }
        set { objc_setAssociatedObject(self, &PTImageLoadKeys.ptLoadUUID, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    @MainActor @objc func swizzled_layoutSubviews() {
        swizzled_layoutSubviews()
        
        var tracker = objc_getAssociatedObject(self, &AssociatedKeys.borderTracker) as? BorderManager
        if tracker == nil {
            tracker = BorderManager(view: self)
            objc_setAssociatedObject(self, &AssociatedKeys.borderTracker, tracker, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
#if POOTOOLS_DEBUG
        if LocalConsole.shared.debugBordersEnabled {
            tracker?.activate()
        } else {
            tracker?.deactivate()
        }
#else
        tracker?.deactivate()
#endif
    }
        
    func isRolling() -> Bool {
        if self is UIScrollView {
            let scrollView = self as! UIScrollView
            if scrollView.isDragging || scrollView.isDecelerating {
                return true
            }
        }
        
        for subView in subviews {
            if subView.isRolling() { return true }
        }
        return false
    }
    
    func roundOriginToPixel() {
        frame.origin.x = (round(frame.origin.x * UIScreen.main.scale)) / UIScreen.main.scale
        frame.origin.y = (round(frame.origin.y * UIScreen.main.scale)) / UIScreen.main.scale
    }
    
    @objc class func sizeFor(string:String,
                             font:UIFont,
                             lineSpacing:CGFloat = 2.5,
                             height:CGFloat = CGFloat.greatestFiniteMagnitude,
                             width:CGFloat = CGFloat.greatestFiniteMagnitude) -> CGSize {
        guard !string.isEmpty else { return .zero }
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = lineSpacing
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .paragraphStyle: paragraph]
        let constraintSize = CGSize(width: width, height: height)
        let rect = string.boundingRect(with: constraintSize, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes, context: nil)
        return CGSize(width: ceil(rect.width), height: ceil(rect.height))
    }
    
    var viewController: UIViewController? {
        weak var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder!.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
    
    var hasSuperview: Bool { superview != nil }

    func allSubViewsOf<T : UIView>(type : T.Type) -> [T] {
        var all = [T]()
        func getSubview(view: UIView) {
            if let aView = view as? T{
                all.append(aView)
            }
            guard view.subviews.count > 0 else { return }
            view.subviews.forEach{ getSubview(view: $0) }
        }
        getSubview(view: self)
        return all
    }

    func addShadow(ofColor color: UIColor, radius: CGFloat, offset: CGSize, opacity: Float) {
        layer.shadowColor = color.cgColor
        layer.shadowOffset = offset
        layer.shadowRadius = radius
        layer.shadowOpacity = opacity
        layer.masksToBounds = false
    }
    
    func addParalax(amount: CGFloat) {
        motionEffects.removeAll()
        let horizontal = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
        horizontal.minimumRelativeValue = -amount
        horizontal.maximumRelativeValue = amount
        
        let vertical = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
        vertical.minimumRelativeValue = -amount
        vertical.maximumRelativeValue = amount
        
        let group = UIMotionEffectGroup()
        group.motionEffects = [horizontal, vertical]
        self.addMotionEffect(group)
    }
    
    func removeParalax() {
        motionEffects.removeAll()
    }
    
    /**
        If view has LTR interface.
     */
    var ltr: Bool { effectiveUserInterfaceLayoutDirection == .leftToRight }
    
    /**
        If view has TRL interface.
     */
    var rtl: Bool { effectiveUserInterfaceLayoutDirection == .rightToLeft }
    
    /**
         Wrapper for layer property `masksToBounds`.
     */
    var masksToBounds: Bool {
        get { layer.masksToBounds }
        set { layer.masksToBounds = newValue }
    }
    
    /**
        Round corners .
     
     - parameter corners: Case of `CACornerMask`. Which corners need to round.
     - parameter curve: Case of `CornerCurve`. Style of rounded corners.
     - parameter radius: Amount of radius.
     */
    func roundCorners(_ corners: CACornerMask = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMinXMinYCorner], curve: CornerCurve = .continuous, radius: CGFloat) {
        layer.cornerRadius = radius
        layer.maskedCorners = corners
        layer.cornerCurve = curve.layerCornerCurve
    }
    
    /**
        Round side by minimum `height` or `width`.
     */
    func roundMinimumSide() {
        roundCorners(radius: min(frame.width / 2, frame.height / 2))
    }
    
    /**
        Wrapper for layer property `customBorderColor`.
     */
    var customBorderColor: UIColor? {
        get {
            guard let color = layer.borderColor else { return nil }
            return UIColor(cgColor: color)
        }
        set {
            guard let color = newValue else {
                layer.borderColor = nil
                return
            }
            // Fix React-Native conflict issue
            guard String(describing: type(of: color)) != "__NSCFType" else { return }
            layer.borderColor = color.cgColor
        }
    }
    
    /**
        Wrapper for layer property `customBorderWidth`.
     */
    var customBorderWidth: CGFloat {
        get {
            layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    /**
        Appear view with fade in animation.
     
     - parameter duration: Duration of animation.
     - parameter completion: Completion when animation ended.
     */
    func fadeIn(duration: TimeInterval = 0.3, completion: PTBoolTask? = nil) {
        UIView.animate(withDuration: duration, delay: .zero, options: [.beginFromCurrentState, .allowUserInteraction], animations: {
            self.alpha = 1
        }, completion: completion)
    }
    
    /**
        Hide view with fade out animation.
     - parameter duration: Duration of animation.
     - parameter completion: Completion when animation ended.
     */
    func fadeOut(duration: TimeInterval = 0.3, completion: PTBoolTask? = nil) {
        UIView.animate(withDuration: duration, delay: .zero, options: [.beginFromCurrentState, .allowUserInteraction], animations: {
            self.alpha = 0
        }, completion: completion)
    }
        
    enum CornerCurve {
        
        case circle
        case continuous
        
        var layerCornerCurve: CALayerCornerCurve {
            switch self {
            case .circle: return .circular
            case .continuous: return .continuous
            }
        }
    }
    
    ///查找当前View的XViewController
    func findController<T:UIViewController>(with class :T.Type) -> T? {
        var responder = next
        while responder != nil {
            if responder!.isKind(of: `class`) {
                return responder as? T
            }
            responder = responder?.next
        }
        return nil
    }
    
    var ctrl: UIViewController? {
        return self.findController(with: UIViewController.self)
    }
    
    var naviCtrl: UINavigationController? {
        return self.findController(with: UINavigationController.self)
    }
    
    var tabBarCtrl: UITabBarController? {
        return self.findController(with: UITabBarController.self)
    }
}

//MARK: Load image core
public extension UIView {
    // 2. 手动取消
    func cancelImageLoad() {
        ptLoadTask?.cancel()
        ptLoadTask = nil
    }
    
    // 3. 核心大一统方法
    func pt_loadCoreImage(contentData: Any,
                          iCloudDocumentName: String = "",
                          borderWidth: CGFloat = PTAppBaseConfig.share.loadImageProgressBorderWidth,
                          borderColor: UIColor = PTAppBaseConfig.share.loadImageProgressBorderColor,
                          showValueLabel: Bool = PTAppBaseConfig.share.loadImageShowValueLabel,
                          valueLabelFont: UIFont = PTAppBaseConfig.share.loadImageShowValueFont,
                          valueLabelColor: UIColor = PTAppBaseConfig.share.loadImageShowValueColor,
                          uniCount: Int = PTAppBaseConfig.share.loadImageShowValueUniCount,
                          emptyImage: UIImage = PTAppBaseConfig.share.defaultEmptyImage,
                          progressHandle: ((_ receivedSize: Int64, _ totalSize: Int64) -> Void)? = nil,
                          setImageBlock: @escaping @MainActor (UIImage?) -> Void, // <--- 关键点：交还给具体类的渲染闭包
                          loadFinish: ((PTLoadImageResult) -> Void)? = nil) {
        // 取消旧任务
        cancelImageLoad()

        let loadID = UUID()
        ptLoadUUID = loadID

        func isValid() -> Bool {
            return self.ptLoadUUID == loadID
        }

        func setEmpty() {
            guard isValid() else { return }
            Task { @MainActor in
                guard isValid() else { return }
                setImageBlock(emptyImage)
            }
        }

        func showImage(_ image: UIImage) {
            guard isValid() else { return }
            Task { @MainActor in
                guard isValid() else { return }
                setImageBlock(image)
                self.layerProgress(value: 1,
                                   borderWidth: borderWidth,
                                   borderColor: borderColor,
                                   showValueLabel: showValueLabel,
                                   valueLabelFont: valueLabelFont,
                                   valueLabelColor: valueLabelColor,
                                   uniCount: uniCount)
                // 构造一个虚拟的 Result 用于本地图片/颜色等的回调
                // 假设 PTLoadImageResult 有个对应的构造器，如果没有请按照你的实际 struct 进行初始化
                // loadFinish?(PTLoadImageResult(allImages: [image], firstImage: image, loadTime: 0))
            }
        }

        func finish(_ result: PTLoadImageResult) {
            guard isValid() else { return }
            Task { @MainActor in
                guard isValid() else { return }
                guard let images = result.allImages, !images.isEmpty else {
                    setEmpty()
                    loadFinish?(result)
                    return
                }

                if images.count > 1 {
                    DispatchQueue.global().async {
                        let gif = UIImage.animatedImage(with: images, duration: result.loadTime)
                        DispatchQueue.main.async {
                            guard isValid() else { return }
                            setImageBlock(gif)
                            loadFinish?(result)
                        }
                    }
                } else {
                    setImageBlock(result.firstImage)
                    loadFinish?(result)
                }
            }
        }

        func loadVideo(url: URL) {
            PTVideoCoverCache.getVideoFirstImage(videoUrl: url.absoluteString) { image in
                guard isValid() else { return }
                if let image {
                    showImage(image)
                } else {
                    setEmpty()
                }
            }
        }

        func loadFromURL(_ url: URL) {
            let ext = url.pathExtension.lowercased()

            // 视频
            if GlobalVideoExts.contains(ext) {
                loadVideo(url: url)
                return
            }

            ptLoadTask = Task {
                if Task.isCancelled { return }

                if let cache = await PTLoadImageFunction.cachedImage(from: url) {
                    if Task.isCancelled { return }
                    finish(cache)
                    return
                }

                let result = await PTLoadImageFunction.loadImage(
                    contentData: url,
                    iCloudDocumentName: iCloudDocumentName
                ) { received, total in
                    guard isValid() else { return }

                    Task { @MainActor in
                        guard isValid() else { return }
                        if let progressHandle {
                            progressHandle(received, total)
                        } else {
                            self.layerProgress(
                                value: CGFloat(received) / CGFloat(total),
                                borderWidth: borderWidth,
                                borderColor: borderColor,
                                showValueLabel: showValueLabel,
                                valueLabelFont: valueLabelFont,
                                valueLabelColor: valueLabelColor,
                                uniCount: uniCount
                            )
                        }
                    }
                }
                if Task.isCancelled { return }
                finish(result)
            }
        }

        switch contentData {
        case let image as UIImage:
            showImage(image)
        case let color as UIColor:
            showImage(color.createImageWithColor())
        case let data as Data:
            if let image = UIImage(data: data) {
                showImage(image)
            } else {
                setEmpty()
            }
        case let asset as PHAsset:
            ptLoadTask = Task {
                if Task.isCancelled { return }
                let result = await PTLoadImageFunction.handleAssetContent(asset: asset)
                if Task.isCancelled { return }
                finish(result)
            }
        case let avasset as AVAsset:
            avasset.getVideoFirstImage { image in
                guard isValid() else { return }
                if let image {
                    showImage(image)
                } else {
                    setEmpty()
                }
            }
        case let url as URL:
            loadFromURL(url)
        case let string as String:
            if FileManager.default.fileExists(atPath: string) {
                if let image = UIImage(contentsOfFile: string) {
                    showImage(image)
                } else {
                    setEmpty()
                }
                return
            }
            if string.isURL(), let url = URL(string: string) {
                loadFromURL(url)
            } else if let image = UIImage(named: string) {
                showImage(image)
            } else {
                setEmpty()
            }
        default:
            setEmpty()
        }
    }
}

public extension UIView {

    @objc func jx_layoutSubviews() {
        jx_layoutSubviews()
        layoutSubviewsCallback?(self)
    }

    var layoutSubviewsCallback: ((UIView) -> Void)? {
        get {
            objc_getAssociatedObject(self, &AssociatedKeys.layoutSubviewsCallback) as? (UIView) -> Void
        } set {
            objc_setAssociatedObject(self, &AssociatedKeys.layoutSubviewsCallback, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    static func swizzle() {
        Swizzle(UIView.self) {
            #selector(layoutSubviews) <-> #selector(jx_layoutSubviews)
        }
    }
}

public extension UIView {
    @objc func viewUI_shake() {
        let keyFrame = CAKeyframeAnimation(keyPath: "position.x")
        keyFrame.duration = 0.3
        let x = layer.position.x
        keyFrame.values = [(x - 30),(x - 30),(x + 20),(x - 20),(x + 10),(x - 10),(x + 5),(x - 5)]
        layer.add(keyFrame, forKey: "shake")
    }
    
    @objc func pt_createLabel(text: String = "",
                              font: UIFont = .systemFont(ofSize: 15),
                              bgColor: UIColor = .clear,
                              textColor: UIColor = .black,
                              textAlignment: NSTextAlignment = .left) -> UILabel {
        
        let label = UILabel()
        label.backgroundColor = bgColor
        label.textColor = textColor
        label.text = text
        label.numberOfLines = 0
        label.adjustsFontSizeToFitWidth = true
        label.sizeToFit()
        label.font = font
        label.textAlignment = textAlignment
        return label
    }
}

//MARK: 視頻剪輯
public extension UIView {
    var imageWithView: UIImage? {
        let renderer = UIGraphicsImageRenderer(bounds: self.bounds)
        return renderer.image { rendererContext in
            self.layer.render(in: rendererContext.cgContext)
        }
    }
    
    func edgesConstraint(subView: UIView, constant: CGFloat = 0) {
        self.leadingConstraint(subView: subView, constant: constant)
        self.trailingConstraint(subView: subView, constant: constant)
        self.topConstraint(subView: subView, constant: constant)
        self.bottomConstraint(subView: subView, constant: constant)
    }
    
    func sizeConstraint(subView: UIView, constant: CGFloat = 0) {
        self.widthConstraint(subView: subView, constant: constant)
        self.heightConstraint(subView: subView, constant: constant)
    }
    
    func sizeConstraint(constant: CGFloat = 0) {
        self.widthConstraint(constant: constant)
        self.heightConstraint(constant: constant)
    }
    
    @discardableResult
    func leadingConstraint(subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: self, attribute: .leading, relatedBy: relatedBy, toItem: subView, attribute: .leading, multiplier: multiplier, constant: constant)
        self.addConstraint(constraint)
        return constraint
    }
    
    @discardableResult
    func trailingConstraint(subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: relatedBy, toItem: subView, attribute: .trailing, multiplier: multiplier, constant: constant)
        self.addConstraint(constraint)
        return constraint
    }
    
    @discardableResult
    func topConstraint(subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: self, attribute: .top, relatedBy: relatedBy, toItem: subView, attribute: .top, multiplier: multiplier, constant: constant)
        self.addConstraint(constraint)
        return constraint
    }
    
    @discardableResult
    func bottomConstraint(subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: relatedBy, toItem: subView, attribute: .bottom, multiplier: multiplier, constant: constant)
        self.addConstraint(constraint)
        return constraint
    }
    
    @discardableResult
    func centerXConstraint(subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: self, attribute: .centerX, relatedBy: relatedBy, toItem: subView, attribute: .centerX, multiplier: multiplier, constant: constant)
        self.addConstraint(constraint)
        return constraint
    }
    
    @discardableResult
    func centerYConstraint(subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: self, attribute: .centerY, relatedBy: relatedBy, toItem: subView, attribute: .centerY, multiplier: multiplier, constant: constant)
        self.addConstraint(constraint)
        return constraint
    }
    
    @discardableResult
    func leadingConstraint(item: UIView, subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: item, attribute: .leading, relatedBy: relatedBy, toItem: subView, attribute: .leading, multiplier: multiplier, constant: constant)
        self.addConstraint(constraint)
        return constraint
    }
    
    @discardableResult
    func trailingConstraint(item: UIView, subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: item, attribute: .trailing, relatedBy: relatedBy, toItem: subView, attribute: .trailing, multiplier: multiplier, constant: constant)
        self.addConstraint(constraint)
        return constraint
    }
    
    @discardableResult
    func topConstraint(item: UIView, subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: item, attribute: .top, relatedBy: relatedBy, toItem: subView, attribute: .top, multiplier: multiplier, constant: constant)
        self.addConstraint(constraint)
        return constraint
    }
    
    @discardableResult
    func bottomConstraint(item: UIView, subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: item, attribute: .bottom, relatedBy: relatedBy, toItem: subView, attribute: .bottom, multiplier: multiplier, constant: constant)
        self.addConstraint(constraint)
        return constraint
    }
    
    @discardableResult
    func centerXConstraint(item: UIView, subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: item, attribute: .centerX, relatedBy: relatedBy, toItem: subView, attribute: .centerX, multiplier: multiplier, constant: constant)
        self.addConstraint(constraint)
        return constraint
    }
    
    @discardableResult
    func centerYConstraint(item: UIView, subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: item, attribute: .centerY, relatedBy: relatedBy, toItem: subView, attribute: .centerY, multiplier: multiplier, constant: constant)
        self.addConstraint(constraint)
        return constraint
    }
    
    @discardableResult
    func widthConstraint(item: UIView, subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: item, attribute: .width, relatedBy: relatedBy, toItem: subView, attribute: .width, multiplier: multiplier, constant: constant)
        self.addConstraint(constraint)
        return constraint
    }
    
    @discardableResult
    func heightConstraint(item: UIView, subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: item, attribute: .height, relatedBy: relatedBy, toItem: subView, attribute: .height, multiplier: multiplier, constant: constant)
        self.addConstraint(constraint)
        return constraint
    }
    
    @discardableResult
    func widthConstraint(subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: self, attribute: .width, relatedBy: relatedBy, toItem: subView, attribute: .width, multiplier: multiplier, constant: constant)
        self.addConstraint(constraint)
        return constraint
    }
    
    @discardableResult
    func heightConstraint(subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: self, attribute: .height, relatedBy: relatedBy, toItem: subView, attribute: .height, multiplier: multiplier, constant: constant)
        self.addConstraint(constraint)
        return constraint
    }
    
    @discardableResult
    func widthConstraint(constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: self, attribute: .width, relatedBy: relatedBy, toItem: nil, attribute: .width, multiplier: multiplier, constant: constant)
        self.addConstraint(constraint)
        return constraint
    }
    
    @discardableResult
    func heightConstraint(constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: self, attribute: .height, relatedBy: relatedBy, toItem: nil, attribute: .height, multiplier: multiplier, constant: constant)
        self.addConstraint(constraint)
        return constraint
    }
}

// MARK: - 截图-对当前视图进行快照
public extension UIView {
    
    /** 是否正在截屏*/
    var isCapturing: Bool {
        get { (objc_getAssociatedObject(self, &AssociatedKeys.viewCapturing) as? Bool) ?? false }
        set { objc_setAssociatedObject(self, &AssociatedKeys.viewCapturing, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    /**  是否包含了WKWebView*/
    func isContainWKWebView() -> Bool {
        if self.isKind(of: WKWebView.self) {
            return true
        } else {
            for view in self.subviews {
                return view.isContainWKWebView()
            }
        }
        return false
    }
    
    /** 快照回调*/
    typealias captureCompletion = (UIImage?) -> Void
    
    /// 对视图进行快照
    ///
    /// - Parameter completion: 回调
    func captureCurrent(_ completion: captureCompletion) {
        self.isCapturing = true
        
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.scale = UIScreen.main.scale
        
        let renderer = UIGraphicsImageRenderer(bounds: self.bounds, format: format)
        let image = renderer.image { context in
            if self.isContainWKWebView() {
                self.drawHierarchy(in: bounds, afterScreenUpdates: true)
            } else {
                self.layer.render(in: context.cgContext)
            }
        }
        
        self.isCapturing = false
        completion(image)
    }
}

// MARK: - 截图
public extension UIView {
    
    /// 生成视图的截图 - bounds
    ///
    /// - Parameters:
    ///   - opaque: alpha通道 true:不透明 / false透明
    ///   - scale: 缩放清晰度
    /// - Returns: 截图
    func generateBoundsScreenshot(_ opaque: Bool = false, scale: CGFloat = 0) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.opaque = opaque
        format.scale = scale == 0 ? UIScreen.main.scale : scale
        
        let renderer = UIGraphicsImageRenderer(bounds: self.bounds, format: format)
        return renderer.image { ctx in
            self.layer.render(in: ctx.cgContext)
        }
    }
    
    /// 生成视图的截图 - frame
    ///
    /// - Returns: 截图
    func generateFrameScreenshot() -> UIImage {
        let imageSize = self.frame.size
        var orientation:UIInterfaceOrientation!
        if let orientations = AppWindows?.windowScene?.interfaceOrientation {
            orientation = orientations
        } else {
            orientation = UIInterfaceOrientation(rawValue: UIDevice.current.orientation.rawValue)
        }
        UIGraphicsBeginImageContextWithOptions(imageSize, false, 0)
        if let context = UIGraphicsGetCurrentContext() {
            context.saveGState()
            context.translateBy(x: center.x, y: center.y)
            context.concatenate(transform)
            context.translateBy(x: -bounds.size.width * layer.anchorPoint.x, y: -bounds.size.height * layer.anchorPoint.y)
            if orientation == .landscapeLeft {
                context.rotate(by: .pi / 2)
                context.translateBy(x: 0, y: -imageSize.width)
            } else if orientation == .landscapeRight {
                context.rotate(by: -.pi / 2)
                context.translateBy(x: -imageSize.height, y: 0)
            } else if orientation == .portraitUpsideDown {
                context.rotate(by: .pi)
                context.translateBy(x: -imageSize.width, y: -imageSize.height)
            }
            if self.responds(to: #selector(drawHierarchy(in:afterScreenUpdates:))) {
                self.drawHierarchy(in: bounds, afterScreenUpdates: true)
            } else {
                layer.render(in: context)
            }
            context.restoreGState()
        }
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image ?? UIImage()
    }
    
    func toImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: self.bounds.size)
        return renderer.image { ctx in
            self.layer.render(in: ctx.cgContext)
        }
    }
}

public protocol UIFadeOut {}

extension UIFadeOut where Self: UIView {
    
    /**
        Hide view with fade out animation.
     
     - parameter duration: Duration of all animation.
     - parameter delay: Pause when view dissapear in middle of animation.
     - parameter work: Apply view changes here.
     - parameter completion: Call after end of animation.
     */
    public func fadeUpdate(duration: TimeInterval = 1,
                           delay: TimeInterval = 0.15,
                           work: @escaping (Self) -> Void,
                           completion: PTActionTask? = nil) {
        let partDuration = (duration - delay) / 2
        let storedAlpha = self.alpha
        UIView.animate(withDuration: partDuration, delay: .zero, options: [.beginFromCurrentState, .allowUserInteraction], animations: { [weak self] in
            self?.alpha = .zero
        }, completion: { [weak self] finished in
            if let self = self {
                work(self)
            }
            UIView.animate(withDuration: partDuration, delay: delay, options: [.beginFromCurrentState, .allowUserInteraction], animations: { [weak self] in
                self?.alpha = storedAlpha
            }, completion: { finished in
                Task { @MainActor in
                    completion?()
                }
            })
        })
    }
}

extension UIView: UIFadeOut {}
#endif
