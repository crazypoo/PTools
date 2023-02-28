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

#if canImport(LifetimeTracker)
import LifetimeTracker
#endif

class PTSwiftViewController: PTBaseViewController {
    
    class var lifetimeConfiguration: LifetimeConfiguration {
            return LifetimeConfiguration(maxCount: 1, groupName: "VC")
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
#if canImport(LifetimeTracker)
        trackLifetime()
#endif
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let gps = PTGetGPSData.share
        gps.locationManager.startUpdatingLocation()
        
        PTLocalConsoleFunction.share.pNSLog("1989-06-02 00:00:00".getConstellation())

        PTKeyChain.saveAccountInfo(service: "com.qq.com", account: "123", password: "312") { success in
        }
        PTGCDManager.gcdAfter(time: 2) {
//            let qrConfig = PTScanQRConfig()
//            qrConfig.canScanQR = false
//            let qr = PTScanQRController(viewConfig: qrConfig)
//            self.navigationController!.pushViewController(qr)
            
//            UIApplication.pt.likeTapHome()
//            
//            self.returnFrontVC()
            
            print(">>>>>>\(CGFloat.statusBarHeight())")


            print(UIDevice.lessThanSysVersion(version: "15", equal: true))
            
            print(PTKeyChain.getAccountInfo(service: "com.qq.com"))
            PTGCDManager.gcdAfter(time: 1){
                PTKeyChain.deleteAccountInfo(service: "com.qq.com", account: "",handle: { success in
                    
                })
                PTGCDManager.gcdAfter(time: 1){
                    print(PTKeyChain.getAccountInfo(service: "com.qq.com"))
                }
            }
            
        }
                
#if canImport(LifetimeTracker)
//    LifetimeTracker.setup(onUpdate: LifetimeTrackerDashboardIntegration(visibility: .visibleWithIssuesDetected, style: .bar).refreshUI)
#endif
        let card1 = "621226200000000000"
        let card2 = "123456789098765"
        let idcard = "111111111111111111"
        
        let color = UIColor.hex("#FFFFFF")
        
        let rangeFullStr = "你好啊"
        let rangeSubStr = "啊"
        let rangeArr = PTUtils.rangeOfSubString(fullStr: rangeFullStr as NSString, subStr: rangeSubStr as NSString)
        print(">>>>>>>>>>>>>>>>>>>>\(rangeArr)")
        
        print((idcard as NSString).getIdentityCardAge())

        PTBankSimpleInfoNetwork.getBankSimpleInfo(cardNum: card1 as NSString) { model in
            print(model.logoUrl)
        }

        print("\((card1 as NSString).bankCardLuhmCheck())\n\((card2 as NSString).bankCardLuhmCheck())")
        print("身份证:\((idcard as NSString).isValidateIdentity())")

        let aesKey = "keykeykeykeykeyk"
        let aesIv = "drowssapdrowssap"

        PTDataEncryption.aesEncryption(data: "adada".data(using: String.Encoding.utf8)!, key: aesKey, iv: aesIv) { encryptionString in
            PTDataEncryption.aseDecrypt(data: Data(base64Encoded: encryptionString, options: Data.Base64DecodingOptions(rawValue: 0))!, key: aesKey, iv: aesIv) { decryptData in
                PTLocalConsoleFunction.share.pNSLog("aes:\(String(describing: String(data: decryptData, encoding: .utf8)))\n")
            }
        }

        PTDataEncryption.desCrypt(operation: CCOperation(kCCEncrypt), key: "321", dataString: "123456789") { outputString in
            print("\(String(describing: outputString))\n")
            PTDataEncryption.desCrypt(operation: CCOperation(kCCDecrypt), key: "321", dataString: outputString) { outputString1 in
                print("\(String(describing: outputString1))\n")
            }
        }

        _ = PTCountryCodes.share.codesModels()

        let view = UIView()
//        view.backgroundColor = UIImage(named: "DemoImage")?.imageMostColor()
        view.backgroundGradient(type: .LeftToRight, colors: [UIColor.blue, UIColor.red])
        view.viewCornerRectCorner(cornerRadii: 30, borderWidth: 3, borderColor: .random, corner: [.topLeft, .topRight])
        self.view.addSubview(view)
        view.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(CGFloat.kNavBarHeight_Total)
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
        self.view.backgroundColor = color
        // Do any additional setup after loading the view.

        let status = UIImageView()
        status.image = "123123123123123".createQRImage(size: 100)
        status.backgroundColor = .random
        AppWindows!.addSubview(status)
        status.snp.makeConstraints { make in
            make.left.top.equalToSuperview()
            make.height.equalTo(CGFloat.statusBarHeight())
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
        
        let ccccccc = UILabel()
        ccccccc.text = "123123123123123112039810923890128309128390128903812903809128390128309182390812903819023819023"
        PTLocalConsoleFunction.share.pNSLog("----------------------------->\(ccccccc.sizeFor(size: CGSize(width:CGFloat.kSCREEN_WIDTH,height:CGFloat(MAXFLOAT))))")

        
        let counting = UILabel()
//        let counting = PTCountingLabel()
//        counting.positiveFormat = "##0.00"
        counting.textColor = .randomColor
        self.view.addSubview(counting)
        counting.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(100)
        }
//        counting.countFrom(starValue: 0, toValue: 100, duration: 3)
        counting.count(fromValue: 0, to: 100, duration: 3,formatter: "%.0f")
        status.layoutSubviewsCallback = { someview in
            print("asdadadadad:\(someview!)")
        }
        
        let linessssss = PTImaginaryLineView()
        linessssss.lineColor = .randomColor
        linessssss.lineType = .Ver
        self.view.addSubview(linessssss)
        linessssss.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(100)
            make.top.bottom.equalToSuperview()
            make.width.equalTo(20)
        }
        
        let customTextF = UITextView()
        self.view.addSubview(customTextF)
        customTextF.bk_placeholder = "123123123123123123123"
        customTextF.bk_wordCountLabel?.textColor = .randomColor
        customTextF.pt_maxWordCount = 10
        customTextF.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.bottom.equalToSuperview().inset(100)
        }

        let stepper = PTStepper()
        stepper.baseNum = "999"
        self.view.addSubview(stepper)
        stepper.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.top.equalTo(customTextF.snp.bottom)
            make.width.equalTo(150)
            make.height.equalTo(44)
        }
        
        PTContract.share.getContractData { models in
            print(models!.indexStrings)
        }
        
        let wave = PTWaterWaveView(startColor: .randomColor, endColor: .randomColor)
        self.view.addSubview(wave)
        wave.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        let coin = PTCoinAnimation()
        self.view.addSubview(coin)
        coin.showLabel.text = "1111111"
        coin.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        PTGCDManager.gcdAfter(time: 2) {
            coin.beginAnimationFunction()
            coin.animationBlock = { finish in
            }
        }
    }
}
