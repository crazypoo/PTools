//
//  PTSwiftViewController.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/3.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import SnapKit

class PTSwiftViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        _ = PTCountryCodes.share.codesModels()
        
        PTCheckUpdateFunction.share.checkTheVersionWithappid(appid: "",force: true)
        
        
        let view = UIView()
//        view.backgroundColor = UIImage(named: "DemoImage")?.imageMostColor()
        view.backgroundGradient(type: .LeftToRight, colors: [UIColor.blue,UIColor.red])
        view.viewCornerRectCorner(cornerRadii: 30,borderWidth: 3,borderColor: .random,corner: [.topLeft,.topRight])
        self.view.addSubview(view)
        view.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(kNavBarHeight_Total)
            make.left.right.bottom.equalToSuperview().inset(40)
        }
        view.layoutSubviewsCallback = { view in
            PTLocalConsoleFunction.share.pNSLog(">>>>>>>>>>>>>>>>>>>>>.\(String(describing: view))")
        }
        
//        UIView.swizzleLayoutSubviewsCallback_UNTRACKABLE_TOGGLE()
//        view.layoutSubviewsCallback = { view in
//            PTLocalConsoleFunction.share.pNSLog(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\(view)")
//        }
//        view.layoutSubviews()
        self.view.backgroundColor = .random
        // Do any additional setup after loading the view.
        
        let status = UIView()
        status.backgroundColor = .random
        AppWindows!.addSubview(status)
        status.snp.makeConstraints { make in
            make.left.top.equalToSuperview()
            make.height.equalTo(kStatusBarHeight)
            make.width.equalTo(CGFloat.ScaleW(w: 85))
        }
        
        let sign = PTSignView(viewConfig: PTSignatureConfig())
        sign.showView()
        sign.doneBlock = { images in
            let imagesssss = UIImageView(image: images)
            self.view.addSubview(imagesssss)
            imagesssss.snp.makeConstraints { make in
                make.width.height.equalTo(100)
                make.top.equalToSuperview()
                make.right.equalToSuperview()
            }
        }        
    }
}
