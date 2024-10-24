//
//  PTFuncDetailViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 1/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import GCDWebServer
import Alamofire
import SnapKit
import Photos
import Vision
import VisionKit
import SwifterSwift
import CommonCrypto
import AttributedString
import PhotosUI

let PTUploadFilePath = FileManager.pt.LibraryDirectory() + "/UploadFile"

class PTFuncDetailViewController: PTBaseViewController {

    private let pickedVideoName = "pickedExportedVideo.mov"
    
    enum PTLivePhotoMediaSelectedType {
        case Image
        case Video
        case LivePhoto
    }
    
    fileprivate var typeString:String!
    
    var webServer:GCDWebUploader?
    fileprivate var localNetwork:Bool = false
    var appNetWorkStatus:NetworkReachabilityManager.NetworkReachabilityStatus? = .unknown

    init(typeString: String!) {
        super.init(nibName: nil, bundle: nil)
        self.typeString = typeString
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        PTNetWorkStatus.shared.obtainDataFromLocalWhenNetworkUnconnected { status in
            self.appNetWorkStatus = status
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        webServer?.stop()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        switch typeString {
        case String.localNetWork:
            PTGCDManager.gcdAfter(time: 1) {
                var uploadInfoString = ""
                switch self.appNetWorkStatus {
                case .reachable(.ethernetOrWiFi):
                    self.localNetwork = !self.localNetwork
                    if self.localNetwork {
                        FileManager.pt.createFolder(folderPath: PTUploadFilePath)
                                
                        self.webServer = GCDWebUploader(uploadDirectory: PTUploadFilePath)
                        self.webServer!.delegate = self
                        self.webServer!.allowHiddenItems = false
                        self.webServer!.allowedFileExtensions = ["mp4","mov","doc","docx","xls","xlsx","txt","pdf","jpg","jpeg","png","gif","mp3"]

                        self.webServer.run { server in
                            if self.webServer!.start() {
                                let port = self.webServer!.port
                                uploadInfoString = String(format: "请在上传设备浏览器上输入%@\n端口为:%lu\n例子:IP地址:端口地址", self.webServer!.serverURL! as CVarArg,port)
                            } else {
                                uploadInfoString = "GCDWebServer not running!"
                            }
                        }
                    } else {
                        uploadInfoString = "GCDWebServer not running!"
                    }
                    
                    let label = UILabel()
                    label.textColor = .black
                    label.textAlignment = .center
                    label.numberOfLines = 0
                    label.lineBreakMode = .byCharWrapping
                    label.text = uploadInfoString
                    self.view.addSubview(label)
                    label.snp.makeConstraints { make in
                        make.edges.equalToSuperview()
                    }
                default:
                    UIViewController.gobal_drop(title: "请先将设备连接到WIFI上方可操作")
                    self.localNetwork = false
                }
            }
        case String.dymanicCode:
            let codeView = PTCodeView(numberOfCodes: 4, numberOfLines: 3, changeTimes: 3)
            view.addSubview(codeView)
            codeView.snp.makeConstraints { make in
                make.size.equalTo(150)
                make.centerX.centerY.equalToSuperview()
            }
        case String.slider:
            let slider = PTSlider(showTitle: true, titleIsValue: false)
            view.addSubview(slider)
            slider.snp.makeConstraints { make in
                make.width.equalTo(100)
                make.height.equalTo(80)
                make.centerX.centerY.equalToSuperview()
            }
        case String.rate:
            let rateConfig = PTRateConfig()
            rateConfig.canTap = true
            rateConfig.hadAnimation = true
            rateConfig.scorePercent = 0.8
            rateConfig.allowIncompleteStar = true
            
            let rate = PTRateView(viewConfig: rateConfig)
            rate.rateBlock = { score in
                PTNSLogConsole(score)
            }
            view.addSubview(rate)
            rate.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.height.equalTo(100)
                make.centerY.equalToSuperview()
            }
        case String.segment:
            let model1 = PTSegmentModel()
            model1.titles = "111111111111"
            model1.imageURL = "DemoImage"
            model1.selectedImageURL = "image_aircondition_gray"
            
            let model2 = PTSegmentModel()
            model2.titles = "2222222222222"
            model2.imageURL = "DemoImage"
            model2.selectedImageURL = "http://img.t.sinajs.cn/t35/style/images/common/face/ext/normal/7a/shenshou_thumb.gif"

            let model3 = PTSegmentModel()
            model3.titles = "3333333333333"
            model3.imageURL = "DemoImage"
            model3.selectedImageURL = "http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg"
            
            let model4 = PTSegmentModel()
            model4.titles = "4444444444444"

            let config = PTSegmentConfig()
            config.showType = .SubBackground
            config.itemSpace = 0
            config.leftEdges = true
            config.originalX = 0
            
            let segView = PTSegmentView(config: config)
            segView.backgroundColor = .random
            segView.viewDatas = [model1,model2,model3,model4]
            view.addSubview(segView)
            segView.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.height.equalTo(44)
                make.centerY.equalToSuperview()
            }
            segView.reloadViewData { index in
                
            }

        case String.countLabel:
            let countLabel = PTCountingLabel()
            countLabel.textAlignment = .center
            countLabel.font = .appfont(size: 30)
            countLabel.textColor = .black
            view.addSubview(countLabel)
            countLabel.format = "%.2f"
            countLabel.countFrom(starValue: 99999999.99, toValue: 0, duration: 1)
            countLabel.snp.makeConstraints { make in
                make.left.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
                make.top.equalToSuperview().inset(20)
                make.bottom.equalTo(self.view.snp.centerY)
            }
            
            let countLabelEx = UILabel()
            countLabelEx.enableCopy = true
            countLabelEx.textAlignment = .center
            countLabelEx.font = .appfont(size: 30)
            countLabelEx.count(fromValue: 99999999.99, to: 0, duration: 1,formatter: "%.2f")
            view.addSubview(countLabelEx)
            countLabelEx.snp.makeConstraints { make in
                make.left.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
                make.top.equalTo(countLabel.snp.bottom)
                make.bottom.equalToSuperview()
            }

        case String.throughLabel:
            let throughLabel = PTLabel()
            throughLabel.text = "111111111"
            throughLabel.backgroundColor = .random
            throughLabel.setVerticalAlignment(value: .Middle)
            throughLabel.setStrikeThroughAlignment(value: .Middle)
            throughLabel.strikeThroughColor = .random
            PTGCDManager.gcdAfter(time: 2) {
                throughLabel.setStrikeThroughEnabled(value: true)
            }
            view.addSubview(throughLabel)
            throughLabel.snp.makeConstraints { make in
                make.top.equalToSuperview().inset(16)
                make.left.right.equalToSuperview()
                make.height.equalTo(44)
            }
            
            let setBtn = UIButton(type: .custom)
            setBtn.backgroundColor = .random
            view.addSubview(setBtn)
            setBtn.snp.makeConstraints { make in
                make.size.equalTo(64)
                make.top.equalTo(throughLabel.snp.bottom).offset(10)
                make.centerX.equalToSuperview()
            }
            setBtn.addActionHandlers { sender in
                throughLabel.setVerticalAlignment(value: PTVerticalAlignment(rawValue: Int(arc4random())%3)!)
                throughLabel.setStrikeThroughAlignment(value: PTStrikeThroughAlignment(rawValue: Int(arc4random())%3)!)
                throughLabel.setStrikeThroughEnabled(value: (Int(arc4random())%2 == 1 ? true : false))
            }
        case String.vision:
            
            let view = UIButton(type: .custom)
            view.backgroundColor = .random
            self.view.addSubview(view)
            view.snp.makeConstraints { make in
                make.size.equalTo(64)
                make.centerX.centerY.equalToSuperview()
            }
            view.addActionHandlers { sender in
                self.dismiss(animated: true, completion: {
                    let pickerConfig = PTMediaLibConfig.share
                    pickerConfig.allowSelectImage = true
                    pickerConfig.allowSelectVideo = false
                    pickerConfig.allowSelectGif = false
                    pickerConfig.maxVideoSelectCount = 1
                    pickerConfig.maxSelectCount = 2
                    pickerConfig.allowEditImage = true
                    let vc = PTMediaLibViewController()
                    vc.mediaLibShow()
                    vc.selectImageBlock = { result, isOriginal in
                        let vision = PTVision.share
                        
                        var visionVersion:Int = VNRecognizeTextRequestRevision2
                        if #available(iOS 16.0, *) {
                            visionVersion = VNRecognizeTextRequestRevision3
                        }
                        
                        vision.findText(withImage: result.first!.image,revision: visionVersion) { resultText, textObservations in
                            UIViewController.gobal_drop(title: resultText)
                        }
                    }
                })
            }
        case String.twitterLabel:
            let customType = PTActiveType.custom(pattern: "\\s克狗扑\\b") //Looks for "克狗扑"
            let customType2 = PTActiveType.custom(pattern: "\\s标签\\b") //Looks for "标签"
            let customType3 = PTActiveType.custom(pattern: "\\s支持\\b") //Looks for "支持"

            let label = PTActiveLabel()

            label.enabledTypes.append(customType)
            label.enabledTypes.append(customType2)
            label.enabledTypes.append(customType3)

            label.urlMaximumLength = 10

            label.customize { label in
                label.text = "我是一个推文 13800138000 微信号:xxxx123 t:aaaaaaaaaaa #推文1 #我是辣鸡 @crazypoo. 推文发自" +
                " https://192.168.0.1 . 13800138000 我顺便 支持 自定义 标签 -> 克狗扑\n\n" +
                    "还可以缩短链接长度: \n https://github.com/crazypoo"
                label.numberOfLines = 0
                label.lineSpacing = 4
                
                label.textColor = UIColor(red: 102.0/255, green: 117.0/255, blue: 127.0/255, alpha: 1)
                label.hashtagColor = UIColor(red: 85.0/255, green: 172.0/255, blue: 238.0/255, alpha: 1)
                label.mentionColor = UIColor(red: 238.0/255, green: 85.0/255, blue: 96.0/255, alpha: 1)
                label.URLColor = UIColor(red: 85.0/255, green: 238.0/255, blue: 151.0/255, alpha: 1)
                label.URLSelectedColor = UIColor(red: 82.0/255, green: 190.0/255, blue: 41.0/255, alpha: 1)
                label.chinaCellPhoneColor = .random
                
                label.handleMentionTap { text in
                    self.alert(title:"Mention", message: text)
                }
                label.handleHashtagTap { text in
                    self.alert(title:"Hashtag", message: text)
                }
                label.handleURLTap { url in
                    self.alert(title:"URL", message: url.absoluteString)
                }
                label.handleChinaCellPhoneTap { phone in
                    self.alert(title:"CellPhone", message: phone)
                }

                //Custom types

                label.customColor[customType] = UIColor.purple
                label.customSelectedColor[customType] = UIColor.green
                label.customColor[customType2] = UIColor.magenta
                label.customSelectedColor[customType2] = UIColor.green
                
                label.configureLinkAttribute = { (type, attributes, isSelected) in
                    var atts = attributes
                    switch type {
                    case PTActiveType.hashtag:
                        atts[NSAttributedString.Key.font] = isSelected ? UIFont.boldSystemFont(ofSize: 16) : UIFont.boldSystemFont(ofSize: 16)
                    case customType3:
                        atts[NSAttributedString.Key.font] = isSelected ? UIFont.boldSystemFont(ofSize: 16) : UIFont.boldSystemFont(ofSize: 14)
                    default: ()
                    }
                    
                    return atts
                }

                label.handleCustomTap(for: customType) { text in
                    self.alert(title:"Custom type", message: text)
                }
                label.handleCustomTap(for: customType2) { text in
                    self.alert(title:"Custom type", message: text)
                }
                label.handleCustomTap(for: customType3) { text in
                    self.alert(title:"Custom type", message: text)
                }
            }

            view.addSubview(label)
            label.snp.makeConstraints { make in
                make.left.right.equalToSuperview().inset(20)
                make.top.equalToSuperview().inset(40)
                make.height.equalTo(300)
            }
        case String.movieCutOutput,String.share,String.menu:
            let layoutBtn = PTLayoutButton()
            layoutBtn.layoutStyle = .leftImageRightTitle
            layoutBtn.normalTitle = "Title"
            layoutBtn.normalSubTitle = "SubTitle"
            layoutBtn.selectedTitleColor = .red
            layoutBtn.selectedTitleFont = .appfont(size: 16)
            layoutBtn.midSpacing = 0
            layoutBtn.titlePadding = 20
            layoutBtn.imageSize = CGSizeMake(30, 30)
            layoutBtn.normalImage = UIImage(named: "DemoImage")!
            layoutBtn.selectedImage = UIImage(named: "image_day_normal_3")!
            layoutBtn.configBackgroundColor = .AlmondColor
            layoutBtn.configBackgroundSelectedColor = .systemBlue
            view.addSubview(layoutBtn)
            layoutBtn.snp.makeConstraints { make in
                make.width.height.equalTo(100)
                make.centerX.centerY.equalToSuperview()
            }
            switch typeString {
            case String.movieCutOutput:
                PTGCDManager.gcdAfter(time: 1) {
                    var value:CGFloat = 0
                    let timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
                        layoutBtn.layerProgress(value: value,borderWidth: 4)
                        value += 0.1
                        if value >= 1 {
                            timer.invalidate()
                            layoutBtn.clearProgressLayer()
                        }
                    }
                    timer.fire()
                }
            default:
                break
            }
            layoutBtn.addActionHandlers { sender in
                layoutBtn.isSelected = !sender.isSelected
                switch self.typeString {
                case String.menu:
                    let menuItems = PTEditMenuItem(title: "111") {
                        PTNSLogConsole("我点击了")
                    }
                    
                    let menu = PTEditMenuItemsInteraction()
                    menu.showMenu([menuItems], targetRect: sender.frame, for: sender)
                default:
                    break
                }
            }
        case String.progressBar:
            let verProgress = PTProgressBar(showType: .Vertical)
            let horProgress = PTProgressBar(showType: .Horizontal)

            view.addSubviews([verProgress,horProgress])
            verProgress.snp.makeConstraints { make in
                make.top.equalToSuperview().inset(20)
                make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
                make.bottom.equalToSuperview().inset(CGFloat.kTabbarSaveAreaHeight)
                make.width.equalTo(22)
            }
            
            horProgress.snp.makeConstraints { make in
                make.top.equalTo(verProgress)
                make.left.equalTo(verProgress.snp.right).offset(10)
                make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
                make.height.equalTo(22)
            }
            
            PTGCDManager.gcdMain {
                verProgress.viewCorner(radius: 11, borderWidth: 1, borderColor: .lightGray)
                horProgress.viewCorner(radius: 11, borderWidth: 1, borderColor: .lightGray)
                
            }
            
            PTGCDManager.gcdAfter(time: 1) {
                verProgress.animationProgress(duration: 1, value: 0.5)
                horProgress.animationProgress(duration: 1, value: 0.75)
            }
        case String.encryption:
            
            let testKey = "0523iZTd7tkX0820"
            let testIV = "1333000000000000"

            let returnButton = UIButton(type: .custom)
            returnButton.setImage(UIImage.system("arrowshape.turn.up.left"), for: .normal)
            
            let switchDES = UISwitch()
            switchDES.onTintColor = .systemBlue
            switchDES.isOn = false
            
            let switchAESECB = UISwitch()
            switchAESECB.onTintColor = .systemRed
            switchAESECB.isOn = false

            let switchAESCBC = UISwitch()
            switchAESCBC.onTintColor = .systemGreen
            switchAESCBC.isOn = false

            let contentLabel = UILabel()
            contentLabel.textColor = .black
            contentLabel.text = "潮州周杰伦是GAY"
            contentLabel.numberOfLines = 0
            contentLabel.textAlignment = .center
            view.addSubviews([returnButton,contentLabel,switchDES,switchAESECB,switchAESCBC])
            returnButton.snp.makeConstraints { make in
                make.size.equalTo(34)
                make.top.equalToSuperview().inset(20)
                make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            }
            contentLabel.snp.makeConstraints { make in
                make.top.equalTo(returnButton.snp.bottom).offset(5)
                make.left.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            }
            
            switchDES.snp.makeConstraints { make in
                make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
                make.height.equalTo(34)
                make.top.equalTo(contentLabel.snp.bottom).offset(10)
            }
            
            switchAESECB.snp.makeConstraints { make in
                make.top.bottom.equalTo(switchDES)
                make.left.equalTo(switchDES.snp.right).offset(20)
            }
            
            switchAESCBC.snp.makeConstraints { make in
                make.top.bottom.equalTo(switchDES)
                make.left.equalTo(switchAESECB.snp.right).offset(20)
            }
            
            switchDES.addSwitchAction { sender in
                if !(contentLabel.text ?? "").stringIsEmpty() {
                    if sender.isOn {
                        Task.init {
                            do {
                                contentLabel.text = try await PTDataEncryption.desCrypt(operation: CCOperation(kCCEncrypt), key: testKey, dataString: contentLabel.text!)
                            } catch {
                                PTNSLogConsole(error.localizedDescription)
                            }
                        }
                    } else {
                        Task.init {
                            do {
                                contentLabel.text = try await PTDataEncryption.desCrypt(operation: CCOperation(kCCDecrypt), key: testKey, dataString: contentLabel.text!)
                            } catch {
                                PTNSLogConsole(error.localizedDescription)
                            }
                        }
                    }
                } else {
                    PTNSLogConsole("nill value")
                }
            }
            
            switchAESECB.addSwitchAction { sender in
                if !(contentLabel.text ?? "").stringIsEmpty() {
                    if sender.isOn {
                        Task.init {
                            do {
                                contentLabel.text = try await PTDataEncryption.aesECBEncryption(data: contentLabel.text!.data(using: .utf8)!, key: testKey)
                            } catch {
                                PTNSLogConsole(error.localizedDescription)
                            }
                        }
                    } else {
                        Task.init {
                            do {
                                let datas = try await PTDataEncryption.aesECBDecrypt(data: Data(base64Encoded: contentLabel.text!)!, key: testKey)
                                contentLabel.text = String(data: datas, encoding: .utf8)
                            } catch {
                                PTNSLogConsole(error.localizedDescription)
                            }
                        }
                    }
                } else {
                    PTNSLogConsole("nill value")
                }
            }
            
            switchAESCBC.addSwitchAction { sender in
                if !(contentLabel.text ?? "").stringIsEmpty() {
                    if sender.isOn {
                        Task.init {
                            do {
                                contentLabel.text = try await PTDataEncryption.aesEncryption(data: contentLabel.text!.data(using: .utf8)!, key: testKey, iv: testIV)
                            } catch {
                                PTNSLogConsole(error.localizedDescription)
                            }
                        }
                    } else {
                        Task.init {
                            do {
                                let datas = try await PTDataEncryption.aesDecrypt(data: Data(base64Encoded: contentLabel.text!)!, key: testKey, iv: testIV)
                                contentLabel.text = String(data: datas, encoding: .utf8)
                            } catch {
                                PTNSLogConsole(error.localizedDescription)
                            }
                        }
                    }
                } else {
                    PTNSLogConsole("nill value")
                }
            }
            
            returnButton.addActionHandlers { sender in
                contentLabel.text = "潮州周杰伦是GAY"
                switchDES.isOn = false
                switchAESECB.isOn = false
                switchAESCBC.isOn = false
            }
        case String.sortButton:
            
            let sortButton = PTSortButton(showType: .Dos)
            sortButton.buttonTitle = "111111111111111111111111111111111111111111111111111!!!!!!!!!!!!!!!!!!"
            sortButton.buttonTitleSelectedColor = .random
            sortButton.imageSize = CGSizeMake(10, 24)
            view.addSubviews([sortButton])
            sortButton.sortTypeHandler = { type in
                PTNSLogConsole("\(type.rawValue)")
            }
            sortButton.snp.makeConstraints { make in
                make.height.equalTo(44)
                make.left.right.equalToSuperview()
                make.top.equalToSuperview().inset(20)
            }
        case String.CycleBanner:
            let banner = PTCycleScrollView()
            banner.autoScroll = true
            // 滚动间隔时间(默认为2秒)
            banner.autoScrollTimeInterval = 3.0
            // 设置图片显示方式=UIImageView的ContentMode
            banner.imageViewContentMode = .scaleAspectFill
            banner.viewCorner(radius: 10)
            // 设置当前PageControl的样式 (.none, .system, .fill, .pill, .snake)
            banner.customPageControlStyle = .snake
            // 非.system的状态下，设置PageControl的tintColor
            banner.customPageControlInActiveTintColor = UIColor.lightGray
            // 设置.system系统的UIPageControl当前显示的颜色
            banner.pageControlCurrentPageColor = UIColor.randomColor
            // 非.system的状态下，设置PageControl的间距(默认为8.0)
            banner.customPageControlIndicatorPadding = 5.0
            // 设置PageControl的位置 (.left, .right 默认为.center)
            banner.pageControlPosition = .center
            banner.scrollDirection = .horizontal
            // 圆角
            banner.backgroundColor = .clear
            banner.textColor = .random
            banner.titleBackgroundColor = .brown
            banner.pageControlActiveImage = DynamicColor.gray.createImageWithColor().transformImage(size: CGSize(width: 4, height: 4)).pt.isRoundCorner(radius: 2,imageSize: CGSize(width: 4, height: 4))
            banner.pageControlInActiveImage = DynamicColor.white.createImageWithColor().transformImage(size: CGSize(width: 8, height: 4)).pt.isRoundCorner(radius: 2,imageSize: CGSize(width: 8, height: 4))
            banner.didSelectItemAtIndexClosure = { index in
                PTNSLogConsole(">>>>>>>>>>>>>>>>>>>\(index)")
            }
            view.addSubviews([banner])
            banner.snp.makeConstraints { make in
                make.left.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
                make.top.equalToSuperview().inset(20)
                make.height.equalTo(190)
            }
            
            let att1:ASAttributedString = """
                    \(wrap: .embedding("""
                    \("1112312312312312312312312312323",.foreground(.init(hexString: "de1e50")!),.font(.appfont(size: 15)),.paragraph(.alignment(.left)))
                    \("112123123123123123",.foreground(.systemBlue),.font(.appfont(size: 15)),.paragraph(.alignment(.left)))
                    """))
                    """
            banner.titles = [att1,att1,att1]
            banner.imagePaths = ["http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg","http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg","http://yuliao202310.oss-cn-beijing.aliyuncs.com/我的二维码 (7).jpg"]
        case String.CollectionTag:
            
            let tagValue = ["1123123","1","123123123123123","22222","1233"]

            var tagModels = [PTTagLayoutModel]()
            tagValue.enumerated().forEach { index,value in
                let tagModel = PTTagLayoutModel()
                tagModel.name = value
                tagModels.append(tagModel)
            }
            
            let cConfig = PTCollectionViewConfig()
            cConfig.viewType = .Tag
            cConfig.itemOriginalX = PTAppBaseConfig.share.defaultViewSpace
            cConfig.itemHeight = 32
            cConfig.cellLeadingSpace = 10
            cConfig.cellTrailingSpace = 10
            cConfig.contentTopSpace = 10
            cConfig.contentBottomSpace = 10
            let aaaaaaa = PTCollectionView(viewConfig: cConfig)
            aaaaaaa.backgroundColor = .random
            aaaaaaa.registerClassCells(classs: [PTTagCell.ID:PTTagCell.self])
            aaaaaaa.cellInCollection = { collectionView ,dataModel,indexPath in
                let itemRow = dataModel.rows[indexPath.row]
                let cellModel = (itemRow.dataModel as! PTTagLayoutModel)
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as! PTTagCell
                cell.cellModel = cellModel
                return cell
            }
            view.addSubviews([aaaaaaa])
            aaaaaaa.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.top.equalToSuperview().inset(20)
                make.height.equalTo(UICollectionView.tagShowLayoutHeight(data: tagModels,topContentSpace: cConfig.contentTopSpace, bottomContentSpace: cConfig.contentBottomSpace,itemLeadingSpace: cConfig.cellLeadingSpace,itemTrailingSpace: cConfig.cellTrailingSpace,itemContentSpace: cConfig.tagCellContentSpace).groupHeight)
            }
            
            
            var tagRows = [PTRows]()
            tagModels.enumerated().forEach { index,value in
                let row = PTRows(ID: PTTagCell.ID,dataModel: value)
                tagRows.append(row)
            }
            let tagSection = [PTSection(rows: tagRows)]
            aaaaaaa.showCollectionDetail(collectionData: tagSection)
        case String.InputBox:
            let GobalPaymentSmallBoxWidth:CGFloat = (CGFloat.kSCREEN_WIDTH - 48 - 8 * 5) / 6

            let inputConfig = PTInputBoxConfiguration()
            inputConfig.inputBoxNumber = 6
            inputConfig.inputBoxWidth = GobalPaymentSmallBoxWidth
            inputConfig.inputBoxHeight = GobalPaymentSmallBoxWidth
            inputConfig.inputBoxSpacing = 8
            inputConfig.inputBoxBorderWidth = 1
            inputConfig.inputBoxCornerRadius = 4
            inputConfig.inputBoxColor = DynamicColor(hexString: "cacaca")
            inputConfig.inputType = .Number
            inputConfig.autoShowKeyboard = true
            inputConfig.inputBoxFinishColors = [UIColor.systemRed]
            inputConfig.inputBoxHighlightedColor = UIColor.systemRed
            inputConfig.finishTextColors = [UIColor.black]
            inputConfig.secureTextEntry = true
            inputConfig.keyboardType = .numberPad
            inputConfig.textColor = UIColor.black
            
            let codeInputView = PTInputBoxView.init(frame: CGRectMake(PTAppBaseConfig.share.defaultViewSpace, CGFloat.kNavBarHeight_Total + 110, CGFloat.kSCREEN_WIDTH - 48, GobalPaymentSmallBoxWidth + 2), config: inputConfig)
            codeInputView.finishBlock = { (view: PTInputBoxView, code: String) -> () in
            }
            
            view.addSubviews([codeInputView])
            codeInputView.snp.makeConstraints { make in
                make.centerX.centerY.equalToSuperview()
                make.width.equalTo(CGFloat.kSCREEN_WIDTH - 48)
                make.height.equalTo(GobalPaymentSmallBoxWidth + 2)
            }
        case String.Stepper:
            let stepper = PTStepper()
            stepper.viewShowType = .RTL
            stepper.contentSpace = 6
            stepper.baseNum = "10"
            stepper.minNum = 1
            stepper.maxNum = 99
            stepper.inputBackgroundColor = .clear
            stepper.addImage = UIImage(named: "image_day_normal_1")!.transformImage(size: CGSizeMake(24, 24))
            stepper.reduceImage = UIImage(named: "image_day_normal_1")!.transformImage(size: CGSizeMake(24, 24))
            stepper.numberTextColor = .black
            stepper.numberTextFont = .appfont(size: 12)
            stepper.valueBlock = { value,type in
                PTNSLogConsole("\(type),\(value)")
            }
            view.addSubviews([stepper])
            stepper.snp.makeConstraints { make in
                make.centerX.centerY.equalToSuperview()
                make.width.equalTo(100)
                make.height.equalTo(24)
            }
        case String.LoginDesc:
            let aaaaa = PTLoginDescButton(config: PTLoginDescConfig())
            view.addSubviews([aaaaa])
            aaaaa.snp.makeConstraints { make in
                make.centerX.centerY.equalToSuperview()
//                make.width.equalTo(100)
                make.height.equalTo(24)
            }
            aaaaa.descHandler = { type in
                PTNSLogConsole("123123123123123123123\(type)")
            }
            
        case String.StepperList:
            
            let stepperModel1 = PTStepperListModel()
            stepperModel1.title = "1111111111"
            stepperModel1.desc = "12312312312312313123123123"
            stepperModel1.stopFinish = true
            
            let stepperModel2 = PTStepperListModel()
            stepperModel2.title = "22222222"
            stepperModel2.stopFinish = true

            let stepperModel3 = PTStepperListModel()
            stepperModel3.title = "33333333333"
            stepperModel3.stopFinish = false

            let stepperModel4 = PTStepperListModel()
            stepperModel4.title = "444444444"
            stepperModel4.stopFinish = false

            let stepperModel5 = PTStepperListModel()
            stepperModel5.title = "5555555"
            stepperModel5.stopFinish = false

            let config = PTStepperListConfig()
            config.type = .Vertical(type: .Normal)
            config.stepperModels = [stepperModel1,stepperModel2,stepperModel3,stepperModel4,stepperModel5]
            config.itemOriginalX = 16
            
            let stepper = PTStepperView(viewConfig: config)
            view.addSubviews([stepper])
            stepper.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.top.equalToSuperview().inset(self.sheetViewController?.options.pullBarHeight ?? 0)
                make.bottom.equalToSuperview()
            }
        case String.LivePhoto,String.LivePhotoDisassemble:
            
            var pickedPhoto: UIImage?
            var pickedVideoURL: URL?
            var disassembleImageURL: URL?

            let livePhotoView = PHLivePhotoView()
            livePhotoView.contentMode = .scaleAspectFit
            livePhotoView.delegate = self
            livePhotoView.backgroundColor = .randomColor
            
            let showImageView = UIImageView()
            showImageView.isUserInteractionEnabled = true
            showImageView.contentMode = .scaleAspectFill
            showImageView.clipsToBounds = true
            showImageView.backgroundColor = .randomColor
            
            let videoImageView = UIImageView()
            videoImageView.isUserInteractionEnabled = true
            videoImageView.contentMode = .scaleAspectFill
            videoImageView.clipsToBounds = true
            videoImageView.backgroundColor = .randomColor
            
            switch typeString {
            case String.LivePhoto:
                let tap_image = UITapGestureRecognizer { sender in
                    self.livePhotoMediaSelect(type: .Image) { result in
                        pickedPhoto = result.image
                        showImageView.image = result.image
                    }
                }
                showImageView.addGestureRecognizer(tap_image)

                let tap_video = UITapGestureRecognizer { sender in
                    self.livePhotoMediaSelect(type: .Video) { result in
                        result.asset.converPHAssetToAVURLAsset { avAsset in
                            if let avURLAsset = avAsset {
                                let _ = avURLAsset.exportToDocuments(filename: self.pickedVideoName) { outputURL in
                                    UIImage.pt.getVideoFirstImage(videoUrl: URL(fileURLWithPath: outputURL.absoluteString).absoluteString) { image in
                                        pickedVideoURL = URL(fileURLWithPath: outputURL.absoluteString)
                                        videoImageView.image = image
                                    }
                                }
                            } else {
                                PTNSLogConsole("没有这个文件")
                            }
                        }
                    }
                }
                videoImageView.addGestureRecognizer(tap_video)
            case String.LivePhotoDisassemble:
                let tap_image = UITapGestureRecognizer { sender in
                    if let imagePath = disassembleImageURL?.path {
                        if FileManager.pt.judgeFileOrFolderExists(filePath: imagePath) {
                            let imageURL = URL(fileURLWithPath: imagePath)
                            PHPhotoLibrary.pt.saveImageUrlToAlbum(fileUrl: imageURL) { finish, error in
                                if finish {
                                    PTGCDManager.gcdMain {
                                        PTAlertTipControl.present(title:"Photo Saved.The photo was successfully saved to Photos.",icon:.Done,style: .Normal)
                                    }
                                } else {
                                    PTGCDManager.gcdMain {
                                        PTAlertTipControl.present(title:"Photo Not Saved",icon:.Error,style: .Normal)
                                    }
                                }
                            }
                        } else {
                            PTGCDManager.gcdMain {
                                PTAlertTipControl.present(title:"Photo cannot be Saved",icon:.Error,style: .Normal)
                            }
                        }
                    } else {
                        PTGCDManager.gcdMain {
                            PTAlertTipControl.present(title:"Photo url error",icon:.Error,style: .Normal)
                        }
                    }
                }
                showImageView.addGestureRecognizer(tap_image)

                let tap_video = UITapGestureRecognizer { sender in
                    if let videoPath = pickedVideoURL?.path {
                        if FileManager.pt.judgeFileOrFolderExists(filePath: videoPath) {
                            let videoURL = URL(fileURLWithPath: videoPath)
                            PHPhotoLibrary.pt.saveVideoToAlbum(fileURL: videoURL) { finish, error in
                                if finish {
                                    PTGCDManager.gcdMain {
                                        PTAlertTipControl.present(title:"Video Saved.The Video was successfully saved to Video.",icon:.Done,style: .Normal)
                                    }
                                } else {
                                    PTGCDManager.gcdMain {
                                        PTAlertTipControl.present(title:"Video Not Saved",icon:.Error,style: .Normal)
                                    }
                                }
                            }
                        } else {
                            PTGCDManager.gcdMain {
                                PTAlertTipControl.present(title:"Video cannot be Saved",icon:.Error,style: .Normal)
                            }
                        }
                    } else {
                        PTGCDManager.gcdMain {
                            PTAlertTipControl.present(title:"Video url error",icon:.Error,style: .Normal)
                        }
                    }
                }
                videoImageView.addGestureRecognizer(tap_video)
            default: break
            }

            let progressView = UIProgressView()
            progressView.trackTintColor = .random
            
            let createButton = UIButton(type: .custom)
            createButton.setTitleColor(.random, for: .normal)
            switch self.typeString {
            case String.LivePhoto:
                createButton.setTitle("Create LivePhoto Button", for: .normal)
            case String.LivePhotoDisassemble:
                createButton.setTitle("Select LivePhoto Button", for: .normal)
            default:break
            }
            createButton.addActionHandlers { sender in
                switch self.typeString {
                case String.LivePhoto:
                    guard let sourceVideoPath = pickedVideoURL else {
                        PTGCDManager.gcdMain {
                            PTAlertTipControl.present(title:"It seems a video was not selected.Try again.",icon:.Error,style: .Normal)
                        }
                        return
                    }
                    var photoURL: URL?
                    if let sourceKeyPhoto = pickedPhoto {
                        guard let data = sourceKeyPhoto.jpegData(compressionQuality: 1.0) else { return }
                        photoURL = URL(fileURLWithPath: FileManager.pt.DocumnetsDirectory().appendingPathComponent("photo.jpg"))
                        if let photoURL = photoURL {
                            try? data.write(to: photoURL)
                        }
                    }
                    PTLivePhoto.generate(from: photoURL, videoURL: sourceVideoPath, progress: { (percent) in
                        PTGCDManager.gcdMain {
                            progressView.progress = Float(percent)
                        }
                    }) { (livePhoto, resources) in
                        livePhotoView.livePhoto = livePhoto
                        livePhotoView.startPlayback(with: .hint)

                        if let resources = resources {
                            PTLivePhoto.saveToLibrary(resources, completion: { (success) in
                                if success {
                                    PTGCDManager.gcdMain {
                                        PTAlertTipControl.present(title:"Live Photo Saved.The live photo was successfully saved to Photos.",icon:.Done,style: .Normal)
                                    }
                                } else {
                                    PTGCDManager.gcdMain {
                                        PTAlertTipControl.present(title:"Live Photo Not Saved.The live photo was not saved to Photos.",icon:.Error,style: .Normal)
                                    }
                                }
                            })
                        } else {
                            PTGCDManager.gcdMain {
                                PTAlertTipControl.present(title:"Live Photo Error........",icon:.Error,style: .Normal)
                            }
                        }
                    }
                case String.LivePhotoDisassemble:
                    self.livePhotoMediaSelect(type: .LivePhoto) { result in
                        if result.asset.pt.isLivePhoto() {
                            result.asset.pt.convertPHAssetToPHLivePhoto { livePhoto in
                                if let lPhoto = livePhoto {
                                    livePhotoView.livePhoto = lPhoto
                                    livePhotoView.startPlayback(with: .hint)
                                    
                                    PTLivePhoto.extractResources(from: lPhoto, completion: { resources in
                                        disassembleImageURL = resources?.pairedImage
                                        pickedVideoURL = resources?.pairedVideo
                                        if let keyPhotoPath = disassembleImageURL {
                                            if FileManager.pt.judgeFileOrFolderExists(filePath: keyPhotoPath.path) {
                                                guard let keyPhotoImage = UIImage(contentsOfFile: keyPhotoPath.path) else {
                                                    return
                                                }
                                                showImageView.image = keyPhotoImage
                                            }
                                        }
                                        if let pairedVideoPath = pickedVideoURL?.path  {
                                            if FileManager.pt.judgeFileOrFolderExists(filePath: pairedVideoPath) {
                                                let fileURL = URL(fileURLWithPath: pairedVideoPath)
                                                UIImage.pt.getVideoFirstImage(videoUrl: fileURL.absoluteString) { image in
                                                    videoImageView.image = image
                                                }
                                            }
                                        }
                                    })
                                }
                            }
                        }
                    }
                default: break
                }
            }
            
            view.addSubviews([livePhotoView,showImageView,videoImageView,progressView,createButton])
            livePhotoView.snp.makeConstraints { make in
                make.left.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
                make.top.equalToSuperview().inset(self.sheetViewController?.options.pullBarHeight ?? 0)
                make.height.equalTo(150)
            }
            
            showImageView.snp.makeConstraints { make in
                make.left.equalTo(livePhotoView)
                make.top.equalTo(livePhotoView.snp.bottom).offset(10)
                make.right.equalTo(self.view.snp.centerX).offset(-5)
                make.height.equalTo(livePhotoView)
            }
            
            videoImageView.snp.makeConstraints { make in
                make.left.equalTo(self.view.snp.centerX).offset(5)
                make.top.bottom.equalTo(showImageView)
                make.right.equalTo(livePhotoView)
            }
            
            progressView.snp.makeConstraints { make in
                make.top.equalTo(showImageView.snp.bottom).offset(10)
                make.left.right.equalTo(livePhotoView)
                make.height.equalTo(20)
            }
            
            createButton.snp.makeConstraints { make in
                make.left.right.equalTo(livePhotoView)
                make.height.equalTo(34)
                make.top.equalTo(progressView.snp.bottom).offset(10)
            }
        default:
            break
        }
    }
    
    func livePhotoMediaSelect(type:PTLivePhotoMediaSelectedType,mediaSelectedCallback:@escaping ((PTResultModel)->Void)) {
        let pickerConfig = PTMediaLibConfig.share
        switch type {
        case .Image:
            pickerConfig.allowSelectImage = true
//            pickerConfig.allowOnlySelectRegularImage = true
            pickerConfig.allowSelectVideo = false
        case .Video:
            pickerConfig.allowSelectImage = false
            pickerConfig.allowSelectVideo = true
        case .LivePhoto:
            pickerConfig.allowOnlySelectLivePhoto = true
            pickerConfig.allowSelectImage = false
            pickerConfig.allowSelectVideo = false
        }
        pickerConfig.allowSelectGif = false
        pickerConfig.allowEditVideo = false
        pickerConfig.maxSelectCount = 1
        pickerConfig.maxVideoSelectCount = 1
        pickerConfig.allowTakePhotoInLibrary = false

        let vc = PTMediaLibViewController()
        vc.mediaLibShow()
        vc.selectedHudStatusBlock = { result in
            if result {
                PTAlertTipControl.present(icon:.Heart,style: .Normal)
            } else {
                PTAlertTipControl.present(icon:.Done,style: .Normal)
            }
        }
        vc.selectImageBlock = { result, isOriginal in
            if result.count > 0 {
                PTNSLogConsole("选择了视频\(result)")
                mediaSelectedCallback(result.first!)
            } else {
                PTGCDManager.gcdMain {
                    PTAlertTipControl.present(title:"沒有選擇媒体",icon:.Error,style: .Normal)
                }
            }
        }
    }
}

extension PTFuncDetailViewController {
    func alert(title:String,message:String) {
        UIViewController.gobal_drop(title: title,subTitle: message)
    }
}

extension PTFuncDetailViewController:GCDWebUploaderDelegate {
    func webUploader(_ uploader: GCDWebUploader, didUploadFileAtPath path: String) {
        PTNSLogConsole("[UPLOAD] \(path)")
    }
    
    func webUploader(_ uploader: GCDWebUploader, didMoveItemFromPath fromPath: String, toPath: String) {
        PTNSLogConsole("[MOVE] \(fromPath) -> \(toPath)")
    }
    
    func webUploader(_ uploader: GCDWebUploader, didDeleteItemAtPath path: String) {
        PTNSLogConsole("[DELETE] \(path)")
    }
    
    func webUploader(_ uploader: GCDWebUploader, didCreateDirectoryAtPath path: String) {
        PTNSLogConsole("[CREATE] \(path)")
    }
}

extension PTFuncDetailViewController : PHLivePhotoViewDelegate { }
