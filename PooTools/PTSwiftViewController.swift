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
    
    lazy var cycleView: LLCycleScrollView = {
        
        let banner = LLCycleScrollView.llCycleScrollViewWithFrame(.zero)
//        banner.delegate = self
        // 滚动间隔时间(默认为2秒)
        banner.autoScrollTimeInterval = 3.0
        // 等待数据状态显示的占位图
        banner.placeHolderImage = PTAppBaseConfig.share.defaultPlaceholderImage
        // 如果没有数据的时候，使用的封面图
        banner.coverImage = PTAppBaseConfig.share.defaultPlaceholderImage
        // 设置图片显示方式=UIImageView的ContentMode
        banner.imageViewContentMode = .scaleAspectFill
        banner.viewCorner(radius: 10)
        // 设置当前PageControl的样式 (.none, .system, .fill, .pill, .snake)
        banner.customPageControlStyle = .pill
        // 非.system的状态下，设置PageControl的tintColor
        banner.customPageControlInActiveTintColor = UIColor.lightGray
        // 设置.system系统的UIPageControl当前显示的颜色
        banner.pageControlCurrentPageColor = UIColor.white
        // 非.system的状态下，设置PageControl的间距(默认为8.0)
        banner.customPageControlIndicatorPadding = 5.0
        // 设置PageControl的位置 (.left, .right 默认为.center)
        banner.pageControlPosition = .center
        // 圆角
        banner.backgroundColor = .clear
        return banner
    }()
    
    var mSections = [PTSection]()
    func comboLayout()->UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout.init { section, environment in
            self.generateSection(section: section)
        }
        layout.register(PTBaseDecorationView_Corner.self, forDecorationViewOfKind: "background")
        layout.register(PTBaseDecorationView.self, forDecorationViewOfKind: "background_no")
        return layout
    }
    
    func generateSection(section:NSInteger)->NSCollectionLayoutSection {
        let sectionModel = mSections[section]

        var group : NSCollectionLayoutGroup
        let behavior : UICollectionLayoutSectionOrthogonalScrollingBehavior = .continuous
        
        var bannerGroupSize : NSCollectionLayoutSize
        var customers = [NSCollectionLayoutGroupCustomItem]()
        var groupH:CGFloat = 0
        let screenW:CGFloat = CGFloat.kSCREEN_WIDTH
        sectionModel.rows.enumerated().forEach { (index,model) in
            let cellHeight:CGFloat = 54
            let customItem = NSCollectionLayoutGroupCustomItem.init(frame: CGRect.init(x: PTAppBaseConfig.share.defaultViewSpace, y: groupH, width: screenW - PTAppBaseConfig.share.defaultViewSpace * 2, height: cellHeight), zIndex: 1000+index)
            customers.append(customItem)
            groupH += cellHeight
        }
        bannerGroupSize = NSCollectionLayoutSize.init(widthDimension: NSCollectionLayoutDimension.absolute(screenW), heightDimension: NSCollectionLayoutDimension.absolute(groupH))
        group = NSCollectionLayoutGroup.custom(layoutSize: bannerGroupSize, itemProvider: { layoutEnvironment in
            customers
        })

        let sectionInsets = NSDirectionalEdgeInsets.init(top: 0, leading: 0, bottom: 0, trailing: 0)
        let laySection = NSCollectionLayoutSection(group: group)
        laySection.orthogonalScrollingBehavior = behavior
        laySection.contentInsets = sectionInsets

        return laySection
    }

    lazy var collectionView : UICollectionView = {
        let view = UICollectionView.init(frame: .zero, collectionViewLayout: self.comboLayout())
        view.backgroundColor = .clear
        view.delegate = self
        view.dataSource = self
        return view
    }()

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
    
    func cellModels() -> [PTFusionCellModel] {
        
        let disclosureIndicatorImageName = "➡️".emojiToImage(emojiFont: .appfont(size: 14))
        let nameFont:UIFont = .appfont(size: 16,bold: true)

        let userIcon = PTFusionCellModel()
        userIcon.leftImage = "🧐".emojiToImage(emojiFont: .appfont(size: 24))
        userIcon.name = "修改用户头像"
        userIcon.contentIcon = "🧐".emojiToImage(emojiFont: .appfont(size: 24))
        userIcon.accessoryType = .DisclosureIndicator
        userIcon.nameColor = .black
        userIcon.disclosureIndicatorImage = disclosureIndicatorImageName
        userIcon.cellFont = nameFont
        
        let userNickName = PTFusionCellModel()
        userNickName.name = "修改用户昵称"
        userNickName.content = "AAAAAAA"
        userNickName.accessoryType = .DisclosureIndicator
        userNickName.nameColor = .black
        userNickName.disclosureIndicatorImage = disclosureIndicatorImageName
        userNickName.cellFont = nameFont

        let userPhone = PTFusionCellModel()
        userPhone.name = "修改用户手机号"
        userPhone.content = "BBBBB"
        userPhone.accessoryType = .Switch
        userPhone.nameColor = .black
        userPhone.disclosureIndicatorImage = disclosureIndicatorImageName
        userPhone.cellFont = nameFont

        let aaaaaa = PTFusionCellModel()
        aaaaaa.name = "123123123123123123123"
        aaaaaa.desc = "aaaaaadddddd"
        aaaaaa.accessoryType = .NoneAccessoryView
        aaaaaa.nameColor = .black
        aaaaaa.cellFont = nameFont

        return [/*userIcon,userNickName,userPhone,*/aaaaaa]
    }

    func showCollectionViewData() {
                
        self.mSections.removeAll()
        
        var rows = [PTRows]()
        self.cellModels().enumerated().forEach { (index,value) in
            let row_List = PTRows.init(title: value.name, placeholder: value.content,cls: PTFusionCell.self, ID: PTFusionCell.ID, dataModel: value)
            rows.append(row_List)
        }
        let cellSection = PTSection.init(rows: rows)
        mSections.append(cellSection)

        self.collectionView.pt_register(by: self.mSections)
        self.collectionView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        PTNSLogConsole(self)
        
        self.view.addSubview(self.collectionView)
        self.collectionView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalToSuperview().inset(CGFloat.kNavBarHeight_Total)
        }

        self.showCollectionViewData()
//        let config = PTTextCustomRightViewConfig()
//        config.image = "DemoImage"
//        config.size = CGSize(width: 24, height: 34)
//        
//        let textf = PTTextField()
//        textf.leftSpace = 30
//        textf.placeholder = "123123123123"
//        textf.rightTapBlock = {
//            PTNSLogConsole("12312312312314123123")
//        }
//        self.view.addSubview(textf)
//        textf.snp.makeConstraints { make in
//            make.left.right.equalToSuperview().inset(20)
//            make.height.equalTo(44)
//            make.centerY.equalToSuperview()
//        }
//        textf.viewCorner(radius: 5, borderWidth: 1, borderColor: .random)
//        textf.rightConfig = config

//        PTGCDManager.gcdAfter(time: 0.5) {
//            if #available(iOS 14, *) {
//                PTImagePicker.openAlbumForImageObject { result in
//                    PTNSLogConsole(result)
//                }
//                Task{
//                    do{
//                        let object:UIImage = try await PTImagePicker.openAlbum()
//                        await MainActor.run{
//                            PTNSLogConsole(object)
//    //                        var message = PTMessageModel(image: object, user: PTChatData.share.user, messageId: UUID().uuidString, date: Date(), sendSuccess: false)//PTMessageModel(text: str, user: user, messageId: UUID().uuidString, date: date,correctionText:saveModel.correctionText)
//    //                        message.sending = true
//    //                        self.insertMessage(message)
//                        }
//                    }
//                    catch let pickerError as PTImagePicker.PickerError
//                    {
//                        pickerError.outPutLog()
//                    }
//                }
//            }
//        }
        
//        let gps = PTGetGPSData.share
//        gps.locationManager.startUpdatingLocation()
//
//        PTNSLogConsole("............>>>>>>>>>>>>>>>>>>>\(Bundle.appScheme())")
//        PTNSLogConsole("............>>>>>>>>>>>>>>>>>>>\("".stringIsEmpty())>>>>>>>>\("12312312312313".stringIsEmpty())")
//
//        PTNSLogConsole("1989-06-02 00:00:00".getConstellation())
//
//        PTKeyChain.saveAccountInfo(service: "com.qq.com", account: "123", password: "312") { success in
//        }
//        PTGCDManager.gcdAfter(time: 2) {
//
//            PTUpdateTipsFunction.share.showUpdateTips(oldVersion:"1.0", newVersion:"1.1", description: "123123kljkljkljkljlkjkljkljlkjlkjkljkljkljkljlkjkljkljkljlkjlkjlkjkljkljkljlkjlkjlkjlkjlkjkljlkjlkjkljlkjkljlkjkljlkjlkjkljkljkljkljkljkljlkjkljlkjlkjlkjlkjlkjlkjlkjkljlkjkljkljlkj", downloadUrl: URL(string: "qq.com")!, isTest: false, showError: false)
//
////            let qrConfig = PTScanQRConfig()
////            qrConfig.canScanQR = false
////            let qr = PTScanQRController(viewConfig: qrConfig)
////            self.navigationController!.pushViewController(qr)
//
////            UIApplication.pt.likeTapHome()
////
////            self.returnFrontVC()
//
//            print(">>>>>>\(CGFloat.statusBarHeight())")
//
//            print(UIDevice.pt.lessThanSysVersion(version: "15", equal: true))
//
//            print(PTKeyChain.getAccountInfo(service: "com.qq.com"))
//            PTGCDManager.gcdAfter(time: 1){
//                PTKeyChain.deleteAccountInfo(service: "com.qq.com", account: "",handle: { success in
//
//                })
//                PTGCDManager.gcdAfter(time: 1){
//                    print(PTKeyChain.getAccountInfo(service: "com.qq.com"))
//                }
//            }
//
//        }
                
#if canImport(LifetimeTracker)
//    LifetimeTracker.setup(onUpdate: LifetimeTrackerDashboardIntegration(visibility: .visibleWithIssuesDetected, style: .bar).refreshUI)
#endif
//        let card1 = "621226200000000000"
//        let card2 = "123456789098765"
//        let idcard = "111111111111111111"
//
//        let color = UIColor.hex("#FFFFFF")
//
//        let rangeFullStr = "你好啊"
//        let rangeSubStr = "啊"
//        let rangeArr = PTUtils.rangeOfSubString(fullStr: rangeFullStr as NSString, subStr: rangeSubStr as NSString)
//        print(">>>>>>>>>>>>>>>>>>>>\(rangeArr)")
//
//        print((idcard as NSString).getIdentityCardAge())
//
//
//        print("\((card1 as NSString).bankCardLuhmCheck())\n\((card2 as NSString).bankCardLuhmCheck())")
//        print("身份证:\((idcard as NSString).isValidateIdentity())")
//
//        let aesKey = "keykeykeykeykeyk"
//        let aesIv = "drowssapdrowssap"
//
//        PTDataEncryption.aesEncryption(data: "adada".data(using: String.Encoding.utf8)!, key: aesKey, iv: aesIv) { encryptionString in
//            PTDataEncryption.aseDecrypt(data: Data(base64Encoded: encryptionString, options: Data.Base64DecodingOptions(rawValue: 0))!, key: aesKey, iv: aesIv) { decryptData in
//                PTNSLogConsole("aes:\(String(describing: String(data: decryptData, encoding: .utf8)))\n")
//            }
//        }
//
//        PTDataEncryption.desCrypt(operation: CCOperation(kCCEncrypt), key: "321", dataString: "123456789") { outputString in
//            print("\(String(describing: outputString))\n")
//            PTDataEncryption.desCrypt(operation: CCOperation(kCCDecrypt), key: "321", dataString: outputString) { outputString1 in
//                print("\(String(describing: outputString1))\n")
//            }
//        }
//
//        _ = PTCountryCodes.share.codesModels()
//
//        let view = UIView()
////        view.backgroundColor = UIImage(named: "DemoImage")?.imageMostColor()
//        view.backgroundGradient(type: .LeftToRight, colors: [UIColor.blue, UIColor.red])
//        view.viewCornerRectCorner(cornerRadii: 30, borderWidth: 3, borderColor: .random, corner: [.topLeft, .topRight])
//        self.view.addSubview(view)
//        view.snp.makeConstraints { make in
//            make.top.equalToSuperview().inset(CGFloat.kNavBarHeight_Total)
//            make.left.right.bottom.equalToSuperview().inset(40)
//        }
//        view.layoutSubviewsCallback = { view in
//            PTNSLogConsole(">>>>>>>>>>>>>>>>>>>>>.\(String(describing: view))")
//        }
//
//        UIView.swizzleLayoutSubviewsCallback_UNTRACKABLE_TOGGLE()
//        view.layoutSubviewsCallback = { view in
//            PTNSLogConsole(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\(view)")
//        }
//        view.layoutSubviews()
//        self.view.backgroundColor = color
        // Do any additional setup after loading the view.
//
//        let status = UIImageView()
//        status.image = "123123123123123".createQRImage(size: 100)
//        status.backgroundColor = .random
//        AppWindows!.addSubview(status)
//        status.snp.makeConstraints { make in
//            make.left.top.equalToSuperview()
//            make.height.equalTo(CGFloat.statusBarHeight())
//            make.width.equalTo(CGFloat.ScaleW(w: 85))
//        }
//
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
//                PTNSLogConsole(">>>>>>>>>>>>>>>\(sendResult)")
//            }
//        }

//        PTNSLogConsole("asdasdadasdasd>>\(Double(600).valueAddUnitToString(unit: unitma))")

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
//
//        let ccccccc = UILabel()
//        ccccccc.text = "123123123123123112039810923890128309128390128903812903809128390128309182390812903819023819023"
//        PTNSLogConsole("----------------------------->\(ccccccc.sizeFor(size: CGSize(width:CGFloat.kSCREEN_WIDTH,height:CGFloat(MAXFLOAT))))")
//
//
//        let counting = UILabel()
////        let counting = PTCountingLabel()
////        counting.positiveFormat = "##0.00"
//        counting.textColor = .randomColor
//        self.view.addSubview(counting)
//        counting.snp.makeConstraints { make in
//            make.left.right.equalToSuperview()
//            make.bottom.equalToSuperview()
//            make.height.equalTo(100)
//        }
////        counting.countFrom(starValue: 0, toValue: 100, duration: 3)
//        counting.count(fromValue: 0, to: 100, duration: 3,formatter: "%.0f")
//        status.layoutSubviewsCallback = { someview in
//            print("asdadadadad:\(someview)")
//        }
//
//        let linessssss = PTImaginaryLineView()
//        linessssss.lineColor = .randomColor
//        linessssss.lineType = .Ver
//        self.view.addSubview(linessssss)
//        linessssss.snp.makeConstraints { make in
//            make.left.equalToSuperview().inset(100)
//            make.top.bottom.equalToSuperview()
//            make.width.equalTo(20)
//        }
//
//        let customTextF = UITextView()
//        self.view.addSubview(customTextF)
//        customTextF.bk_placeholder = "123123123123123123123"
//        customTextF.bk_wordCountLabel?.textColor = .randomColor
//        customTextF.pt_maxWordCount = 10
//        customTextF.snp.makeConstraints { make in
//            make.left.right.equalToSuperview()
//            make.top.bottom.equalToSuperview().inset(100)
//        }
//
//        let stepper = PTStepper()
//        stepper.baseNum = "999"
//        self.view.addSubview(stepper)
//        stepper.snp.makeConstraints { make in
//            make.right.equalToSuperview()
//            make.top.equalTo(customTextF.snp.bottom)
//            make.width.equalTo(150)
//            make.height.equalTo(44)
//        }
//
//        PTContract.share.getContractData { models in
//            print(models!.indexStrings)
//        }
//
//        let wave = PTWaterWaveView(startColor: .randomColor, endColor: .randomColor)
//        self.view.addSubview(wave)
//        wave.snp.makeConstraints { make in
//            make.edges.equalToSuperview()
//        }
//        wave.layoutSubviewsCallback = { view in
//        }
//
//        let coin = PTCoinAnimation()
//        self.view.addSubview(coin)
//        coin.showLabel.text = "1111111"
//        coin.snp.makeConstraints { make in
//            make.edges.equalToSuperview()
//        }
//        PTGCDManager.gcdAfter(time: 2) {
//            coin.beginAnimationFunction()
//            coin.animationBlock = { finish in
//            }
//        }
    }
}

extension PTSwiftViewController:UICollectionViewDelegate,UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.mSections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.mSections[section].rows.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let itemSec = self.mSections[indexPath.section]
        let itemRow = itemSec.rows[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as! PTFusionCell
        cell.dataContent.backgroundColor = .white
        cell.cellModel = (itemRow.dataModel as! PTFusionCellModel)
        cell.dataContent.lineView.isHidden = indexPath.row == (itemSec.rows.count - 1) ? true : false
        cell.dataContent.topLineView.isHidden = true
        
        if itemSec.rows.count == 1 {
            PTGCDManager.gcdMain {
                cell.dataContent.viewCornerRectCorner(cornerRadii:5,corner:.allCorners)
            }
        } else {
            if indexPath.row == 0 {
                PTGCDManager.gcdMain {
                    cell.dataContent.viewCornerRectCorner(cornerRadii: 5,corner:[.topLeft,.topRight])
                }
            } else if indexPath.row == (itemSec.rows.count - 1) {
                PTGCDManager.gcdMain {
                    cell.dataContent.viewCornerRectCorner(cornerRadii: 5,corner:[.bottomLeft,.bottomRight])
                }
            }
        }
        return cell
    }
}
