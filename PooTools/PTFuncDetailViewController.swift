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
import AnyImageKit
import Photos
import Vision
import VisionKit

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
        self.webServer?.stop()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        switch self.typeString {
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
            self.view.addSubview(codeView)
            codeView.snp.makeConstraints { make in
                make.size.equalTo(150)
                make.centerX.centerY.equalToSuperview()
            }
        case String.slider:
            let slider = PTSlider(showTitle: true, titleIsValue: false)
            self.view.addSubview(slider)
            slider.snp.makeConstraints { make in
                make.width.equalTo(100)
                make.height.equalTo(80)
                make.centerX.centerY.equalToSuperview()
            }
        case String.rate:
            PTGCDManager.gcdAfter(time: 1, block: {
                let rateConfig = PTRateConfig()
                rateConfig.canTap = true
                rateConfig.hadAnimation = true
                rateConfig.scorePercent = 0.2
                rateConfig.allowIncompleteStar = true
                
                let rate = PTRateView(viewConfig: rateConfig)
                rate.rateBlock = { score in
                    PTNSLogConsole(score)
                }
                self.view.addSubview(rate)
                rate.snp.makeConstraints { make in
                    make.left.right.equalToSuperview()
                    make.height.equalTo(100)
                    make.centerY.equalToSuperview()
                }
            })
        case String.segment:
            let model1 = PTSegmentModel()
            model1.titles = "aaaaa"
            model1.imageURL = "DemoImage"
            model1.selectedImageURL = "image_aircondition_gray"
            
            let model2 = PTSegmentModel()
            model2.titles = "2222"
            model2.imageURL = "DemoImage"
            model2.selectedImageURL = "http://img.t.sinajs.cn/t35/style/images/common/face/ext/normal/7a/shenshou_thumb.gif"

            let config = PTSegmentConfig()
            config.showType = .Background
            config.itemSpace = 10
            config.leftEdges = true
            config.originalX = 20
            
            let segView = PTSegmentView(config: config)
            segView.backgroundColor = .random
            segView.viewDatas = [model1,model2]
            segView.reloadViewData { index in
                
            }
            self.view.addSubview(segView)
            segView.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.height.equalTo(44)
                make.centerY.equalToSuperview()
            }
        case String.countLabel:
            let countLabel = PTCountingLabel()
            countLabel.textAlignment = .center
            countLabel.font = .appfont(size: 30)
            countLabel.textColor = .black
            self.view.addSubview(countLabel)
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
            self.view.addSubview(throughLabel)
            throughLabel.snp.makeConstraints { make in
                make.top.equalToSuperview().inset(16)
                make.left.right.equalToSuperview()
                make.height.equalTo(44)
            }
            
            let setBtn = UIButton(type: .custom)
            setBtn.backgroundColor = .random
            self.view.addSubview(setBtn)
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
                var options = PickerOptionsInfo()
                options.selectLimit = 1
                options.selectOptions = .photo
                
                let controller = ImagePickerController(options: options, delegate: self)
                controller.trackDelegate = self
                controller.modalPresentationStyle = .fullScreen
                self.present(controller, animated: true, completion: nil)
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
                label.text = "我是一个推文 #推文1 #我是辣鸡 @crazypoo. 推文发自" +
                " https://192.168.0.1 . 我顺便 支持 自定义 标签 -> 克狗扑\n\n" +
                    "还可以缩短链接长度: \n https://github.com/crazypoo"
                label.numberOfLines = 0
                label.lineSpacing = 4
                
                label.textColor = UIColor(red: 102.0/255, green: 117.0/255, blue: 127.0/255, alpha: 1)
                label.hashtagColor = UIColor(red: 85.0/255, green: 172.0/255, blue: 238.0/255, alpha: 1)
                label.mentionColor = UIColor(red: 238.0/255, green: 85.0/255, blue: 96.0/255, alpha: 1)
                label.URLColor = UIColor(red: 85.0/255, green: 238.0/255, blue: 151.0/255, alpha: 1)
                label.URLSelectedColor = UIColor(red: 82.0/255, green: 190.0/255, blue: 41.0/255, alpha: 1)

                label.handleMentionTap { text in
                    self.alert(title:"Mention", message: text)
                }
                label.handleHashtagTap { text in
                    self.alert(title:"Hashtag", message: text)
                }
                label.handleURLTap { url in
                    self.alert(title:"URL", message: url.absoluteString)
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
        case String.movieCutOutput,String.share:
            let layoutBtn = PTLayoutButton()
            layoutBtn.layoutStyle = .leftImageRightTitle
            layoutBtn.setTitle("123", for: .normal)
            layoutBtn.midSpacing = 0
            layoutBtn.imageSize = CGSizeMake(100, 100)
            layoutBtn.backgroundColor = .systemBlue
            view.addSubview(layoutBtn)
            layoutBtn.snp.makeConstraints { make in
                make.width.height.equalTo(100)
                make.centerX.centerY.equalToSuperview()
            }
            switch self.typeString {
            case String.movieCutOutput:
                PTGCDManager.gcdAfter(time: 1) {
                    layoutBtn.layerProgress(value: 0.5,borderWidth: 4)
                }
            default:
                break
            }
            layoutBtn.addActionHandlers { sender in
                switch self.typeString {
                case String.movieCutOutput:
                    layoutBtn.updateLayerProgress(progress: 0.7)
                default:
                    break
                }
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

extension PTFuncDetailViewController {
    override func floatingPanel(_ fpc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout {
        let layout = PTCustomControlHeightPanelLayout()
        layout.viewHeight = CGFloat.kSCREEN_HEIGHT / 2
        return layout
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

// MARK: - ImagePickerControllerDelegate
extension PTFuncDetailViewController: ImagePickerControllerDelegate {
    
    func imagePicker(_ picker: ImagePickerController, didFinishPicking result: PickerResult) {
        PTNSLogConsole(result.assets.first!.image)
        
        picker.dismiss(animated: true, completion: nil)

        result.assets.first!.phAsset.loadImage { result in
            switch result {
            case .success(let success):
                
                if #available(iOS 14.0, *) {
                    let vision = PTVision.share
                    
                    var visionVersion:Int = VNRecognizeTextRequestRevision2
                    if #available(iOS 16.0, *) {
                        visionVersion = VNRecognizeTextRequestRevision3
                    }
                    
                    vision.findText(withImage: success,revision: visionVersion) { resultText, textObservations in
                        UIViewController.gobal_drop(title: resultText)
                    }
                }
            case .failure(let failure):
                PTNSLogConsole(failure)
            }
        }
    }
}

// MARK: - ImageKitDataTrackDelegate
extension PTFuncDetailViewController: ImageKitDataTrackDelegate {
    
    func dataTrack(page: AnyImagePage, state: AnyImagePageState) {
        switch state {
        case .enter:
            PTNSLogConsole("[Data Track] ENTER Page: \(page.rawValue)")
        case .leave:
            PTNSLogConsole("[Data Track] LEAVE Page: \(page.rawValue)")
        }
    }
    
    func dataTrack(event: AnyImageEvent, userInfo: [AnyImageEventUserInfoKey: Any]) {
        PTNSLogConsole("[Data Track] EVENT: \(event.rawValue), userInfo: \(userInfo)")
    }
}
