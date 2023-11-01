//
//  PTCheckUpdateFunction.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/3.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import KakaJSON
import SwifterSwift

class IpadScreenshotUrls :PTBaseModel {

}

class AppletvScreenshotUrls :PTBaseModel {

}

class Features :PTBaseModel {

}

class Advisories :PTBaseModel {

}

class Results :PTBaseModel {
    var primaryGenreName: String = ""
    var artworkUrl100: String = ""
    var currency: String = ""
    var artworkUrl512: String = ""
    var ipadScreenshotUrls: [IpadScreenshotUrls]?
    var fileSizeBytes: String = ""
    var genres: [String]?
    var languageCodesISO2A: [String]?
    var artworkUrl60: String = ""
    var supportedDevices: [String]?
    var bundleId: String = ""
    var trackViewUrl: String = ""
    var version: String = ""
    var description: String = ""
    var releaseDate: String = ""
    var genreIds: [String]?
    var appletvScreenshotUrls: [AppletvScreenshotUrls]?
    var wrapperType: String = ""
    var isGameCenterEnabled: Bool = false
    var averageUserRatingForCurrentVersion: Int = 0
    var artistViewUrl: String = ""
    var trackId: Int = 0
    var userRatingCountForCurrentVersion: Int = 0
    var minimumOsVersion: String = ""
    var formattedPrice: String = ""
    var primaryGenreId: Int = 0
    var currentVersionReleaseDate: String = ""
    var userRatingCount: Int = 0
    var artistId: Int = 0
    var trackContentRating: String = ""
    var artistName: String = ""
    var price: Int = 0
    var trackCensoredName: String = ""
    var trackName: String = ""
    var kind: String = ""
    var contentAdvisoryRating: String!
    var features: [Features]?
    var screenshotUrls: [String]?
    var releaseNotes: String = ""
    var isVppDeviceBasedLicensingEnabled: Bool = false
    var sellerName: String = ""
    var averageUserRating: Int = 0
    var advisories: [Advisories]!
}

class PTCheckUpdateModel:PTBaseModel {
    var results: [Results]!
    var resultCount: Int = 0
}

@objcMembers
public class PTCheckUpdateFunction: NSObject {
    public static let share = PTCheckUpdateFunction()
    
    public enum PTUpdateAlertType {
        case System
        case User
    }
    
    func compareVesionWithServerVersion(version:String)->Bool {
        let currentVersion = kAppVersion
        let versionArray = version.components(separatedBy: ".")
        let currentVesionArray = currentVersion!.components(separatedBy: ".")
        let a = (versionArray.count > currentVesionArray.count ) ? currentVesionArray.count : versionArray.count
        
        for i in 0..<a {
            let forA = versionArray[i].int!
            let forB:Int = currentVesionArray[i].int!
            
            if forA > forB {
                return true
            } else if forA < forB {
                return false
            }
        }
        return false
    }
    
    public func checkTheVersionWithappid(appid:String,
                                         test:Bool,
                                         url:URL?,
                                         version:String?,
                                         note:String?,
                                         force:Bool,
                                         alertType:PTUpdateAlertType? = .System) {
        if test {
            var okBtns = [String]()
            if force {
                okBtns = ["更新"]
            } else {
                okBtns = ["稍后再说","更新"]
            }
            UIAlertController.base_alertVC(title:"发现新版本\(version ?? "1.0.0")\n\(note ?? "")",titleFont: .appfont(size: 17,bold: true),msg: "是否更新?",okBtns: okBtns,moreBtn: { index,title in
                switch index {
                case 0:
                    if force {
                        if url != nil {
                            PTAppStoreFunction.jumpLink(url: url!)
                        } else {
                            PTNSLogConsole("非法url")
                        }
                    }
                case 1:
                    if url != nil {
                        PTAppStoreFunction.jumpLink(url: url!)
                    } else {
                        PTNSLogConsole("非法url")
                    }
                default:
                    break
                }
            })
        } else {
            if !appid.stringIsEmpty() {
                Task.init {
                    do {
                        let result = try await Network.requestApi(needGobal:false,urlStr: "https://itunes.apple.com/cn/lookup?id=\(appid)",modelType: PTCheckUpdateModel.self)
                        let responseModel = result.customerModel as! PTCheckUpdateModel
                        if responseModel.results.count > 0 {
                            let versionModel = responseModel.results.first!
                            let versionStr = versionModel.version
                            var appStoreVersion = versionStr.replacingOccurrences(of: ".", with: "")
                            if appStoreVersion.nsString.length == 2 {
                                appStoreVersion = appStoreVersion.appending("0")
                            } else if appStoreVersion.nsString.length == 1 {
                                appStoreVersion = appStoreVersion.appending("00")
                            }
                            
                            var currentVersion = kAppVersion?.replacingOccurrences(of: ".", with: "")
                            if currentVersion?.nsString.length == 2 {
                                currentVersion = currentVersion?.appending("0")
                            } else if currentVersion?.nsString.length == 1 {
                                currentVersion = currentVersion?.appending("00")
                            }

                            if self.compareVesionWithServerVersion(version: versionStr) {
                                if appStoreVersion.float()! > currentVersion!.float()! {
                                    var okBtns = [String]()
                                    if force {
                                        okBtns = ["更新"]
                                    } else {
                                        okBtns = ["稍后再说","更新"]
                                    }
                                    switch alertType {
                                    case .System:
                                        await UIAlertController.base_alertVC(title:"发现新版本\(versionStr)\n\(versionModel.releaseNotes)",titleFont: .appfont(size: 17,bold: true),msg: "是否更新?",okBtns: okBtns,moreBtn: { index,title in
                                            switch index {
                                            case 0:
                                                if force {
                                                    PTAppStoreFunction.jumpToAppStore(appid: appid)
                                                }
                                            case 1:
                                                PTAppStoreFunction.jumpToAppStore(appid: appid)
                                            default:
                                                break
                                            }
                                        })
                                    case .User:
                                        PTGCDManager.gcdMain() {
                                            self.alert_updateTips(oldVersion: version!, newVersion: versionStr, description: (versionModel.releaseNotes), downloadUrl: URL(string: PTAppStoreFunction.appStoreURL(appid: appid))!)
                                        }
                                    default:
                                        break
                                    }
                                }
                            }
                        }
                    } catch {
                        PTNSLogConsole(error.localizedDescription)
                    }
                }
            } else {
                PTNSLogConsole("没有检测到APPID")
            }
        }
    }
        
    func alert_Tips(tipsTitle:String? = "",
                          cancelTitle:String = "",
                          cancelBlock: PTActionTask? = nil,
                          doneTitle:String,
                          doneBlock: PTActionTask? = nil,
                          tipContentView:((_ contentView:UIView)->Void)?) {
        let tipsControl = PTUpdateTipsViewController(titleString: tipsTitle,cancelTitle: cancelTitle, doneTitle: doneTitle)
        tipsControl.modalPresentationStyle = .fullScreen
        if cancelBlock != nil {
            tipsControl.cancelTask = cancelBlock!
        }
        if doneBlock != nil {
            tipsControl.doneTask = doneBlock!
        }

        if tipContentView != nil {
            tipContentView!(tipsControl.contentView)
        }
        PTUtils.getCurrentVC().present(tipsControl, animated: true, completion: nil)
    }
    
    //MARK: 初始化UpdateTips
    ///初始化UpdateTips
    /// - Parameters:
    ///   - oV: 舊版本號
    ///   - nV: 新版本號
    ///   - descriptionString: 更新信息
    ///   - url: 下載URL
    ///   - test: 是否測試
    ///   - isShowError: 是否顯示錯誤
    ///   - isForcedUpgrade: 是否強制升級
    func alert_updateTips(oldVersion oV: String,
                                newVersion nV: String,
                                description descriptionString: String,
                                downloadUrl url: URL,
                                isTest test:Bool = false,
                                showError isShowError:Bool = true,
                                forcedUpgrade isForcedUpgrade:Bool = false) {
        let cancelTitle:String = isForcedUpgrade ? "" : NSLocalizedString("取消升级", comment: "")
        self.alert_Tips(tipsTitle: NSLocalizedString("发现新版本", comment: ""),cancelTitle: cancelTitle,cancelBlock: {
            if test {
                if isShowError {
                    UserDefaults.standard.set(1, forKey: uAppNoMoreShowUpdate)
                }
            }
        },doneTitle: NSLocalizedString("升级", comment: "")) {
            let realURL:URL = (url.scheme ?? "").stringIsEmpty() ? URL.init(string: "https://" + url.description)! : url
            PTAppStoreFunction.jumpLink(url: realURL)
        } tipContentView: { contentView in
            
            let tipsContent = PTUpdateTipsContentView(oV: oV, nV: nV, descriptionString: descriptionString)
            contentView.addSubview(tipsContent)
            tipsContent.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }
}
