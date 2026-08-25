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

@MainActor var GLOBAL_BORDER_TRACKERS: [BorderManager] = []
extension UIView: PTProtocolCompatible {}
public typealias LayoutSubviewsCallback = (_ view:UIView) -> Void

@MainActor
private final class PTCornerTrackerView: UIView {
    var cornerAction: ((CGRect) -> Void)?
    var gradientAction: ((CGRect) -> Void)?
    var progressAction: ((CGRect) -> Void)?

    private var lastRenderedBounds: CGRect = .null
    private var traitChangeRegistration: (any UITraitChangeRegistration)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        isAccessibilityElement = false
        accessibilityElementsHidden = true

        // 中文：动态颜色变化时重新应用 Layer；Español: reaplica las capas cuando cambian los colores dinámicos.
        traitChangeRegistration = registerForTraitChanges([UITraitUserInterfaceStyle.self]) { [weak self] (_: PTCornerTrackerView, _: UITraitCollection) in
            self?.invalidateLayout()
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func invalidateLayout() {
        lastRenderedBounds = .null
        setNeedsLayout()
    }

    func applyCurrentLayout() {
        let currentBounds = CGRect(origin: .zero, size: bounds.size)
        guard currentBounds.width > 0, currentBounds.height > 0 else { return }
        guard currentBounds != lastRenderedBounds else { return }

        lastRenderedBounds = currentBounds
        gradientAction?(currentBounds)
        cornerAction?(currentBounds)
        progressAction?(currentBounds)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        applyCurrentLayout()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        invalidateLayout()
    }
}

private struct PTCornerStyle {
    let radius: CGFloat
    let topLeft: CGFloat
    let topRight: CGFloat
    let bottomLeft: CGFloat
    let bottomRight: CGFloat
    let corner: UIRectCorner
    let capsule: Bool

    private func safeValue(_ value: CGFloat) -> CGFloat {
        value.isFinite ? max(0, value) : 0
    }

    func radii(in bounds: CGRect) -> (topLeft: CGFloat, topRight: CGFloat, bottomLeft: CGFloat, bottomRight: CGFloat) {
        let width = max(0, bounds.width)
        let height = max(0, bounds.height)
        let maximumRadius = min(width, height) / 2

        if capsule {
            return (maximumRadius, maximumRadius, maximumRadius, maximumRadius)
        }

        let baseRadius = safeValue(radius)
        func selectedRadius(_ value: CGFloat) -> CGFloat {
            let explicitRadius = safeValue(value)
            return min(explicitRadius > 0 ? explicitRadius : baseRadius, maximumRadius)
        }

        guard corner != .allCorners else {
            let value = min(baseRadius, maximumRadius)
            return (value, value, value, value)
        }

        return (
            corner.contains(.topLeft) ? selectedRadius(topLeft) : 0,
            corner.contains(.topRight) ? selectedRadius(topRight) : 0,
            corner.contains(.bottomLeft) ? selectedRadius(bottomLeft) : 0,
            corner.contains(.bottomRight) ? selectedRadius(bottomRight) : 0
        )
    }

    func path(in bounds: CGRect) -> UIBezierPath {
        let values = radii(in: bounds)
        let minX = bounds.minX
        let minY = bounds.minY
        let maxX = bounds.maxX
        let maxY = bounds.maxY
        let path = UIBezierPath()

        path.move(to: CGPoint(x: minX + values.topLeft, y: minY))
        path.addLine(to: CGPoint(x: maxX - values.topRight, y: minY))
        if values.topRight > 0 {
            path.addArc(withCenter: CGPoint(x: maxX - values.topRight, y: minY + values.topRight),
                        radius: values.topRight,
                        startAngle: -.pi / 2,
                        endAngle: 0,
                        clockwise: true)
        }

        path.addLine(to: CGPoint(x: maxX, y: maxY - values.bottomRight))
        if values.bottomRight > 0 {
            path.addArc(withCenter: CGPoint(x: maxX - values.bottomRight, y: maxY - values.bottomRight),
                        radius: values.bottomRight,
                        startAngle: 0,
                        endAngle: .pi / 2,
                        clockwise: true)
        }

        path.addLine(to: CGPoint(x: minX + values.bottomLeft, y: maxY))
        if values.bottomLeft > 0 {
            path.addArc(withCenter: CGPoint(x: minX + values.bottomLeft, y: maxY - values.bottomLeft),
                        radius: values.bottomLeft,
                        startAngle: .pi / 2,
                        endAngle: .pi,
                        clockwise: true)
        }

        path.addLine(to: CGPoint(x: minX, y: minY + values.topLeft))
        if values.topLeft > 0 {
            path.addArc(withCenter: CGPoint(x: minX + values.topLeft, y: minY + values.topLeft),
                        radius: values.topLeft,
                        startAngle: .pi,
                        endAngle: -.pi / 2,
                        clockwise: true)
        }

        path.close()
        return path
    }

    var maskedCorners: CACornerMask {
        var result: CACornerMask = []
        if corner.contains(.topLeft) || corner == .allCorners { result.insert(.layerMinXMinYCorner) }
        if corner.contains(.topRight) || corner == .allCorners { result.insert(.layerMaxXMinYCorner) }
        if corner.contains(.bottomLeft) || corner == .allCorners { result.insert(.layerMinXMaxYCorner) }
        if corner.contains(.bottomRight) || corner == .allCorners { result.insert(.layerMaxXMaxYCorner) }
        return result
    }

    func usesNativeLayer(in bounds: CGRect) -> Bool {
        let values = radii(in: bounds)
        return values.topLeft == values.topRight
            && values.topLeft == values.bottomLeft
            && values.topLeft == values.bottomRight
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
    @MainActor var jx_x: CGFloat{
        get {
            base.frame.origin.x
        } set {
            base.frame.origin.x = newValue
        }
    }
    
    /// 快捷获取/设置 y 坐标
    @MainActor var jx_y: CGFloat{
        get {
            base.frame.origin.y
        } set {
            base.frame.origin.y = newValue
        }
    }
    
    /// 快捷获取/设置 宽度
    @MainActor var jx_width: CGFloat{
        get {
            base.frame.size.width
        } set {
            base.frame.size.width = newValue
        }
    }
    
    /// 快捷获取/设置 高度
    @MainActor var jx_height: CGFloat{
        get {
            base.frame.size.height
        } set {
            base.frame.size.height = newValue
        }
    }
    
    /// 获取视图自身的中心点 (相对于自身 bounds)
    @MainActor var jx_viewCenter: CGPoint{
        get {
            CGPoint(x: jx_width * 0.5, y: jx_height * 0.5)
        }
    }
    
    /// 快捷获取/设置 centerX
    @MainActor var jx_centerX: CGFloat{
        get {
            jx_width * 0.5
        } set{
            base.center.x = newValue
        }
    }
    
    /// 快捷获取/设置 centerY
    @MainActor var jx_centerY: CGFloat{
        get {
            jx_height * 0.5
        } set{
            base.center.y = newValue
        }
    }
    
    /// 在父视图中的 Y 轴中心坐标
    @MainActor var inSuperViewCenterY: CGFloat{
        jx_y + jx_centerY
    }
    
    /// 快捷获取/设置 最大 X 值 (MaxX)
    @MainActor var maxX: CGFloat{
        get {
            jx_x + jx_width
        } set{
            jx_x = newValue - jx_width
        }
    }
    
    /// 快捷获取/设置 最大 Y 值 (MaxY)
    @MainActor var maxY: CGFloat{
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
            tracker.frame = CGRect(origin: .zero, size: bounds.size)
            return tracker
        }
        let newTracker = PTCornerTrackerView()
        newTracker.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        newTracker.frame = CGRect(origin: .zero, size: bounds.size)
        // 中文：监听器只负责布局，不参与交互；Español: el rastreador solo observa el diseño y no participa en la interacción.
        self.insertSubview(newTracker, at: 0)
        return newTracker
    }

    private func removeTrackerIfUnused() {
        guard let tracker = self.subviews.first(where: { $0 is PTCornerTrackerView }) as? PTCornerTrackerView else { return }
        guard tracker.cornerAction == nil, tracker.gradientAction == nil, tracker.progressAction == nil else { return }
        tracker.removeFromSuperview()
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
        PTCornerStyle(radius: radius,
                      topLeft: topLeft,
                      topRight: topRight,
                      bottomLeft: bottomLeft,
                      bottomRight: bottomRight,
                      corner: corner,
                      capsule: capsule).path(in: bounds)
    }
    
    @objc func viewCorner(radius:CGFloat = 0,
                          borderWidth:CGFloat = 0,
                          borderColor:UIColor = UIColor.clear,
                          capsule:Bool = false) {
        self.viewCornerRectCorner(radius: radius,borderWidth: borderWidth,borderColor: borderColor,corner: .allCorners,capsule: capsule)
    }
        
    @objc func viewCornerRectCorner(radius: CGFloat = 5, topLeft: CGFloat = 0, topRight: CGFloat = 0, bottomLeft: CGFloat = 0, bottomRight: CGFloat = 0, borderWidth: CGFloat = 0, borderColor: UIColor = UIColor.clear, corner: UIRectCorner = .allCorners, capsule: Bool = false) {
        let style = PTCornerStyle(radius: radius,
                                  topLeft: topLeft,
                                  topRight: topRight,
                                  bottomLeft: bottomLeft,
                                  bottomRight: bottomRight,
                                  corner: corner,
                                  capsule: capsule)
        let tracker = getOrCreateTracker()
        tracker.cornerAction = { [weak self] currentBounds in
            self?.applyViewCorner(style: style,
                                  borderWidth: borderWidth,
                                  borderColor: borderColor,
                                  bounds: currentBounds)
        }
        tracker.invalidateLayout()
        tracker.applyCurrentLayout()
    }

    private func applyViewCorner(style: PTCornerStyle,
                                 borderWidth: CGFloat,
                                 borderColor: UIColor,
                                 bounds: CGRect) {
        let values = style.radii(in: bounds)
        let safeBorderWidth = borderWidth.isFinite ? max(0, borderWidth) : 0

        if #available(iOS 26.0, *) {
            let topLeft = style.corner.contains(.topLeft) || style.corner == .allCorners || style.capsule ? UICornerRadius(floatLiteral: values.topLeft) : nil
            let topRight = style.corner.contains(.topRight) || style.corner == .allCorners || style.capsule ? UICornerRadius(floatLiteral: values.topRight) : nil
            let bottomLeft = style.corner.contains(.bottomLeft) || style.corner == .allCorners || style.capsule ? UICornerRadius(floatLiteral: values.bottomLeft) : nil
            let bottomRight = style.corner.contains(.bottomRight) || style.corner == .allCorners || style.capsule ? UICornerRadius(floatLiteral: values.bottomRight) : nil

            corner26(tL: topLeft, tR: topRight, bL: bottomLeft, bR: bottomRight, capsule: style.capsule)
            layer.mask = nil
            removeCustomCornerBorderLayer()
            layer.masksToBounds = true
            layer.borderWidth = safeBorderWidth
            layer.borderColor = borderColor.cgColor
            return
        }

        layer.masksToBounds = true
        layer.borderColor = borderColor.cgColor

        if style.usesNativeLayer(in: bounds) {
            layer.mask = nil
            removeCustomCornerBorderLayer()
            layer.cornerRadius = values.topLeft
            layer.maskedCorners = style.maskedCorners
            layer.borderWidth = safeBorderWidth
            return
        }

        layer.cornerRadius = 0
        layer.maskedCorners = []
        layer.borderWidth = 0

        let maskLayer: CAShapeLayer
        if let existing = layer.mask as? CAShapeLayer, existing.name == "PTCornerMaskLayer" {
            maskLayer = existing
        } else {
            maskLayer = CAShapeLayer()
            maskLayer.name = "PTCornerMaskLayer"
            layer.mask = maskLayer
        }
        maskLayer.frame = CGRect(origin: .zero, size: bounds.size)
        maskLayer.path = style.path(in: bounds).cgPath

        guard safeBorderWidth > 0 else {
            removeCustomCornerBorderLayer()
            return
        }

        let halfBorder = min(safeBorderWidth / 2, min(bounds.width, bounds.height) / 2)
        let borderBounds = bounds.insetBy(dx: halfBorder, dy: halfBorder)
        let borderLayer = customCornerBorderLayer()
        borderLayer.frame = CGRect(origin: .zero, size: bounds.size)
        borderLayer.path = style.path(in: borderBounds).cgPath
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.strokeColor = borderColor.cgColor
        borderLayer.lineWidth = safeBorderWidth
    }

    private func customCornerBorderLayer() -> CAShapeLayer {
        if let layer = layer.sublayers?.first(where: { $0.name == "PTCustomBorderLayer" }) as? CAShapeLayer {
            return layer
        }
        let layer = CAShapeLayer()
        layer.name = "PTCustomBorderLayer"
        self.layer.addSublayer(layer)
        return layer
    }

    private func removeCustomCornerBorderLayer() {
        layer.sublayers?.filter { $0.name == "PTCustomBorderLayer" }.forEach { $0.removeFromSuperlayer() }
    }

    @objc func removeViewCorner() {
        if let tracker = subviews.first(where: { $0 is PTCornerTrackerView }) as? PTCornerTrackerView {
            tracker.cornerAction = nil
            tracker.invalidateLayout()
        }
        layer.mask = nil
        layer.cornerRadius = 0
        layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMinXMinYCorner]
        layer.masksToBounds = false
        layer.borderWidth = 0
        layer.borderColor = UIColor.clear.cgColor
        removeCustomCornerBorderLayer()
        if #available(iOS 26.0, *) {
            cornerConfiguration = .corners(topLeftRadius: nil, topRightRadius: nil, bottomLeftRadius: nil, bottomRightRadius: nil)
        }
        removeTrackerIfUnused()
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
            if let first = values.first ?? nil,
               values.dropFirst().allSatisfy({ $0 == first }) {
                self.cornerConfiguration = .uniformCorners(radius: first)
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
        let hasBackgroundGradient = bgType != nil && !(bgColors?.isEmpty ?? true)
        let hasBorderGradient = borderType != nil
            && !(borderColors?.isEmpty ?? true)
            && borderWidth.isFinite
            && borderWidth > 0

        if (hasBackgroundGradient || hasBorderGradient) && !ptGradientBackgroundColorCaptured {
            ptGradientOriginalBackgroundColor = backgroundColor
            ptGradientBackgroundColorCaptured = true
        }

        let tracker = getOrCreateTracker()
        guard hasBackgroundGradient || hasBorderGradient else {
            layer.sublayers?
                .filter { $0.name == "PTSuperBg" || $0.name == "PTSuperBorder" }
                .forEach { $0.removeFromSuperlayer() }
            if ptGradientBackgroundColorCaptured {
                backgroundColor = ptGradientOriginalBackgroundColor
            }
            ptGradientOriginalBackgroundColor = nil
            ptGradientBackgroundColorCaptured = false
            tracker.gradientAction = nil
            tracker.invalidateLayout()
            removeTrackerIfUnused()
            return
        }

        tracker.gradientAction = { [weak self] currentBounds in
            guard let self, currentBounds.width > 0, currentBounds.height > 0 else { return }

            let bgPath = self.pt_customCornerPath(bounds: currentBounds,
                                                  radius: radius,
                                                  topLeft: topLeft,
                                                  topRight: topRight,
                                                  bottomLeft: bottomLeft,
                                                  bottomRight: bottomRight,
                                                  corner: corner,
                                                  capsule: capsule)

            let bgLayer = self.gradientLayer(named: "PTSuperBg", insertAt: 0)
            if hasBackgroundGradient, let bgType, let bgColors {
                bgLayer.frame = currentBounds
                bgLayer.colors = bgColors.map(\.cgColor)
                self.applyGradientType(bgLayer, type: bgType)
                let mask = self.gradientMaskLayer(for: bgLayer, named: "PTSuperBgMask")
                mask.frame = currentBounds
                mask.path = bgPath.cgPath
                mask.fillColor = UIColor.white.cgColor
                bgLayer.mask = mask
                self.backgroundColor = .clear
            } else {
                bgLayer.removeFromSuperlayer()
            }

            let borderLayer = self.gradientLayer(named: "PTSuperBorder", insertAt: hasBackgroundGradient ? 1 : 0)
            if hasBorderGradient, let borderType, let borderColors {
                let safeBorderWidth = max(0, borderWidth)
                let halfBorder = min(safeBorderWidth / 2, min(currentBounds.width, currentBounds.height) / 2)
                let insetBounds = currentBounds.insetBy(dx: halfBorder, dy: halfBorder)
                let borderPath = self.pt_customCornerPath(bounds: insetBounds,
                                                          radius: radius - halfBorder,
                                                          topLeft: topLeft - halfBorder,
                                                          topRight: topRight - halfBorder,
                                                          bottomLeft: bottomLeft - halfBorder,
                                                          bottomRight: bottomRight - halfBorder,
                                                          corner: corner,
                                                          capsule: capsule)

                borderLayer.frame = currentBounds
                borderLayer.colors = borderColors.map(\.cgColor)
                self.applyGradientType(borderLayer, type: borderType)
                let mask = self.gradientMaskLayer(for: borderLayer, named: "PTSuperBorderMask")
                mask.frame = currentBounds
                mask.path = borderPath.cgPath
                mask.fillColor = UIColor.clear.cgColor
                mask.strokeColor = UIColor.black.cgColor
                mask.lineWidth = safeBorderWidth
                borderLayer.mask = mask
            } else {
                borderLayer.removeFromSuperlayer()
            }

            if hasBackgroundGradient {
                self.backgroundColor = .clear
            } else if self.ptGradientBackgroundColorCaptured {
                self.backgroundColor = self.ptGradientOriginalBackgroundColor
            }
        }
        tracker.invalidateLayout()
        tracker.applyCurrentLayout()
    }

    private func gradientLayer(named name: String, insertAt index: Int) -> CAGradientLayer {
        if let existing = layer.sublayers?.first(where: { $0.name == name }) as? CAGradientLayer {
            return existing
        }
        let newLayer = CAGradientLayer()
        newLayer.name = name
        layer.insertSublayer(newLayer, at: UInt32(max(0, index)))
        return newLayer
    }

    private func gradientMaskLayer(for gradientLayer: CAGradientLayer, named name: String) -> CAShapeLayer {
        if let existing = gradientLayer.mask as? CAShapeLayer, existing.name == name {
            return existing
        }
        let newMask = CAShapeLayer()
        newMask.name = name
        gradientLayer.mask = newMask
        return newMask
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
        let safeValue = value.isFinite ? min(max(value, 0), 1) : 0
        let safeBorderWidth = borderWidth.isFinite ? max(0, borderWidth) : 0
        ptProgressCleanupTask?.cancel()
        ptProgressCleanupTask = nil
        let progressGeneration = UUID()
        ptProgressGeneration = progressGeneration

        let shape: CAShapeLayer
        if let existing = viewShapeLayer {
            shape = existing
        } else {
            shape = CAShapeLayer()
            shape.name = "PTProgressLayer"
            shape.fillColor = UIColor.clear.cgColor
            shape.lineCap = .round
            layer.addSublayer(shape)
            viewShapeLayer = shape
        }
        shape.strokeColor = borderColor.cgColor
        shape.lineWidth = safeBorderWidth
        shape.opacity = 1
        shape.removeAllAnimations()

        if showValueLabel {
            let label: UILabel
            if let existing = viewShapeLayerProgressLabel {
                label = existing
            } else {
                label = UILabel()
                addSubview(label)
                label.snp.makeConstraints { $0.center.equalToSuperview() }
                viewShapeLayerProgressLabel = label
            }
            label.font = valueLabelFont
            label.textColor = valueLabelColor
            label.textAlignment = .center
            label.alpha = 1
            label.text = String(format: "%.\(uniCount)f%%", 100 * safeValue)
        } else {
            viewShapeLayerProgressLabel?.removeFromSuperview()
            viewShapeLayerProgressLabel = nil
        }

        let tracker = getOrCreateTracker()
        tracker.progressAction = { [weak self] currentBounds in
            guard let self, let shape = self.viewShapeLayer,
                  currentBounds.width > 0, currentBounds.height > 0 else { return }

            let halfBorder = min(safeBorderWidth / 2, min(currentBounds.width, currentBounds.height) / 2)
            let insetBounds = currentBounds.insetBy(dx: halfBorder, dy: halfBorder)
            let path = self.pt_customCornerPath(bounds: insetBounds,
                                                radius: radius - halfBorder,
                                                topLeft: topLeft - halfBorder,
                                                topRight: topRight - halfBorder,
                                                bottomLeft: bottomLeft - halfBorder,
                                                bottomRight: bottomRight - halfBorder,
                                                corner: corner,
                                                capsule: capsule)
            shape.path = path.cgPath
            self.layer.bringSublayerToFront(shape)
        }
        tracker.invalidateLayout()
        tracker.applyCurrentLayout()
        shape.strokeEnd = safeValue

        if safeValue >= 0.999 {
            ptProgressCleanupTask = Task { @MainActor [weak self] in
                do {
                    try await Task.sleep(nanoseconds: 200_000_000)
                } catch {
                    return
                }
                guard let self,
                      self.ptProgressGeneration == progressGeneration,
                      let shape = self.viewShapeLayer else { return }
                UIView.animate(withDuration: 0.3, animations: {
                    shape.opacity = 0
                    self.viewShapeLayerProgressLabel?.alpha = 0
                }) { [weak self] _ in
                    guard let self, self.ptProgressGeneration == progressGeneration else { return }
                    self.clearProgressLayer()
                }
            }
        }
    }
    
    func clearProgressLayer() {
        ptProgressCleanupTask?.cancel()
        ptProgressCleanupTask = nil
        ptProgressGeneration = nil
        viewShapeLayer?.removeFromSuperlayer()
        viewShapeLayer = nil

        viewShapeLayerProgressLabel?.removeFromSuperview()
        viewShapeLayerProgressLabel = nil
        
        // 中文：移除进度条监听，避免清理后尺寸变化再次访问已释放的 Layer。
        if let tracker = self.subviews.first(where: { $0 is PTCornerTrackerView }) as? PTCornerTrackerView {
            tracker.progressAction = nil
            tracker.invalidateLayout()
        }
        removeTrackerIfUnused()
    }
}

public extension UIView {
              
    /// 判断当前系统语言布局是否为从右到左 (RTL, 例如阿拉伯语)
    static func isRTL() -> Bool {
        UIView.userInterfaceLayoutDirection(for: UIView.appearance().semanticContentAttribute) == .rightToLeft
    }
    
    @MainActor
    private struct AssociatedKeys {
        static var layoutSubviewsCallback: UInt8 = 0
        static var layoutShapeLayerCallback: UInt8 = 0
        static var layoutShapeLayerProgressLabelCallback: UInt8 = 0
        static var gradientOriginalBackgroundColor: UInt8 = 0
        static var gradientBackgroundColorCaptured: UInt8 = 0
        static var progressCleanupTask: UInt8 = 0
        static var progressGeneration: UInt8 = 0
        static var viewCapturing: UInt8 = 0
        static var borderTracker: UInt8 = 0 // 新增用于绑定 Tracker
    }

    @MainActor
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

    private var ptGradientOriginalBackgroundColor: UIColor? {
        get {
            objc_getAssociatedObject(self, &AssociatedKeys.gradientOriginalBackgroundColor) as? UIColor
        }
        set {
            objc_setAssociatedObject(self,
                                     &AssociatedKeys.gradientOriginalBackgroundColor,
                                     newValue,
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    private var ptGradientBackgroundColorCaptured: Bool {
        get {
            (objc_getAssociatedObject(self, &AssociatedKeys.gradientBackgroundColorCaptured) as? Bool) ?? false
        }
        set {
            objc_setAssociatedObject(self,
                                     &AssociatedKeys.gradientBackgroundColorCaptured,
                                     newValue,
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    private var ptProgressCleanupTask: Task<Void, Never>? {
        get {
            objc_getAssociatedObject(self, &AssociatedKeys.progressCleanupTask) as? Task<Void, Never>
        }
        set {
            objc_setAssociatedObject(self,
                                     &AssociatedKeys.progressCleanupTask,
                                     newValue,
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    private var ptProgressGeneration: UUID? {
        get {
            objc_getAssociatedObject(self, &AssociatedKeys.progressGeneration) as? UUID
        }
        set {
            objc_setAssociatedObject(self,
                                     &AssociatedKeys.progressGeneration,
                                     newValue,
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
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
        if let scrollView = self as? UIScrollView {
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
                             lineBreakMode: NSLineBreakMode = .byWordWrapping,
                             height:CGFloat = CGFloat.greatestFiniteMagnitude,
                             width:CGFloat = CGFloat.greatestFiniteMagnitude) -> CGSize {
        guard !string.isEmpty else { return .zero }
        return string.boundingSize(font: font,lineSpacing: lineSpacing,lineBreakMode: lineBreakMode,width: width,height: height)
    }
    
    var viewController: UIViewController? {
        weak var parentResponder: UIResponder? = self
        while let responder = parentResponder?.next {
            parentResponder = responder
            if let viewController = responder as? UIViewController {
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
        removeViewCorner()
        layer.cornerRadius = radius
        layer.maskedCorners = corners
        layer.cornerCurve = curve.layerCornerCurve
    }
    
    /**
        Round side by minimum `height` or `width`.
     */
    func roundMinimumSide() {
        // 中文：交给动态圆角路径等待 Auto Layout 完成，避免 SnapKit 尚未布局时读取到零尺寸。
        viewCorner(capsule: true)
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
        while let currentResponder = responder {
            if currentResponder.isKind(of: `class`) {
                return currentResponder as? T
            }
            responder = currentResponder.next
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

public extension UIView {

    /// 类型化图片加载入口，旧的 Any 入口继续作为兼容层保留。
    @MainActor
    func pt_loadCoreImage(source: PTImageSource,
                          configuration: PTImageLoadConfiguration,
                          progressHandle: (@MainActor @Sendable (_ receivedSize: Int64, _ totalSize: Int64) -> Void)? = nil,
                          setImageBlock: @escaping @MainActor @Sendable (UIImage?) -> Void,
                          loadFinish: (@MainActor @Sendable (PTLoadImageResult) -> Void)? = nil) {
        switch source {
        case .image(let image):
            pt_loadCoreImage(contentData: image,
                             configuration: configuration,
                             progressHandle: progressHandle,
                             setImageBlock: setImageBlock,
                             loadFinish: loadFinish)
        case .data(let data):
            pt_loadCoreImage(contentData: data,
                             configuration: configuration,
                             progressHandle: progressHandle,
                             setImageBlock: setImageBlock,
                             loadFinish: loadFinish)
        case .asset(let asset):
            pt_loadCoreImage(contentData: asset,
                             configuration: configuration,
                             progressHandle: progressHandle,
                             setImageBlock: setImageBlock,
                             loadFinish: loadFinish)
        case .color(let color):
            pt_loadCoreImage(contentData: color,
                             configuration: configuration,
                             progressHandle: progressHandle,
                             setImageBlock: setImageBlock,
                             loadFinish: loadFinish)
        case .url(let url):
            pt_loadCoreImage(contentData: url,
                             configuration: configuration,
                             progressHandle: progressHandle,
                             setImageBlock: setImageBlock,
                             loadFinish: loadFinish)
        case .named(let name):
            pt_loadCoreImage(contentData: name,
                             configuration: configuration,
                             progressHandle: progressHandle,
                             setImageBlock: setImageBlock,
                             loadFinish: loadFinish)
        }
    }

    @MainActor
    func pt_loadCoreImage(contentData: Any,
                          configuration: PTImageLoadConfiguration,
                          progressHandle: (@MainActor @Sendable (_ receivedSize: Int64, _ totalSize: Int64) -> Void)? = nil,
                          setImageBlock: @escaping @MainActor @Sendable (UIImage?) -> Void,
                          loadFinish: (@MainActor @Sendable (PTLoadImageResult) -> Void)? = nil) {
        pt_loadCoreImage(contentData: contentData,
                         iCloudDocumentName: configuration.iCloudDocumentName,
                         radius: configuration.radius,
                         topLeft: configuration.topLeft,
                         topRight: configuration.topRight,
                         bottomLeft: configuration.bottomLeft,
                         bottomRight: configuration.bottomRight,
                         corner: configuration.corner,
                         capsule: configuration.capsule,
                         borderWidth: configuration.borderWidth,
                         borderColor: configuration.borderColor,
                         showValueLabel: configuration.showValueLabel,
                         valueLabelFont: configuration.valueLabelFont,
                         valueLabelColor: configuration.valueLabelColor,
                         uniCount: configuration.uniCount,
                         emptyImage: configuration.emptyImage,
                         progressHandle: progressHandle,
                         setImageBlock: setImageBlock,
                         loadFinish: loadFinish)
    }
    
    // 2. 手动取消
    // 🌟 标记 @MainActor 确保在主线程操作 Task 引用
    @MainActor
    func cancelImageLoad() {
        ptLoadTask?.cancel()
        ptLoadTask = nil
        ptLoadUUID = nil
    }
    
    // 3. 核心大一统方法
    @MainActor // 🌟 整个方法基于 UI，直接标记为 MainActor
    func pt_loadCoreImage(contentData: Any,
                          iCloudDocumentName: String = "",
                          radius: CGFloat = 0,
                          topLeft: CGFloat = 0,
                          topRight: CGFloat = 0,
                          bottomLeft: CGFloat = 0,
                          bottomRight: CGFloat = 0,
                          corner: UIRectCorner = .allCorners,
                          capsule: Bool = false,
                          borderWidth: CGFloat? = nil,
                          borderColor: UIColor? = nil,
                          showValueLabel: Bool? = nil,
                          valueLabelFont: UIFont? = nil,
                          valueLabelColor: UIColor? = nil,
                          uniCount: Int? = nil,
                          emptyImage: UIImage? = nil,
                          progressHandle: (@MainActor @Sendable (_ receivedSize: Int64, _ totalSize: Int64) -> Void)? = nil,
                          setImageBlock: @escaping @MainActor @Sendable (UIImage?) -> Void,
                          loadFinish: (@MainActor @Sendable (PTLoadImageResult) -> Void)? = nil) {
        
        let borderW = borderWidth ?? PTAppBaseConfig.share.loadImageProgressBorderWidth
        let borderC = borderColor ?? PTAppBaseConfig.share.loadImageProgressBorderColor
        let showValueL = showValueLabel ?? PTAppBaseConfig.share.loadImageShowValueLabel
        let valueLabelF = valueLabelFont ?? PTAppBaseConfig.share.loadImageShowValueFont
        let valueLabelC = valueLabelColor ?? PTAppBaseConfig.share.loadImageShowValueColor
        let uniC = uniCount ?? PTAppBaseConfig.share.loadImageShowValueUniCount
        let placeholder = emptyImage ?? PTAppBaseConfig.share.defaultEmptyImage

        // 取消旧任务
        cancelImageLoad()

        let loadID = UUID()
        self.ptLoadUUID = loadID

        // 内部安全校验：由于整个上下文是 @MainActor，直接比对是安全的
        let isValid: @MainActor @Sendable () -> Bool = { [weak self] in
            return self?.ptLoadUUID == loadID
        }

        let setEmpty: @MainActor @Sendable () -> Void = {
            guard isValid() else { return }
            // 此时调用 setImageBlock 绝对安全
            setImageBlock(placeholder)
        }

        let showImage: @MainActor @Sendable (UIImage) -> Void = { [weak self] image in
            guard let self = self, isValid() else { return }
            
            setImageBlock(image)
            self.layerProgress(value: 1,
                               radius: radius,
                               topLeft: topLeft,
                               topRight: topRight,
                               bottomLeft: bottomLeft,
                               bottomRight: bottomRight,
                               corner: corner,
                               capsule: capsule,
                               borderWidth: borderW,
                               borderColor: borderC,
                               showValueLabel: showValueL,
                               valueLabelFont: valueLabelF,
                               valueLabelColor: valueLabelC,
                               uniCount: uniC)
        }

        let finish: @MainActor @Sendable (PTLoadImageResult) -> Void = { result in
            guard isValid() else { return }
            
            guard let images = result.allImages, !images.isEmpty else {
                setEmpty()
                loadFinish?(result)
                return
            }

            if images.count > 1 {
                let loadTime = result.loadTime
                guard let gif = UIImage.animatedImage(with: images, duration: loadTime) else {
                    setEmpty()
                    loadFinish?(result)
                    return
                }
                showImage(gif)
                loadFinish?(result)
            } else {
                guard let image = result.firstImage else {
                    setEmpty()
                    loadFinish?(result)
                    return
                }
                showImage(image)
                loadFinish?(result)
            }
        }

        let loadVideo: @MainActor @Sendable (URL) -> Void = { [weak self] url in
            PTVideoCoverCache.getVideoFirstImage(videoUrl: url.absoluteString) { [weak self] image in
                Task { @MainActor in
                    guard self?.ptLoadUUID == loadID else { return }
                    if let image {
                        finish(PTLoadImageResult(allImages: [image],
                                                 firstImage: image,
                                                 loadTime: 0,
                                                 imageType: .other))
                    } else {
                        finish(PTLoadImageResult(allImages: nil,
                                                 firstImage: nil,
                                                 loadTime: 0,
                                                 imageType: .unknown))
                    }
                }
            }
        }

        func loadFromURL(_ url: URL) {
            let ext = url.pathExtension.lowercased()

            // 视频
            if GlobalVideoExts.contains(ext) {
                loadVideo(url)
                return
            }

            // 🌟 将 Task 明确标记为继承 @MainActor，保护内部的 UI 操作
            ptLoadTask = Task { @MainActor in
                if Task.isCancelled { return }

                if let cache = await PTLoadImageFunction.cachedImage(from: url) {
                    if Task.isCancelled { return }
                    finish(cache)
                    return
                }

                let result = await PTLoadImageFunction.loadImage(
                    contentData: url,
                    iCloudDocumentName: iCloudDocumentName
                ) { @Sendable received, total in
                    // 🌟 网络进度回调（可能是后台），切回主线程再操作 self
                    Task { @MainActor in
                        guard self.ptLoadUUID == loadID else { return }
                        if let progressHandle {
                            progressHandle(received, total)
                        } else {
                            let progress = total > 0
                                ? min(max(CGFloat(received) / CGFloat(total), 0), 1)
                                : 0
                            self.layerProgress(
                                value: progress,
                                radius: radius,
                                topLeft: topLeft,
                                topRight: topRight,
                                bottomLeft: bottomLeft,
                                bottomRight: bottomRight,
                                corner: corner,
                                capsule: capsule,
                                borderWidth: borderW,
                                borderColor: borderC,
                                showValueLabel: showValueL,
                                valueLabelFont: valueLabelF,
                                valueLabelColor: valueLabelC,
                                uniCount: uniC
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
            finish(PTLoadImageResult(allImages: [image], firstImage: image, loadTime: 0, imageType: .other))
        case let color as UIColor:
            let image = color.createImageWithColor()
            finish(PTLoadImageResult(allImages: [image], firstImage: image, loadTime: 0, imageType: .other))
        case let data as Data:
            if let image = UIImage(data: data) {
                finish(PTLoadImageResult(allImages: [image], firstImage: image, loadTime: 0, imageType: .other))
            } else {
                finish(PTLoadImageResult(allImages: nil, firstImage: nil, loadTime: 0, imageType: .unknown))
            }
        case let asset as PHAsset:
            ptLoadTask = Task { @MainActor in
                if Task.isCancelled { return }
                let result = await PTLoadImageFunction.handleAssetContent(asset: asset)
                if Task.isCancelled { return }
                finish(result)
            }
        case let avasset as AVAsset:
            avasset.getVideoFirstImage { [weak self] image in
                Task { @MainActor in
                    // 确保 UIView 还没有被销毁，并且本次加载任务没有被新任务覆盖
                    guard let self = self, self.ptLoadUUID == loadID else { return }
                    
                    if let image {
                        finish(PTLoadImageResult(allImages: [image],
                                                 firstImage: image,
                                                 loadTime: 0,
                                                 imageType: .other))
                    } else {
                        finish(PTLoadImageResult(allImages: nil,
                                                 firstImage: nil,
                                                 loadTime: 0,
                                                 imageType: .unknown))
                    }
                }
            }
        case let url as URL:
            loadFromURL(url)
        case let string as String:
            if FileManager.default.fileExists(atPath: string) {
                if let image = UIImage(contentsOfFile: string) {
                    finish(PTLoadImageResult(allImages: [image], firstImage: image, loadTime: 0, imageType: .other))
                } else {
                    finish(PTLoadImageResult(allImages: nil, firstImage: nil, loadTime: 0, imageType: .unknown))
                }
                return
            }
            if string.isURL(), let url = URL(string: string) {
                loadFromURL(url)
            } else if let image = UIImage(named: string) {
                finish(PTLoadImageResult(allImages: [image], firstImage: image, loadTime: 0, imageType: .other))
            } else {
                finish(PTLoadImageResult(allImages: nil, firstImage: nil, loadTime: 0, imageType: .unknown))
            }
        default:
            finish(PTLoadImageResult(allImages: nil, firstImage: nil, loadTime: 0, imageType: .unknown))
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
        guard !bounds.isEmpty else { return nil }
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

    private func pt_commonAncestor(of first: UIView, and second: UIView?) -> UIView? {
        guard let second else { return first }
        var candidate: UIView? = first
        while let current = candidate {
            if current === second || second.isDescendant(of: current) {
                return current
            }
            candidate = current.superview
        }
        return nil
    }

    private func pt_installConstraint(_ constraint: NSLayoutConstraint,
                                      first: UIView,
                                      second: UIView?) {
        // 中文：约束必须安装到两个视图的最近公共祖先；无公共祖先时只返回未激活约束，避免 UIKit 直接抛异常。
        guard let owner = pt_commonAncestor(of: first, and: second) else { return }
        owner.addConstraint(constraint)
    }
    
    @discardableResult
    func leadingConstraint(subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: self, attribute: .leading, relatedBy: relatedBy, toItem: subView, attribute: .leading, multiplier: multiplier, constant: constant)
        pt_installConstraint(constraint, first: self, second: subView)
        return constraint
    }
    
    @discardableResult
    func trailingConstraint(subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: relatedBy, toItem: subView, attribute: .trailing, multiplier: multiplier, constant: constant)
        pt_installConstraint(constraint, first: self, second: subView)
        return constraint
    }
    
    @discardableResult
    func topConstraint(subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: self, attribute: .top, relatedBy: relatedBy, toItem: subView, attribute: .top, multiplier: multiplier, constant: constant)
        pt_installConstraint(constraint, first: self, second: subView)
        return constraint
    }
    
    @discardableResult
    func bottomConstraint(subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: relatedBy, toItem: subView, attribute: .bottom, multiplier: multiplier, constant: constant)
        pt_installConstraint(constraint, first: self, second: subView)
        return constraint
    }
    
    @discardableResult
    func centerXConstraint(subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: self, attribute: .centerX, relatedBy: relatedBy, toItem: subView, attribute: .centerX, multiplier: multiplier, constant: constant)
        pt_installConstraint(constraint, first: self, second: subView)
        return constraint
    }
    
    @discardableResult
    func centerYConstraint(subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: self, attribute: .centerY, relatedBy: relatedBy, toItem: subView, attribute: .centerY, multiplier: multiplier, constant: constant)
        pt_installConstraint(constraint, first: self, second: subView)
        return constraint
    }
    
    @discardableResult
    func leadingConstraint(item: UIView, subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: item, attribute: .leading, relatedBy: relatedBy, toItem: subView, attribute: .leading, multiplier: multiplier, constant: constant)
        pt_installConstraint(constraint, first: item, second: subView)
        return constraint
    }
    
    @discardableResult
    func trailingConstraint(item: UIView, subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: item, attribute: .trailing, relatedBy: relatedBy, toItem: subView, attribute: .trailing, multiplier: multiplier, constant: constant)
        pt_installConstraint(constraint, first: item, second: subView)
        return constraint
    }
    
    @discardableResult
    func topConstraint(item: UIView, subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: item, attribute: .top, relatedBy: relatedBy, toItem: subView, attribute: .top, multiplier: multiplier, constant: constant)
        pt_installConstraint(constraint, first: item, second: subView)
        return constraint
    }
    
    @discardableResult
    func bottomConstraint(item: UIView, subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: item, attribute: .bottom, relatedBy: relatedBy, toItem: subView, attribute: .bottom, multiplier: multiplier, constant: constant)
        pt_installConstraint(constraint, first: item, second: subView)
        return constraint
    }
    
    @discardableResult
    func centerXConstraint(item: UIView, subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: item, attribute: .centerX, relatedBy: relatedBy, toItem: subView, attribute: .centerX, multiplier: multiplier, constant: constant)
        pt_installConstraint(constraint, first: item, second: subView)
        return constraint
    }
    
    @discardableResult
    func centerYConstraint(item: UIView, subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: item, attribute: .centerY, relatedBy: relatedBy, toItem: subView, attribute: .centerY, multiplier: multiplier, constant: constant)
        pt_installConstraint(constraint, first: item, second: subView)
        return constraint
    }
    
    @discardableResult
    func widthConstraint(item: UIView, subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: item, attribute: .width, relatedBy: relatedBy, toItem: subView, attribute: .width, multiplier: multiplier, constant: constant)
        pt_installConstraint(constraint, first: item, second: subView)
        return constraint
    }
    
    @discardableResult
    func heightConstraint(item: UIView, subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: item, attribute: .height, relatedBy: relatedBy, toItem: subView, attribute: .height, multiplier: multiplier, constant: constant)
        pt_installConstraint(constraint, first: item, second: subView)
        return constraint
    }
    
    @discardableResult
    func widthConstraint(subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: self, attribute: .width, relatedBy: relatedBy, toItem: subView, attribute: .width, multiplier: multiplier, constant: constant)
        pt_installConstraint(constraint, first: self, second: subView)
        return constraint
    }
    
    @discardableResult
    func heightConstraint(subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: self, attribute: .height, relatedBy: relatedBy, toItem: subView, attribute: .height, multiplier: multiplier, constant: constant)
        pt_installConstraint(constraint, first: self, second: subView)
        return constraint
    }
    
    @discardableResult
    func widthConstraint(constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: self, attribute: .width, relatedBy: relatedBy, toItem: nil, attribute: .width, multiplier: 1, constant: constant)
        pt_installConstraint(constraint, first: self, second: nil)
        return constraint
    }
    
    @discardableResult
    func heightConstraint(constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: self, attribute: .height, relatedBy: relatedBy, toItem: nil, attribute: .height, multiplier: 1, constant: constant)
        pt_installConstraint(constraint, first: self, second: nil)
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
        }
        return subviews.contains { $0.isContainWKWebView() }
    }
    
    /** 快照回调*/
    typealias captureCompletion = (UIImage?) -> Void
    
    /// 对视图进行快照
    ///
    /// - Parameter completion: 回调
    func captureCurrent(_ completion: captureCompletion) {
        self.isCapturing = true

        guard !bounds.isEmpty else {
            self.isCapturing = false
            completion(nil)
            return
        }
        
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
        guard !bounds.isEmpty else { return UIImage() }
        let format = UIGraphicsImageRendererFormat()
        format.opaque = opaque
        format.scale = scale.isFinite && scale > 0 ? scale : UIScreen.main.scale
        
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
        guard imageSize.width > 0, imageSize.height > 0 else { return UIImage() }
        let orientation = AppWindows?.windowScene?.interfaceOrientation
            ?? UIInterfaceOrientation(rawValue: UIDevice.current.orientation.rawValue)
            ?? .portrait
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
        guard !bounds.isEmpty else { return UIImage() }
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
    // 🌟 修复 1：明确整个扩展方法都在主线程执行
    @MainActor
    public func fadeUpdate(duration: TimeInterval = 1,
                           delay: TimeInterval = 0.15,
                           work: @escaping @MainActor (Self) -> Void,
                           completion: (@MainActor @Sendable () -> Void)? = nil) {
        
        let safeDuration = max(0, duration.isFinite ? duration : 0)
        let safeDelay = min(max(0, delay.isFinite ? delay : 0), safeDuration)
        let partDuration = max(0, (safeDuration - safeDelay) / 2)
        let storedAlpha = self.alpha
        
        // 第一阶段：淡出
        UIView.animate(withDuration: partDuration, delay: .zero, options: [.beginFromCurrentState, .allowUserInteraction], animations: { [weak self] in
            self?.alpha = .zero
        }, completion: { [weak self] finished in
            guard let self = self else { return }
            
            // 🌟 在这里执行外部传入的 UI 数据更新操作
            // 因为 work 被标记了 @MainActor，且当前在 UIView.animate 的主线程回调中，所以绝对安全
            work(self)
            
            // 第二阶段：淡入（嵌套动画）
            UIView.animate(withDuration: partDuration, delay: safeDelay, options: [.beginFromCurrentState, .allowUserInteraction], animations: { [weak self] in
                self?.alpha = storedAlpha
            }, completion: { finished in
                // 🌟 修复 4：UIView.animate 的 completion 天然就在 MainActor 上，
                // 直接调用即可，去掉了冗余的 Task { @MainActor in }，动画衔接会更丝滑
                completion?()
            })
        })
    }
}

extension UIView: UIFadeOut {}
#endif
