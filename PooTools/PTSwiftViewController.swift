//
//  PTSwiftViewController.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/3.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import CommonCrypto
import CryptoSwift
import SnapKit
import UIKit
import Photos
import Combine
import TipKit
import AttributedString

let shareText = "我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡"
let shareURLString = "https://www.github.com/crazypoo"

class PTSwiftViewController: PTBaseViewController {
        
//    private var videoEdit: PTVideoEdit?
//    fileprivate var cancellables = Set<AnyCancellable>()
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
            
    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        PTNSLogConsole(self)

//        let layoutBtn = PTLayoutButton()
//        layoutBtn.layoutStyle = .leftImageRightTitle
//        layoutBtn.setTitle("123", for: .normal)
//        layoutBtn.midSpacing = 0
//        layoutBtn.imageSize = CGSizeMake(100, 100)
//        
//        layoutBtn.backgroundColor = .systemBlue
//        view.addSubview(layoutBtn)
//        layoutBtn.snp.makeConstraints { make in
//            make.width.height.equalTo(100)
//            make.centerX.centerY.equalToSuperview()
//        }
//        
//        PTGCDManager.gcdMain {
//            layoutBtn.layerProgress(value: 0.5,borderWidth: 4)
//        }
//        
//        layoutBtn.addActionHandlers { sender in
//        }
        
//        self.view.addSubview(cycleView)
//        cycleView.snp.makeConstraints { make in
//            make.left.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
//            make.height.equalTo(150)
//            make.top.equalToSuperview().inset(CGFloat.kNavBarHeight_Total)
//        }
//             
//        cycleView.titles = ["1","2","3"/*,"4","5","6"*/]
//        cycleView.imagePaths = ["DemoImage.png"/*,"http://img.t.sinajs.cn/t35/style/images/common/face/ext/normal/7a/shenshou_thumb.gif"*/,"image_aircondition_gray.png"/*,"DemoImage.png","DemoImage.png","DemoImage.png","http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg"*/]

        screenShotHandle = { image in
        }
    }
}

extension PTSwiftViewController:PTRouterable {
    static var priority: UInt {
        PTRouterDefaultPriority
    }
    
    static var patternString: [String] {
        ["scheme://router/demo"]
    }
    
    static var descriptions: String {
        "PTSwiftViewController"
    }
    
    static func registerAction(info: [String : Any]) -> Any {
        PTNSLogConsole("Router info:\(info)")
        let vc =  PTSwiftViewController()
        return vc
    }
}

//@available(iOS 17, *)
//#Preview {
//    PTSwiftViewController()
//}
