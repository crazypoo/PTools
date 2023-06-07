//
//  PTViewRulerPlugin.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 7/6/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import AttributedString
import SwifterSwift

open class PTViewRulerPlugin: NSObject {
    static let share = PTViewRulerPlugin.init()
    
    fileprivate lazy var rulerView:PTRulerInfoView = {
        let view = PTRulerInfoView()
        return  view
    }()
    
    public var showed:Bool = false
    
    public override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(self.closePlugin(nofiti:)), name: NSNotification.Name(kPTClosePluginNotification), object: nil)
    }
        
    @objc func closePlugin(nofiti:Notification) {
        self.showed = false
        self.hide()
    }
    
    public func show() {
        self.rulerView.hide()
        AppWindows?.addSubview(self.rulerView)
        self.rulerView.show()
        self.showed = true
    }
    
    public func hide() {
        self.rulerView.hide()
        self.rulerView.removeFromSuperview()
    }
}

fileprivate class PTVisualInfoWindow:UIWindow {
    fileprivate lazy var infoLabel:UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        return view
    }()
    
    private lazy var closeBtn:UIButton = {
        let view = UIButton(type: .custom)
        view.setImage("❌".emojiToImage(emojiFont: .appfont(size: 14)), for: .normal)
        view.addActionHandlers { sender in
            NotificationCenter.default.post(name: NSNotification.Name(kPTClosePluginNotification), object: nil, userInfo: nil)
        }
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func commonInit() {
        self.backgroundColor = .white
        PTGCDManager.gcdMain {
            self.viewCorner(radius: CGFloat.SizeFrom750(x: 8), borderWidth: 1, borderColor: UIColor.hex("#999999", alpha: 0.2))
        }
        self.windowLevel = .alert
                
        let pan = UIGestureRecognizer { sender in
            let pans = sender as! UIPanGestureRecognizer
            let panView = pans.view
            if !panView!.isHidden {
                let offsetPoint = pans.translation(in: pans.view)
                pans.setTranslation(.zero, in: pans.view)
                let newX = panView!.frame.origin.x + panView!.frame.size.width + offsetPoint.x
                let newY = panView!.frame.origin.y + panView!.frame.size.height + offsetPoint.y
                
                let centerPoint = CGPoint(x: newX, y: newY)
                panView?.center = centerPoint
            }
        }
        self.addGestureRecognizer(pan)
        
        self.addSubviews([self.closeBtn,self.infoLabel])
        self.closeBtn.snp.makeConstraints { make in
            make.size.equalTo(CGFloat.SizeFrom750(x: 44))
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(10)
        }
        self.infoLabel.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview().inset(5)
            make.right.equalTo(self.closeBtn.snp.left).offset(-10)
        }
    }
}

fileprivate class PTRulerInfoView:UIView {
    
    let viewPointSize:CGFloat = 62
    
    fileprivate lazy var imageView : UIImageView = {
        let view = UIImageView()
        view.image = "🛑".emojiToImage(emojiFont: .appfont(size: 6))
        view.isUserInteractionEnabled = true
        
        let pan = UIPanGestureRecognizer { sender in
            let pans = sender as! UIPanGestureRecognizer
            let offsetPoint = pans.translation(in: pans.view)
            pans.setTranslation(.zero, in: pans.view)
            let panView = pans.view
            let newX = panView!.frame.origin.x + panView!.frame.size.width / 2 + offsetPoint.x
            let newY = panView!.frame.origin.y + panView!.frame.size.height / 2 + offsetPoint.y
            
            let centerPoint = CGPoint(x: newX, y: newY)
            panView?.center = centerPoint

            let imageCenterPointY = self.imageView.frame.origin.y + self.imageView.frame.size.height / 2
            let imageCenterPointX = self.imageView.frame.origin.x + self.imageView.frame.size.width / 2

            self.horizontalLine.frame = CGRectMake(0, imageCenterPointY - 0.25, self.frame.size.width, 0.5)
            self.verticalLine.frame = CGRectMake(imageCenterPointX - 0.25, 0, 0.5, self.frame.size.height)
            
            self.leftLabel.text = String(format: "%.1f", imageCenterPointX)
            self.leftLabel.sizeToFit()
            self.leftLabel.frame = CGRectMake(imageCenterPointX / 2, imageCenterPointY - self.leftLabel.frame.size.height, self.leftLabel.frame.size.width, self.leftLabel.frame.size.height)
            
            self.topLabel.text = String(format: "%.1f", imageCenterPointY)
            self.topLabel.sizeToFit()
            self.topLabel.frame = CGRectMake(imageCenterPointX - self.topLabel.frame.size.width, imageCenterPointY / 2, self.topLabel.frame.size.width, self.topLabel.frame.size.height)
            
            self.rightLabel.text = String(format: "%.1f", self.frame.size.width - imageCenterPointX)
            self.rightLabel.sizeToFit()
            self.rightLabel.frame = CGRectMake(imageCenterPointX + (self.frame.size.width - imageCenterPointX) / 2, imageCenterPointY - self.rightLabel.frame.size.height, self.rightLabel.frame.size.width, self.rightLabel.frame.size.height)

            self.bottomLabel.text = String(format: "%.1f", self.frame.size.height - imageCenterPointY)
            self.bottomLabel.sizeToFit()
            self.bottomLabel.frame = CGRectMake(imageCenterPointX - self.bottomLabel.frame.size.width, imageCenterPointY + (self.frame.size.height - imageCenterPointY) / 2, self.bottomLabel.frame.size.width, self.bottomLabel.frame.size.height)

            self.configInfoLabelText()
        }
        view.addGestureRecognizer(pan)
        
        return view
    }()
    
    fileprivate lazy var horizontalLine : UIView = {
        let view = UIView()
        view.backgroundColor = .red
        return view
    }()

    fileprivate lazy var verticalLine : UIView = {
        let view = UIView()
        view.backgroundColor = .red
        return view
    }()
    
    fileprivate lazy var leftLabel : UILabel = {
        
        let centerPoint = self.imageView.frame.origin.x + self.imageView.frame.size.width / 2
        
        let view = UILabel()
        view.textColor = .red
        view.font = .appfont(size: 12)
        view.text = String(format: "%.1f", centerPoint)
        return view
    }()
    
    fileprivate lazy var rightLabel : UILabel = {
        
        let centerPoint = self.frame.size.width - self.imageView.frame.origin.x + self.imageView.frame.size.width / 2
        
        let view = UILabel()
        view.textColor = .red
        view.font = .appfont(size: 12)
        view.text = String(format: "%.1f", centerPoint)
        return view
    }()
    
    fileprivate lazy var topLabel : UILabel = {
        
        let centerPoint = self.imageView.frame.origin.y + self.imageView.frame.size.height / 2
        
        let view = UILabel()
        view.textColor = .red
        view.font = .appfont(size: 12)
        view.text = String(format: "%.1f", centerPoint)
        return view
    }()
    
    fileprivate lazy var bottomLabel : UILabel = {
        
        let centerPoint = self.frame.size.height - self.imageView.frame.origin.y + self.imageView.frame.size.height / 2
        
        let view = UILabel()
        view.textColor = .red
        view.font = .appfont(size: 12)
        view.text = String(format: "%.1f", centerPoint)
        return view
    }()
    
    fileprivate lazy var infoWindow:PTVisualInfoWindow = {
        let infoWindowFrame:CGRect = CGRect(x: CGFloat.SizeFrom750(x: 30), y: CGFloat.kSCREEN_HEIGHT - CGFloat.SizeFrom750(x: 100) - CGFloat.SizeFrom750(x: 30), width: CGFloat.kSCREEN_WIDTH - 2 * CGFloat.SizeFrom750(x: 30), height: CGFloat.SizeFrom750(x: 100))

        let view = PTVisualInfoWindow(frame: infoWindowFrame)
        return view
    }()
    
    init() {
        super.init(frame: CGRectMake(0, 0, CGFloat.kSCREEN_WIDTH, CGFloat.kSCREEN_HEIGHT))
        self.backgroundColor = .clear
        self.layer.zPosition = CGFloat(Float.greatestFiniteMagnitude)
        
        self.imageView.frame = CGRectMake(CGFloat.kSCREEN_WIDTH / 2 - self.viewPointSize / 2, CGFloat.kSCREEN_HEIGHT / 2 - self.viewPointSize / 2, self.viewPointSize, self.viewPointSize)
        self.horizontalLine.frame = CGRectMake(0, self.imageView.frame.origin.y + self.imageView.frame.size.height / 2 - 0.25, self.frame.size.width, 0.5)
        self.verticalLine.frame = CGRectMake(self.imageView.frame.origin.x + self.imageView.frame.size.width / 2 - 0.25, 0, 0.5, self.frame.size.height)
        self.addSubviews([self.imageView,self.horizontalLine,self.verticalLine])
        self.bringSubviewToFront(self.imageView)
        
        self.addSubviews([self.leftLabel,self.topLabel,self.rightLabel,self.bottomLabel])
        self.leftLabel.sizeToFit()
        self.topLabel.sizeToFit()
        self.rightLabel.sizeToFit()
        self.bottomLabel.sizeToFit()
        self.leftLabel.frame = CGRectMake((self.imageView.frame.origin.x + self.imageView.frame.size.width / 2) / 2, self.imageView.frame.origin.y + self.imageView.frame.size.height / 2 - self.leftLabel.frame.size.height, self.leftLabel.frame.size.width, self.leftLabel.frame.size.height)
        self.topLabel.frame = CGRectMake((self.imageView.frame.origin.x + self.imageView.frame.size.width / 2) - self.topLabel.frame.size.width, (self.imageView.frame.origin.y + self.imageView.frame.size.height / 2) / 2, self.topLabel.frame.size.width, self.topLabel.frame.size.height)
        self.rightLabel.frame = CGRectMake((self.imageView.frame.origin.x + self.imageView.frame.size.width / 2) + (self.frame.size.width - (self.imageView.frame.origin.x + self.imageView.frame.size.width / 2)) / 2, (self.imageView.frame.origin.y + self.imageView.frame.size.height / 2) - self.rightLabel.frame.size.height, self.rightLabel.frame.size.width, self.rightLabel.frame.size.height)
        self.bottomLabel.frame = CGRectMake((self.imageView.frame.origin.x + self.imageView.frame.size.width / 2) - self.bottomLabel.frame.size.width, (self.imageView.frame.origin.y + self.imageView.frame.size.height / 2) + (self.frame.size.height - (self.imageView.frame.origin.y + self.imageView.frame.size.height / 2)) / 2, self.bottomLabel.frame.size.width, self.bottomLabel.frame.size.height)
        
        self.infoWindow.infoLabel.text = String(format: "位置: 上%@ 左%@ 下%@ 右%@", self.topLabel.text ?? "0",self.leftLabel.text ?? "0",self.bottomLabel.text ?? "0",self.rightLabel.text ?? "0")
        self.infoWindow.isHidden = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configInfoLabelText() {
        let stringInfo = String(format: "位置: 上%@ 左%@ 下%@ 右%@", self.topLabel.text ?? "0",self.leftLabel.text ?? "0",self.bottomLabel.text ?? "0",self.rightLabel.text ?? "0")
        self.infoWindow.infoLabel.text = stringInfo
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if CGRectContainsPoint(self.imageView.frame, point) {
            return true
        }
        return false
    }
    
    func show() {
        self.infoWindow.isHidden = false
        self.isHidden = false
    }
    
    func hide() {
        self.infoWindow.isHidden = true
        self.isHidden = true
    }
}
