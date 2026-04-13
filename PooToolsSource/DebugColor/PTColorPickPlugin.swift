//
//  PTColorPickPlugin.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 6/6/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SwifterSwift
import SnapKit

let CorpSize: CGFloat = 150

public typealias PTColorPickMagnifyLayerBlock = (CGPoint) -> String
public let kPTClosePluginNotification = "kPTClosePluginNotification"

public extension CGFloat {
    static func SizeFrom750(x: CGFloat) -> CGFloat {
        x * CGFloat.kSCREEN_WIDTH / 750
    }
}

open class PTColorPickPlugin: NSObject {
    public static let share = PTColorPickPlugin()
    
    public var showed: Bool = false
    
    public override init() {
        super.init()
    }
    
    public func show() {
        PTColorPickWindow.share.show()
        showed = true
    }
    
    public func close() {
        PTColorPickWindow.share.hide()
        showed = false
    }
}

// MARK: - 像素缓冲区管理 (修复颜色不匹配 & 色彩空间问题)
final class PTPixelBuffer {
    // 使用自带的数组管理内存，完全避免 CFData 指针变成野指针的风险
    private var rawData: [UInt8] = []
    
    private(set) var width: Int = 0
    private(set) var height: Int = 0
    private(set) var bytesPerRow: Int = 0
    
    func update(from image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        
        width = cgImage.width
        height = cgImage.height
        
        let bytesPerPixel = 4
        bytesPerRow = width * bytesPerPixel
        let totalBytes = height * bytesPerRow
        
        // 初始化一块全零的内存空间
        rawData = [UInt8](repeating: 0, count: totalBytes)
        
        // 🔥 核心修复：创建一个标准的 DeviceRGB 色彩空间
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        // 强制指定字节顺序为 RGBA (大端模式 + PremultipliedLast)
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        
        // 将图像绘制到我们的内存上下文中，这一步会自动处理任何格式的图片，输出纯正的 RGBA 数据
        guard let context = CGContext(data: &rawData,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: 8,
                                      bytesPerRow: bytesPerRow,
                                      space: colorSpace,
                                      bitmapInfo: bitmapInfo) else { return }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
    }
    
    func color(at pixel: CGPoint) -> String {
        guard !rawData.isEmpty else { return "" }
        
        // 使用 round 四舍五入，提高拾取边缘像素的精准度
        let x = Int(round(pixel.x))
        let y = Int(round(pixel.y))
        
        guard x >= 0, y >= 0, x < width, y < height else { return "" }
        
        let offset = y * bytesPerRow + x * 4
        
        // 由于上面强制使用了 RGBA 上下文，这里可以放心大胆地按顺序读取
        let r = rawData[offset]
        let g = rawData[offset + 1]
        let b = rawData[offset + 2]
        
        return String(format: "#%02x%02x%02x", r, g, b).uppercased()
    }
}

// MARK: - 放大镜图层 (优化 GPU 渲染性能)
fileprivate class PTColorPickMagnifyLayer: CALayer {

    static let size: CGFloat = 150
    // 🔥 修复点：调整为 2.5 倍放大，方便肉眼确认十字线对准的像素
    static let zoom: CGFloat = 2.5

    var image: CGImage? {
        didSet {
            if imageLayer.contents == nil || (imageLayer.contents as AnyObject) !== (image as AnyObject) {
                imageLayer.contents = image
            }
        }
    }

    private let imageLayer = CALayer()
    private let crosshair = CAShapeLayer()

    override init() {
        super.init()

        bounds = CGRect(x: 0, y: 0, width: CorpSize, height: CorpSize)
        anchorPoint = CGPoint(x: 0.5, y: 1)

        imageLayer.frame = bounds
        imageLayer.magnificationFilter = .nearest // 保持像素颗粒感
        addSublayer(imageLayer)

        cornerRadius = CorpSize / 2
        masksToBounds = true
        borderWidth = 3
        borderColor = UIColor.white.cgColor

        setupCrosshair()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupCrosshair() {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: CorpSize / 2, y: 0))
        path.addLine(to: CGPoint(x: CorpSize / 2, y: CorpSize))
        path.move(to: CGPoint(x: 0, y: CorpSize / 2))
        path.addLine(to: CGPoint(x: CorpSize, y: CorpSize / 2))

        crosshair.path = path.cgPath
        crosshair.strokeColor = UIColor.red.cgColor
        // 让十字线细一点，避免遮挡中心目标像素
        crosshair.lineWidth = 0.5
        addSublayer(crosshair)
    }

    func update(targetPoint: CGPoint, screenScale: CGFloat) {
        guard let cgImage = image else { return }

        let pixelWidth = CGFloat(cgImage.width)
        let pixelHeight = CGFloat(cgImage.height)

        let cropPixelSize = (Self.size * screenScale) / Self.zoom

        let x = (targetPoint.x * screenScale) - (cropPixelSize / 2.0)
        let y = (targetPoint.y * screenScale) - (cropPixelSize / 2.0)

        let rect = CGRect(
            x: x / pixelWidth,
            y: y / pixelHeight,
            width: cropPixelSize / pixelWidth,
            height: cropPixelSize / pixelHeight
        )
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        imageLayer.contentsRect = rect
        CATransaction.commit()
    }
}

// MARK: - 颜色信息界面
fileprivate class PTColorPickInfoView: UIView {
    public var closeBlock: ((UIButton, PTColorPickInfoView) -> Void)?
    
    public var currentColor: String? {
        didSet {
            if let color = currentColor, !color.isEmpty {
                colorView.backgroundColor = UIColor(hexString: color)
                colorValueLbl.text = color
            }
        }
    }
    
    private lazy var colorView: UIView = {
        let view = UIView()
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor(hexString: "#999999")?.withAlphaComponent(0.2).cgColor
        return view
    }()
    
    private lazy var colorValueLbl: UILabel = {
        let view = UILabel()
        view.textColor = UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .light ? UIColor(hexString: "#333333")! : UIColor(hexString: "#DDDDDD")!
        }
        view.font = UIFont.systemFont(ofSize: CGFloat.SizeFrom750(x: 28)) // 如果你有 .appfont 方法可以替换回来
        return view
    }()
    
    fileprivate lazy var closeBtn: UIButton = {
        let view = UIButton(type: .custom)
        // 注意：如果你使用了扩展方法 emojiToImage，可以保留。这里用系统默认作为 fallback 保底
        view.setTitle("❌", for: .normal)
        // view.setImage("❌".emojiToImage(emojiFont: .appfont(size: 20)), for: .normal)
        view.addAction(UIAction(handler: { [weak self] _ in
            guard let self = self else { return }
            self.closeBlock?(view, self)
        }), for: .touchUpInside)
        return view
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
        commonInit()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func commonInit() {
        backgroundColor = UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .light ? .white : .black
        }
                
        addSubviews([colorView, closeBtn, colorValueLbl])
        
        colorView.snp.makeConstraints { make in
            make.size.equalTo(CGFloat.SizeFrom750(x: 28))
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().inset(CGFloat.SizeFrom750(x: 32))
        }
        
        closeBtn.snp.makeConstraints { make in
            make.size.equalTo(CGFloat.SizeFrom750(x: 44))
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(CGFloat.SizeFrom750(x: 32))
        }
        
        colorValueLbl.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalTo(self.colorView.snp.right).offset(8)
            make.right.equalTo(self.closeBtn.snp.left).offset(-8)
        }
        
        // 假设你有扩展方法 viewCorner，这里做个简单兼容实现，你可以改回你自己的
        self.layer.cornerRadius = CGFloat.SizeFrom750(x: 8)
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor(hexString: "#999999")?.withAlphaComponent(0.2).cgColor
    }
}

// MARK: - 吸管窗口界面
public class PTColorPickWindow: UIWindow {
    static let share = PTColorPickWindow()
    
    // 🔥 删除了 displayLink 和 lastCaptureTime，不需要它们了
    
    private var screenShotImage: UIImage = UIImage()
    private let pixelBuffer = PTPixelBuffer()
    
    private lazy var magnifyLayer: PTColorPickMagnifyLayer = {
        let layer = PTColorPickMagnifyLayer()
        layer.contentsScale = UIScreen.main.scale
        return layer
    }()
    
    public var currentColor: String? {
        didSet {
            pickInfoView.currentColor = currentColor
        }
    }
    
    private lazy var pickInfoView: PTColorPickInfoView = {
        let view = PTColorPickInfoView(frame: .zero)
        view.closeBlock = { [weak self] _, _ in
            self?.hide()
        }
        return view
    }()
    
    init() {
        if let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first {
            super.init(windowScene: scene)
        } else {
            super.init(frame: UIScreen.main.bounds)
        }
        
        windowLevel = .alert + 202
        backgroundColor = .clear
        
        magnifyLayer.position = CGPoint(x: 100, y: 100)
        magnifyLayer.isHidden = true // 初始隐藏，手势触发才显示
        layer.addSublayer(magnifyLayer)
        
        addSubview(pickInfoView)
        let bottomInset: CGFloat = 34
        pickInfoView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(CGFloat.SizeFrom750(x: 30))
            make.bottom.equalToSuperview().inset(bottomInset + CGFloat.SizeFrom750(x: 30))
            make.width.equalTo(CGFloat.kSCREEN_WIDTH - 2 * CGFloat.SizeFrom750(x: 30))
            make.height.equalTo(CGFloat.SizeFrom750(x: 100))
        }
        bringSubviewToFront(pickInfoView)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(pan)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - 核心逻辑处理
private extension PTColorPickWindow {
    
    @objc func handlePan(_ pan: UIPanGestureRecognizer) {
        let point = pan.location(in: self)
        if pan.state == .began {
            // 🔥 核心优化：只在手指刚刚按下时，截图一次。拖拽期间绝对不截图。
            capture()
            magnifyLayer.isHidden = false
        } else if pan.state == .ended || pan.state == .cancelled {
            // 手指抬起时，可以选择隐藏放大镜
            magnifyLayer.isHidden = true
        }
        
        // 更新放大镜UI
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        magnifyLayer.position = point
        magnifyLayer.image = screenShotImage.cgImage
        magnifyLayer.update(targetPoint: point, screenScale: UIScreen.main.scale)
        CATransaction.commit()
        
        // 实时更新颜色信息
        updateColorAt(point: point)
    }
    
    private func updateColorAt(point: CGPoint) {
        let scale = UIScreen.main.scale
        let pixelPoint = CGPoint(x: point.x * scale, y: point.y * scale)
        let hex = pixelBuffer.color(at: pixelPoint)
        
        if !hex.isEmpty {
            self.currentColor = hex
        }
    }
    
    private func capture() {
        guard let scene = windowScene else { return }
        
        let bounds = UIScreen.main.bounds
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        
        let renderer = UIGraphicsImageRenderer(bounds: bounds, format: format)
        
        screenShotImage = renderer.image { context in
            for window in scene.windows where window != self && !window.isHidden && window.alpha > 0.01 {
                window.drawHierarchy(in: window.bounds, afterScreenUpdates: false)
            }
        }
        // 更新缓冲区
        pixelBuffer.update(from: screenShotImage)
    }
}

// MARK: - 生命周期
extension PTColorPickWindow {
    func show() {
        isHidden = false
        capture() // 弹出时主动截图一次
    }
    
    func hide() {
        isHidden = true
        magnifyLayer.isHidden = true
    }
}

// MARK: - 点击穿透
extension PTColorPickWindow {
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        
        // 如果点击的是关闭按钮或者信息面板，正常响应
        if view == pickInfoView || view == pickInfoView.closeBtn {
            return view
        }
        
        // 其余屏幕区域交给 Window 响应以处理 Pan 手势
        return self
    }
}
