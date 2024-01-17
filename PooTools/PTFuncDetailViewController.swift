//
//  PTFuncDetailViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 1/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import FloatingPanel
import GCDWebServer
import Alamofire
import SnapKit
import Photos
import Vision
import VisionKit
import SwifterSwift
import CommonCrypto

let PTUploadFilePath = FileManager.pt.LibraryDirectory() + "/UploadFile"

class PTFuncDetailViewController: PTBaseViewController {

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
        
        XMNetWorkStatus.shared.obtainDataFromLocalWhenNetworkUnconnected { status in
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
                let pickerConfig = PTMediaLibConfig.share
                pickerConfig.allowSelectImage = true
                pickerConfig.allowSelectVideo = false
                pickerConfig.allowSelectGif = false
                pickerConfig.maxVideoSelectCount = 1
                pickerConfig.maxSelectCount = 1
                let vc = PTMediaLibViewController()
                vc.mediaLibShow()
                vc.selectImageBlock = { result, isOriginal in
                    if #available(iOS 14.0, *) {
                        let vision = PTVision.share
                        
                        var visionVersion:Int = VNRecognizeTextRequestRevision2
                        if #available(iOS 16.0, *) {
                            visionVersion = VNRecognizeTextRequestRevision3
                        }
                        
                        vision.findText(withImage: result.first!.image,revision: visionVersion) { resultText, textObservations in
                            UIViewController.gobal_drop(title: resultText)
                        }
                    }
                }
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
                label.text = "13800138000我啊啊啊啊啊啊啊是的" + "\n" + "#推文1 18665710271"
//                label.text = "我是一个推文 #推文1 #我是辣鸡 @crazypoo. 推文发自" +
//                " https://192.168.0.1 . $13800138000 我顺便 支持 自定义 标签 -> 克狗扑\n\n" +
//                    "还可以缩短链接长度: \n https://github.com/crazypoo"
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
        default:
            break
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
