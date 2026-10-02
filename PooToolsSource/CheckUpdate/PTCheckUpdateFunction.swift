//
//  PTCheckUpdateFunction.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/3.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import SwiftJWT
import Alamofire

struct IpadScreenshotUrls: PTCodableModelProtocol, Sendable {
    init() {}
}

struct AppletvScreenshotUrls: PTCodableModelProtocol, Sendable {
    init() {}
}

struct Features: PTCodableModelProtocol, Sendable {
    init() {}
}

struct Results: PTCodableModelProtocol, Sendable {
    var primaryGenreName: String = ""
    var artworkUrl100: String = ""
    var currency: String = ""
    var artworkUrl512: String = ""
    var ipadScreenshotUrls: [IpadScreenshotUrls] = []
    var fileSizeBytes: String = ""
    var genres: [String] = []
    var languageCodesISO2A: [String] = []
    var artworkUrl60: String = ""
    var supportedDevices: [String] = []
    var bundleId: String = ""
    var trackViewUrl: String = ""
    var version: String = ""
    var description: String = ""
    var releaseDate: String = ""
    var genreIds: [String] = []
    var appletvScreenshotUrls: [AppletvScreenshotUrls] = []
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
    var contentAdvisoryRating: String = ""
    var features: [Features] = []
    var screenshotUrls: [String] = []
    var releaseNotes: String = ""
    var isVppDeviceBasedLicensingEnabled: Bool = false
    var sellerName: String = ""
    var averageUserRating: Int = 0
    var advisories: [String] = []
    
    init() {}
}

struct PTCheckUpdateModel: PTCodableModelProtocol, Sendable {
    var results: [Results] = []
    var resultCount: Int = 0
    init() {}
}

// English: TestFlight network responses use immutable value snapshots across async boundaries.
// Español: Las respuestas de TestFlight usan instantáneas de valor inmutables entre límites async.
// 中文：TestFlight 网络响应通过不可变值快照跨越异步边界。
public struct PTTFPagingSnapshot: PTCodableModelProtocol {
    public var total: Int = 0
    public var limit: Int = 0
    public init() {}
}

public struct PTTFMetaSnapshot: PTCodableModelProtocol {
    public var paging: PTTFPagingSnapshot?
    public init() {}
}

public struct PTTFLinkSnapshot: PTCodableModelProtocol {
    public var currentLink: String = ""
    public var related: String = ""
    public var next: String = ""

    public init() {}

    private enum CodingKeys: String, CodingKey {
        case currentLink = "self"
        case related
        case next
    }
}

public struct PTTFLinkMainSnapshot: PTCodableModelProtocol {
    public var links: PTTFLinkSnapshot?

    public init() {}
}

public struct PTTFRelationshipsSnapshot: PTCodableModelProtocol {
    public var app: PTTFLinkMainSnapshot?
    public var builds: PTTFLinkMainSnapshot?
    public var betaAppReviewSubmission: PTTFLinkMainSnapshot?
    public var appStoreVersion: PTTFLinkMainSnapshot?
    public var appEncryptionDeclaration: PTTFLinkMainSnapshot?
    public var individualTesters: PTTFLinkMainSnapshot?
    public var perfPowerMetrics: PTTFLinkMainSnapshot?
    public var betaBuildLocalizations: PTTFLinkMainSnapshot?
    public var betaGroups: PTTFLinkMainSnapshot?
    public var diagnosticSignatures: PTTFLinkMainSnapshot?
    public var preReleaseVersion: PTTFLinkMainSnapshot?
    public var buildBetaDetail: PTTFLinkMainSnapshot?
    public var icons: PTTFLinkMainSnapshot?

    public init() {}
}

public struct PTTFIconAssetTokenSnapshot: PTCodableModelProtocol {
    public var width: CGFloat = 0
    public var templateUrl: String = ""
    public var height: CGFloat = 0

    public init() {}
}

public struct PTTFAttributesSnapshot: PTCodableModelProtocol {
    public var version: String = ""
    public var platform: String = ""
    public var minOsVersion: String = ""
    public var computedMinMacOsVersion: String = ""
    public var lsMinimumSystemVersion: String = ""
    public var uploadedDate: String = ""
    public var expired: Bool = true
    public var processingState: String = ""
    public var buildAudienceType: String = ""
    public var expirationDate: String = ""
    public var usesNonExemptEncryption: Bool = false
    public var computedMinVisionOsVersion: String = ""
    public var iconAssetToken: PTTFIconAssetTokenSnapshot?
    public var locale: String = ""
    public var whatsNew: String = ""
    public var publicLink: String = ""
    public var name: String = ""

    public init() {}

    public var processingStateBool: Bool { processingState == "VALID" }
}

public struct PTTFVersionDataSnapshot: PTCodableModelProtocol {
    public var id: String = ""
    public var relationships: PTTFRelationshipsSnapshot?
    public var links: PTTFLinkSnapshot?
    public var type: String = ""
    public var attributes: PTTFAttributesSnapshot?

    public init() {}
}

public struct PTTFModelCollectionSnapshot: PTCodableModelProtocol {
    public var meta: PTTFMetaSnapshot?
    public var links: PTTFLinkSnapshot?
    public var data: [PTTFVersionDataSnapshot]?

    public init() {}
}

public struct PTTFNewerBuildVersionSnapshot: PTCodableModelProtocol {
    public var links: PTTFLinkSnapshot?
    public var data: PTTFVersionDataSnapshot?

    public init() {}
}

public struct PTTFUpdateSnapshot: PTCodableModelProtocol {
    public var version: String = ""
    public var desc: String = ""
    public var downloadURL: String = ""

    public init(version: String = "", desc: String = "", downloadURL: String = "") {
        self.version = version
        self.desc = desc
        self.downloadURL = downloadURL
    }
}

// English: These reference models remain source-compatible adapters for callers on the 5.x API.
// Español: Estos modelos de referencia permanecen como adaptadores compatibles con la API 5.x.
// 中文：这些引用模型作为 5.x API 的源码兼容适配器保留。
/*
 TF Mode

 These legacy reference models remain source-compatible adapters; the public class-based decoder API can migrate to immutable snapshot structs.
 Estos modelos de referencia mantienen la compatibilidad de origen; la API pública de decodificación basada en clases puede migrar a estructuras de instantáneas inmutables.
 这些旧引用模型用于保持源码兼容；基于公开类的解码 API 可以迁移到不可变快照结构体。
 */
public final class PTTFPaging: Codable {
    public var total: Int = 0
    public var limit: Int = 0
    required public init() {}
}

public final class PTTFMeta: Codable {
    public var paging: PTTFPaging?
    required public init() {}
}

public final class PTTLinkMainModel: Codable {
    public var links: PTTFLinks?
    required public init() {}
}

public final class PTTFRelationships: Codable {
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
    required public init() {}
}

public final class PTTFLinks: Codable {
    public var currentLink: String = ""
    public var related: String = ""
    public var next:String = ""
    
    required public init() {}

    private enum CodingKeys: String, CodingKey {
        case currentLink = "self"
        case related
        case next
    }
}

public final class PTTFIconAssetTokenModle: Codable {
    public var width:CGFloat = 0
    public var templateUrl:String = ""
    public var height:CGFloat = 0
    
    required public init() {}
}

public final class PTTFAttributes: Codable {
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
    
    required public init() {}

    public var processingStateBool:Bool {
        switch processingState {
        case "VALID":
                return true
            default:
                return false
        }
    }
}

public final class PTTFVersionData: Codable {
    public var id: String = ""
    public var relationships: PTTFRelationships?
    public var links: PTTFLinks?
    public var type: String = ""
    public var attributes: PTTFAttributes?
    
    required public init() {}
}

public final class PTTFModelCollection: Codable {
    public var meta: PTTFMeta?
    public var links: PTTFLinks?
    public var data: [PTTFVersionData]?
    
    required public init() {}
}

public final class PTTFNewerBuildVersionModel: Codable {
    public var links:PTTFLinks?
    public var data:PTTFVersionData?
    
    required public init() {}
}

public struct PTAppleClaims: Claims, Sendable {
    let iss: String
    let iat: Date
    let exp: Date
    let aud: String
}

public final class PTTFUpdateCustomModel: Codable {
    var version:String = ""
    var desc:String = ""
    var downloadURL:String = ""
    
    required public init() {}
}

@objcMembers
public class PTCheckUpdateFunction: NSObject {
    @MainActor public static let share = PTCheckUpdateFunction()
    
    //MARK: LoadingHud
    var hud:PTHudView?
    
    public enum PTUpdateAlertType:Int {
        case System
        case User
    }
    
    @MainActor public func renewVersion(newVersion:String) -> (String,String) {
        var appStoreVersion = newVersion.replacingOccurrences(of: ".", with: "")
        if appStoreVersion.nsString.length == 2 {
            appStoreVersion += "0"
        } else if appStoreVersion.nsString.length == 1 {
            appStoreVersion += "00"
        }
        
        var currentVersion = (kAppVersion ?? "0.0.0").replacingOccurrences(of: ".", with: "")
        if currentVersion.nsString.length == 2 {
            currentVersion += "0"
        } else if currentVersion.nsString.length == 1 {
            currentVersion += "00"
        }
        return (currentVersion,appStoreVersion)
    }
    
    @MainActor public func tfUpdate(force:Bool,
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
                    if let url {
                        PTAppStoreFunction.jumpLink(url: url)
                    } else {
                        PTNSLogConsole("非法url",levelType: .error,loggerType: .checkUpdate)
                    }
                }
            case 1:
                if let url {
                    PTAppStoreFunction.jumpLink(url: url)
                } else {
                    PTNSLogConsole("非法url",levelType: .error,loggerType: .checkUpdate)
                }
            default:
                break
            }
        })
    }
    
    @MainActor public func updateAlert(force:Bool,
                                       appid:String,
                                       version:String,
                                       note:String?,
                                       alertType:PTUpdateAlertType = .System) {
        let versionResult = self.renewVersion(newVersion: version)
        let currentVersion = versionResult.0
        let appStoreVersion = versionResult.1
        guard let appStoreFloat = appStoreVersion.float(),
              let currentFloat = currentVersion.float() else { return }
        if appStoreFloat > currentFloat {
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
                Task { @MainActor in
                    guard let storeURL = URL(string: PTAppStoreFunction.appStoreURL(appid: appid)) else {
                        PTNSLogConsole("非法 App Store URL", levelType: .error, loggerType: .checkUpdate)
                        return
                    }
                    self.alert_updateTips(oldVersion: kAppVersion ?? "0.0.0", newVersion: version, description: (note ?? ""), downloadUrl: storeURL)
                }
            }
        }
        
    }
    
    @MainActor public func checkUpdateAlert(appid:String,
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
    
    @MainActor public func checkTheVersionWithappid(appid:String? = nil,
                                                    test:Bool,
                                                    url:URL?,
                                                    version:String?,
                                                    note:String?,
                                                    force:Bool,
                                                    alertType:PTUpdateAlertType = .System) {
        let aID = appid ?? PTAppBaseConfig.share.appID
        if test {
            self.tfUpdate(force: force, version: version ?? "1.0.0", note: note, url: url)
        } else {
            if !aID.isEmpty {
                Task.init {
                    do {
                        let result = try await Network.requestCodableApi(needGobal:false,urlStr: "https://itunes.apple.com/cn/lookup?id=\(aID)",modelType: PTCheckUpdateModel.self)
                        if let responseModel = result.customerModel {
                            if !responseModel.results.isEmpty {
                                guard let versionModel = responseModel.results.first else {
                                    PTNSLogConsole("Data error", levelType: .error, loggerType: .checkUpdate)
                                    return
                                }
                                let versionStr = versionModel.version
                                
                                self.updateAlert(force: force, appid: aID, version: versionStr, note: versionModel.releaseNotes, alertType: alertType)
                            } else {
                                PTNSLogConsole("Data error",levelType: .error,loggerType: .checkUpdate)
                            }
                        } else {
                            PTNSLogConsole("Data error",levelType: .error,loggerType: .checkUpdate)
                        }
                    } catch {
                        PTNSLogConsole(error.localizedDescription,levelType: .error,loggerType: .checkUpdate)
                    }
                }
            } else {
                PTNSLogConsole("没有检测到APPID",levelType: .error,loggerType: .checkUpdate)
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
        PTUtils.getCurrentVC()?.pt_present(tipsControl, animated: true, completion: nil)
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
                    Task { @MainActor in
                        PTCoreUserDefaultsWrapper.shared.AppNoMoreShowUpdate = true
                    }
                }
            }
        },doneTitle: "PT Upgrade".localized()) {
            Task { @MainActor in
                guard let realURL = (url.scheme ?? "").stringIsEmpty()
                        ? URL(string: "https://" + url.description)
                        : Optional(url) else {
                    PTNSLogConsole("非法url", levelType: .error, loggerType: .checkUpdate)
                    return
                }
                PTAppStoreFunction.jumpLink(url: realURL)
            }
        } tipContentView: { contentView in
            let tipsContent = PTUpdateTipsContentView(oV: oV, nV: nV, descriptionString: descriptionString)
            contentView.addSubview(tipsContent)
            tipsContent.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }
    
    private func hudConfig() {
        Task { @MainActor in
            let hudConfig = PTHudConfig.share
            hudConfig.hudColors = [.gray,.gray]
            hudConfig.lineWidth = 4
        }
    }
    
    @MainActor func hudShow() {
        self.hudConfig()
        if self.hud == nil {
            self.hud = PTHudView()
            self.hud?.hudShow()
        }
    }
    
    @MainActor func hudHide(completion:PTActionTask? = nil) {
        if let hud = self.hud {
            self.hud = nil
            hud.hide {
                completion?()
            }
        }
    }
    
    private class func toggleHud(show:Bool) {
        PTGCDManager.shared.runOnMain {
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
    
    public static func appConnectApiRequest<T: Codable & Sendable>(token:String,apiUrl:String,parameters:[String:any Any & Sendable]? = nil,modelType: T.Type,showHud:Bool = true,success:@escaping @MainActor @Sendable (Any?,String) -> Void,fail:@escaping @MainActor @Sendable (NSError) -> Void) {
        if showHud {
            toggleHud(show: true)
        }
        
        Task {
            do {
                let headerDic = ["Authorization":"Bearer \(token)","Content-Type":"application/json"]
                let header = HTTPHeaders(headerDic)
                let model = try await Network.requestCodableApi(needGobal:false,urlStr: apiUrl,method: .get,header: header,parameters: parameters,modelType: modelType,encoder: URLEncoding.default)
                if showHud {
                    toggleHud(show: false)
                }
                await MainActor.run {
                    success(model.customerModel, model.originalString)
                }
            } catch {
                if showHud {
                    toggleHud(show: false)
                }
                PTNSLogConsole("\(error.localizedDescription)",levelType: .notice,loggerType: .network)
                
                let nsError = error as NSError
                await MainActor.run {
                    fail(nsError)
                }
            }
        }
    }
    
    @MainActor
    final class PTTFUpdateState {
        var build: String = "1.0.0"
        var note: String = ""
        var downLoadLink: String = ""
    }
    
    public static func fetchTestFlightBuildSnapshots(issuerID: String, keyID: String, privateKey: String, expTime: TimeInterval = 1200, updateModelCallback: @escaping @MainActor @Sendable (PTTFUpdateSnapshot?) -> Void) {
        
        guard let token = generateJWT(issuerID: issuerID, keyID: keyID, privateKey: privateKey, expTime: expTime) else {
            PTNSLogConsole("无法生成 JWT")
            return
        }
        
        PTCheckUpdateFunction.appConnectApiRequest(token: token, apiUrl: "https://api.appstoreconnect.apple.com/v1/builds", modelType: PTTFModelCollectionSnapshot.self) { result, jsonString in
            
            guard let resultModel = result as? PTTFModelCollectionSnapshot,
                  let firstData = resultModel.data?.first,
                  !firstData.id.stringIsEmpty() else {
                Task { @MainActor in updateModelCallback(nil) }
                return
            }
            
            let buildId = firstData.id
            let apiUrlString = firstData.relationships?.betaBuildLocalizations?.links?.related ?? ""
            
            Task { @MainActor in
                // 💡 修复点 1：实例化我们的状态类。用 let 声明，这样跨闭包捕获它是绝对安全的！
                let updateState = PTTFUpdateState()
                
                // 💡 修复点 2：将 appID 提前在主线程读取出来，避免在后台闭包里发生数据竞争
                let appID = PTAppBaseConfig.share.appID
                
                await PTGCDManager.shared.taskGroupUtility(semaphoreCount: 3, threadCount: 3) { currentIndex,finishTask in
                    switch currentIndex {
                    case 0:
                        PTCheckUpdateFunction.appConnectApiRequest(token: token, apiUrl: "https://api.appstoreconnect.apple.com/v1/buildBetaDetails/\(buildId)/build", modelType: PTTFNewerBuildVersionSnapshot.self, showHud: false) { newerResult, _ in
                            
                            if let resultModelBuilda = newerResult as? PTTFNewerBuildVersionSnapshot,
                               let versionStr = resultModelBuilda.data?.attributes?.version {
                                Task { @MainActor in
                                    // 通过常量实例去修改属性，安全！
                                    updateState.build = versionStr
                                }
                            }
                            finishTask()
                        } fail: { _ in
                            finishTask()
                        }
                    case 1:
                        PTCheckUpdateFunction.appConnectApiRequest(token: token, apiUrl: apiUrlString, modelType: PTTFModelCollectionSnapshot.self, showHud: false) { infoResult, _ in
                            
                            if let resultModelBuilda = infoResult as? PTTFModelCollectionSnapshot,
                               let whatsNewStr = resultModelBuilda.data?.first?.attributes?.whatsNew {
                                Task { @MainActor in
                                    updateState.note = whatsNewStr
                                }
                            }
                            finishTask()
                        } fail: { _ in
                            finishTask()
                        }
                    case 2:
                        // 使用刚刚提前提取出来的 appID
                        let para = ["filter[app]": appID, "fields[betaGroups]": "name,publicLink"]
                        PTCheckUpdateFunction.appConnectApiRequest(token: token, apiUrl: "https://api.appstoreconnect.apple.com/v1/betaGroups", parameters: para, modelType: PTTFModelCollectionSnapshot.self, showHud: false) { newerResult, _ in
                            
                            if let resultModelBuilda = newerResult as? PTTFModelCollectionSnapshot,
                               let linkStr = resultModelBuilda.data?.filter({ !($0.attributes?.publicLink ?? "").stringIsEmpty() }).first?.attributes?.publicLink {
                                Task { @MainActor in
                                    updateState.downLoadLink = linkStr
                                }
                            }
                            finishTask()
                        } fail: { _ in
                            finishTask()
                        }
                    default:
                        finishTask()
                    }
                    
                } allRequestsFinished: {
                    Task { @MainActor in
                        // 💡 最终完成时，直接从我们的状态类中取值即可
                        PTNSLogConsole("\(updateState.build)\(updateState.note)")
                        let updateModel = PTTFUpdateSnapshot(version: updateState.build,
                                                             desc: updateState.note,
                                                             downloadURL: updateState.downLoadLink)
                        
                        updateModelCallback(updateModel)
                    }
                }
            }
        } fail: { _ in
            Task { @MainActor in updateModelCallback(nil) }
        }
    }

    // English: Preserve the 5.x reference-model callback as a thin MainActor adapter.
    // Español: Conserva el callback con modelo de referencia de 5.x como un adaptador fino de MainActor.
    // 中文：保留 5.x 引用模型回调，并将其限制为 MainActor 兼容适配层。
    @available(*, deprecated, message: "Use fetchTestFlightBuildSnapshots(issuerID:keyID:privateKey:expTime:updateModelCallback:)")
    public static func fetchTestFlightBuilds(issuerID: String,
                                             keyID: String,
                                             privateKey: String,
                                             expTime: TimeInterval = 1200,
                                             updateModelCallback: @escaping @MainActor @Sendable (PTTFUpdateCustomModel?) -> Void) {
        fetchTestFlightBuildSnapshots(issuerID: issuerID,
                                      keyID: keyID,
                                      privateKey: privateKey,
                                      expTime: expTime) { snapshot in
            guard let snapshot else {
                updateModelCallback(nil)
                return
            }
            let model = PTTFUpdateCustomModel()
            model.version = snapshot.version
            model.desc = snapshot.desc
            model.downloadURL = snapshot.downloadURL
            updateModelCallback(model)
        }
    }
}
