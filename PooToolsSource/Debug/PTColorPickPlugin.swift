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

let CorpSize:CGFloat = 150

public typealias PTColorPickMagnifyLayerBlock = (CGPoint) -> String

public let kPTClosePluginNotification = "kPTClosePluginNotification"

public extension CGFloat {
    static func SizeFrom750(x:CGFloat) -> CGFloat {
        x * CGFloat.kSCREEN_WIDTH / 750
    }
}

open class PTColorPickPlugin : NSObject {
    public static let share = PTColorPickPlugin()
    
    public var showed:Bool = false
    
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

final class PTPixelBuffer {

    private(set) var data: UnsafePointer<UInt8>?
    private(set) var width: Int = 0
    private(set) var height: Int = 0
    private(set) var bytesPerRow: Int = 0

    func update(from image: UIImage) {
        guard let cgImage = image.cgImage else { return }

        width = cgImage.width
        height = cgImage.height
        bytesPerRow = cgImage.bytesPerRow

        guard let cfData = cgImage.dataProvider?.data else { return }
        data = CFDataGetBytePtr(cfData)
    }

    func color(at pixel: CGPoint) -> String {
        guard let data else { return "" }

        let x = Int(pixel.x)
        let y = Int(pixel.y)

        guard x >= 0, y >= 0, x < width, y < height else {
            return ""
        }

        let offset = y * bytesPerRow + x * 4

        let r = data[offset]
        let g = data[offset + 1]
        let b = data[offset + 2]

        return String(format:"#%02x%02x%02x", r, g, b)
    }
}

fileprivate class PTColorPickMagnifyLayer: CALayer {

    static let size: CGFloat = 150
    static let zoom: CGFloat = 1

    var targetPixelPoint: CGPoint = .zero
    var image: CGImage?

    private let imageLayer = CALayer()
    private let crosshair = CAShapeLayer()

    override init() {
        super.init()

        bounds = CGRect(x: 0, y: 0, width: CorpSize, height: CorpSize)
        anchorPoint = CGPoint(x: 0.5, y: 1)

        imageLayer.frame = bounds
        imageLayer.magnificationFilter = .nearest
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
        crosshair.lineWidth = 1
        addSublayer(crosshair)
    }

    func update() {
        guard let image else { return }

        // 计算当前缩放比例下的裁剪区域大小
        let cropSize = Int(Self.size / Self.zoom)

        // 确保裁剪区域不会超出图像的边界
        let x = max(0, targetPixelPoint.x - CGFloat(cropSize / 2))
        let y = max(0, targetPixelPoint.y - CGFloat(cropSize / 2))

        let width = min(CGFloat(cropSize), CGFloat(image.width) - x)
        let height = min(CGFloat(cropSize), CGFloat(image.height) - y)

        // 创建裁剪区域
        let rect = CGRect(x: x, y: y, width: width, height: height)

        // 确保裁剪图像正确
        guard let cropped = image.cropping(to: rect) else { return }

        imageLayer.contents = cropped
    }
    
    func updateWithAdjustedPoint(_ point: CGPoint) {
        guard let image else { return }

        // 镜头裁剪区域的尺寸
        let cropSize = Int(Self.size / Self.zoom)
        
        // 确保裁剪区域不会超出图像的边界
        let x = max(0, point.x - CGFloat(cropSize / 2))
        let y = max(0, point.y - CGFloat(cropSize / 2))

        let width = min(CGFloat(cropSize), CGFloat(image.width) - x)
        let height = min(CGFloat(cropSize), CGFloat(image.height) - y)

        // 创建裁剪区域
        let rect = CGRect(x: x, y: y, width: width, height: height)

        // 确保裁剪图像正确
        guard let cropped = image.cropping(to: rect) else { return }

        imageLayer.contents = cropped

    }
}

//MARK: 颜色吸盘的信息界面
fileprivate class PTColorPickInfoView : UIView {
    
    public var closeBlock:((UIButton,PTColorPickInfoView) -> Void)?
    
    public var currentColor:String? {
        didSet {
            if !(currentColor ?? "").stringIsEmpty() {
                colorView.backgroundColor = UIColor(hexString: currentColor!)
                colorValueLbl.text = currentColor!
            }
        }
    }
    
    private lazy var colorView:UIView = {
        let view = UIView()
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.hex("#999999",alpha:0.2).cgColor
        return view
    }()
    
    private lazy var colorValueLbl:UILabel = {
        let view = UILabel()
        view.textColor = UIColor(dynamicProvider: { traitCollection in
            if traitCollection.userInterfaceStyle == .light {
                return UIColor(hexString:"#333333")!
            } else {
                return UIColor(hexString:"#DDDDDD")!
            }
        })
        view.font = .appfont(size: CGFloat.SizeFrom750(x: 28))
        return view
    }()
    
    fileprivate lazy var closeBtn:UIButton = {
        let view = UIButton(type: .custom)
        view.setImage("❌".emojiToImage(emojiFont: .appfont(size: 20)), for: .normal)
        view.addActionHandlers { sender in
            self.closeBlock?(sender,self)
        }
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
    
    open override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    func commonInit() {
        backgroundColor = UIColor(dynamicProvider: { traitCollection in
            if traitCollection.userInterfaceStyle == .light {
                return .white
            } else {
                return .black
            }
        })
                
        addSubviews([colorView,closeBtn,colorValueLbl])
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
        
        self.viewCorner(radius: CGFloat.SizeFrom750(x: 8),borderWidth: 1,borderColor: UIColor.hex("#999999",alpha:0.2))
    }
}

//MARK: 吸管窗口
public class PTColorPickWindow: UIWindow {
    
    static let share = PTColorPickWindow()

    private var displayLink: CADisplayLink!
    private var lastCaptureTime: CFTimeInterval = 0

    private var screenShotImage: UIImage = UIImage()
    private let pixelBuffer = PTPixelBuffer()

    private var latestTouchPoint: CGPoint = .zero

    private lazy var magnifyLayer: PTColorPickMagnifyLayer = {
        let layer = PTColorPickMagnifyLayer()
        layer.contentsScale = UIScreen.main.scale
        return layer
    }()

    public var currentColor:String? {
        didSet {
            pickInfoView.currentColor = currentColor
        }
    }

    private lazy var pickInfoView:PTColorPickInfoView = {
        let view = PTColorPickInfoView(frame: .zero)
        view.closeBlock = { sender , pickerInfo in
            self.hide()
        }
        return view
    }()

    // MARK: - Init
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

        magnifyLayer.bounds = CGRect(x: 0, y: 0, width: CorpSize, height: CorpSize)
        magnifyLayer.position = CGPoint(x: 100, y: 100) // 初始位置
        layer.addSublayer(magnifyLayer)

        addSubview(pickInfoView)
        pickInfoView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset( CGFloat.SizeFrom750(x: 30))
            make.top.equalToSuperview().inset((CGFloat.kSCREEN_HEIGHT - CGFloat.SizeFrom750(x: 100) - CGFloat.SizeFrom750(x: 30) - CGFloat.kTabbarSaveAreaHeight))
            make.width.equalTo((CGFloat.kSCREEN_WIDTH - 2 * CGFloat.SizeFrom750(x: 30)))
            make.height.equalTo(CGFloat.SizeFrom750(x: 100))
        }
        bringSubviewToFront(pickInfoView)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(pan)
        
        setupDisplayLink()
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - 手势处理
private extension PTColorPickWindow {
    
    @objc func handlePan(_ pan: UIPanGestureRecognizer) {

        let point = pan.location(in: self)
        latestTouchPoint = point
        if pan.state == .began {
            capture()
        }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        magnifyLayer.position = point
        magnifyLayer.targetPixelPoint = point
        magnifyLayer.image = screenShotImage.cgImage
        magnifyLayer.update()
        
        // 修复缩放比例问题
        let scale = UIScreen.main.scale
        let adjustedPoint = CGPoint(x: point.x * scale, y: point.y * scale)
        magnifyLayer.updateWithAdjustedPoint(adjustedPoint)
        CATransaction.commit()
    }
    
    private func setupDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(loop))
        displayLink.add(to: .main, forMode: .common)
    }

    @objc private func loop() {

        guard !isHidden else { return }

        let scale:CGFloat = UIScreen.main.scale

        let pixelPoint = CGPoint(
            x: latestTouchPoint.x * scale,
            y: latestTouchPoint.y * scale
        )

        let hex = pixelBuffer.color(at: pixelPoint)
        PTColorPickWindow.share.currentColor = hex

        captureIfNeeded()
    }
    
    private func captureIfNeeded() {
        let now = CACurrentMediaTime()

        /// ⭐ 控制截图频率（核心）
        if now - lastCaptureTime < 0.2 { return }

        capture()
    }

    private func capture() {
        lastCaptureTime = CACurrentMediaTime()

        guard let scene = windowScene else { return }

        let size = UIScreen.main.bounds.size

        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)

        for window in scene.windows where window != self {
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: false)
        }

        screenShotImage = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()

        pixelBuffer.update(from: screenShotImage)
    }
}

// MARK: - 生命周期
private extension PTColorPickWindow {
    
    func show() {
        isHidden = false
    }
    
    func hide() {
        isHidden = true
    }
}

// MARK: - 点击穿透（🔥关键）
extension PTColorPickWindow {
    
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        
        /// 只让自身响应拖动，其余全部穿透
        if let gestureView = self.gestureRecognizers?.first?.view,
           view == gestureView {
            return view
        } else if let findView = view as? PTColorPickInfoView {
            return findView.closeBtn
        }
        return self
    }
}
