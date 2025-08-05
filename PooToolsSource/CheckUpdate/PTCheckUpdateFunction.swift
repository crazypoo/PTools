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
import SwiftJWT
import Alamofire
import KakaJSON

class IpadScreenshotUrls :PTBaseModel {

}

class AppletvScreenshotUrls :PTBaseModel {

}

class Features :PTBaseModel {

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
    var advisories: [String]!
}

class PTCheckUpdateModel:PTBaseModel {
    var results: [Results]!
    var resultCount: Int = 0
}

/*
 TF Mode
 */
public class PTTFPaging :PTBaseModel {
    public var total: Int = 0
    public var limit: Int = 0
}

public class PTTFMeta :PTBaseModel {
    public var paging: PTTFPaging?
}

public class PTTLinkMainModel:PTBaseModel {
    public var links: PTTFLinks?
}

public class PTTFRelationships :PTBaseModel {
    public var app: PTTLinkMainModel?
    public var builds: PTTLinkMainModel?
    public var betaAppReviewSubmission:PTTLinkMainModel?
    public var appStoreVersion:PTTLinkMainModel?
    public var appEncryptionDeclaration:PTTLinkMainModel?
    public var individualTesters:PTTLinkMainModel?
    public var perfPowerMetrics:PTTLinkMainModel?
    public var betaBuildLocalizations:PTTLinkMainModel?
    public var betaGroups:PTTLinkMainModel?
    public var diagnosticSignatures:PTTLinkMainModel?
    public var preReleaseVersion:PTTLinkMainModel?
    public var buildBetaDetail:PTTLinkMainModel?
    public var icons:PTTLinkMainModel?
}

public class PTTFLinks :PTBaseModel {
    public var currentLink: String = ""
    public var related: String = ""
    public var next:String = ""
    
    open override func kj_modelKey(from property: KakaJSON.Property) -> ModelPropertyKey {
        switch property.name {
        case "currentLink":
            return "self"
        default:
            return property.name
        }
    }
}

public class PTTFIconAssetTokenModle:PTBaseModel {
    public var width:CGFloat = 0
    public var templateUrl:String = ""
    public var height:CGFloat = 0
}

public class PTTFAttributes :PTBaseModel {
    public var version: String = ""
    public var platform: String = ""
    public var minOsVersion:String = ""
    public var computedMinMacOsVersion:String = ""
    public var lsMinimumSystemVersion:String = ""
    public var uploadedDate:String = ""
    public var expired:Bool = true
    public var processingState:String = ""
    public var buildAudienceType:String = ""
    public var expirationDate:String = ""
    public var usesNonExemptEncryption:Bool = false
    public var computedMinVisionOsVersion:String = ""
    public var iconAssetToken:PTTFIconAssetTokenModle?
    public var locale:String = ""
    public var whatsNew:String = ""
    public var publicLink:String = ""
    public var name:String = ""
    
    public var processingStateBool:Bool {
        switch processingState {
        case "VALID":
                return true
            default:
                return false
        }
    }
}

public class PTTFVersionData :PTBaseModel {
    public var id: String = ""
    public var relationships: PTTFRelationships?
    public var links: PTTFLinks?
    public var type: String = ""
    public var attributes: PTTFAttributes?
}

public class PTTFModelCollection :PTBaseModel {
    public var meta: PTTFMeta?
    public var links: PTTFLinks?
    public var data: [PTTFVersionData]?
}

public class PTTFNewerBuildVersionModel:PTBaseModel {
    public var links:PTTFLinks?
    public var data:PTTFVersionData?
}

public struct PTAppleClaims: Claims {
    let iss: String
    let iat: Date
    let exp: Date
    let aud: String
}

public class PTTFUpdateCustomModel:PTBaseModel {
    var version:String = ""
    var desc:String = ""
    var downloadURL:String = ""
}

@objcMembers
public class PTCheckUpdateFunction: NSObject {
    public static let share = PTCheckUpdateFunction()
    
    //MARK: LoadingHud
    var hud:PTHudView?

    public enum PTUpdateAlertType:Int {
        case System
        case User
    }
    
    public func compareVesionWithServerVersion(version:String) -> Bool {
        let currentVersion = kAppVersion
        let versionArray = version.components(separatedBy: ".")
        let currentVesionArray = currentVersion!.components(separatedBy: ".")
        let a = min(versionArray.count,currentVesionArray.count)
        
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
    
    public func renewVersion(newVersion:String) -> (String,String) {
        var appStoreVersion = newVersion.replacingOccurrences(of: ".", with: "")
        if appStoreVersion.nsString.length == 2 {
            appStoreVersion += "0"
        } else if appStoreVersion.nsString.length == 1 {
            appStoreVersion += "00"
        }
        
        var currentVersion = kAppVersion!.replacingOccurrences(of: ".", with: "")
        if currentVersion.nsString.length == 2 {
            currentVersion += "0"
        } else if currentVersion.nsString.length == 1 {
            currentVersion += "00"
        }
        return (currentVersion,appStoreVersion)
    }
    
    public func tfUpdate(force:Bool,
                         version:String,
                         note:String?,
                         url:URL?) {
        var okBtns = [String]()
        if force {
            okBtns = ["PT Upgrade".localized()]
        } else {
            okBtns = ["PT Upgrade later".localized(),"PT Upgrade".localized()]
        }
        UIAlertController.base_alertVC(title:"\("PT Found new version".localized())\(version)\n\(note ?? "")",titleFont: .appfont(size: 17,bold: true),msg: "PT Upgrade question mark".localized(),okBtns: okBtns,moreBtn: { index,title in
            switch index {
            case 0:
                if force {
                    if url != nil {
                        PTAppStoreFunction.jumpLink(url: url!)
                    } else {
                        PTNSLogConsole("非法url",levelType: .Error,loggerType: .CheckUpdate)
                    }
                }
            case 1:
                if url != nil {
                    PTAppStoreFunction.jumpLink(url: url!)
                } else {
                    PTNSLogConsole("非法url",levelType: .Error,loggerType: .CheckUpdate)
                }
            default:
                break
            }
        })
    }
    
    public func updateAlert(force:Bool,
                            appid:String,
                            version:String,
                            note:String?,
                            alertType:PTUpdateAlertType = .System) {
        let versionResult = self.renewVersion(newVersion: version)
        let currentVersion = versionResult.0
        let appStoreVersion = versionResult.1
        if appStoreVersion.float()! > currentVersion.float()! {
            var okBtns = [String]()
            if force {
                okBtns = ["PT Upgrade".localized()]
            } else {
                okBtns = ["PT Upgrade later".localized(),"PT Upgrade".localized()]
            }
            switch alertType {
            case .System:
                UIAlertController.base_alertVC(title:"\("PT Found new version".localized())\(version)\n\(note ?? "")",titleFont: .appfont(size: 17,bold: true),msg: "PT Upgrade question mark".localized(),okBtns: okBtns,moreBtn: { index,title in
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
                PTGCDManager.gcdMain {
                    self.alert_updateTips(oldVersion: kAppVersion!, newVersion: version, description: (note ?? ""), downloadUrl: URL(string: PTAppStoreFunction.appStoreURL(appid: appid))!)
                }
            }
        }

    }
    
    public func checkUpdateAlert(appid:String,
                                 test:Bool,
                                 url:URL?,
                                 version:String,
                                 note:String?,
                                 force:Bool,
                                 alertType:PTUpdateAlertType = .System) {
        if test {
            self.tfUpdate(force: force, version: version, note: note, url: url)
        } else {
            self.updateAlert(force: force, appid: appid, version: version, note: note, alertType: alertType)
        }
    }
    
    public func checkTheVersionWithappid(appid:String = PTAppBaseConfig.share.appID,
                                         test:Bool,
                                         url:URL?,
                                         version:String?,
                                         note:String?,
                                         force:Bool,
                                         alertType:PTUpdateAlertType = .System) {
        if test {
            self.tfUpdate(force: force, version: version ?? "1.0.0", note: note, url: url)
        } else {
            if !appid.isEmpty {
                Task.init {
                    do {
                        let result = try await Network.requestApi(needGobal:false,urlStr: "https://itunes.apple.com/cn/lookup?id=\(appid)",modelType: PTCheckUpdateModel.self)
                        let responseModel = result.customerModel as! PTCheckUpdateModel
                        if responseModel.results.count > 0 {
                            let versionModel = responseModel.results.first!
                            let versionStr = versionModel.version
                            
                            self.updateAlert(force: force, appid: appid, version: versionStr, note: versionModel.releaseNotes, alertType: alertType)
                        }
                    } catch {
                        PTNSLogConsole(error.localizedDescription,levelType: .Error,loggerType: .CheckUpdate)
                    }
                }
            } else {
                PTNSLogConsole("没有检测到APPID",levelType: .Error,loggerType: .CheckUpdate)
            }
        }
    }
        
    @MainActor func alert_Tips(tipsTitle: String = "",
                               cancelTitle: String = "",
                               cancelBlock: PTActionTask? = nil,
                               doneTitle: String,
                               doneBlock: PTActionTask? = nil,
                               tipContentView:((_ contentView:UIView) -> Void)? = nil) {
        let tipsControl = PTUpdateTipsViewController(titleString: tipsTitle,cancelTitle: cancelTitle, doneTitle: doneTitle)
        tipsControl.modalPresentationStyle = .formSheet
        tipsControl.cancelTask = cancelBlock
        tipsControl.doneTask = doneBlock
        tipContentView?(tipsControl.contentView)
        PTUtils.getCurrentVC().pt_present(tipsControl, animated: true, completion: nil)
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
    @MainActor func alert_updateTips(oldVersion oV: String,
                                     newVersion nV: String,
                                     description descriptionString: String,
                                     downloadUrl url: URL,
                                     isTest test:Bool = false,
                                     showError isShowError:Bool = true,
                                     forcedUpgrade isForcedUpgrade:Bool = false) {
        let cancelTitle:String = isForcedUpgrade ? "" : "PT Cancel upgrade".localized()
        alert_Tips(tipsTitle: "PT Found new version".localized(),cancelTitle: cancelTitle,cancelBlock: {
            if test {
                if isShowError {
                    PTCoreUserDefultsWrapper.AppNoMoreShowUpdate = true
                }
            }
        },doneTitle: "PT Upgrade".localized()) {
            let realURL:URL = (url.scheme ?? "").stringIsEmpty() ? URL(string: "https://" + url.description)! : url
            PTAppStoreFunction.jumpLink(url: realURL)
        } tipContentView: { contentView in
            let tipsContent = PTUpdateTipsContentView(oV: oV, nV: nV, descriptionString: descriptionString)
            contentView.addSubview(tipsContent)
            tipsContent.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }
    
    private func hudConfig() {
        let hudConfig = PTHudConfig.share
        hudConfig.hudColors = [.gray,.gray]
        hudConfig.lineWidth = 4
    }
    
    func hudShow() {
        PTGCDManager.gcdMain {
            self.hudConfig()
            if self.hud == nil {
                self.hud = PTHudView()
                self.hud!.hudShow()
            }
        }
    }
    
    func hudHide(completion:PTActionTask? = nil) {
        if self.hud != nil {
            self.hud!.hide {
                self.hud = nil
                completion?()
            }
        }
    }

    private class func toggleHud(show:Bool) {
        PTGCDManager.gcdMain {
            show ? PTCheckUpdateFunction.share.hudShow() : PTCheckUpdateFunction.share.hudHide()
        }
    }
    
    // 生成 JWT Token
    public static func generateJWT(issuerID:String,keyID:String,privateKey:String,expTime:TimeInterval = 1200) -> String? {
        // 设置 iat 和 exp 时间
        let currentDate = Date()
        let expirationDate = currentDate.addingTimeInterval(expTime) // 有效期 20 分钟

        // 创建 JWT Claims
        let claims = PTAppleClaims(
            iss: issuerID,
            iat: currentDate,
            exp: expirationDate,
            aud: "appstoreconnect-v1"
        )

        // 创建 JWT Header
        var jwtHeader = Header()
        jwtHeader.kid = keyID

        // 生成 JWT
        var jwt = JWT(header: jwtHeader, claims: claims)
        do {
            let jwtSigner = JWTSigner.es256(privateKey: Data(privateKey.utf8))
            let token = try jwt.sign(using: jwtSigner)
            return token
        } catch {
            PTNSLogConsole("JWT 生成失败: \(error)")
            return nil
        }
    }

    public static func appConnectApiRequest(token:String,apiUrl:String,parameters:[String:Any]? = nil,modelType: Convertible.Type,showHud:Bool = true,success:@escaping ((Any?,String) -> Void),fail:@escaping ((NSError) -> Void)) {
        if showHud {
            toggleHud(show: true)
        }

        Task {
            do {
                let headerDic = ["Authorization":"Bearer \(token)","Content-Type":"application/json"]
                let header = HTTPHeaders(headerDic)
                let model = try await Network.requestApi(needGobal:false,urlStr: apiUrl,method: .get,header: header,parameters: parameters,modelType: modelType,encoder: URLEncoding.default)
                if showHud {
                    toggleHud(show: false)
                }
                success(model.customerModel,model.originalString)
            } catch {
                if showHud {
                    toggleHud(show: false)
                }
                PTNSLogConsole("\(error.localizedDescription)",levelType: .Notice,loggerType: .Network)
                
                let nsError = error as NSError
                fail(nsError)
            }
        }
    }

    public static func fetchTestFlightBuilds(issuerID:String,keyID:String,privateKey:String,expTime:TimeInterval = 1200,updateModelCallback:@escaping ((PTTFUpdateCustomModel?) -> Void)) {
        guard let token = generateJWT(issuerID:issuerID,keyID:keyID,privateKey:privateKey,expTime:expTime) else {
            PTNSLogConsole("无法生成 JWT")
            return
        }
        
        PTCheckUpdateFunction.appConnectApiRequest(token: token, apiUrl: "https://api.appstoreconnect.apple.com/v1/builds", modelType: PTTFModelCollection.self) { result, jsonString in
            PTGCDManager.gcdMain {
                if let resultModel = result as? PTTFModelCollection {
                    var build:String = ""
                    var note = ""
                    var downLoadLink = ""
                    if let buildId = resultModel.data?[0].id,!buildId.stringIsEmpty() {
                        PTGCDManager.gcdGroupUtility(label: "com.tf.get", semaphoreCount: 3, threadCount: 3) { dispatchSemaphore, dispatchGroup, currentIndex in
                            switch currentIndex {
                            case 0:
                                PTCheckUpdateFunction.appConnectApiRequest(token: token, apiUrl: "https://api.appstoreconnect.apple.com/v1/buildBetaDetails/\(buildId)/build", modelType: PTTFNewerBuildVersionModel.self,showHud: false) { newerResult, newerJsonString in
                                    PTGCDManager.gcdMain {
                                        if let resultModelBuilda = newerResult as? PTTFNewerBuildVersionModel {
                                            build = resultModelBuilda.data?.attributes?.version ?? "1.0.0"
                                        }
                                        dispatchSemaphore.signal()
                                        dispatchGroup.leave()
                                    }
                                } fail: { error in
                                    dispatchSemaphore.signal()
                                    dispatchGroup.leave()
                                }
                            case 1:
                                PTCheckUpdateFunction.appConnectApiRequest(token: token, apiUrl: resultModel.data![0].relationships?.betaBuildLocalizations?.links?.related ?? "", modelType: PTTFModelCollection.self,showHud: false) { infoResult, infoJsonString in
                                    PTGCDManager.gcdMain {
                                        if let resultModelBuilda = infoResult as? PTTFModelCollection {
                                            note = resultModelBuilda.data?.first?.attributes?.whatsNew ?? ""
                                        }
                                        dispatchSemaphore.signal()
                                        dispatchGroup.leave()
                                    }
                                } fail: { error in
                                    dispatchSemaphore.signal()
                                    dispatchGroup.leave()
                                }
                            case 2:
                                                                
                                let para = ["filter[app]":PTAppBaseConfig.share.appID,"fields[betaGroups]":"name,publicLink"]
                                PTCheckUpdateFunction.appConnectApiRequest(token: token, apiUrl: "https://api.appstoreconnect.apple.com/v1/betaGroups", parameters: para,modelType: PTTFModelCollection.self,showHud: false) { newerResult, newerJsonString in
                                    PTGCDManager.gcdMain {
                                        if let resultModelBuilda = newerResult as? PTTFModelCollection {
                                            downLoadLink = resultModelBuilda.data?.filter { !($0.attributes?.publicLink ?? "").stringIsEmpty() }.first?.attributes?.publicLink ?? ""
                                        }
                                        dispatchSemaphore.signal()
                                        dispatchGroup.leave()
                                    }
                                } fail: { error in
                                    dispatchSemaphore.signal()
                                    dispatchGroup.leave()
                                }
                            default:
                                dispatchSemaphore.signal()
                                dispatchGroup.leave()
                            }

                        } allRequestsFinished: {
                            PTNSLogConsole("\(build)\(note)")
                            let updateModel = PTTFUpdateCustomModel()
                            updateModel.version = build
                            updateModel.downloadURL = downLoadLink
                            updateModel.desc = note
                            
                            updateModelCallback(updateModel)
                        }
                    } else {
                        updateModelCallback(nil)
                    }
                } else {
                    updateModelCallback(nil)
                }
            }
        } fail: { error in
            updateModelCallback(nil)
        }
    }
}
