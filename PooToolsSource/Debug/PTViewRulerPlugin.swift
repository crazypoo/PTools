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
    public static let share = PTViewRulerPlugin.init()
    
    fileprivate lazy var rulerView:PTRulerInfoView = {
        let view = PTRulerInfoView()
        return  view
    }()
    
    public var showed:Bool = false
    
    public override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(closePlugin(nofiti:)), name: NSNotification.Name(kPTClosePluginNotification), object: nil)
    }
        
    @objc func closePlugin(nofiti:Notification) {
        showed = false
        hide()
    }
    
    public func show() {
        rulerView.hide()
        AppWindows?.addSubview(rulerView)
        rulerView.show()
        showed = true
    }
    
    public func hide() {
        if showed {
            rulerView.hide()
        }
        showed = false
    }
}

fileprivate class PTVisualInfoController:UIView {
    
    var closeBlock:((UIButton,PTVisualInfoController) -> Void)?

    public lazy var infoLabel:UILabel = {
        let view = UILabel()
        view.font = .appfont(size: 16)
        view.numberOfLines = 0
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
        initUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initUI() {
        isUserInteractionEnabled = true
        backgroundColor = UIColor(dynamicProvider: { traitCollection in
            if traitCollection.userInterfaceStyle == .light {
                return .white
            } else {
                return .black
            }
        })
        
        self.addSubviews([self.closeBtn,self.infoLabel])

        PTGCDManager.gcdMain {
            self.viewCorner(radius: CGFloat.SizeFrom750(x: 8),borderWidth: 1,borderColor: UIColor.hex("#999999",alpha:0.2))
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        PTGCDManager.gcdAfter(time: 0.1) {
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
}

fileprivate class PTRulerInfoView:UIView {
    
    let viewPointSize:CGFloat = 62
    
    fileprivate lazy var topImage:UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.image = "⬇️".emojiToImage(emojiFont: .appfont(size: 6))
        return view
    }()
    
    fileprivate lazy var imageView : UIImageView = {
        let view = UIImageView()
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
        
        view.addSubviews([self.topImage])
        self.topImage.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.bottom.equalTo(view.snp.centerY)
            make.width.equalTo(self.topImage.snp.height)
            make.centerX.equalToSuperview()
        }
        
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
        
    fileprivate lazy var visualController:PTVisualInfoController = {
        let infoWindowFrame:CGRect = CGRect(x: CGFloat.SizeFrom750(x: 30), y: CGFloat.kSCREEN_HEIGHT - CGFloat.SizeFrom750(x: 100) - CGFloat.SizeFrom750(x: 30), width: CGFloat.kSCREEN_WIDTH - 2 * CGFloat.SizeFrom750(x: 30), height: CGFloat.SizeFrom750(x: 100))

        let view = PTVisualInfoController(frame: infoWindowFrame)
        view.closeBlock = { sender , pickerInfo in
            NotificationCenter.default.post(name: NSNotification.Name(kPTClosePluginNotification), object: nil, userInfo: nil)
        }
        return view
    }()
    
    init() {
        super.init(frame: CGRectMake(0, 0, CGFloat.kSCREEN_WIDTH, CGFloat.kSCREEN_HEIGHT))
        backgroundColor = .clear
        layer.zPosition = CGFloat(Float.greatestFiniteMagnitude)
        
        imageView.frame = CGRectMake(CGFloat.kSCREEN_WIDTH / 2 - viewPointSize / 2, CGFloat.kSCREEN_HEIGHT / 2 - viewPointSize / 2, viewPointSize, viewPointSize)
        self.horizontalLine.frame = CGRectMake(0, imageView.frame.origin.y + imageView.frame.size.height / 2 - 0.25, frame.size.width, 0.5)
        self.verticalLine.frame = CGRectMake(imageView.frame.origin.x + imageView.frame.size.width / 2 - 0.25, 0, 0.5, frame.size.height)
        addSubviews([imageView, horizontalLine, verticalLine])
        bringSubviewToFront(imageView)
        
        addSubviews([leftLabel, topLabel, rightLabel, bottomLabel])
        leftLabel.sizeToFit()
        topLabel.sizeToFit()
        rightLabel.sizeToFit()
        bottomLabel.sizeToFit()
        self.leftLabel.frame = CGRectMake((imageView.frame.origin.x + imageView.frame.size.width / 2) / 2, imageView.frame.origin.y + imageView.frame.size.height / 2 - leftLabel.frame.size.height, leftLabel.frame.size.width, leftLabel.frame.size.height)
        self.topLabel.frame = CGRectMake((imageView.frame.origin.x + imageView.frame.size.width / 2) - topLabel.frame.size.width, (imageView.frame.origin.y + imageView.frame.size.height / 2) / 2, topLabel.frame.size.width, topLabel.frame.size.height)
        self.rightLabel.frame = CGRectMake((imageView.frame.origin.x + imageView.frame.size.width / 2) + (self.frame.size.width - (imageView.frame.origin.x + imageView.frame.size.width / 2)) / 2, (imageView.frame.origin.y + imageView.frame.size.height / 2) - rightLabel.frame.size.height, rightLabel.frame.size.width, rightLabel.frame.size.height)
        self.bottomLabel.frame = CGRectMake((imageView.frame.origin.x + imageView.frame.size.width / 2) - bottomLabel.frame.size.width, (imageView.frame.origin.y + imageView.frame.size.height / 2) + (frame.size.height - (imageView.frame.origin.y + imageView.frame.size.height / 2)) / 2, bottomLabel.frame.size.width, bottomLabel.frame.size.height)
        
        
        AppWindows?.addSubviews([visualController])
        configInfoLabelText()
        visualController.isHidden = false
        
        NotificationCenter.default.addObserver(self, selector: #selector(closePlugin(nofiti:)), name: NSNotification.Name(kPTClosePluginNotification), object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configInfoLabelText() {
        let stringInfo = String(format: "PT Ruler".localized(), topLabel.text ?? "0", leftLabel.text ?? "0", bottomLabel.text ?? "0", rightLabel.text ?? "0")
        let height = UIView.sizeFor(string: stringInfo, font: .appfont(size: 16),width: CGFloat.kSCREEN_WIDTH - 60 - CGFloat.SizeFrom750(x: 44) - 20 - 5).height
        var base = CGFloat.SizeFrom750(x: 100)
        if height > base {
            base = height
        }
        visualController.infoLabel.text = stringInfo
        visualController.snp.remakeConstraints { make in
            make.left.right.equalToSuperview().inset(30)
            make.bottom.equalToSuperview().inset(CGFloat.kTabbarSaveAreaHeight)
            make.height.equalTo(base)
        }
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if CGRectContainsPoint(imageView.frame, point) {
            return true
        }
        return false
    }
    
    @objc func closePlugin(nofiti:Notification) {
        hide()
    }

    func show() {
        visualController.isHidden = false
        isHidden = false
    }
    
    func hide() {
        visualController.isHidden = true
        isHidden = true
    }
}
