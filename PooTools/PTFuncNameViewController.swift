//
//  PTFuncNameViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 1/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift
import DeviceKit
import AnyImageKit
import Photos
import Combine

public extension String {
    static let localNetWork = "局域网传送"
    
    static let imageReview = "图片展示"
    static let videoEditor = "视频编辑"
    static let sign = "签名"
    static let dymanicCode = "动态验证码"
    static let osskit = "语音"
    static let vision = "看图识字"

    static let phoneSimpleInfo = "手机信息"
    static let phoneCall = "打电话"
    static let cleanCache = "清理缓存"
    static let touchID = "TouchID"
    static let rotation = "旋转屏幕"
    static let share = "分享"
    static let checkUpdate = "检测更新"
    static let language = "語言"
    static let darkMode = "DarkMode"

    static let slider = "滑动条"
    static let rate = "评价星星"
    static let segment = "分选栏目"
    static let countLabel = "跳动Label"
    static let throughLabel = "划线Label"
    static let twitterLabel = "推文Label"
    static let movieCutOutput = "类似剪映的视频输出进度效果"
    static let progressBar = "进度条"
    static let alert = "Alert"
    static let feedbackAlert = "反馈弹框"
    static let menu = "Menu"
    static let loading = "Loading"
    static let permission = "Permission"
    static let tipkit = "TipKit"
    static let document = "UIDocument"

    static let route = "路由"
    
    static let encryption = "Encryption"
}

class PTFuncNameViewController: PTBaseViewController {

    lazy var currentSelectedLanguage : String = {
        let string = LanguageKey(rawValue: PTLanguage.share.language)!.desc
        return string
    }()

    enum LanguageKey : String {
        case ChineseHans = "zh-Hans"
        case ChineseHK = "zh-HK"
        case English = "en"
        case Spanish = "es"
        
        static var allValues : [LanguageKey] {
            return [.ChineseHans, .ChineseHK, .English,.Spanish]
        }
        
        var desc:String {
            switch self {
            case .ChineseHans:
                return "中文(简体)"
            case .ChineseHK:
                return "中文(繁体)"
            case .English:
                return "English"
            case .Spanish:
                return "Español"
            }
        }
        
        static var allNames : [String] {
            var values = [String]()
            self.allValues.enumerated().forEach { index,value in
                values.append(value.desc)
            }
            return values
        }
    }

    fileprivate var vcEmpty:Bool = true
    
    fileprivate lazy var outputURL :URL = {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let outputURL = documentsDirectory.appendingPathComponent("output.mp4")
        return outputURL
    }()

    private var videoEdit: PTVideoEdit?
    fileprivate var cancellables = Set<AnyCancellable>()

    func rowBaseModel(name:String) -> PTFusionCellModel {
        let models = PTFusionCellModel()
        models.name = name
        models.haveLine = true
        models.accessoryType = .DisclosureIndicator
        models.disclosureIndicatorImage = "▶️".emojiToImage(emojiFont: .appfont(size: 12))
        return models
    }
    
    lazy var cSections : [PTSection] = {
        let disclosureIndicatorImage = "▶️".emojiToImage(emojiFont: .appfont(size: 12))
        let sectionTitleFont:UIFont = .appfont(size: 18,bold: true)
        /**
            网络
         */
        let localNet = self.rowBaseModel(name: .localNetWork)
        localNet.leftImage = "🌐".emojiToImage(emojiFont: .appfont(size: 24))
        localNet.contentIcon = "🌠".emojiToImage(emojiFont: .appfont(size: 24))
        localNet.content = "12312312312312312312312312312312312312312312321"
        localNet.cellClass = PTFusionCell.self
        localNet.cellID = PTFusionCell.ID
        let netArrs = [localNet]
                
        let sectionModel_net = PTFusionCellModel()
        sectionModel_net.name = "网络"
        sectionModel_net.cellFont = sectionTitleFont
        sectionModel_net.accessoryType = .More
        sectionModel_net.disclosureIndicatorImage = disclosureIndicatorImage
        sectionModel_net.moreLayoutStyle = .leftTitleRightImage
        sectionModel_net.moreDisclosureIndicator = "http://img.t.sinajs.cn/t35/style/images/common/face/ext/normal/7a/shenshou_thumb.gif"

        let netSection = PTSection.init(headerTitle: sectionModel_net.name,headerCls: PTFusionHeader.self,headerID: PTFusionHeader.ID,footerCls: PTTestFooter.self,footerID: PTTestFooter.ID,footerHeight: 44,headerHeight: 44, rows: UICollectionView.sectionRows(rowsModel: netArrs),headerDataModel: sectionModel_net)
        
        /**
            图片
         */
        let imageReview = self.rowBaseModel(name: .imageReview)
        
        let videoEditor = self.rowBaseModel(name: .videoEditor)

        let sign = self.rowBaseModel(name: .sign)

        let dymanicCode = self.rowBaseModel(name: .dymanicCode)

        let oss = self.rowBaseModel(name: .osskit)

        let vision = self.rowBaseModel(name: .vision)
        
        let mediaArrs = [imageReview,videoEditor,sign,dymanicCode,oss,vision]
        
        var mediaRows = [PTRows]()
        mediaArrs.enumerated().forEach { index,value in
            let row = PTRows(title:value.name,cls:PTFusionCell.self,ID: PTFusionCell.ID,dataModel: value)
            mediaRows.append(row)
        }
        
        let sectionModel_media = PTFusionCellModel()
        sectionModel_media.name = "多媒体"
        sectionModel_media.cellFont = sectionTitleFont
        sectionModel_media.accessoryType = .Switch

        let mediaSection = PTSection.init(headerTitle: sectionModel_media.name,headerCls: PTFusionHeader.self,headerID: PTFusionHeader.ID,footerCls: PTTestFooter.self,footerID: PTTestFooter.ID,footerHeight: 44,headerHeight: 44, rows: mediaRows,headerDataModel: sectionModel_media)

        /**
            本机
         */
        let jailBroken = PTFusionCellModel()
        jailBroken.name = .phoneSimpleInfo
        jailBroken.cellDescFont = .appfont(size: 12)
        jailBroken.desc = "是否X类型:\(UIDevice.pt.oneOfXDevice() ? "是" : "否"),是否越狱了:\(UIDevice.pt.isJailBroken ? "是" : "否"),机型:\(Device.identifier),运营商:\(String(describing: UIDevice.pt.carrierNames()?.first))"
        jailBroken.accessoryType = .NoneAccessoryView
        
        let callPhone = self.rowBaseModel(name: .phoneCall)
        callPhone.cellDescFont = .appfont(size: 12)
        callPhone.desc = "打电话到13800138000"

        let cleanCaches = self.rowBaseModel(name: .cleanCache)
        cleanCaches.cellDescFont = .appfont(size: 12)
        cleanCaches.desc = "缓存:\(String(format: "%@", PCleanCache.getCacheSize()))"

        let touchID = self.rowBaseModel(name: .touchID)

        let rotation = self.rowBaseModel(name: .rotation)

        let share = self.rowBaseModel(name: .share)

        let checkUpdate = self.rowBaseModel(name: .checkUpdate)
        
        let language = self.rowBaseModel(name: .language)
        
        let darkMode = self.rowBaseModel(name: .darkMode)
        
        let phoneArrs = [jailBroken,callPhone,cleanCaches,touchID,rotation,share,checkUpdate,language,darkMode]
        
        var phoneRows = [PTRows]()
        phoneArrs.enumerated().forEach { index,value in
            let row = PTRows(title:value.name,cls:PTFusionCell.self,ID: PTFusionCell.ID,dataModel: value)
            phoneRows.append(row)
        }
        
        let sectionModel_phone = PTFusionCellModel()
        sectionModel_phone.name = "本机"
        sectionModel_phone.cellFont = sectionTitleFont
        sectionModel_phone.accessoryType = .More
        sectionModel_phone.disclosureIndicatorImage = disclosureIndicatorImage
        sectionModel_phone.moreLayoutStyle = .leftTitleRightImage

        let phoneSection = PTSection.init(headerTitle: sectionModel_phone.name,headerCls: PTFusionHeader.self,headerID: PTFusionHeader.ID,footerCls: PTTestFooter.self,footerID: PTTestFooter.ID,footerHeight: 44,headerHeight: 44, rows: phoneRows,headerDataModel: sectionModel_phone)
        
        /**
            UIKIT
         */
        let slider = self.rowBaseModel(name: .slider)
        
        let rate = self.rowBaseModel(name: .rate)

        let segment = self.rowBaseModel(name: .segment)

        let countLabel = self.rowBaseModel(name: .countLabel)
        
        let throughLabel = self.rowBaseModel(name: .throughLabel)
        
        let twitterLabel = self.rowBaseModel(name: .twitterLabel)
        
        let movieCutOutput = self.rowBaseModel(name: .movieCutOutput)
        
        let progressBar = self.rowBaseModel(name: .progressBar)
        
        let asTips = self.rowBaseModel(name: .alert)
        
        let menu = self.rowBaseModel(name: .menu)
        
        let loading = self.rowBaseModel(name: .loading)

        let permission = self.rowBaseModel(name: .permission)
        
        let tipkit = self.rowBaseModel(name: .tipkit)
        
        let document = self.rowBaseModel(name: .document)
        
        let uikitArrs = [slider,rate,segment,countLabel,throughLabel,twitterLabel,movieCutOutput,progressBar,asTips,menu,loading,permission,tipkit,document]
        
        var uikitRows = [PTRows]()
        uikitArrs.enumerated().forEach { index,value in
            let row = PTRows(title:value.name,cls:PTFusionCell.self,ID: PTFusionCell.ID,dataModel: value)
            uikitRows.append(row)
        }
        
        let sectionModel_uikit = PTFusionCellModel()
        sectionModel_uikit.name = "UIKIT"
        sectionModel_uikit.cellFont = sectionTitleFont
        sectionModel_uikit.accessoryType = .More
        sectionModel_uikit.disclosureIndicatorImage = disclosureIndicatorImage
        sectionModel_uikit.moreLayoutStyle = .upTitleDownImage

        let uikitSection = PTSection.init(headerTitle: sectionModel_uikit.name,headerCls: PTFusionHeader.self,headerID: PTFusionHeader.ID,footerCls: PTTestFooter.self,footerID: PTTestFooter.ID,footerHeight: 44,headerHeight: 44, rows: uikitRows,headerDataModel: sectionModel_uikit)
        
        /**
            Route
         */
        let route = self.rowBaseModel(name: .route)

        let routeArrs = [route]
        
        var routeRows = [PTRows]()
        routeArrs.enumerated().forEach { index,value in
            let row = PTRows(title:value.name,cls:PTFusionCell.self,ID: PTFusionCell.ID,dataModel: value)
            routeRows.append(row)
        }
        
        let sectionModel_route = PTFusionCellModel()
        sectionModel_route.name = "Route"
        sectionModel_route.cellFont = sectionTitleFont
        sectionModel_route.accessoryType = .NoneAccessoryView

        let routeSection = PTSection.init(headerTitle: sectionModel_route.name,headerCls: PTFusionHeader.self,headerID: PTFusionHeader.ID,footerCls: PTTestFooter.self,footerID: PTTestFooter.ID,footerHeight: 44,headerHeight: 44, rows: routeRows,headerDataModel: sectionModel_route)
        
        /**
            Encryption
         */
        let encryption = self.rowBaseModel(name: .encryption)

        let encryptionArrs = [encryption]
        
        var encryptionRows = [PTRows]()
        encryptionArrs.enumerated().forEach { index,value in
            let row = PTRows(title:value.name,cls:PTFusionCell.self,ID: PTFusionCell.ID,dataModel: value)
            encryptionRows.append(row)
        }
        
        let sectionModel_encryption = PTFusionCellModel()
        sectionModel_encryption.name = "Encryption"
        sectionModel_encryption.cellFont = sectionTitleFont
        sectionModel_encryption.accessoryType = .NoneAccessoryView

        let encryptionSection = PTSection.init(headerTitle: sectionModel_encryption.name,headerCls: PTFusionHeader.self,headerID: PTFusionHeader.ID,footerCls: PTVersionFooter.self,footerID: PTVersionFooter.ID,footerHeight: 88,headerHeight: 44, rows: encryptionRows,headerDataModel: sectionModel_route)

        return [netSection,mediaSection,phoneSection,uikitSection,routeSection,encryptionSection]
    }()
    
    lazy var collectionView : PTCollectionView = {
        let cConfig = PTCollectionViewConfig()
        cConfig.viewType = .Normal
        cConfig.itemHeight = PTAppBaseConfig.share.baseCellHeight
        cConfig.topRefresh = true
        cConfig.showEmptyAlert = !vcEmpty
        let aaaaaaa = PTCollectionView(viewConfig: cConfig)
                
        aaaaaaa.headerInCollection = { kind,collectionView,model,index in
            let sectionModel = (model.headerDataModel as! PTFusionCellModel)
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: model.headerID!, for: index) as! PTFusionHeader
            header.sectionModel = sectionModel
            if sectionModel.name == "网络" {
                header.moreActionBlock = { text,sender in
                    PTNSLogConsole("点击了More")
                }
            } else if sectionModel.name == "多媒体" {
                header.switchValue = true
                header.switchValueChangeBlock = { text,sender in
                    PTNSLogConsole("点击了Switch")
                }
            }
            return header
        }
        aaaaaaa.footerInCollection = { kind,collectionView,model,index in
            if model.footerID == PTVersionFooter.ID {
                let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: model.footerID!, for: index) as! PTVersionFooter
                return footer
            } else {
                let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: model.footerID!, for: index) as! PTTestFooter
                return footer
            }
        }
        aaaaaaa.cellInCollection = { collectionView ,dataModel,indexPath in
            let itemRow = dataModel.rows[indexPath.row]
            let cellModel = (itemRow.dataModel as! PTFusionCellModel)
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as! PTFusionCell
            cell.cellModel = cellModel
            cell.contentView.backgroundColor = PTAppBaseConfig.share.baseCellBackgroundColor
            
            if dataModel.rows.count == 1 {
                cell.hideTopLine = true
            } else {
                cell.hideTopLine = indexPath.row == 0 ? true : false
            }
            cell.hideBottomLine = (dataModel.rows.count - 1) == indexPath.row ? true : false
            return cell
        }
        aaaaaaa.collectionDidSelect = { collectionViews,sModel,indexPath in
            let itemRow = sModel.rows[indexPath.row]
            let cellModel = (itemRow.dataModel as! PTFusionCellModel)
            if itemRow.title == .imageReview {
                let model1 = PTMediaBrowserModel()
                model1.imageURL = "http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg"
                model1.imageInfo = "56555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555551312333444444"
                
                let model2 = PTMediaBrowserModel()
                model2.imageURL = "http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg"
                model2.imageInfo = "123"

                let model3 = PTMediaBrowserModel()
                model3.imageURL = "http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4"
                model3.imageInfo = "MP4"

                let model4 = PTMediaBrowserModel()
                model4.imageURL = "http://img.t.sinajs.cn/t35/style/images/common/face/ext/normal/7a/shenshou_thumb.gif"
                model4.imageInfo = "GIF"

                let mediaConfig = PTMediaBrowserConfig()
                mediaConfig.actionType = .All
                mediaConfig.mediaData = [model1,model2,model3,model4]
                
                let browser = PTMediaBrowserController()
                browser.viewConfig = mediaConfig
                browser.modalPresentationStyle = .fullScreen
                self.pt_present(browser)
            } else if itemRow.title == .phoneCall {
                PTPhoneBlock.callPhoneNumber(phoneNumber: "13800138000", call: { duration in
                }, cancel: {
                    
                }, canCall: { finish in
                    
                })
            } else if itemRow.title == .cleanCache {
                if PCleanCache.clearCaches() {
                    UIAlertController.gobal_drop(title: "清理成功")
                    self.showCollectionViewData()
                } else {
                    UIAlertController.gobal_drop(title: "暂时没有缓存了")
                }
            } else if itemRow.title == .touchID {
                let touchID = PTBiologyID.shared
                touchID.biologyStatusBlock = { type in
                    PTNSLogConsole("\(type)")
                }
                touchID.biologyVerifyStatusBlock = { type in
                    PTNSLogConsole("\(type)")
                }
                touchID.biologyStart(alertTitle: "Test")
            } else if itemRow.title == .videoEditor {
                var options = PickerOptionsInfo()
                options.selectLimit = 1
                options.selectOptions = .video
                
                let controller = ImagePickerController(options: options, delegate: self)
                controller.trackDelegate = self
                controller.modalPresentationStyle = .fullScreen
                self.pt_present(controller, animated: true, completion: nil)
            } else if itemRow.title == .sign {
                let signConfig = PTSignatureConfig()
                
                let sign = PTSignView(viewConfig: signConfig)
                sign.showView()
                sign.doneBlock = { image in
                    let newImage = UIImageView(image: image)
                    self.view.addSubview(newImage)
                    newImage.snp.makeConstraints { make in
                        make.left.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
                        make.top.equalTo(self.collectionView)
                        make.height.equalTo(150)
                    }
                    
                    PTGCDManager.gcdAfter(time: 5) {
                        newImage.removeFromSuperview()
                    }
                }
                sign.dismissBlock = {
                    
                }
            } else if itemRow.title == .rotation {
                let r:Int = Int(arc4random_uniform(6))
                PTRotationManager.share.setOrientation(orientation: UIDeviceOrientation.init(rawValue: r)!)
            } else if itemRow.title == .osskit {
                let vc = PTSpeechViewController()
                self.navigationController?.pushViewController(vc)
            } else if itemRow.title == .share {
                guard let url = URL(string: shareURLString) else {
                    return
                }

                let share = PTShareCustomActivity()
                share.text = shareText
                share.url = url
                share.image = UIImage(named: "DemoImage")
                share.customActivityTitle = "测试Title"
                share.customActivityImage = "🖼️".emojiToImage(emojiFont: .appfont(size: 54))

                let items: [Any] = [shareText, url, UIImage(named: "DemoImage")!]

                let vc = PTActivityViewController(activityItems: items,applicationActivities: [share])
                vc.previewNumberOfLines = 10
                vc.presentActionSheet(self, from: collectionViews.cellForItem(at: indexPath)!)

            } else if itemRow.title == .checkUpdate {
                PTCheckUpdateFunction.share.checkTheVersionWithappid(appid: "6446323709", test: false, url: URL(string: shareURLString), version: "1.0.0", note: "123", force: false,alertType: .User)
            } else if itemRow.title == .route {
                UIAlertController.baseActionSheet(title: "Route", titles: ["普通","帶數據","Handler"], otherBlock: { sheet,index,title in
                    switch index {
                    case 0:
                        PTRouter.routeJump(vcName: NSStringFromClass(PTRouteViewController.self), scheme: PTRouteViewController.patternString.first!)
                    case 1:
                        PTRouter.addRouterItem(RouteItem(path: PTRouteViewController.patternString.first!, className: NSStringFromClass(PTRouteViewController.self)))
                        let model = PTRouterExampleModel()
                        PTRouter.openURL(("scheme://route/route",["model":model]))
                    case 2:
                        PTRouter.addRouterItem(RouteItem(path: PTRouteViewController.patternString.first!, className: NSStringFromClass(PTRouteViewController.self)))
                        
                        let handler = { (value:String) in
                            UIViewController.gobal_drop(title: value)
                        }
                        
                        PTRouter.openURL(("scheme://route/route",["task":handler]))
                    default:
                        break
                    }
                })
            } else if itemRow.title == .alert {
                UIAlertController.baseActionSheet(title: "AlertTips", titles: ["low","hight",String.feedbackAlert,"ActionSheet"], otherBlock: { sheet,index,title in
                    switch index {
                    case 0:
                        PTAlertTipControl.present(title:"Job Done!",subtitle: "WOW",icon:.Done,style: .Normal)
                    case 1:
                        PTAlertTipControl.present(title:"Hola!",subtitle: "Que?",icon:.Error,style: .SupportVisionOS)
                    case 2:
                        UIAlertController.alertSendFeedBack { title, content in
                            UIAlertController.gobal_drop(title: title,subTitle: content) {
                                UIAlertController.base_textfield_alertVC(okBtn: "PT Button comfirm".localized(), cancelBtn: "PT Button cancel".localized(), placeHolders: ["placeholder"], textFieldTexts: ["Test"], keyboardType: [.default], textFieldDelegate: self) { result in
                                    
                                }
                            } notifiDismiss: {
                                UIAlertController.alertVC(title: "notifi消失之后", msg: "哦", cancel: "PT Button cancel".localized(), cancelBlock: {
                                    
                                })
                            }
                        }
                    case 3:
                        UIAlertController.baseActionSheet(title: "Title",subTitle: "SubTitle",cancelButtonName: "Cancel",destructiveButtons: ["Destructive"], titles: ["1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1"], destructiveBlock: { sheet, index, title in
                            
                        },otherBlock: { sheet,index,title in
                        })
                    default:
                        break
                    }
                })

            } else if itemRow.title == .loading {
                UIAlertController.baseActionSheet(title: "Loading", titles: ["LoadingHub","CycleLoading"], otherBlock: { sheet,index,title in
                    switch index {
                    case 0:
                        let hud = PTHudView()
                        hud.hudShow()
                        PTGCDManager.gcdAfter(time: 5) {
                            hud.hide {
                                
                            }
                        }
                    case 1:
                        let cycle = PTCycleLoadingView()
                        self.view.addSubviews([cycle])
                        cycle.snp.makeConstraints { make in
                            make.size.equalTo(100)
                            make.centerX.centerY.equalToSuperview()
                        }
                        cycle.startAnimation()
                        PTGCDManager.gcdAfter(time: 5) {
                            cycle.stopAnimation() {
                                cycle.removeFromSuperview()
                            }
                        }
                    default:
                        break
                    }
                })
            } else if itemRow.title == .permission {
                let locationAlways = PTPermissionModel()
                locationAlways.type = .location(access: .always)
                locationAlways.desc = "我们有需要长时间使用你的定位信息,来在网络测速的时候在地图上大概显示你IP所属位置"
                
                let locationWhen = PTPermissionModel()
                locationWhen.type = .location(access: .whenInUse)
                locationWhen.desc = "我们有需要的时候使用你的定位信息,来在网络测速的时候在地图上大概显示你IP所属位置"

                let camera = PTPermissionModel()
                camera.type = .camera
                camera.desc = "我们需要使用你的照相机,来实现拍照后图片编辑功能"

                let mic = PTPermissionModel()
                mic.type = .microphone
                mic.desc = "我们需要访问你的麦克风,来实现视频拍摄和编辑功能"

                let photo = PTPermissionModel()
                photo.type = .photoLibrary
                photo.desc = "我们需要访问你的相册和照片,来使用图片的编辑功能"

                let permissionVC = PTPermissionViewController(datas: [locationAlways,locationWhen,camera,mic,photo])
                permissionVC.modalPresentationStyle = .fullScreen
                self.pt_present(permissionVC, animated: true)
                permissionVC.viewDismissBlock = {
                }

            } else if itemRow.title == .language {
                UIAlertController.baseActionSheet(title: .language,subTitle: self.currentSelectedLanguage, titles: LanguageKey.allNames, otherBlock: { sheet,index,title in
                    self.currentSelectedLanguage = LanguageKey.allValues[index].desc
                    PTLanguage.share.language = LanguageKey.allValues[index].rawValue
                })                
            } else if itemRow.title == .darkMode {
                let vc = PTDarkModeControl()
                self.navigationController?.pushViewController(vc)
            } else if itemRow.title == .tipkit {
                if #available(iOS 17.0, *) {
                    let vc = PTTipsDemoController()
                    self.navigationController?.pushViewController(vc)
                }
            } else if itemRow.title == .document {
                if #available(iOS 17.0, *) {
                    let vc = PTDocumentViewController()
                    self.navigationController?.pushViewController(vc)
                }
            } else {
                let vc = PTFuncDetailViewController(typeString: itemRow.title)
                PTFloatingPanelFuction.floatPanel_VC(vc: vc,panGesDelegate: self,currentViewController: self)
            }
        }
        aaaaaaa.headerRefreshTask = { sender in
            if #available(iOS 17, *) {
                self.collectionView.clearAllData { collectionview in
                    sender.endRefreshing()
                }
            } else {
                sender.endRefreshing()
            }
        }
        
        aaaaaaa.emptyTap = { sender in
            if #available(iOS 17, *) {
                self.collectionView.showEmptyLoading()
                PTGCDManager.gcdAfter(time: 1, block: {
                    self.collectionView.hideEmptyLoading(task: {
                        self.showCollectionViewData()
                    })
                })
            }
        }
        return aaaaaaa
    }()
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .all
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        .portrait
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
                
        self.registerScreenShotService()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.flashAd(notifi:)), name: NSNotification.Name.init(PLaunchAdDetailDisplayNotification), object: nil)
        
        let more = UIButton(type: .custom)
        more.setTitleColor(.random, for: .normal)
        more.setTitle("More", for: .normal)
        more.bounds = CGRect(x: 0, y: 0, width: 34, height: 34)
#if POOTOOLS_NAVBARCONTROLLER
        self.zx_navBar?.addSubviews([more])
        more.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            more.size.equalTo(more.bounds.size)
            make.bottom.equalToSuperview().inset(5)
        }
#else
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: more)
#endif
        let popoverContent = PTBaseViewController(hideBaseNavBar: true)
        
        let popoverButton = UIButton(type: .custom)
        popoverButton.backgroundColor = .random
        
        popoverContent.view.addSubview(popoverButton)
        popoverButton.snp.makeConstraints { make in
            make.size.equalTo(50)
            make.centerY.centerX.equalToSuperview()
        }
        popoverButton.addActionHandlers { sender in
            popoverContent.dismiss(animated: true) {
                let infoVc = PTSwiftViewController()
                PTUtils.pt_pushViewController(infoVc)
            }
        }
        
        more.addActionHandlers { sender in
            self.popover(popoverVC: popoverContent, popoverSize: CGSize(width: 100, height: 300), sender: sender, arrowDirections: .any)
        }
        
        self.view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
#if POOTOOLS_NAVBARCONTROLLER
            make.top.equalToSuperview().inset(CGFloat.kNavBarHeight_Total)
#else
            make.top.equalToSuperview()
#endif
            make.left.right.bottom.equalToSuperview()
        }
        
        if #unavailable(iOS 17.0) {
            self.showCollectionViewData()
        } else {
            if vcEmpty {
                self.emptyDataViewConfig = PTEmptyDataViewConfig()
                self.showEmptyView {
                    self.emptyReload()
                }
                
                PTGCDManager.gcdAfter(time: 5) {
                    self.emptyReload()
                }
            }
        }
        
        self.inputValueSample(value: 15)
        
        
        @PTLockAtomic
        var json:[String:String]?
        json = ["A":"1"]
        PTNSLogConsole(">>>>>>>>>>>>>>>>>\(String(describing: json))")        
    }
    
    func flashAd(notifi:Notification) {
        let obj = notifi.object as! [String:Any]
        obj.allKeys().enumerated().forEach { index,value in
            let keyValue = obj[value]
            if keyValue is String {
                if (keyValue as! String).isURL() {
                    PTAppStoreFunction.jumpLink(url: URL(string: (keyValue as! String))!)
                }
            }
        }
    }
    
    @available(iOS 17, *)
    func emptyReload() {
        self.emptyViewLoading()
        PTGCDManager.gcdAfter(time: 2) {
            self.hideEmptyView {
                self.showCollectionViewData()
            }
        }
    }
    
    func showCollectionViewData() {
        collectionView.showCollectionDetail(collectionData: cSections)
    }
    
    func inputValueSample(@PTClampedProperyWrapper(range:1...10) value:Int = 1) {
        PTNSLogConsole(">>>>>>>>>>>>>>>>>>>>>>>>>\(value)")
    }
}

// MARK: - ImagePickerControllerDelegate
extension PTFuncNameViewController: ImagePickerControllerDelegate {
    
    // 获取PHAsset并转换为AVAsset的方法
    func convertPHAssetToAVAsset(phAsset: PHAsset, completion: @escaping (AVAsset?) -> Void) {
        let options = PHVideoRequestOptions()
        options.version = .original

        PHImageManager.default().requestAVAsset(forVideo: phAsset, options: options) { avAsset, _, _ in
            completion(avAsset)
        }
    }
        
    func saveVideoToCache(playerItem: AVPlayerItem,result:((_ finish:Bool)->Void)? = nil) {
        let videoAsset = playerItem.asset
        let exportSession = AVAssetExportSession(asset: videoAsset, presetName: AVAssetExportPresetHighestQuality)
        exportSession?.outputFileType = .mp4

        guard let exportSession = exportSession else {
            PTNSLogConsole("无法创建AVAssetExportSession")
            return
        }

        exportSession.outputURL = outputURL
        
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                PTNSLogConsole("视频保存到本地成功")
                if result != nil {
                    result!(true)
                }
            case .failed:
                PTNSLogConsole("视频导出失败：\(exportSession.error?.localizedDescription ?? "")")
                if result != nil {
                    result!(false)
                }
            default:
                break
            }
        }
    }
    
    func saveVideoToAlbum(result:((_ finish:Bool)->Void)? = nil) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: self.outputURL)
        }) { success, error in
            if success {
                PTNSLogConsole("视频保存成功")
                if result != nil {
                    result!(true)
                }
            } else {
                PTNSLogConsole("视频保存失败：\(error?.localizedDescription ?? "")")
                if result != nil {
                    result!(false)
                }
            }
        }
    }

    func imagePicker(_ picker: ImagePickerController, didFinishPicking result: PickerResult) {
        PTNSLogConsole(result.assets.first!.image)
        
        picker.dismiss(animated: true, completion: nil)

        convertPHAssetToAVAsset(phAsset: result.assets.first!.phAsset) { avAsset in
            if let avAsset = avAsset {
                PTGCDManager.gcdMain {
                    let controller = PTVideoEditorVideoEditorViewController(asset: avAsset, videoEdit: self.videoEdit)
                    controller.onEditCompleted
                        .sink {  editedPlayerItem, videoEdit in
                            self.videoEdit = videoEdit
                            
                            self.saveVideoToCache(playerItem: editedPlayerItem) { finish in
                                if finish {
                                    UIImage.pt.getVideoFirstImage(videoUrl: self.outputURL.description) { images in
                                        PTNSLogConsole(images as Any)
                                    }
                                }
                            }
                        }
                        .store(in: &self.cancellables)
                    controller.modalPresentationStyle = .fullScreen
                    let nav = PTBaseNavControl(rootViewController: controller)
                    self.navigationController?.present(nav, animated: true)
                }
            } else {
                UIViewController.gobal_drop(title: "获取失败,请重试")
            }
        }
    }
}

// MARK: - ImageKitDataTrackDelegate
extension PTFuncNameViewController: ImageKitDataTrackDelegate {
    
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

extension PTFuncNameViewController:UITextFieldDelegate {}
