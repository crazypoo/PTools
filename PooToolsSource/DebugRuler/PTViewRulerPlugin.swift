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

@MainActor
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
        guard let scene = PTSceneContext.activeWindow()?.windowScene else { return }
        show(in: scene)
    }

    // English: Present the ruler in the caller's scene instead of the process-wide fallback window.
    // Español: Presenta la regla en la escena del llamador en lugar de usar la ventana global del proceso.
    // 中文：在调用方所在场景显示标尺，不再依赖进程级兜底窗口。
    public func show(in scene: UIWindowScene) {
        guard let window = PTSceneContext.activeWindow(in: scene) else { return }
        rulerView.hide()
        window.addSubview(rulerView)
        rulerView.attach(to: window)
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

        Task { @MainActor  in
            self.viewCorner(radius: CGFloat.SizeFrom750(x: 8),borderWidth: 1,borderColor: UIColor.hex("#999999",alpha:0.2))
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        PTGCDManager.shared.delayOnMain(time: 0.1) {
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

    private weak var hostWindow: UIWindow?
    
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
        let inset = CGFloat.SizeFrom750(x: 30)
        let height = CGFloat.SizeFrom750(x: 100)
        let infoWindowFrame = CGRect(x: inset,
                                     y: max(0, bounds.height - height - inset),
                                     width: max(1, bounds.width - 2 * inset),
                                     height: height)

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
        
        imageView.frame = CGRect.zero
        self.horizontalLine.frame = .zero
        self.verticalLine.frame = .zero
        addSubviews([imageView, horizontalLine, verticalLine])
        bringSubviewToFront(imageView)
        
        addSubviews([leftLabel, topLabel, rightLabel, bottomLabel])
        updateGeometry()
        visualController.isHidden = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(closePlugin(nofiti:)), name: NSNotification.Name(kPTClosePluginNotification), object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // English: Attach both ruler surfaces to the same scene-owned window before showing them.
    // Español: Conecta ambas superficies de la regla a la ventana de la escena antes de mostrarlas.
    // 中文：显示前将标尺的两个界面都挂载到同一个场景窗口。
    func attach(to window: UIWindow) {
        hostWindow = window
        frame = window.bounds
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        updateGeometry()

        if visualController.superview !== window {
            visualController.removeFromSuperview()
            window.addSubview(visualController)
        }
        configInfoLabelText()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateGeometry()
    }

    // English: Recalculate frame-based ruler geometry after a scene or window size changes.
    // Español: Recalcula la geometría basada en frames cuando cambia el tamaño de la escena o la ventana.
    // 中文：场景或窗口尺寸变化后重新计算基于 frame 的标尺布局。
    private func updateGeometry() {
        let centerX = bounds.midX
        let centerY = bounds.midY
        imageView.frame = CGRect(x: centerX - viewPointSize / 2,
                                 y: centerY - viewPointSize / 2,
                                 width: viewPointSize,
                                 height: viewPointSize)
        horizontalLine.frame = CGRect(x: 0, y: centerY - 0.25, width: bounds.width, height: 0.5)
        verticalLine.frame = CGRect(x: centerX - 0.25, y: 0, width: 0.5, height: bounds.height)

        leftLabel.sizeToFit()
        topLabel.sizeToFit()
        rightLabel.sizeToFit()
        bottomLabel.sizeToFit()
        leftLabel.frame = CGRect(x: centerX / 2,
                                 y: centerY - leftLabel.frame.height,
                                 width: leftLabel.frame.width,
                                 height: leftLabel.frame.height)
        topLabel.frame = CGRect(x: centerX - topLabel.frame.width,
                                y: centerY / 2,
                                width: topLabel.frame.width,
                                height: topLabel.frame.height)
        rightLabel.frame = CGRect(x: centerX + (bounds.width - centerX) / 2,
                                  y: centerY - rightLabel.frame.height,
                                  width: rightLabel.frame.width,
                                  height: rightLabel.frame.height)
        bottomLabel.frame = CGRect(x: centerX - bottomLabel.frame.width,
                                   y: centerY + (bounds.height - centerY) / 2,
                                   width: bottomLabel.frame.width,
                                   height: bottomLabel.frame.height)
    }
    
    func configInfoLabelText() {
        let stringInfo = String(format: "PT Ruler".localized(), topLabel.text ?? "0", leftLabel.text ?? "0", bottomLabel.text ?? "0", rightLabel.text ?? "0")
        let textWidth = max(1, bounds.width - 60 - CGFloat.SizeFrom750(x: 44) - 20 - 5)
        let height = UIView.sizeFor(string: stringInfo, font: .appfont(size: 16), width: textWidth).height
        var base = CGFloat.SizeFrom750(x: 100)
        if height > base {
            base = height
        }
        visualController.infoLabel.text = stringInfo
        let bottomInset = hostWindow?.safeAreaInsets.bottom ?? 0
        visualController.snp.remakeConstraints { make in
            make.left.right.equalToSuperview().inset(30)
            make.bottom.equalToSuperview().inset(bottomInset)
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
