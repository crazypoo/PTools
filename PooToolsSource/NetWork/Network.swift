//
//  Network.swift
//  MiniChatSwift
//
//  Created by 林勇彬 on 2022/5/21.
//  Copyright © 2022 九州所想. All rights reserved.
//

import UIKit
import Alamofire
import KakaJSON
import Network

public let NetWorkNoError = NSError(domain: "PT Network no network".localized(), code: 99999999996)
public let NetWorkJsonExplainError = NSError(domain: "PT Network json fail".localized(), code: 99999999998)
public let NetWorkModelExplainError = NSError(domain: "PT Network model fail".localized(), code: 99999999999)
public let NetWorkDownloadError = NSError(domain: "PT Network download fail".localized(), code: 99999999997)
public let NetWorkCheckIPError = NSError(domain: "IP address error", code: 99999999995)

public let AppTestMode = "PT App network environment test".localized()
public let AppCustomMode = "PT App network environment custom".localized()
public let AppDisMode = "PT App network environment distribution".localized()

public enum NetWorkStatus: Int {
    case unknown
    case notReachable
    case wwan
    case wifi
    
    public static func valueName(type:NetWorkStatus) -> String {
        switch type {
        case .unknown:
            "PT App network status unknow".localized()
        case .notReachable:
            "PT App network status disconnect".localized()
        case .wwan:
            "2,3,4G,5G"
        case .wifi:
            "WIFI"
        }
    }
}

public enum NetWorkEnvironment: Int {
    case Development
    case Test
    case Distribution
    
    public static func valueName(type:NetWorkEnvironment) -> String {
        switch type {
        case .Development:
            "PT App network environment custom".localized()
        case .Test:
            "PT App network environment test".localized()
        case .Distribution:
            "PT App network environment distribution".localized()
        }
    }
}

public typealias NetWorkStatusBlock = (_ NetWorkStatus: String, _ NetWorkEnvironment: String,_ NetworkStatusType:NetworkReachabilityManager.NetworkReachabilityStatus) -> Void
public typealias UploadProgress = (_ progress: Progress) -> Void
public typealias FileDownloadProgress = (_ bytesRead:Int64,_ totalBytesRead:Int64,_ progress:Double)->()
public typealias FileDownloadSuccess = (_ reponse:AFDownloadResponse<Data>)->()
public typealias FileDownloadFail = (_ error:Error?)->()

public var PTBaseURLMode:NetWorkEnvironment {
    guard let sliderValue = PTCoreUserDefultsWrapper.AppServiceIdentifier else { return .Distribution }
    if sliderValue == "1" {
        return .Distribution
    } else if sliderValue == "2" {
        return .Test
    } else if sliderValue == "3" {
        return .Development
    }
    return .Distribution
}

// MARK: - 网络运行状态监听
@objcMembers
public class PTNetWorkStatus {
    
    public static let shared = PTNetWorkStatus()
    public var checkNetwork = "www.google.com"
    /// 当前网络环境状态
    private var currentNetWorkStatus: NetWorkStatus = .wifi
    /// 当前运行环境状态
    private var currentEnvironment: NetWorkEnvironment = .Test
    
    private let monitor = NWPathMonitor()

    let reachabilityManager = Alamofire.NetworkReachabilityManager(host: PTNetWorkStatus.shared.checkNetwork)
    
    private func detectNetWork(netWork: @escaping NetWorkStatusBlock) {
        reachabilityManager?.startListening(onUpdatePerforming: { [weak self] (status) in
            guard let weakSelf = self else { return }
            if self?.reachabilityManager?.isReachable ?? false {
                switch status {
                case .notReachable:
                    weakSelf.currentNetWorkStatus = .notReachable
                case .unknown:
                    weakSelf.currentNetWorkStatus = .unknown
                case .reachable(.cellular):
                    weakSelf.currentNetWorkStatus = .wwan
                case .reachable(.ethernetOrWiFi):
                    weakSelf.currentNetWorkStatus = .wifi
                }
            } else {
                weakSelf.currentNetWorkStatus = .notReachable
            }
            
            netWork(NetWorkStatus.valueName(type: weakSelf.currentNetWorkStatus), NetWorkEnvironment.valueName(type: weakSelf.currentEnvironment),status)
        })
    }
    
    ///监听网络运行状态
    public func obtainDataFromLocalWhenNetworkUnconnected(handle:((NetworkReachabilityManager.NetworkReachabilityStatus)->Void)?) {
        detectNetWork { (status, environment,statusType)  in
                        
            PTNSLogConsole(String(format: "PT App current mode".localized(), status,environment))

            if handle != nil {
                handle!(statusType)
            }
        }
    }
    
    public func netWork(handle: @escaping (_ status:NetWorkStatus)->Void) {
        monitor.pathUpdateHandler = { path in
            if path.usesInterfaceType(.wifi) {
                handle(.wifi)
            } else if path.usesInterfaceType(.cellular) {
                handle(.wwan)
            } else {
                handle(.notReachable)
            }
        }
        let queue = DispatchQueue(label: "Network")
        monitor.start(queue: queue)
    }
    
    public func checkNetworkStatusCancel() {
        monitor.cancel()
    }
    
    deinit {
        checkNetworkStatusCancel()
    }
}

@objcMembers
public class Network: NSObject {
    
    static public let share = Network()
            
    ///网络请求时间
    open var netRequsetTime:TimeInterval = 20
    open var serverAddress:String = ""
    open var serverAddress_dev:String = ""
    open var userToken:String = ""

    open var fileUrl:String = ""
    open var saveFilePath:String = "" // 文件下载保存的路径
    open var cancelledData : Data?//用于停止下载时,保存已下载的部分
    open var downloadRequest:DownloadRequest? //下载请求对象
    open var destination:DownloadRequest.Destination!//下载文件的保存路径
    
    open var progress:FileDownloadProgress?
    open var success:FileDownloadSuccess?
    open var fail:FileDownloadFail?
    
    private var queue:DispatchQueue = DispatchQueue.main

    /// manager
    private static var manager: Session = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = Network.share.netRequsetTime
        return Session(configuration: configuration)
    }()
    
    open var hud:PTHudView?
    open var hudConfig : PTHudConfig {
        let hudConfig = PTHudConfig.share
        hudConfig.hudColors = [.gray,.gray]
        hudConfig.lineWidth = 4
        return hudConfig
    }
    
    func hudShow() {
        PTGCDManager.gcdMain {
            let _ = Network.share.hudConfig
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
                if completion != nil {
                    completion!()
                }
            }
        }
    }
        
    //MARK: 服务器URL
    public class func gobalUrl() -> String {
        if UIApplication.applicationEnvironment() != .appStore {
            PTNSLogConsole("PTBaseURLMode:\(PTBaseURLMode)")
            switch PTBaseURLMode {
            case .Development:
                let url_debug:String = PTCoreUserDefultsWrapper.AppRequestUrl
                if url_debug.isEmpty {
                    return Network.share.serverAddress_dev
                } else {
                    return url_debug
                }
            case .Test:
                return Network.share.serverAddress_dev
            case .Distribution:
                return Network.share.serverAddress
            }
        } else {
            return Network.share.serverAddress
        }
    }
    
    class public func getIpAddress(url:String = "https://api.ipify.org") async throws -> String {
        var apiHeader = HTTPHeaders.init([:])
        apiHeader["Content-Type"] = "application/json;charset=UTF-8"
        apiHeader["Accept"] = "application/json"

        let model = try await Network.requestApi(needGobal:false,urlStr: url,method: .get,header: apiHeader)
        let ipAddress = String(data: model.resultData!, encoding: .utf8) ?? ""
        return ipAddress
    }
    
    class public func requestIPInfo(ipAddress:String,lang:OSSVoiceEnum = .ChineseSimplified) async throws -> PTIPInfoModel {
        
        let urlStr1 = "http://ip-api.com/json/\(ipAddress)?lang=\(lang.rawValue)"
        var apiHeader = HTTPHeaders.init([:])
        apiHeader["Content-Type"] = "application/json;charset=UTF-8"
        apiHeader["Accept"] = "application/json"
        let models = try await Network.requestApi(needGobal: false, urlStr: urlStr1,method: .get,header: apiHeader,modelType: PTIPInfoModel.self)
        return models.customerModel as! PTIPInfoModel
    }
    
    //JSONEncoding  JSON参数
    //URLEncoding    URL参数
    /// 项目总接口
    /// - Parameters:
    ///   - needGobal:
    ///   - urlStr: url地址
    ///   - method: 方法类型，默认post
    ///   - header:
    ///   - parameters: 请求参数，默认nil
    ///   - modelType: 是否需要传入接口的数据模型，默认nil
    ///   - encoder: 编码方式，默认url编码
    ///   - jsonRequest:
    ///  - Returns: ResponseModel
    class public func requestApi(needGobal:Bool? = true,
                                 urlStr:String,
                                 method: HTTPMethod = .post,
                                 header:HTTPHeaders? = nil,
                                 parameters: Parameters? = nil,
                                 modelType: Convertible.Type? = nil,
                                 encoder:ParameterEncoding = URLEncoding.default,
                                 jsonRequest:Bool? = false) async throws -> PTBaseStructModel {

        try await withCheckedThrowingContinuation { continuation in
            
            let urlStr1 = (needGobal! ? Network.gobalUrl() : "") + urlStr
            if !urlStr1.isURL() || urlStr.stringIsEmpty() {
                continuation.resume(throwing: AFError.invalidURL(url: "https://www.qq.com"))
                return
            }

            // 判断网络是否可用
            if let reachabilityManager = PTNetWorkStatus.shared.reachabilityManager {
                if !reachabilityManager.isReachable {
                    continuation.resume(throwing: AFError.createURLRequestFailed(error: NetWorkNoError))
                    return
                }
            }

            var apiHeader = HTTPHeaders()
            let token = Network.share.userToken
            if !token.stringIsEmpty() && header == nil {
                apiHeader = HTTPHeaders.init(["token": token, "device": "iOS"])
                if jsonRequest! {
                    apiHeader["Content-Type"] = "application/json;charset=UTF-8"
                    apiHeader["Accept"] = "application/json"
                }
            } else if token.stringIsEmpty() && header != nil {
                apiHeader = header!
                if jsonRequest! {
                    apiHeader["Content-Type"] = "application/json;charset=UTF-8"
                    apiHeader["Accept"] = "application/json"
                }
            } else if !token.stringIsEmpty() && header != nil {
                apiHeader = header!
                apiHeader["token"] = token
                if jsonRequest! {
                    apiHeader["Content-Type"] = "application/json;charset=UTF-8"
                    apiHeader["Accept"] = "application/json"
                }
            }

            var postString = ""
            switch method {
            case .post:
                postString = "POST请求"
            case .get:
                postString = "GET请求"
            default:
                postString = "其他"
            }
            PTNSLogConsole("🌐❤️1.请求地址 = \(urlStr1)\n💛2.参数 = \(parameters?.jsonString() ?? "没有参数")\n💙3.请求头 = \(header?.dictionary.jsonString() ?? "没有请求头")\n🩷4.请求类型 = \(postString)🌐",levelType: PTLogMode,loggerType: .Network)

            Network.manager.request(urlStr1, method: method, parameters: parameters, encoding: encoder, headers: apiHeader).responseData { data in
                switch data.result {
                case .success(_):
                    
                    var requestStruct = PTBaseStructModel()
                    requestStruct.resultData = data.data
                    let jsonStr = data.data?.toDict()?.toJSON() ?? ""
                    PTNSLogConsole("🌐接口请求成功回调🌐\n❤️1.请求地址 = \(urlStr1)\n💛2.result:\((!jsonStr.stringIsEmpty() ? jsonStr : ((data.data ?? Data()).string(encoding: .utf8)))!)🌐",levelType: PTLogMode,loggerType: .Network)
                    requestStruct.originalString = jsonStr
                    guard let modelType1 = modelType else {
                        continuation.resume(returning: requestStruct)
                        return
                    }
                    requestStruct.customerModel = jsonStr.kj.model(type: modelType1)
                    continuation.resume(returning: requestStruct)
                case .failure(let error):
                    PTNSLogConsole("❌接口:\(urlStr1)\n🎈----------------------出现错误----------------------🎈\(String(describing: error.errorDescription))❌", levelType: .Error,loggerType: .Network)
                    continuation.resume(throwing: error)
                }
            }
        }
    }
        
    /// 图片上传接口
    /// - Parameters:
    ///   - needGobal:是否使用全局URL
    ///   - images: 图片集合
    ///   - path:路徑
    ///   - method:
    ///   - fileKey:fileKey
    ///   - parmas:數據
    ///   - header:頭部
    ///   - modelType:Model
    ///   - jsonRequest:是否jsonRequest
    ///   - pngData:是否Png
    ///   - progressBlock: 进度回调
    /// - Returns:ResponseModel
    class public func imageUpload(needGobal:Bool? = true,
                                  images:[UIImage]?,
                                  path:String? = "/api/project/ossImg",
                                  method: HTTPMethod = .post,
                                  fileKey:[String]? = ["images"],
                                  parmas:[String:String]? = nil,
                                  header:HTTPHeaders? = nil,
                                  modelType: Convertible.Type? = nil,
                                  jsonRequest:Bool? = false,
                                  pngData:Bool? = true,
                                  progressBlock:UploadProgress? = nil) async throws -> PTBaseStructModel {
        
        let pathUrl = (needGobal! ? Network.gobalUrl() : "") + path!
        if !pathUrl.isURL() || (path ?? "").stringIsEmpty() {
            throw AFError.invalidURL(url: "https://www.qq.com")
        }

        // 判断网络是否可用
        if let reachabilityManager = PTNetWorkStatus.shared.reachabilityManager {
            if !reachabilityManager.isReachable {
                throw AFError.createURLRequestFailed(error: NetWorkNoError)
            }
        }
        
        var apiHeader = HTTPHeaders()
        let token = Network.share.userToken
        if !token.stringIsEmpty() && header == nil {
            apiHeader = HTTPHeaders.init(["token":token,"device":"iOS"])
            if jsonRequest! {
                apiHeader["Content-Type"] = "application/json;charset=UTF-8"
                apiHeader["Accept"] = "application/json"
            }
        } else if token.stringIsEmpty() && header != nil {
            apiHeader = header!
            if jsonRequest! {
                apiHeader["Content-Type"] = "application/json;charset=UTF-8"
                apiHeader["Accept"] = "application/json"
            }
        } else if !token.stringIsEmpty() && header != nil {
            apiHeader = header!
            apiHeader["token"] = token
            if jsonRequest! {
                apiHeader["Content-Type"] = "application/json;charset=UTF-8"
                apiHeader["Accept"] = "application/json"
            }
        }

        return try await withCheckedThrowingContinuation { continuation in
            Network.manager.upload(multipartFormData: { multipartFormData in
                images?.enumerated().forEach { index,image in
                    if pngData! {
                        if let imgData = image.pngData() {
                            multipartFormData.append(imgData, withName: fileKey![index],fileName: "image_\(index).png", mimeType: "image/png")
                        }
                    } else {
                        if let imgData = image.jpegData(compressionQuality: 0.2) {
                            multipartFormData.append(imgData, withName: fileKey![index],fileName: "image_\(index).png", mimeType: "image/png")
                        }
                    }
                }
                if parmas != nil {
                    parmas?.keys.enumerated().forEach({ index,value in
                        multipartFormData.append(Data(parmas![value]!.utf8), withName: value)
                    })
                }
            }, to: pathUrl,method: method,headers: apiHeader).uploadProgress(closure: { progress in
                PTGCDManager.gcdMain {
                    if progressBlock != nil {
                        progressBlock!(progress)
                    }
                }
            }).response { response in
                switch response.result {
                case .success(_):
                    var requestStruct = PTBaseStructModel()
                    let jsonStr = response.data?.toDict()?.toJSON() ?? ""
                    requestStruct.originalString = jsonStr
                    requestStruct.resultData = response.data
                    
                    PTNSLogConsole("🌐接口请求成功回调🌐\n❤️1.请求地址 = \(pathUrl)\n💛2.result:\((!jsonStr.stringIsEmpty() ? jsonStr : ((response.data ?? Data()).string(encoding: .utf8)))!)🌐",levelType: PTLogMode,loggerType: .Network)

                    guard let modelType1 = modelType else {
                        continuation.resume(returning: requestStruct)
                        return
                    }
                    requestStruct.customerModel = jsonStr.kj.model(type: modelType1)
                    continuation.resume(returning: requestStruct)
                case .failure(let error):
                    PTNSLogConsole("❌❤️1.请求地址 =\(pathUrl)\n💛2.error:\(error)❌", levelType: .Error,loggerType: .Network)
                    continuation.resume(throwing:error)
                }
            }
        }
    }
    
    class open func fileDownLoad(fileUrl:String,saveFilePath:String,queue:DispatchQueue? = DispatchQueue.main,progress:FileDownloadProgress?) async throws -> Data {
        
        await withUnsafeContinuation { continuation in
            let download = Network()
            download.createDownload(fileUrl: fileUrl, saveFilePath: saveFilePath,queue: queue, progress: progress) { reponse in
                continuation.resume(returning: reponse.value!)
            } fail: { error in
                continuation.resume(throwing: error as! Never/*NSError(domain: error.debugDescription, code: 999) as! Never*/)
            }
        }
    }

    // 默认主线程
    public func createDownload(fileUrl:String,saveFilePath:String,queue:DispatchQueue? = DispatchQueue.main,progress:FileDownloadProgress?,success:FileDownloadSuccess?, fail:FileDownloadFail?) {
        
        self.fileUrl = fileUrl
        self.saveFilePath = saveFilePath
        self.success = success
        self.progress = progress
        self.fail = fail
        
        
        if !fileUrl.isURL() || fileUrl.stringIsEmpty() {
            if self.fail != nil {
                self.fail?(AFError.invalidURL(url: "https://www.qq.com"))
            }
            return
        }

        if queue != nil {
            self.queue = queue!
        }
        
        // 配置下载存储路径
        destination = {_,response in
            let saveUrl = URL(fileURLWithPath: saveFilePath)
            return (saveUrl,[.removePreviousFile, .createIntermediateDirectories] )
        }
        // 这里直接就开始下载了
        startDownloadFile()
    }
    
    // 暂停下载
    public func suspendDownload() {
        downloadRequest?.task?.suspend()
    }
    // 取消下载
    public func cancelDownload() {
        downloadRequest?.cancel()
        downloadRequest = nil;
        progress = nil
    }
    
    // 开始下载
    public func startDownloadFile() {
        if cancelledData != nil {
            downloadRequest = AF.download(resumingWith: cancelledData!, to: destination)
            downloadRequest?.downloadProgress { [weak self] (pro) in
                guard let `self` = self else {return}
                PTGCDManager.gcdMain {
                    self.progress?(pro.completedUnitCount,pro.totalUnitCount,pro.fractionCompleted)
                }
            }
            downloadRequest?.responseData(queue: queue, completionHandler: downloadResponse)
            
        } else if downloadRequest != nil {
            downloadRequest?.task?.resume()
        } else {
            downloadRequest = AF.download(fileUrl, to: destination)
            downloadRequest?.downloadProgress { [weak self] (pro) in
                guard let `self` = self else {return}
                PTGCDManager.gcdMain {
                    self.progress?(pro.completedUnitCount,pro.totalUnitCount,pro.fractionCompleted)
                }
            }
            
            downloadRequest?.responseData(queue: queue, completionHandler: downloadResponse)
        }
    }
    
    //根据下载状态处理
    private func downloadResponse(response:AFDownloadResponse<Data>) {
        switch response.result {
        case .success:
            if let data = response.value, data.count > 1000 {
                if success != nil{
                    PTGCDManager.gcdMain {
                        self.success?(response)
                    }
                }
            } else {
                PTGCDManager.gcdMain {
                    self.fail?(NetWorkDownloadError as Error)
                }
            }
        case .failure:
            cancelledData = response.resumeData//意外停止的话,把已下载的数据存储起来
            PTGCDManager.gcdMain {
                self.fail?(response.error)
            }
        }
    }
}

