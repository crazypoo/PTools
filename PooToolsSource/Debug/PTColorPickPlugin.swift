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
        NotificationCenter.default.addObserver(self, selector: #selector(closePlugin(nofiti:)), name: NSNotification.Name(kPTClosePluginNotification), object: nil)
    }
    
    public func show() {
        PTColorPickWindow.share.show()
        PTColorPickInfoWindow.share.show()
        showed = true
    }
    
    public func close() {
        PTColorPickWindow.share.hide()
        PTColorPickInfoWindow.share.hide()
        showed = false
    }
    
    @objc func closePlugin(nofiti:Notification) {
        showed = false
    }
}

fileprivate class PTColorPickMagnifyLayer: CALayer {
    static let kMagnifySize:CGFloat = 150
    static let kRimThickness:CGFloat = 3
    let kGridNum:Int = 15
    let kPixelSkip:Int = 1
    
    let gridCirclePath:CGPath = {
        let circlePath:CGMutablePath = CGMutablePath()
        let radius = kMagnifySize / 2
        circlePath.addArc(center: CGPointMake(0, 0), radius: radius - kRimThickness / 2, startAngle: 0, endAngle: 2 * Double.pi, clockwise: true)
        return circlePath
    }()
    
    public var targetPoint:CGPoint = .zero
    public var pointColorBlock:PTColorPickMagnifyLayerBlock?
    
    public override init() {
        super.init()
        bounds = CGRectMake(-PTColorPickMagnifyLayer.kMagnifySize / 2, -PTColorPickMagnifyLayer.kMagnifySize / 2, PTColorPickMagnifyLayer.kMagnifySize, PTColorPickMagnifyLayer.kMagnifySize)
        anchorPoint = CGPoint(x: 0.5, y: 1)
        
        let magnifyImage = magnifyImage()
        let magnifyLayer = CALayer()
        magnifyLayer.bounds = bounds
        magnifyLayer.position = CGPoint(x: CGRectGetMidX(bounds), y: CGRectGetMidY(bounds))
        magnifyLayer.contents = magnifyImage.cgImage
        magnifyLayer.magnificationFilter = .nearest
        addSublayer(magnifyLayer)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func draw(in ctx: CGContext) {
        ctx.addPath(gridCirclePath)
        ctx.clip()
        drawGridInContext(ctx: ctx)
    }
    
    func drawGridInContext(ctx:CGContext) {
        let gridSize:CGFloat = CGFloat(ceilf(Float(PTColorPickMagnifyLayer.kMagnifySize / CGFloat(kGridNum))))
        
        var currentPoint:CGPoint = targetPoint
        currentPoint.x -= CGFloat(kGridNum * kPixelSkip / 2)
        currentPoint.y -= CGFloat(kGridNum * kPixelSkip / 2)
        
        for j in 0..<kGridNum {
            for i in 0..<kGridNum {
                let gridRect = CGRectMake(gridSize * CGFloat(i) - PTColorPickMagnifyLayer.kMagnifySize / 2, gridSize * CGFloat(j) - PTColorPickMagnifyLayer.kMagnifySize / 2, gridSize, gridSize)
                var gridColor = UIColor.clear
                if pointColorBlock != nil {
                    let pointColorHexString = pointColorBlock!(currentPoint)
                    gridColor = UIColor(hexString: pointColorHexString) ?? UIColor.randomColor
                }
                ctx.setFillColor(gridColor.cgColor)
                ctx.fill([gridRect])
                currentPoint.x += CGFloat(kPixelSkip)
            }
            currentPoint.x -= CGFloat(kGridNum * kPixelSkip)
            currentPoint.y += CGFloat(kPixelSkip)
        }
    }
    
    func magnifyImage() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0)
        let ctx = UIGraphicsGetCurrentContext()
        
        let size = PTColorPickMagnifyLayer.kMagnifySize
        ctx?.translateBy(x: size / 2, y: size / 2)
        
        ctx?.saveGState()
        ctx?.addPath(gridCirclePath)
        ctx?.clip()
        ctx?.restoreGState()
        
        ctx?.setLineWidth(PTColorPickMagnifyLayer.kRimThickness - 1)
        ctx?.setStrokeColor(UIColor.white.cgColor)
        ctx?.addPath(gridCirclePath)
        ctx?.strokePath()
        
        let gridWidth:CGFloat = CGFloat(ceilf(Float(PTColorPickMagnifyLayer.kMagnifySize / CGFloat(kGridNum))))
        let xyOffset:CGFloat = -(gridWidth + 1) / 2
        let selectedRect = CGRect(x: xyOffset, y: xyOffset, width: gridWidth, height: gridWidth)
        ctx?.addRect(selectedRect)
                
        let dyColor = UIColor.init { trainCollection in
            if trainCollection.userInterfaceStyle == .light {
                return .black
            } else {
                return .white
            }
        }
        ctx?.setStrokeColor(dyColor.cgColor)
        ctx?.setLineWidth(1)
        ctx?.strokePath()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
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
    
    private lazy var closeBtn:UIButton = {
        let view = UIButton(type: .custom)
        view.setImage("❌".emojiToImage(emojiFont: .appfont(size: 20)), for: .normal)
        view.addActionHandlers { sender in
            self.closeBlock?(sender,self)
        }
        return view
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        PTGCDManager.gcdAfter(time: 0.1) {
            let colorWidth = CGFloat.SizeFrom750(x: 28)
            let colorHeight = CGFloat.SizeFrom750(x: 28)
            self.colorView.frame = CGRect(x: CGFloat.SizeFrom750(x: 32), y: (self.frame.size.height - colorHeight) / 2, width: colorWidth, height: colorHeight)
            
            let colorValueWidth = CGFloat.SizeFrom750(x: 150)
            self.colorValueLbl.frame = CGRect(x: self.colorView.frame.origin.x + self.colorView.frame.size.width + CGFloat.SizeFrom750(x: 20), y: 0, width: colorValueWidth, height: self.frame.size.height)
            
            let closeWidth = CGFloat.SizeFrom750(x: 44)
            let closeHeight = CGFloat.SizeFrom750(x: 44)
            self.closeBtn.frame = CGRect(x: self.frame.size.width - closeWidth - CGFloat.SizeFrom750(x: 32), y: (self.frame.size.height - closeHeight) / 2, width: closeWidth, height: closeHeight)
        }
    }
    
    func commonInit() {
        backgroundColor = UIColor(dynamicProvider: { traitCollection in
            if traitCollection.userInterfaceStyle == .light {
                return .white
            } else {
                return .black
            }
        })
                
        addSubviews([colorView, colorValueLbl, closeBtn])
        
        PTGCDManager.gcdMain {
            self.viewCorner(radius: CGFloat.SizeFrom750(x: 8),borderWidth: 1,borderColor: UIColor.hex("#999999",alpha:0.2))
        }
    }
    
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        let currentPoint = touch?.location(in: self)
        let prePoint = touch?.previousLocation(in: self)
        let offsetX = currentPoint!.x - prePoint!.x
        let offsetY = currentPoint!.y - prePoint!.y
        transform = CGAffineTransform(translationX: offsetX, y: offsetY)
    }
}

//MARK: 颜色信息窗口
fileprivate class PTColorPickInfoWindow : UIWindow {
    static let share = PTColorPickInfoWindow()
    
    public var currentColor:String? {
        didSet {
            pickInfoView.currentColor = currentColor
            PTNSLogConsole(currentColor!,levelType: PTLogMode,loggerType: .Color)
        }
    }
    
    private lazy var pickInfoView:PTColorPickInfoView = {
        let view = PTColorPickInfoView()
        view.closeBlock = { sender , pickerInfo in
            NotificationCenter.default.post(name: NSNotification.Name(kPTClosePluginNotification), object: nil, userInfo: nil)
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

        windowLevel = .alert + 201
        backgroundColor = .clear
                
        addSubview(pickInfoView)
        pickInfoView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset( CGFloat.SizeFrom750(x: 30))
            make.top.equalToSuperview().inset((CGFloat.kSCREEN_HEIGHT - CGFloat.SizeFrom750(x: 100) - CGFloat.SizeFrom750(x: 30) - CGFloat.kTabbarSaveAreaHeight))
            make.width.equalTo((CGFloat.kSCREEN_WIDTH - 2 * CGFloat.SizeFrom750(x: 30)))
            make.height.equalTo(CGFloat.SizeFrom750(x: 100))
        }
                
        NotificationCenter.default.addObserver(self, selector: #selector(closePlugin(nofiti:)), name: NSNotification.Name(kPTClosePluginNotification), object: nil)

    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func closePlugin(nofiti:Notification) {
        hide()
    }
    
    public func show() {
        isHidden = false
    }
    
    public func hide() {
        isHidden = true
    }
}

//MARK: 吸管窗口
public class PTColorPickWindow: UIWindow {
    
    static let share = PTColorPickWindow()
    
    // MARK: - 模式（🔥高级能力）
    public enum PickMode {
        case fullScreen   // 精准（默认）
        case mainWindow   // 高性能
    }
    
    public var pickMode: PickMode = .fullScreen
    
    private var lastCaptureTime: CFTimeInterval = 0
    private var screenShotImage: UIImage = UIImage()
    
    private lazy var magnifyLayer: PTColorPickMagnifyLayer = {
        let layer = PTColorPickMagnifyLayer()
        layer.contentsScale = UIScreen.main.scale
        return layer
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
        
        magnifyLayer.frame = bounds
        magnifyLayer.pointColorBlock = { [weak self] point in
            guard let self else { return "" }
            return self.colorAtPoint(point: point)
        }
        layer.addSublayer(magnifyLayer)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(pan)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(closePlugin),
                                               name: NSNotification.Name(kPTClosePluginNotification),
                                               object: nil)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - 手势处理
private extension PTColorPickWindow {
    
    @objc func handlePan(_ pan: UIPanGestureRecognizer) {
        guard let view = pan.view else { return }
        
        if pan.state == .began {
            updateScreenShotImage()
        }
        
        let offset = pan.translation(in: view)
        pan.setTranslation(.zero, in: view)
        
        let newCenter = CGPoint(
            x: view.center.x + offset.x,
            y: view.center.y + offset.y
        )
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        view.center = newCenter
        
        /// ⭐ 统一为屏幕坐标（关键）
        let screenPoint = convert(newCenter, to: nil)
        
        let scale = screenShotImage.scale
        let pixelPoint = CGPoint(
            x: screenPoint.x * scale,
            y: screenPoint.y * scale
        )

        magnifyLayer.targetPoint = pixelPoint
        magnifyLayer.setNeedsDisplay()
        
        CATransaction.commit()
        
        let hex = colorAtPoint(point: screenPoint)
        PTColorPickInfoWindow.share.currentColor = hex
    }
}

// MARK: - 取色（已修复 scale）
private extension PTColorPickWindow {
    
    func colorAtPoint(point: CGPoint) -> String {
        return colorAtPixelPoint(point)
    }
    
    func colorAtPixelPoint(_ pixelPoint: CGPoint) -> String {
        guard let cgImage = screenShotImage.cgImage else { return "" }
        
        let x = Int(pixelPoint.x)
        let y = Int(pixelPoint.y)
        
        guard x >= 0,
              y >= 0,
              x < cgImage.width,
              y < cgImage.height else {
            return ""
        }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let pixelData = UnsafeMutablePointer<UInt8>.allocate(capacity: 4)
        defer { pixelData.deallocate() }
        
        let context = CGContext(
            data: pixelData,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        
        context.translateBy(x: -CGFloat(x),
                            y: CGFloat(y - cgImage.height))
        
        context.draw(cgImage, in: CGRect(
            x: 0,
            y: 0,
            width: cgImage.width,
            height: cgImage.height
        ))
        
        return String(format: "#%02x%02x%02x",
                      pixelData[0],
                      pixelData[1],
                      pixelData[2])
    }
}

// MARK: - 截图核心（🔥最关键优化）
private extension PTColorPickWindow {
    
    func updateScreenShotImage() {
        let now = CACurrentMediaTime()
        guard now - lastCaptureTime > 0.2 else { return }
        lastCaptureTime = now
        
        guard let scene = windowScene else { return }
        
        let size = UIScreen.main.bounds.size
        
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        switch pickMode {
            
        case .fullScreen:
            /// ⭐ 所有 window（精准）
            let windows = scene.windows
                .filter {
                    $0 != self &&
                    $0 != PTColorPickInfoWindow.share &&
                    !$0.isHidden
                }
                .sorted { $0.windowLevel < $1.windowLevel }
            
            for window in windows {
                context.saveGState()
                context.translateBy(x: window.frame.origin.x,
                                    y: window.frame.origin.y)
                window.layer.render(in: context)
                context.restoreGState()
            }
            
        case .mainWindow:
            /// ⭐ 只主 window（高性能）
            if let keyWindow = scene.windows.first(where: \.isKeyWindow) {
                context.saveGState()
                context.translateBy(x: keyWindow.frame.origin.x,
                                    y: keyWindow.frame.origin.y)
                keyWindow.layer.render(in: context)
                context.restoreGState()
            }
        }
        
        screenShotImage = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
    }
}

// MARK: - 生命周期
private extension PTColorPickWindow {
    
    @objc func closePlugin() {
        isHidden = true
    }
    
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
        if view == self {
            return self
        }
        
        return nil
    }
}
