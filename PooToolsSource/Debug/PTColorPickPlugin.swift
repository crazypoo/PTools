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
    static let share = PTColorPickPlugin()
    
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
    
    public var closeBlock:((UIButton,PTColorPickInfoView)->Void)?
    
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
        view.setImage("❌".emojiToImage(emojiFont: .appfont(size: 14)), for: .normal)
        view.addActionHandlers { sender in
            if self.closeBlock != nil {
                self.closeBlock!(sender,self)
            }
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
        backgroundColor = UIColor.init(dynamicProvider: { traitCollection in
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
            PTNSLogConsole(currentColor!)
        }
    }
    
    private lazy var pickInfoView:PTColorPickInfoView = {
        let view = PTColorPickInfoView(frame: self.bounds)
        view.closeBlock = { sender , pickerInfo in
            NotificationCenter.default.post(name: NSNotification.Name(kPTClosePluginNotification), object: nil, userInfo: nil)
        }
        return view
    }()
    
    init() {
        super.init(frame: CGRect(x: CGFloat.SizeFrom750(x: 30), y: CGFloat.kSCREEN_HEIGHT - CGFloat.SizeFrom750(x: 100) - CGFloat.SizeFrom750(x: 30) - CGFloat.kTabbarSaveAreaHeight, width: CGFloat.kSCREEN_WIDTH - 2 * CGFloat.SizeFrom750(x: 30), height: CGFloat.SizeFrom750(x: 100)))
        
        windowLevel = .alert
        
        addSubview(pickInfoView)
        
        let pan = UIPanGestureRecognizer { sender in
            let pans = sender as! UIPanGestureRecognizer
            
            let offsetPoint = pans.translation(in: pans.view)
            pans.setTranslation(.zero, in: pans.view)
            let panView = pans.view
            let newX = panView!.frame.origin.x + panView!.frame.size.width / 2 + offsetPoint.x
            let newY = panView!.frame.origin.y + panView!.frame.size.height / 2 + offsetPoint.y
            
            let centerPoint = CGPoint(x: newX, y: newY)
            panView?.center = centerPoint
        }
        addGestureRecognizer(pan)
        
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
fileprivate class PTColorPickWindow : UIWindow {
    static let share = PTColorPickWindow()
    
    let kColorPickWindowSize:CGFloat = 150
    
    private var screenShotImage:UIImage = UIImage()
    
    private lazy var magnifyLayer:PTColorPickMagnifyLayer = {
        let layer = PTColorPickMagnifyLayer()
        layer.contentsScale = UIScreen.main.scale
        return  layer
    }()
    
    init() {
        super.init(frame: CGRectMake(CGFloat.kSCREEN_WIDTH / 2 - kColorPickWindowSize / 2, CGFloat.kSCREEN_HEIGHT / 2 - kColorPickWindowSize / 2, kColorPickWindowSize, kColorPickWindowSize))
        backgroundColor = .clear
        windowLevel = .statusBar + 1
        
        magnifyLayer.frame = bounds
        magnifyLayer.pointColorBlock = { point in
            self.colorAtPoint(point: point)
        }
        layer.addSublayer(magnifyLayer)
        
        let pan = UIPanGestureRecognizer { sender in
            let pans = sender as! UIPanGestureRecognizer
            if pans.state == .began {
                self.updateScreenShotImage()
            }
            
            let offsetPoint = pans.translation(in: pans.view)
            pans.setTranslation(.zero, in: pans.view)
            let panView = pans.view
            let newX = panView!.frame.origin.x + panView!.frame.size.width / 2 + offsetPoint.x
            let newY = panView!.frame.origin.y + panView!.frame.size.height / 2  + offsetPoint.y

            CATransaction.begin()
            CATransaction.setDisableActions(true)
                        
            let centerPoint = CGPoint(x: newX, y: newY)
            panView?.center = centerPoint
            
            self.magnifyLayer.targetPoint = centerPoint
            var magnifyFrame = self.magnifyLayer.frame
            magnifyFrame.origin = CGPoint(x: round(magnifyFrame.origin.x), y: round(magnifyFrame.origin.y))
            self.magnifyLayer.frame = magnifyFrame
            self.magnifyLayer.setNeedsDisplay()
            
            CATransaction.commit()
            
            let hexColor = self.colorAtPoint(point: centerPoint)
            
            PTColorPickInfoWindow.share.currentColor = hexColor
        }
        addGestureRecognizer(pan)
        
        NotificationCenter.default.addObserver(self, selector: #selector(closePlugin(nofiti:)), name: NSNotification.Name(kPTClosePluginNotification), object: nil)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func colorAtPoint(point:CGPoint) -> String {
        self.colorAtPoint(point: point, inImage: screenShotImage)
    }
    
    func colorAtPoint(point:CGPoint,inImage:UIImage) -> String {
        
        if !CGRectContainsPoint(CGRect(x: 0, y: 0, width: inImage.size.width, height: inImage.size.height), point) {
            return ""
        }
        
        let pointX = trunc(point.x)
        let pointY = trunc(point.y)
        let cgImage = inImage.cgImage
        let width = inImage.size.width
        let height = inImage.size.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel:Int = 4
        let bytesPerRow = bytesPerPixel * 1
        let bitsPerComponent:Int = 8
        let pixelData = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: 4)
        let context = CGContext(data: pixelData , width: 1, height: 1, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: (CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue))!
        context.setBlendMode(.copy)
        
        context.translateBy(x: -pointX, y: pointY-height)
        context.draw(cgImage!, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        let hexColor = String(format: "#%02x%02x%02x", pixelData[0],pixelData[1],pixelData[2])
        return hexColor
    }
    
    private func updateScreenShotImage() {
        UIGraphicsBeginImageContext(UIScreen.main.bounds.size)
        AppWindows!.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        screenShotImage = image!
    }
    
    @objc func closePlugin(nofiti:Notification) {
        isHidden = true
    }
    
    public func show() {
        isHidden = false
    }
    
    public func hide() {
        isHidden = true
    }
}
