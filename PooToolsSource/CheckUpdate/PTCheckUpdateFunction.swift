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
    
    func compareVesionWithServerVersion(version:String)->Bool
    {
        let currentVersion = kAppVersion
        let versionArray = version.components(separatedBy: ".")
        let currentVesionArray = currentVersion!.components(separatedBy: ".")
        let a = (versionArray.count > currentVesionArray.count ) ? currentVesionArray.count : versionArray.count
        
        for i in 0...a
        {
            let forA = versionArray[i].int!
            var forB:Int = 0
            if i > (currentVesionArray.count - 1)
            {
                forB = 0
            }
            else
            {
                forB = currentVesionArray[i].int!
            }
            
            if forA > forB
            {
                return true
            }
            else if forA < forB
            {
                return false
            }
        }
        return false
    }
    
    public func checkTheVersionWithappid(appid:String,test:Bool,url:URL?,version:String?,note:String?,force:Bool)
    {
        if test
        {
            var okBtns = [String]()
            if force
            {
                okBtns = ["更新"]
            }
            else
            {
                okBtns = ["稍后再说","更新"]
            }
            PTUtils.base_alertVC(title:"发现新版本\(version ?? "1.0.0")\n\(note ?? "")",titleFont: .appfont(size: 17,bold: true),msg: "是否更新?",okBtns: okBtns,showIn: PTUtils.getCurrentVC()) { index, title in
                switch index {
                case 0:
                    if force
                    {
                        if url != nil
                        {
                            self.jumpToDownloadLink(link: url!)
                        }
                        else
                        {
                            PTLocalConsoleFunction.share.pNSLog("非法url")
                        }
                    }
                case 1:
                    if url != nil
                    {
                        self.jumpToDownloadLink(link: url!)
                    }
                    else
                    {
                        PTLocalConsoleFunction.share.pNSLog("非法url")
                    }
                default:
                    break
                }
            }

        }
        else
        {
            if !appid.stringIsEmpty()
            {
                Network.requestApi(urlStr: "http://itunes.apple.com/cn/lookup?id=\(appid)",modelType: PTCheckUpdateModel.self) { result, error in
                    guard let responseModel = result!.originalString.kj.model(PTCheckUpdateModel.self) else { return }
                    if responseModel.results.count > 0
                    {
                        let versionModel = responseModel.results.first!
                        let versionStr = versionModel.version
                        var appStoreVersion = versionStr.replacingOccurrences(of: ".", with: "")
                        if appStoreVersion.nsString.length == 2
                        {
                            appStoreVersion = appStoreVersion.appending("0")
                        }
                        else if appStoreVersion.nsString.length == 1
                        {
                            appStoreVersion = appStoreVersion.appending("00")
                        }
                        
                        var currentVersion = kAppVersion?.replacingOccurrences(of: ".", with: "")
                        if currentVersion?.nsString.length == 2
                        {
                            currentVersion = currentVersion?.appending("0")
                        }
                        else if currentVersion?.nsString.length == 1
                        {
                            currentVersion = currentVersion?.appending("00")
                        }

                        if self.compareVesionWithServerVersion(version: versionStr)
                        {
                            if appStoreVersion.float()! > currentVersion!.float()!
                            {
                                var okBtns = [String]()
                                if force
                                {
                                    okBtns = ["更新"]
                                }
                                else
                                {
                                    okBtns = ["稍后再说","更新"]
                                }
                                PTUtils.base_alertVC(title:"发现新版本\(versionStr)\n\(versionModel.releaseNotes)",titleFont: .appfont(size: 17,bold: true),msg: "是否更新?",okBtns: okBtns,showIn: PTUtils.getCurrentVC()) { index, title in
                                    switch index {
                                    case 0:
                                        if force
                                        {
                                            self.jumpToAppStore(appid: appid)
                                        }
                                    case 1:
                                        self.jumpToAppStore(appid: appid)
                                    default:
                                        break
                                    }
                                }
                            }
                        }
                    }
                }
            }
            else
            {
                PTLocalConsoleFunction.share.pNSLog("没有检测到APPID")
            }
        }
    }
    
    private func jumpToAppStore(appid:String)
    {
        let uriString = String(format: "itms-apps://itunes.apple.com/app/id%@",appid)
        UIApplication.shared.open(URL(string: uriString)!, options: [:], completionHandler: nil)
    }
    
    private func jumpToDownloadLink(link:URL)
    {
        UIApplication.shared.open(link, options: [:], completionHandler: nil)
    }
}
