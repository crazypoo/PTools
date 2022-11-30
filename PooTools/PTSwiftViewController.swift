//
//  PTSwiftViewController.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/3.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import CryptoSwift
import CommonCrypto

class PTSwiftViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let card1 = "621226200000000000"
        let card2 = "123456789098765"
        let idcard = "111111111111111111"
        
        print((idcard as NSString).getIdentityCardAge())
        
        PTBankSimpleInfoNetwork.getBankSimpleInfo(cardNum: card1 as NSString) { model in
            print(model.logoUrl)
        }
                
        print("\((card1 as NSString).bankCardLuhmCheck())\n\((card2 as NSString).bankCardLuhmCheck())")
        print("身份证:\((idcard as NSString).isValidateIdentity())")

        let aesKey = "keykeykeykeykeyk"
        let aesIv = "drowssapdrowssap"
        
        PTDataEncryption.aes_encryption(data: "adada".data(using: String.Encoding.utf8)!, key: aesKey, iv: aesIv) { encryptionString in            
            PTDataEncryption.ase_decrypt(data: Data(base64Encoded: encryptionString,options: Data.Base64DecodingOptions(rawValue: 0))!, key: aesKey, iv: aesIv) { decryptData in
                PTNSLog("aes:\(decryptData)\n")
            }
        }

        PTDataEncryption.des_crypt(operation: CCOperation(kCCEncrypt), key: "321", dataString: "123456789") { outputString in
            print("\(String(describing: outputString))\n")
            PTDataEncryption.des_crypt(operation: CCOperation(kCCDecrypt), key: "321", dataString: outputString) { outputString1 in
                print("\(String(describing: outputString1))\n")
            }
        }

        _ = PTCountryCodes.share.codesModels()
        
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
        
        let status = UIImageView()
        status.image = "123123123123123".createQRImage(size: 100)
        status.backgroundColor = .random
        AppWindows!.addSubview(status)
        status.snp.makeConstraints { make in
            make.left.top.equalToSuperview()
            make.height.equalTo(kStatusBarHeight)
            make.width.equalTo(CGFloat.ScaleW(w: 85))
        }
        
//        let sign = PTSignView(viewConfig: PTSignatureConfig())
//        sign.showView()
//        sign.doneBlock = { images in
//            let imagesssss = UIImageView(image: images)
//            self.view.addSubview(imagesssss)
//            imagesssss.snp.makeConstraints { make in
//                make.width.height.equalTo(100)
//                make.top.equalToSuperview()
//                make.right.equalToSuperview()
//            }
//        }
        
        
//        PTUtils.gcdAfter(time: 5) {
//            PTCallMessageMailFunction.sendMessage(content: "12312312312", users: ["15336934140"]) { sendResult in
//                PTLocalConsoleFunction.share.pNSLog(">>>>>>>>>>>>>>>\(sendResult)")
//            }
//        }
        
//        PTLocalConsoleFunction.share.pNSLog("asdasdadasdasd>>\(Double(600).valueAddUnitToString(unit: unitma))")
        
//        let vvvvv = PTGrowingTextView()
//        self.view.addSubview(vvvvv)
//        vvvvv.snp.makeConstraints { make in
//            make.left.right.equalToSuperview()
//            make.bottom.equalToSuperview()
//            make.height.equalTo(100)
//        }
//
//        let data = PTPermissionModel()
//        data.type = .tracking
//        data.name = "123123"
//        data.desc = "12312344444"
//        let vc = PTPermissionViewController.init(datas: [data])
//        if vc.appfirst == "0"
//        {
//        }
//        let nav = UINavigationController(rootViewController: vc)
//        nav.modalPresentationStyle = .fullScreen
//        self.navigationController?.present(nav, animated: true)
//        vc.viewDismissBlock = {
//        }
        let counting = PTCountingLabel()
        counting.positiveFormat = "##0.00"
        self.view.addSubview(counting)
        counting.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(100)
        }
        counting.countFrom(starValue: 0, toValue: 100, duration: 3)
    }
}
