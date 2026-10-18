//
//  PTTakePictureReviewer.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 1/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
#if canImport(PToolsConstraintLayout)
import PToolsConstraintLayout
#endif

// English: Import the umbrella Core target explicitly for standalone SwiftPM builds.
// Español: Importa explícitamente el target Core para las compilaciones SwiftPM independientes.
// 中文：独立 SwiftPM 编译时，显式导入 Core 聚合 target。
#if SWIFT_PACKAGE
import ptools
#endif
#if SWIFT_PACKAGE
import PToolsSymbols
#endif
import SnapKit

//MARK: ScreenShot的小控件
public class PTTakePictureReviewer:UIView {
                
    let ItemWidth:CGFloat = 88
    let ItemHeight:CGFloat = 164
    
    public var dismissTask:PTActionTask?
    
    public var actionHandle:PTScreenShotImageHandle?
    public var reviewHandle:PTActionTask?
    
    private var AnimationValue:CGFloat {
        ItemWidth + PTAppBaseConfig.share.defaultViewSpace
    }
    
    private lazy var closeButton : UIButton = {
        let view = UIButton(type: .close)
        view.addActionHandlers { sender in
            self.dismissAlert()
        }
        return view
    }()
    
    lazy var shareImageView:UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.isUserInteractionEnabled = true
        
        let tap = UITapGestureRecognizer { _ in
            self.reviewHandle?()
        }
        view.addGestureRecognizer(tap)
        return view
    }()
    
    private lazy var feedback:PTLayoutButton = {
        let view = self.viewLayoutBtnSet(title: "编辑", image: UIImage(.slider.horizontal_3))
        view.addActionHandlers { sender in
            self.actionHandle?(.Edit,self.shareImageView.image!)
            self.dismissAlert()
        }
        return view
    }()
    
    public init(screenShotImage:UIImage,dismiss: PTActionTask? = nil) {
        super.init(frame: CGRect(x: PTAppBaseConfig.share.defaultViewSpace, y: CGFloat.kSCREEN_HEIGHT - CGFloat.kTabbarHeight_Total - ItemHeight - 15 - CGFloat.kNavBarHeight_Total, width: ItemWidth, height: ItemHeight))
        backgroundColor = .DevMaskColor
        
        dismissTask = dismiss
        
        addSubviews([closeButton,feedback,shareImageView])
        closeButton.ptLayout.makeConstraints { make in
            make.right.top.equalToSuperview().inset(5)
            make.width.height.equalTo(15)
        }
        
        feedback.ptLayout.makeConstraints { make in
            make.left.right.equalToSuperview().inset(5)
            make.bottom.equalToSuperview()
            make.height.equalTo(24)
        }
                        
        shareImageView.image = screenShotImage
        shareImageView.ptLayout.makeConstraints { make in
            make.left.right.equalToSuperview().inset(5)
            make.top.equalTo(closeButton.ptLayout.bottom).offset(5)
            make.bottom.equalTo(self.feedback.ptLayout.top).offset(-5)
        }
        
        PTUtils.getCurrentVC()?.view.addSubview(self)
        showAlert()
        
        Task { @MainActor in
            self.viewCorner(radius: 5,borderWidth: 0,borderColor: .clear)
            self.shareImageView.viewCorner(radius: 5)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showAlert() {
        PTAnimationFunction.animationIn(animationView: self, animationType: .Left, transformValue: AnimationValue)
    }
    
    public func dismissAlert() {
        PTAnimationFunction.animationOut(animationView: self, animationType: .Left, toValue: -AnimationValue, animation: {
            Task { @MainActor in
                self.alpha = 0
            }
        }) { ok in
            Task { @MainActor in
                self.removeFromSuperview()
                self.dismissTask?()
            }
        }
    }
    
    func viewLayoutBtnSet(title:String,image:Any) -> PTLayoutButton {
        let view = PTLayoutButton()
        view.layoutStyle = .leftImageRightTitle
        view.midSpacing = 5
        view.imageSize = CGSize(width: 15, height: 15)
        view.normalTitleFont = .appfont(size: 13)
        view.normalTitle = title
        view.normalTitleColor = .white
        view.layoutLoadImage(contentData: image)
        return view
    }
}
