// English: Centralized selection handling for the Example Demo Catalog.
// Español: Gestión centralizada de la selección del catálogo de Demos del Example.
// 中文：集中处理 Example Demo Catalog 的选择行为。

import UIKit
import SnapKit
import Photos
import Combine
#if canImport(PToolsUIFoundation)
import PToolsUIFoundation
#endif
import PooTools

@MainActor
enum PTDemoSelectionCoordinator {
    // English: Keep the catalog controller focused on display and forward behavior by stable Demo ID.
    // Español: Mantén el controlador centrado en la presentación y delega por el ID estable del Demo.
    // 中文：让目录控制器只负责展示，并通过稳定 Demo ID 转发行为。
    static func select(section: PTSection, indexPath: IndexPath, from controller: PTFuncNameViewController) {
        let sModel = section
        if let itemRow = sModel.rows?[indexPath.row], let descriptor = PTDemoRegistry.descriptor(forRawID: itemRow.diffId) {
            if descriptor.id.rawValue == "media.image-review" {
                PTGCDManager.shared.runOnMain {
                    let model1 = PTMediaBrowserModel()
                    model1.imageURL = "https://i-blog.csdnimg.cn/blog_migrate/becd8bdd2845791b0f9b28ba58a27bac.jpeg"
                    model1.imageInfo = "56555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555551312333444444"
                    
                    let model2 = PTMediaBrowserModel()
                    model2.imageURL = "http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg"
                    model2.imageInfo = "123"

                    let model3 = PTMediaBrowserModel()
                    model3.imageURL = "https://imgservice.appsmartnet.com/bab1688/after/1770799498649A9178A4122E547D39B72A55A6950BE84_mmexport1749953776009 2.mp4"
                    model3.imageInfo = "MP4"

                    let model4 = PTMediaBrowserModel()
                    model4.imageURL = "http://img.t.sinajs.cn/t35/style/images/common/face/ext/normal/7a/shenshou_thumb.gif"
                    model4.imageInfo = "GIF"
                    
                    let mediaConfig = PTMediaBrowserConfig.share
                    mediaConfig.dismissY = 200
                    mediaConfig.actionType = .All
                    mediaConfig.pageControlOption = .snake
                    mediaConfig.imageLongTapAction = true
                    mediaConfig.dynamicBackground = true
                    mediaConfig.pageControlShow = true
                    let browser = PTMediaBrowserController(mediaData: [model3,model1,model2,model4])
                    browser.mediasShow()
                }
            } else if descriptor.id.rawValue == "device.phone-call" {
                PTGCDManager.shared.runOnMain {
                    PTPhoneBlock.callPhoneNumber(phoneNumber: "13800138000", call: { duration in
                    }, cancel: {
                        
                    }, canCall: { finish in
                        
                    })
                }
            } else if descriptor.id.rawValue == "storage.clear-cache" {
                PTGCDManager.shared.runOnBackground(priority: .background) {
                    Task { @MainActor in
                        let isCleared = await PCleanCache.clearCaches()
                        if isCleared {
                                UIAlertController.drop(title: "清理成功")
                            controller.showCollectionViewData()
                        } else {
                                UIAlertController.drop(title: "暂时没有缓存了")
                        }
                    }
                }
            } else if descriptor.id.rawValue == "security.biometrics" {
                
                Task { @MainActor in
                    let biometricsManager = PTBiometricsManager.shared
                        
                    // 1. 获取设备支持状态 (对应以前的 biologyStatusBlock)
                    // 现在变成了一个同步属性，直接读取即可，不用等回调！
                    let supportType = biometricsManager.currentBiometryStatus
                    PTNSLogConsole("设备支持的生物识别类型: \(supportType)")
                    // 2. 发起验证并等待结果 (对应以前的 biologyStart + biologyVerifyStatusBlock)
                    // 使用 Task 包装异步任务
                    PTNSLogConsole("开始验证...")
                    
                    // 使用 await 等待验证结果，代码会在这里暂停，直到用户验证完成才往下走
                    let verifyStatus = await biometricsManager.startAuthentication(alertTitle: "Test")
                    
                    // 拿到结果后直接处理
                    PTNSLogConsole("验证结果: \(verifyStatus)")
                    
                    // 你可以根据具体状态进行业务处理，例如：
                    if verifyStatus == .success {
                        PTNSLogConsole("✅ 验证成功，可以进入下一步了！")
                    } else if verifyStatus == .domainStateChanged {
                        PTNSLogConsole("⚠️ 警告：检测到用户录入了新的指纹/面容，需要重新登录！")
                    } else {
                        PTNSLogConsole("❌ 验证失败或取消")
                    }
                }
            } else if descriptor.id.rawValue == "media.video-editor" {
                PTGCDManager.shared.runOnMain {
                    let pickerConfig = PTMediaLibConfig.share
                    pickerConfig.allowSelectImage = false
                    pickerConfig.allowSelectVideo = true
                    pickerConfig.allowSelectGif = false
                    pickerConfig.allowEditVideo = false
                    pickerConfig.maxSelectCount = 1
                    pickerConfig.maxVideoSelectCount = 1
                    pickerConfig.useCustomCamera = false
                    
                    let vc = PTMediaLibViewController()
                    vc.mediaLibShow()
                    vc.selectedHudStatusBlock = { result in
                        Task { @MainActor in
                            if result {
                                PTAlertTipsViewController.tipsAlertShow(icon: .Heart)
                            } else {
                                PTAlertTipsViewController.tipsAlertShow(icon: .Done)
                            }
                        }
                    }
                    vc.selectImageBlock = { result, isOriginal in
                        PTNSLogConsole("視頻選擇後:>>>>>>>>>>>>>\(result)")
                        if let resultFirst = result.first {
                            resultFirst.asset.convertPHAssetToAVAsset { progress in
                                PTNSLogConsole("progress:>>>>>>>>>>>>>\(progress)")

                            } completion: { avAsset in
                                if let getAv = avAsset {
                                    Task { @MainActor in
                                        let controller = PTVideoEditorToolsViewController(asset: resultFirst.asset,avAsset: getAv.asset)
                                        controller.videoEditorShow(vc: controller)
                                        controller.onEditCompleteHandler = { url in
                                            PTAlertTipsViewController.tipsAlertShow(title:"我好了\(url)",icon: .Done)
                                        }
                                    }
                                } else {
                                    Task { @MainActor in
                                        PTAlertTipsViewController.tipsAlertShow(title:"PT Alert Opps".localized(),subtitle:"PT Video editor get video error".localized(),icon: .Error)
                                    }
                                }
                            }
                        } else {
                            Task { @MainActor in
                                PTAlertTipsViewController.tipsAlertShow(title:"沒有選擇Video",icon: .Error)
                            }
                        }
                    }
                }
            } else if descriptor.id.rawValue == "media.signature" {
                PTGCDManager.shared.runOnMain {
                    let signConfig = PTSignatureConfig()
                    
                    let sign = PTSignView(viewConfig: signConfig)
                    sign.showView()
                    sign.doneBlock = { image in
                        let newImage = UIImageView(image: image)
                        controller.view.addSubview(newImage)
                        newImage.snp.makeConstraints { make in
                            make.left.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
                            make.top.equalTo(controller.collectionView)
                            make.height.equalTo(150)
                        }
                        
                        PTGCDManager.shared.delayOnMain(time: 5) {
                            newImage.removeFromSuperview()
                        }
                    }
                    sign.dismissBlock = {
                        
                    }
                }
            } else if descriptor.id.rawValue == "device.rotation" {
                PTGCDManager.shared.runOnMain {
                    PTRotationManager.shared.toggleOrientation()
                }
//                let r:Int = Int(arc4random_uniform(2))
//                PTRotationManager.shared.rotation(to: PTRotationManager.Orientation.allCases[r])
            } else if descriptor.id.rawValue == "audio.speech" {
                PTGCDManager.shared.runOnMain {
                    let vc = PTSpeechViewController()
                    controller.navigationController?.pushViewController(vc, animated: true)
                }
            } else if descriptor.id.rawValue == "ui.share" {
                PTGCDManager.shared.runOnMain {
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
                    if let cell = controller.catalogCollectionView.contentCollectionView.cellForItem(at: indexPath) {
                        vc.presentActionSheet(controller, from: cell)
                    }
                }
            } else if descriptor.id.rawValue == "network.check-update" {
                PTGCDManager.shared.runOnMain {
                    PTCheckUpdateFunction.share.checkTheVersionWithappid(appid: "6596749489", test: false, url: URL(string: shareURLString), version: "1.0.0", note: "123", force: false,alertType: .User)
                }
            } else if descriptor.id.rawValue == "navigation.route" {
                PTGCDManager.shared.runOnMain {
                    UIAlertController.baseActionSheet(title: "Route", titles: ["example"], otherBlock: { sheet,index,title in
                        switch index {
                        case 0:
                            PTGCDManager.shared.runOnMain(block: {
                                controller.routeFunction()
                            })
                        default:
                            break
                        }
                    })
                }
            } else if descriptor.id.rawValue == "ui.alert" {
                PTGCDManager.shared.runOnMain {
                    UIAlertController.baseActionSheet(title: "AlertTips", titles: ["low","hight",String.feedbackAlert,"ActionSheet","CustomActionSheet","new","newActionSheet","Like system"], otherBlock: { sheet,index,title in
                        switch index {
                        case 0:
                            let tips = PTAlertTipsViewController(title: "Job Done!", subtitle: "WOW", icon: .Done)
                            PTAlertManager.show(tips)
                        case 1:
                            let tips = PTAlertTipsViewController(title: "Hola!", subtitle: "Que?", icon: .Error,style: .SupportVisionOS)
                            PTAlertManager.show(tips)
                        case 2:
                            UIAlertController.alertSendFeedBack { title, content in
                            UIAlertController.drop(title: title,subTitle: content) {
                                    Task { @MainActor in
                                        UIAlertController.base_textfield_alertVC(okBtn: "PT Button comfirm".localized(), cancelBtn: "PT Button cancel".localized(), placeHolders: ["placeholder"], textFieldTexts: ["Test"], keyboardType: [.default], textFieldDelegate: controller) { result in
                                            
                                        }
                                    }
                                } notifiDismiss: {
                                    Task { @MainActor in
                                        UIAlertController.alertVC(title: "notifi消失之后", msg: "哦", cancel: "PT Button cancel".localized(), cancelBlock: {
                                        })
                                    }
                                }
                            }
                        case 3:
                            UIAlertController.baseActionSheet(title: "Title",subTitle: "SubTitle",cancelButtonName: "Cancel",destructiveButtons: ["Destructive","Destructive1","Destructive2"], titles: ["1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1"], destructiveBlock: { sheet, index, title in
                                
                            },otherBlock: { sheet,index,title in
                            })
                        case 4:
                            let title = PTActionSheetTitleItem(title: "Title", subTitle: "SubTitle")
                            
                            let cancelItem = PTActionSheetItem(title: "取消",image: UIImage(named: "DemoImage"),itemAlignment:.leading,itemLayout: .leftImageRightTitle)

                            let deItem = PTActionSheetItem(title: "其他",titleColor:.systemRed,image: "http://img.t.sinajs.cn/t35/style/images/common/face/ext/normal/7a/shenshou_thumb.gif",itemAlignment:.trailing,itemLayout: .leftTitleRightImage)

                            let content1 = PTActionSheetItem(title: "1",image: "http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg",itemAlignment:.left,itemLayout: .leftTitleRightImage)
                            let content2 = PTActionSheetItem(title: "2",image: "http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg",itemAlignment:.right,itemLayout: .leftTitleRightImage)
                            let content3 = PTActionSheetItem(title: "3",image: "http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg",itemAlignment:.fill,itemLayout: .leftTitleRightImage)

                            let actionSheet = PTActionSheetController(titleItem:title,cancelItem:cancelItem,destructiveItems: [deItem],contentItems: [content1,content2,content3])
                            PTAlertManager.show(actionSheet)

                        case 5:
                            let newAlertController = PTCustomerAlertController(title: "",customerViewHeight:0,buttons: ["11111","33333"],buttonsColors: [.systemBlue],cornerSize: 15)
                            PTAlertManager.show(newAlertController)
                        case 6:
                            let titleItem = PTActionSheetTitleItem(title: "Title",subTitle: "SubTitle")

                            var destructiveItems = [PTActionSheetItem]()
                            ["Destructive","Destructive1","Destructive2"].enumerated().forEach { index,value in
                                let item = PTActionSheetItem(title: value)
                                item.titleColor = .systemRed
                                destructiveItems.append(item)
                            }
                            
                            var contentItems = [PTActionSheetItem]()
                            ["1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1"].enumerated().forEach { index,value in
                                let item = PTActionSheetItem(title: value)
                                contentItems.append(item)
                            }
                            
                            let newAlertController = PTActionSheetController(titleItem:titleItem,destructiveItems: destructiveItems,contentItems: contentItems)
                            PTAlertManager.show(newAlertController)
                        case 7:
                            UIAlertController.base_alertVC(title:"1",msg:"8888888888888",cancelBtn:"33333")
                        default:
                            break
                        }
                    })
                }
            } else if descriptor.id.rawValue == "ui.loading" {
                PTGCDManager.shared.runOnMain {
                    UIAlertController.baseActionSheet(title: "Loading", titles: ["LoadingHub","CycleLoading","TextHub","ButtonHud","Progress1","Progress2","Progress3"], otherBlock: { sheet,index,title in
                        switch index {
                        case 0:
                            let hud = PTHudView()
                            hud.hudShow()
                            PTGCDManager.shared.delayOnMain(time: 5) {
                                hud.hide { }
                            }
                        case 1:
                            let cycle = PTCycleLoadingView()
                            controller.view.addSubviews([cycle])
                            cycle.snp.makeConstraints { make in
                                make.size.equalTo(100)
                                make.centerX.centerY.equalToSuperview()
                            }
                            cycle.startAnimation()
                            // English: Keep the delayed UI cleanup on MainActor to avoid capturing a UIKit view in a GCD callback.
                            // Español: Mantén la limpieza diferida de UI en MainActor para no capturar una vista UIKit en un callback GCD.
                            // 中文：将延迟 UI 清理保持在 MainActor，避免在 GCD 回调中捕获 UIKit 视图。
                            Task { @MainActor [weak cycle] in
                                try? await Task.sleep(for: .seconds(5))
                                guard !Task.isCancelled, let cycle else { return }
                                cycle.stopAnimation()
                                cycle.removeFromSuperview()
                            }
                        case 2:
                            PTGCDManager.shared.delayOnMain(time: 1, block: {
                                PTProgressHUD.show(text: "Progress HUD")
                            })
                        case 3:
                            PTGCDManager.shared.delayOnMain(time: 1, block: {
                                PTProgressHUD.showLogo(text: "Logo HUD", image: UIImage(named: "DemoImage"))
                            })
                        case 4:
                            PTGCDManager.shared.delayOnMain(time: 1, block: {
                                PTProgressHUD.showProgress(text: "Determinate bar", progressMode: .determinateBar)
                            })
                        case 5:
                            PTGCDManager.shared.delayOnMain(time: 1, block: {
                                PTProgressHUD.showProgress(text:"2222222222222",progressMode: .determinatePie)
                            })
                        case 6:
                            PTGCDManager.shared.delayOnMain(time: 1, block: {
                                PTProgressHUD.showProgress(text: "Determinate ring", progressMode: .determinateRing)
                            })
                        default:
                            break
                        }
                    })
                }
            } else if descriptor.id.rawValue == "permissions.overview" {
                PTGCDManager.shared.runOnMain {
                    let permissionVC = PTPermissionViewController()
                    permissionVC.permissionShow(vc: controller)
                    permissionVC.viewDismissBlock = {
                    }
                }
            } else if descriptor.id.rawValue == "permissions.settings" {
                PTGCDManager.shared.runOnMain {
                    let permissionVC = PTPermissionSettingViewController()
                    permissionVC.permissionShow(vc: controller)
                }
            } else if descriptor.id.rawValue == "theme.language" {
                PTGCDManager.shared.runOnMain {
                    UIAlertController.baseActionSheet(title: .language,subTitle: controller.currentSelectedLanguage, titles: PTFuncNameViewController.LanguageKey.allNames, otherBlock: { sheet,index,title in
                        controller.currentSelectedLanguage = PTFuncNameViewController.LanguageKey.allValues[index].desc
                        PTLanguage.share.language = PTFuncNameViewController.LanguageKey.allValues[index].rawValue
                    })
                }
            } else if descriptor.id.rawValue == "theme.dark-mode" {
                PTGCDManager.shared.runOnMain {
                    let vc = PTDarkModeControl()
                    controller.navigationController?.pushViewController(vc, animated: true)
                }
            } else if descriptor.id.rawValue == "modern.tipkit" {
                PTGCDManager.shared.runOnMain {
                    let vc = PTTipsDemoController()
                    controller.navigationController?.pushViewController(vc, animated: true)
                }
            } else if descriptor.id.rawValue == "documents.uidocument" {
                PTGCDManager.shared.runOnMain {
                    let vc = PTDocumentViewController()
                    controller.navigationController?.pushViewController(vc, animated: true)
                }
            } else if descriptor.id.rawValue == "ui.svga" {
//                let vc = PTSVGAViewController()
//                controller.navigationController?.pushViewController(vc)
            } else if descriptor.id.rawValue == "device.scan-qr" {
                PTGCDManager.shared.runOnMain {
                    let vc = PTScanQRController(viewConfig: PTScanQRConfig())
                    vc.resultBlock = { result,error in
                        PTNSLogConsole("\(result)")
                    }
                    controller.navigationController?.pushViewController(vc, animated: true)
                }
            } else if descriptor.id.rawValue == "media.filter-camera" {
                PTGCDManager.shared.runOnMain {
                    let cameraConfig = PTCameraFilterConfig.share
                    cameraConfig.allowRecordVideo = true
                    let pointFont = UIFont.appfont(size: 20)

                    cameraConfig.backImage = "❌".emojiToImage(emojiFont: pointFont)
                    cameraConfig.flashImage = UIImage(.flashlight.offFill).withTintColor(.white)
                    cameraConfig.flashImageSelected = UIImage(.flashlight.onFill).withTintColor(.white)
                    
                    cameraConfig.filtersImageSelected = UIImage(.line._3HorizontalDecreaseCircleFill)
                    cameraConfig.filtersImage = UIImage(.line._3HorizontalDecreaseCircle)

                    let vc = PTFilterCameraViewController()
                    vc.onlyCamera = false
                    vc.modalPresentationStyle = .fullScreen
                    controller.showDetailViewController(vc, sender: nil)
                }
            } else if descriptor.id.rawValue == "media.image-editor" {
                PTGCDManager.shared.runOnMain {
                    let image = UIImage(named: "DemoImage")!
                    
                    let vc = PTEditImageViewController(readyEditImage: image)
                    vc.editFinishBlock = { ei ,editImageModel in
                        PTMediaSaveService.save(image: ei) { result in
                            if case .failure = result {
                                PTAlertTipsViewController.tipsAlertShow(title:"Opps",subtitle: "保存图片失败",icon: .Error)
                            }
                        }
                    }
                    let nav = PTBaseNavControl(rootViewController: vc)
                    nav.view.backgroundColor = .black
                    nav.modalPresentationStyle = .fullScreen
                    controller.showDetailViewController(nav, sender: nil)
                }
            } else if descriptor.id.rawValue == "ui.message-kit" {
                PTGCDManager.shared.runOnMain {
                    let vc = PTTestChatViewController()
                    controller.navigationController?.pushViewController(vc, animated: true)
                }
            } else if descriptor.id.rawValue == "media.blur-image-list" {
                PTGCDManager.shared.runOnMain {
                    let vc = PTImageListViewController()
                    controller.navigationController?.pushViewController(vc, animated: true)
                }
            } else if descriptor.id.rawValue == "media.photo-picker" {
                PTGCDManager.shared.runOnMain {
                    PTMediaLibConfig.share.allowEditImage = true
                    PTMediaLibConfig.share.maxSelectCount = 9
                    PTMediaLibConfig.share.allowSelectImage = true
                    PTMediaLibConfig.share.allowSelectVideo = true
                    PTMediaLibConfig.share.allowMixSelect = true
                    PTMediaLibConfig.share.maxVideoSelectCount = 1
                    PTMediaLibConfig.share.allowEditVideo = true
                    PTMediaLibConfig.share.useCustomCamera = true

                    let vc = PTMediaLibViewController()
                    vc.mediaLibShow()
                    vc.selectImageBlock = { result,isOriginal in
                        if result.count > 0 {
                            PTNSLogConsole("\(result)")
                        } else {
                            PTAlertTipsViewController.tipsAlertShow(title:"失败",subtitle: "",icon: .Error)
                        }
                    }
                }
            } else {
                PTGCDManager.shared.runOnMain {
                    let sizes: [PTSheetSize] = [
                        ["input.stepper-list", "media.live-photo", "media.live-photo-disassemble", "ui.cycle-banner"].contains(descriptor.id.rawValue) ? .percent(0.9) : .percent(0.5)
                    ]
                    PTDemoCoordinator.shared.present(descriptor, from: controller, sizes: sizes)
                }
            }
        }


    }
}
