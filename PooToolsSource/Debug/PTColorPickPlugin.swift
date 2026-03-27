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

    static let size: CGFloat = 150
    static let zoom: CGFloat = 2   // ⭐ 放大倍数（你可以调）

    var targetPixelPoint: CGPoint = .zero
    var screenshot: UIImage?

    private let imageLayer = CALayer()

    override init() {
        super.init()

        bounds = CGRect(
            x: -Self.size / 2,
            y: -Self.size / 2,
            width: Self.size,
            height: Self.size
        )

        anchorPoint = CGPoint(x: 0.5, y: 1)

        imageLayer.frame = bounds
        imageLayer.magnificationFilter = .nearest
        addSublayer(imageLayer)

        cornerRadius = Self.size / 2
        masksToBounds = true

        borderWidth = 3
        borderColor = UIColor.white.cgColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update() {
        guard let cgImage = screenshot?.cgImage else { return }

        let pixelX = Int(targetPixelPoint.x)
        let pixelY = Int(targetPixelPoint.y)

        let cropSize = Int(Self.size / Self.zoom)

        let rect = CGRect(
            x: pixelX - cropSize / 2,
            y: pixelY - cropSize / 2,
            width: cropSize,
            height: cropSize
        )

        guard let cropped = cgImage.cropping(to: rect) else { return }

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

    public enum PickMode {
        case fullScreen
        case mainWindow
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

        magnifyLayer.frame = CGRectMake(0, 0, 150, 150)
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

        /// ⭐ 用手指真实位置（关键）
        let screenPoint = pan.location(in: nil)

        if pan.state == .began {
            updateScreenShotImage()
        }

        /// ⭐ UI跟着手指走
        center = screenPoint

        let scale = screenShotImage.scale

        /// ⭐ 统一转 pixel 坐标
        let pixelPoint = CGPoint(
            x: screenPoint.x * scale,
            y: screenPoint.y * scale
        )

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        magnifyLayer.targetPixelPoint = pixelPoint
        magnifyLayer.screenshot = screenShotImage
        magnifyLayer.update()

        CATransaction.commit()

        /// ⭐ 取色（同一坐标体系）
        let hex = colorAtPixelPoint(pixelPoint)
        PTColorPickInfoWindow.share.currentColor = hex
    }
}

// MARK: - 取色（已修复 scale）
private extension PTColorPickWindow {
    
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
        
        guard let data = cgImage.dataProvider?.data else { return "" }
        let ptr = CFDataGetBytePtr(data)
        
        let bytesPerPixel = 4
        let bytesPerRow = cgImage.bytesPerRow
        
        let offset = y * bytesPerRow + x * bytesPerPixel
        
        let r = ptr?[offset] ?? 0
        let g = ptr?[offset + 1] ?? 0
        let b = ptr?[offset + 2] ?? 0
        
        return String(format: "#%02x%02x%02x", r, g, b)
    }
}

// MARK: - 截图核心（🔥最关键优化）
private extension PTColorPickWindow {
    
    func updateScreenShotImage() {
        let now = CACurrentMediaTime()
        guard now - lastCaptureTime > 0.1 else { return }
        lastCaptureTime = now

        guard let scene = windowScene else { return }

        let size = UIScreen.main.bounds.size

        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return }

        switch pickMode {

        case .fullScreen:
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
