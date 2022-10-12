//
//  Network.swift
//  MiniChatSwift
//
//  Created by 林勇彬 on 2022/5/21.
//  Copyright © 2022 九州所想. All rights reserved.
//

import UIKit
import Alamofire
import MBProgressHUD
import KakaJSON
import SwiftyJSON

public enum NetWorkStatus: String {
    case unknown      = "未知网络"
    case notReachable = "网络无连接"
    case wwan         = "2，3，4G网络"
    case wifi          = "wifi网络"
}

public enum NetWorkEnvironment: String {
    case Development  = "开发环境"
    case Test         = "测试环境"
    case Distribution = "生产环境"
}

public typealias ReslutClosure = (_ result: ResponseModel?,_ error: AFError?) -> Void
public typealias NetWorkStatusBlock = (_ NetWorkStatus: String, _ NetWorkEnvironment: String,_ NetworkStatusType:NetworkReachabilityManager.NetworkReachabilityStatus) -> Void
public typealias NetWorkErrorBlock = () -> Void
public typealias NetWorkServerStatusBlock = (_ result: ResponseModel) -> Void
public typealias UploadProgress = (_ progress: Progress) -> Void

public var PTBaseURLMode:NetWorkEnvironment
{
    guard let sliderValue = UserDefaults.standard.value(forKey: "AppServiceIdentifier") as? String else { return .Distribution }
    if sliderValue == "1" {
        return .Distribution
    }else if sliderValue == "2" {
        return .Test
    }else if sliderValue == "3" {
        return .Development
    }
    return .Distribution
}

// MARK: - 网络运行状态监听
public class XMNetWorkStatus {
    
    static let shared = XMNetWorkStatus()
    /// 当前网络环境状态
    private var currentNetWorkStatus: NetWorkStatus = .wifi
    /// 当前运行环境状态
    private var currentEnvironment: NetWorkEnvironment = .Test
    
    let reachabilityManager = Alamofire.NetworkReachabilityManager(host: "www.baidu.com")
    
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
            netWork(weakSelf.currentNetWorkStatus.rawValue, weakSelf.currentEnvironment.rawValue,status)
        })
    }
    
    ///监听网络运行状态
    public func obtainDataFromLocalWhenNetworkUnconnected(handle:((NetworkReachabilityManager.NetworkReachabilityStatus)->Void)?) {
        detectNetWork { (status, environment,statusType)  in
            PTNSLog("当前网络环境为-> \(status) 当前运行环境为-> \(environment)")
            if handle != nil
            {
                handle!(statusType)
            }
        }
    }
}


@objcMembers
public class Network: NSObject {
    
    static public let share = Network()
        
    static var header:HTTPHeaders?
    
    public var netRequsetTime:TimeInterval = 20
    public var serverAddress:String = ""
    public var serverAddress_dev:String = ""
    public var userToken:String = ""

    /// manager
    private static var manager: Session = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = Network.share.netRequsetTime
        return Session(configuration: configuration)
    }()
    
    /// manager
    public static var hud: MBProgressHUD = {
        let hud = MBProgressHUD.init(view: AppWindows!)
        AppWindows!.addSubview(hud)
        hud.show(animated: true)
        return hud
    }()
    
    //MARK: 服务器URL
    public class func gobalUrl() -> String
    {
        if UIApplication.applicationEnvironment() != .appStore
        {
            PTLocalConsoleFunction.share.pNSLog("PTBaseURLMode:\(PTBaseURLMode)")
            switch PTBaseURLMode {
            case .Development:
                let userDefaults_url = UserDefaults.standard.value(forKey: "UI_test_url")
                let url_debug:String = userDefaults_url == nil ? "" : (userDefaults_url as! String)
                if url_debug.isEmpty
                {
                    return Network.share.serverAddress_dev
                }
                else
                {
                    return url_debug
                }
            case .Test:
                return Network.share.serverAddress_dev
            case .Distribution:
                return Network.share.serverAddress
            }
        }
        else
        {
            return Network.share.serverAddress
        }
    }
    
    //JSONEncoding  JSON参数
    //URLEncoding    URL参数
    /// 项目总接口
    /// - Parameters:
    ///   - urlStr: url地址
    ///   - method: 方法类型，默认post
    ///   - parameters: 请求参数，默认nil
    ///   - modelType: 是否需要传入接口的数据模型，默认nil
    ///   - encoder: 编码方式，默认url编码
    ///   - showHud: 是否需要loading，默认true
    ///   - resultBlock: 方法回调
    class public func requestApi(urlStr:String,
                          method: HTTPMethod = .post,
                          parameters: Parameters? = nil,
                          modelType: Convertible.Type? = nil,
                          encoder:ParameterEncoding = URLEncoding.default,
                          showHud:Bool? = true,
                          jsonRequest:Bool? = false,
                          netWorkErrorBlock:NetWorkErrorBlock? = nil,
                          netWorkServerStatusBlock:NetWorkServerStatusBlock? = nil,
                          resultBlock: @escaping ReslutClosure){
        
        
        let urlStr = Network.gobalUrl() + urlStr
        
        // 判断网络是否可用
        if let reachabilityManager = XMNetWorkStatus.shared.reachabilityManager {
            if !reachabilityManager.isReachable {
                if netWorkErrorBlock != nil
                {
                    netWorkErrorBlock!()
                }
                return
            }
        }
        
        let token = Network.share.userToken
        if !token.stringIsEmpty() {
            header = HTTPHeaders.init(["token":token,"device":"iOS"])
            if jsonRequest!
            {
                header!["Content-Type"] = "application/json;charset=UTF-8"
                header!["Accept"] = "application/json"
            }
        }
        
        if showHud!{
            Network.hud.show(animated: true)
        }
        PTLocalConsoleFunction.share.pNSLog("😂😂😂😂😂😂😂😂😂😂😂😂\n❤️1.请求地址 = \(urlStr)\n💛2.参数 = \(parameters?.jsonString() ?? "没有参数")\n💙3.请求头 = \(header?.dictionary.jsonString() ?? "没有请求头")\n😂😂😂😂😂😂😂😂😂😂😂😂")
        PTUtils.showNetworkActivityIndicator(true)
        
        Network.manager.request(urlStr, method: method, parameters: parameters, encoding: encoder, headers: header).responseData { data in
            if showHud! {
                Network.hud.hide(animated: true)
            }
            PTUtils.showNetworkActivityIndicator(false)
            switch data.result {
            case .success(_):
                let json = JSON(data.value ?? "")
                guard let jsonStr = json.rawString(String.Encoding.utf8, options: JSONSerialization.WritingOptions.prettyPrinted) else { return }
                
                PTLocalConsoleFunction.share.pNSLog("😂😂😂😂😂😂😂😂😂😂😂😂\n❤️1.请求地址 = \(urlStr)\n💛2.result:\(jsonStr)\n😂😂😂😂😂😂😂😂😂😂😂😂")

                guard let responseModel = jsonStr.kj.model(ResponseModel.self) else { return }
                responseModel.originalString = jsonStr
                
                if netWorkServerStatusBlock != nil
                {
                    netWorkServerStatusBlock!(responseModel)
                }
                
                guard let modelType = modelType else { resultBlock(responseModel,nil); return }
                if responseModel.data is [String : Any] {
                    guard let reslut = responseModel.data as? [String : Any] else {resultBlock(responseModel,nil); return }
                    responseModel.data = reslut.kj.model(type: modelType)
                }else if responseModel.data is Array<Any> {
                    responseModel.datas = (responseModel.data as! Array<Any>).kj.modelArray(type: modelType)
                }

                resultBlock(responseModel,nil)

            case .failure(let error):
                PTLocalConsoleFunction.share.pNSLog("------------------------------------>\n接口:\(urlStr)\n----------------------出现错误----------------------\n\(String(describing: error.errorDescription))",error: true)
                resultBlock(nil,error)
            }
        }
    }
    
    /// 图片上传接口
    /// - Parameters:
    ///   - images: 图片集合
    ///   - progressBlock: 进度回调
    ///   - success: 成功回调
    ///   - failure: 失败回调
    class public func imageUpload(images:[UIImage]?,
                           path:String? = "/api/project/ossImg",
                           fileKey:String? = "images",
                           parmas:[String:String]? = nil,
                           netWorkErrorBlock:NetWorkErrorBlock? = nil,
                           progressBlock:UploadProgress? = nil,
                           resultBlock: @escaping ReslutClosure) {
        
        let pathUrl = Network.gobalUrl() + path!
        
        // 判断网络是否可用
        if let reachabilityManager = XMNetWorkStatus.shared.reachabilityManager {
            if !reachabilityManager.isReachable {
                if netWorkErrorBlock != nil
                {
                    netWorkErrorBlock!()
                }
                return
            }
        }
        
        let hud:MBProgressHUD = MBProgressHUD.showAdded(to: AppWindows!, animated: true)
        hud.show(animated: true)
        
        var headerDic = [String:String]()
        headerDic["device"] = "iOS"
        let token = Network.share.userToken
        if !token.stringIsEmpty()
        {
            headerDic["token"] = token
        }
        let requestHeaders = HTTPHeaders.init(headerDic)
        
        Network.manager.upload(multipartFormData: { (multipartFormData) in
            images?.enumerated().forEach { index,image in
                if let imgData = image.jpegData(compressionQuality: 0.2) {
                    multipartFormData.append(imgData, withName: fileKey!,fileName: "image_\(index).png", mimeType: "image/png")
                }
            }
            if parmas != nil
            {
                parmas?.keys.enumerated().forEach({ index,value in
                    multipartFormData.append(Data(parmas![value]!.utf8), withName: value)
                })
            }
        }, to: pathUrl,method: .post, headers: requestHeaders) { (result) in
        }
        .uploadProgress(closure: { (progress) in
            if progressBlock != nil
            {
                progressBlock!(progress)
            }
        })
        .response { response in
            hud.hide(animated: true)
            
            switch response.result {
            case .success(let result):
                guard let responseModel = result?.toDict()?.kj.model(ResponseModel.self) else { return }
                PTLocalConsoleFunction.share.pNSLog("😂😂😂😂😂😂😂😂😂😂😂😂\n❤️1.请求地址 = \(pathUrl)\n💛2.result:\(result!.toDict()!)\n😂😂😂😂😂😂😂😂😂😂😂😂")
                resultBlock(responseModel,nil)
            case .failure(let error):
                PTLocalConsoleFunction.share.pNSLog("😂😂😂😂😂😂😂😂😂😂😂😂\n❤️1.请求地址 =\(pathUrl)\n💛2.error:\(error)",error: true)
                resultBlock(nil,error)

            }
        }
    }
}

@objcMembers
public class PTFileDownloadApi: NSObject {
    
    public typealias FileDownloadProgress = (_ bytesRead:Int64,_ totalBytesRead:Int64,_ progrss:Double)->()
    public typealias FileDownloadSuccess = (_ reponse:Any)->()
    public typealias FileDownloadFail = (_ error:Error?)->()
    
    @objc public var fileUrl:String = ""
    @objc public var saveFilePath:String = "" // 文件下载保存的路径
    public var cancelledData : Data?//用于停止下载时,保存已下载的部分
    public var downloadRequest:DownloadRequest? //下载请求对象
    public var destination:DownloadRequest.Destination!//下载文件的保存路径
    
    public var progress:FileDownloadProgress?
    public var success:FileDownloadSuccess?
    public var fail:FileDownloadFail?
    
    private var queue:DispatchQueue = DispatchQueue.main
  
    // 默认主线程
    public convenience init(fileUrl:String,saveFilePath:String,queue:DispatchQueue? = DispatchQueue.main,progress:FileDownloadProgress?,success:FileDownloadSuccess?, fail:FileDownloadFail?) {
        
        self.init()
        self.fileUrl = fileUrl
        self.saveFilePath = saveFilePath
        self.success = success
        self.progress = progress
        self.fail = fail
        
        if queue != nil {
            self.queue = queue!
        }
        
        // 配置下载存储路径
        self.destination = {_,response in
            let saveUrl = URL(fileURLWithPath: saveFilePath)
            return (saveUrl,[.removePreviousFile, .createIntermediateDirectories] )
        }
        // 这里直接就开始下载了
        self.startDownloadFile()
    }
    
    // 暂停下载
    public func suspendDownload() {
        self.downloadRequest?.task?.suspend()
    }
    // 取消下载
    public func cancelDownload() {
        self.downloadRequest?.cancel()
        self.downloadRequest = nil;
        self.progress = nil
    }
    
    // 开始下载
    public func startDownloadFile() {
        if self.cancelledData != nil {
            self.downloadRequest = AF.download(resumingWith: self.cancelledData!, to: self.destination)
            self.downloadRequest?.downloadProgress { [weak self] (pro) in
                guard let `self` = self else {return}
                DispatchQueue.main.async {
                    self.progress?(pro.completedUnitCount,pro.totalUnitCount,pro.fractionCompleted)
                }
            }
            self.downloadRequest?.responseData(queue: queue, completionHandler: downloadResponse)
            
        }else if self.downloadRequest != nil {
            self.downloadRequest?.task?.resume()
        }else {
            self.downloadRequest = AF.download(fileUrl, to: self.destination)
            self.downloadRequest?.downloadProgress { [weak self] (pro) in
                guard let `self` = self else {return}
                DispatchQueue.main.async {
                    self.progress?(pro.completedUnitCount,pro.totalUnitCount,pro.fractionCompleted)
                }
            }
            
            self.downloadRequest?.responseData(queue: queue, completionHandler: downloadResponse)
        }
    }
    
    //根据下载状态处理
    private func downloadResponse(response:AFDownloadResponse<Data>){
        switch response.result {
        case .success:
            if let data = response.value, data.count > 1000 {
                if self.success != nil{
                    DispatchQueue.main.async {
                        self.success?(response)
                    }
                }
            }else {
                DispatchQueue.main.async {
                    self.fail?(NSError(domain: "文件下载失败", code: 12345, userInfo: nil) as Error)
                }
            }
        case .failure:
            self.cancelledData = response.resumeData//意外停止的话,把已下载的数据存储起来
            DispatchQueue.main.async {
                self.fail?(response.error)
            }
        }
    }
}
