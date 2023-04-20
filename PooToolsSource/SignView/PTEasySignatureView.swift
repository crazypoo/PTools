//
//  PTEasySignatureView.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/5.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift
import AttributedString

public class PTSignatureConfig:NSObject {
    public var lineWidth:CGFloat = 1
    public var signNavTitleFont:UIFont = UIFont.appfont(size: 12,bold: true)
    public var signNavTitleColor:UIColor = UIColor.randomColor
    public var signNavDescFont:UIFont = UIFont.appfont(size: 10)
    public var signNavDescColor:UIColor = UIColor.randomColor
    public var signContentTitleFont:UIFont = UIFont.appfont(size: 15,bold: true)
    public var signContentTitleColor:UIColor = UIColor.randomColor
    public var signContentDescFont:UIFont = UIFont.appfont(size: 13)
    public var signContentDescColor:UIColor = UIColor.randomColor
    public var infoTitle:String = "请在白色区域手写签名"
    public var infoDesc:String = "正楷,工整书写"
    public var clearName:String = "清除"
    public var clearFont:UIFont = .appfont(size: 14)
    public var clearTextColor:UIColor = .randomColor
    public var saveName:String = "保存"
    public var saveFont:UIFont = .appfont(size: 14)
    public var saveTextColor:UIColor = .randomColor
    public var navBarColor:UIColor = .randomColor
    public var signViewBackground:UIColor = .randomColor
    public var waterMarkMessage:String = ""
}

public typealias OnSignatureWriteAction = (_ have:Bool) -> Void

class PTEasySignatureView: UIView {
    
    var viewConfig:PTSignatureConfig!
    var minFloat:CGFloat = 0
    var maxFloat:CGFloat = 0
    var previousPoint:CGPoint = .zero
    var currentPointArr:NSMutableArray = NSMutableArray()
    var hasSignatureImg:Bool = false
    var isHaveDraw:Bool = false
    var onSignatureWriteAction:OnSignatureWriteAction?
    var touchForce:CGFloat = 0
    var isSure:Bool = false
    var showMessage:String = ""
    var SignatureImg:UIImage!
    
    var path:UIBezierPath!
    func createPath()->UIBezierPath {
        let paths = UIBezierPath()
        paths.lineWidth = self.viewConfig.lineWidth
        paths.lineCapStyle = .round
        paths.lineJoinStyle = .round
        return paths
    }
    
    lazy var infoLabel:UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        
        var totalAtts:ASAttributedString = ASAttributedString("")
        if !self.viewConfig.infoTitle.stringIsEmpty() && self.viewConfig.infoDesc.stringIsEmpty() {
            let textAtt:ASAttributedString = ASAttributedString("\(self.viewConfig.infoTitle)",.paragraph(.alignment(.center),.lineSpacing(4.5)),.font(self.viewConfig.signContentTitleFont),.foreground(self.viewConfig.signContentTitleColor))
            totalAtts = textAtt
        } else if self.viewConfig.infoTitle.stringIsEmpty() && !self.viewConfig.infoDesc.stringIsEmpty() {
            let descAtt:ASAttributedString = ASAttributedString("\(self.viewConfig.infoDesc)",.paragraph(.alignment(.center)),.font(self.viewConfig.signContentDescFont),.foreground(self.viewConfig.signContentDescColor))
            totalAtts = descAtt
        } else if !self.viewConfig.infoTitle.stringIsEmpty() && !self.viewConfig.infoDesc.stringIsEmpty() {
            let textAtt:ASAttributedString = ASAttributedString("\(self.viewConfig.infoTitle)",.paragraph(.alignment(.center),.lineSpacing(4.5)),.font(self.viewConfig.signContentTitleFont),.foreground(self.viewConfig.signContentTitleColor))
            let descAtt:ASAttributedString = ASAttributedString("\n\(self.viewConfig.infoDesc)",.paragraph(.alignment(.center)),.font(self.viewConfig.signContentDescFont),.foreground(self.viewConfig.signContentDescColor))
            totalAtts = textAtt + descAtt
        }
        view.attributed.text = totalAtts
        return view
    }()
    
    init(viewConfig:PTSignatureConfig) {
        self.viewConfig = viewConfig
        super.init(frame: .zero)
        self.commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func midPoint(p0:CGPoint,p1:CGPoint)->CGPoint {
        return CGPoint(x: (p0.x + p1.x) / 2, y: (p0.y + p1.y) / 2)
    }
    
    func check3DTouch()->Bool {
        return self.traitCollection.forceTouchCapability == .available
    }
    
    func commonInit() {
        self.backgroundColor = self.viewConfig.signViewBackground

        self.path = self.createPath()
        
        let pan = UIPanGestureRecognizer.init { sender in
            let senderPan = (sender as! UIPanGestureRecognizer)
            let currentPoint = senderPan.location(in: self)
            let midPoint = self.midPoint(p0: self.previousPoint, p1: currentPoint)
            self.currentPointArr.add(NSValue.init(cgPoint: currentPoint))
            self.hasSignatureImg = true
            let viewHeight = self.frame.size.height
            let currentY = currentPoint.y
            switch senderPan.state {
            case .began:
                self.path.move(to: currentPoint)
            case .changed:
                self.path.addQuadCurve(to: midPoint, controlPoint: self.previousPoint)
            default:break
            }
            
            if currentY >= 0 && viewHeight >= currentY {
                if self.maxFloat == 0 && self.minFloat == 0 {
                    self.maxFloat = currentPoint.x
                    self.minFloat = currentPoint.x
                } else {
                    if currentPoint.x >= self.maxFloat {
                        self.maxFloat = currentPoint.x
                    }
                    
                    if self.minFloat >= currentPoint.x {
                        self.minFloat = currentPoint.x
                    }
                }
            }
            self.previousPoint = currentPoint
            self.setNeedsDisplay()
            self.isHaveDraw = true
            if self.onSignatureWriteAction != nil {
                self.onSignatureWriteAction!(true)
            }
        }
        pan.minimumNumberOfTouches = 1
        pan.maximumNumberOfTouches = 1
        self.addGestureRecognizer(pan)
        
        self.addSubview(self.infoLabel)
        self.infoLabel.snp.makeConstraints { make in
            make.centerY.centerX.equalToSuperview()
        }
    }
    
    override func draw(_ rect: CGRect) {
        
        if self.check3DTouch() {
            UIColor(white: 0, alpha: self.viewConfig.lineWidth * (1 - self.touchForce)).setStroke()
        } else {
            UIColor.black.setStroke()
        }
        self.path.stroke()
        
        if !self.isSure && !self.isHaveDraw {
            self.infoLabel.isHidden = false
        } else {
            self.infoLabel.isHidden = true
            self.isSure = false
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touche = touches.first
        if self.check3DTouch() {
            self.touchForce = touche!.force
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touche = touches.first
        if self.check3DTouch() {
            self.touchForce = touche!.force
        }
    }
    
    func clearSign() {
        if self.currentPointArr.count > 0 {
            self.currentPointArr.removeAllObjects()
        }
        self.hasSignatureImg = false
        self.maxFloat = 0
        self.minFloat = 0
        self.isHaveDraw = false
        self.path = self.createPath()
        self.setNeedsDisplay()
        if self.onSignatureWriteAction != nil {
            self.onSignatureWriteAction!(false)
        }
    }
    
    func saveSign() {
        if self.minFloat == 0 && self.maxFloat == 0 {
            self.minFloat = 0
            self.maxFloat = 0
        }
        self.isSure = true
        self.setNeedsDisplay()
        self.imageRepresentation()
    }
    
    func scaleToSize(image:UIImage)->UIImage {
        let rect:CGRect = CGRect(x: 0, y: 0, width: image.size.width, height: self.frame.size.height)
        UIGraphicsBeginImageContext(rect.size)
        image.draw(in: rect)
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.setNeedsDisplay()
        return scaledImage!
    }
    
    func cutImage(image:UIImage)->UIImage {
        var rect:CGRect!
        if self.minFloat == 0 && self.maxFloat == 0 {
            rect = .zero
        } else {
            rect = CGRect(x: self.minFloat - 3, y: 0, width: self.maxFloat - self.minFloat + 6, height: self.frame.size.height)
        }
        let imageRef = image.cgImage!.cropping(to: rect)
        let img = UIImage(cgImage: imageRef!)
        let lastImage = self.addText(image: img, text: self.showMessage)
        self.setNeedsDisplay()
        return lastImage
    }
    
    func addText(image:UIImage,text:String)->UIImage {
        let imageW = image.size.width
        let imageH = image.size.height
        let textFont = self.viewConfig.signContentTitleFont
        let sizeToFit = text.nsString.boundingRect(with: CGSize(width: 128, height: 30),options: NSStringDrawingOptions.usesLineFragmentOrigin,attributes: [NSAttributedString.Key.font:textFont], context: nil).size
        
        UIGraphicsBeginImageContext(image.size)
        UIColor.red.set()
        image.draw(in: CGRect(x: 0, y: 0, width: imageW, height: imageH))
        text.nsString.draw(in: CGRect(x: (imageW - sizeToFit.width) / 2, y: (imageH - sizeToFit.height) / 2, width: sizeToFit.width, height: sizeToFit.height),withAttributes: [NSAttributedString.Key.font:textFont])
        let aimage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return aimage!
    }

    func imageRepresentation() {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, UIScreen.main.scale)
        self.layer.render(in: UIGraphicsGetCurrentContext()!)
        var images:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        images = PTImageBlackToTransparent.imageBlackToTransparent(image: images) ?? UIImage()
        
        if self.showMessage.stringIsEmpty() {
            self.SignatureImg = self.scaleToSize(image: images)
        } else {
            let img = self.cutImage(image: images)
            self.SignatureImg = self.scaleToSize(image: img)
        }
    }
}
