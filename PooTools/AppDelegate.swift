//
//  AppDelegate.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 1/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation
import IQKeyboardToolbarManager
import OSLog
#if DEBUG
import YCSymbolTracker
#endif
#if canImport(InAppViewDebugger)
import InAppViewDebugger
#endif
import Bugly
import TipKit
import MediaPlayer
import Alamofire
import SwifterSwift
import FamilyControls

//find . -type f | grep -e ".a" -e ".framework" | xargs grep -s UIWebView
enum RequestManager {
    static func mockRequest(url: String) {
        let url = URL(string: url)!

        let session = URLSession.shared

        let task = session.dataTask(with: url) { data, _, error in
            if let error {
                PTNSLogConsole("Error: \(error)")
                return
            }

            guard let data else {
                PTNSLogConsole("Error: Missing data for mocking request.")
                return
            }

            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                PTNSLogConsole("JSON Response: \(json)")
            } catch {
                PTNSLogConsole("Error parsing JSON: \(error)")
            }
        }

        task.resume()
    }
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Override point for customization after application launch.
        var debugDevice = false
        let buglyConfig = BuglyConfig()
        #if DEBUG
        debugDevice = true
        buglyConfig.debugMode = true
        #endif
        buglyConfig.channel = "iOS"
        buglyConfig.blockMonitorEnable = true
        buglyConfig.blockMonitorTimeout = 2
        buglyConfig.consolelogEnable = false
        buglyConfig.viewControllerTrackingEnable = false
        Bugly.start(withAppId: "32b6206a5d",
                    developmentDevice: debugDevice,
                    config: buglyConfig)
                
        IQKeyboardToolbarManager.shared.isEnabled = true
        
        PTAppBaseConfig.share.defaultPlaceholderImage = "🖼️".emojiToImage(emojiFont: .appfont(size: 44))
        
#if DEBUG
        let filePath = NSTemporaryDirectory().appending("/demo.order")
        YCSymbolTracker.exportSymbols(filePath: filePath)
#endif
        switch PTPermission.mediaLibrary.status {
        case .notDetermined:
            PTPermission.mediaLibrary.request {
                switch PTPermission.mediaLibrary.status {
                case .authorized:
                    self.sharePlaylist()
                default:
                    PTAlertTipControl.present(title:"用戶拒絕了",icon:.Error,style: .Normal)
                }
            }
        case .authorized:
            self.sharePlaylist()
        default:
            break
        }
//        let keyID = "B9Q98BMSBQ" // Get from https://developer.apple.com/account/ios/authkey/
//        let teamID = "77J8946934" // Get from https://developer.apple.com/account/#/membership/
//        createToken(keyID: keyID, teamID: teamID)
    
        PTLocationManager.shared.requestLocation()
            
        return true
    }
    
    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func minCount(@PTClampedProperyWrapper(range:1...10) counts:Int) ->Int {
        counts
    }
    
//    func findPlaylist() {
//        let query = MPMediaQuery.playlists()
//        if let playLists = query.collections {
//            for playList in playLists {
//                if let playlistName = playList.value(forKey: MPMediaPlaylistPropertyName) as? String {
//                    PTNSLogConsole("Playlist Name: \(playlistName)")
//                    let songs = playList.items
//                    for song in songs {
//                        if let songTitle = song.title {
//                            PTNSLogConsole("Song Title: \(songTitle)")
//                        }
//                    }
//                }
//            }
//        }
//    }
//    
    func sharePlaylist() {
        // 获取用户的播放列表
        let query = MPMediaQuery.playlists()
        if let playlists = query.collections {
            // 这里假设你想分享第一个播放列表
            if let playlist = playlists.first as? MPMediaPlaylist {
                // 获取播放列表的 persistentID
                let persistentID = playlist.persistentID
//                self.fetchPlaylistLink(gotID: "\(persistentID)")
                // 创建分享链接
//                let playlistLink = "https://music.apple.com/playlist/\(persistentID)"
//                
//                // 创建分享内容
//                let shareText = "Check out this playlist: \(playlistLink)"
//                let activityViewController = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
//
//                let currentVC = PTUtils.getCurrentVC()
//                // 在iPad上配置弹出框的位置
//                if let popoverController = activityViewController.popoverPresentationController {
//                    popoverController.sourceView = currentVC.view
//                    popoverController.sourceRect = CGRect(x: currentVC.view.bounds.midX, y: currentVC.view.bounds.midY, width: 0, height: 0)
//                    popoverController.permittedArrowDirections = []
//                }
//
//                // 显示分享视图控制器
//                currentVC.present(activityViewController, animated: true, completion: nil)
            }
        }
    }

    @objc func updateSpeedLabels() {
//        PTNSLogConsole("\(String(format: "Download Speed: %.2f KB/s", networkSpeedMonitor.downloadSpeed / 1024))")
//        PTNSLogConsole("\(String(format: "Upload Speed: %.2f KB/s", networkSpeedMonitor.uploadSpeed / 1024))")
        
        let downloadSpeed = PTNetworkSpeedMonitor.shared.averageDownloadSpeed() / 1024
        let uploadSpeed = PTNetworkSpeedMonitor.shared.averageUploadSpeed() / 1024
        
        PTNSLogConsole("\(String(format: "Download Speed: %.2f KB/s", downloadSpeed))")
        PTNSLogConsole("\(String(format: "Upload Speed: %.2f KB/s", uploadSpeed))")
    }

//    func fetchPlaylistLink(gotID:String) {
//        let persistentID = gotID
//
//        // Get content of the .p8 file
//        let p8 = """
//"""
//
//        // Assign developer information and token expiration setting
//        let jwt = JWT(keyID: "", teamID: "", issueDate: Date(), expireDuration: 60 * 60)
//
//        do {
//            let token = try jwt.sign(with: p8)
//            // Use the token in the authorization header in your requests connecting to Apple’s API server.
//            // e.g. urlRequest.addValue(_ value: "bearer \(token)", forHTTPHeaderField field: "authorization")
//            PTNSLogConsole("Generated JWT: \(token)")
//            PTNSLogConsole("準備請求")
//
////            // 设置 Apple Music API 的请求URL
////            let baseURL = "https://api.music.apple.com/v1/me/library/playlists/"
////            let urlString = baseURL + persistentID
////
////            // 设置API请求的头部信息
////            var request = URLRequest(url: URL(string: urlString)!)
////            request.httpMethod = "GET"
////            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
////            PTNSLogConsole("請求中")
////            // 发起API请求
////            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
////                if let data = data {
////                    do {
////                        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
////                        if let urlString = json?["url"] as? String {
////                            // 这个urlString就是可以直接访问播放列表的链接
////                            PTNSLogConsole("Playlist Link: \(urlString)")
////                        }
////                    } catch {
////                        PTNSLogConsole("Error parsing JSON: \(error.localizedDescription)")
////                    }
////                } else if let error = error {
////                    PTNSLogConsole("Error fetching playlist link: \(error.localizedDescription)")
////                } else {
////                    PTNSLogConsole("哦?")
////                }
////            }
////            task.resume()
//            let baseURL = "https://api.music.apple.com/v1/me/library/playlists/"
//
//            let headers: HTTPHeaders = [
//                "Authorization": "Bearer \(token)",
//                "Accept": "application/json"
//            ]
//
//            let urlString = baseURL + persistentID
//            
//            Task.init {
//                do {
//                    let model = try await Network.requestApi(needGobal: false, urlStr: urlString,method: .get,header: headers)
//                    PTNSLogConsole("成功\(model)")
//                } catch {
//                    PTNSLogConsole("請求報錯\(error.localizedDescription)")
//                }
//            }
//        } catch {
//            // Handle error
//            PTNSLogConsole(error.localizedDescription)
//        }
//    }
}

extension AppDelegate {
        
    func applicationWillEnterForeground(_ application: UIApplication) {
        PSecurityStrategy.addBlurEffect()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        PSecurityStrategy.removeBlurEffect()
    }
        
//    class func appDelegate() -> AppDelegate? {
//        UIApplication.shared.delegate as? AppDelegate
//    }
}
