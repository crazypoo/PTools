//
//  PTNetworkSpeedTestFunction.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 13/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import KakaJSON

@objc public enum PTNetworkSpeedTestStateType:Int {
    case Download
    case Upload
    case Free
}

@objc public enum PTNetworkSpeedTestType:Int {
    case Download
    case Upload
    case Latency
}

@objcMembers
public class PTNetworkSpeedTestFunction: NSObject {
    public static let shared = PTNetworkSpeedTestFunction()
    
    fileprivate let fileBytes = 1024 * 1024 * 10
    
    public var netSpeedStateType:PTNetworkSpeedTestStateType = .Free
    
    fileprivate var downloadStartTime: CFAbsoluteTime?
    fileprivate var uploadStartTime: CFAbsoluteTime?
    fileprivate var totalBytesDownloaded: Int64 = 0
    fileprivate var totalBytesUploaded: Int64 = 0
    
    fileprivate var tapStartTime: CFAbsoluteTime?
    fileprivate var uploadTask: URLSessionUploadTask?
    fileprivate var downloadTask: URLSessionDataTask?

    fileprivate lazy var downloadValue:CGFloat = 0.00
    fileprivate lazy var uploadValue:CGFloat = 0.00
    fileprivate lazy var latencyValue:CGFloat = 0.00
    public lazy var netWorkName:String = ""
    
    public lazy var downloadValueArrs :[CGFloat] = []
    public lazy var uploadValueArrs :[CGFloat] = []
    
    public var downloadCurrentTask : ((CGFloat)->Void)?
    public var uploadCurrentTask : ((CGFloat)->Void)?
    public var valueUpdateTask:((PTNetworkSpeedTestType,CGFloat)->Void)?
    public var testDone:PTActionTask?
    
    public var downloadTestURL = "http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4"
    public var uploadTestURL = "https://www.googleapis.com/upload/drive/v3/files?uploadType=resumable"

    //MARK: 网络数据转换
    fileprivate func netFormula(value:CGFloat)->CGFloat {
        value / 125000
    }

    //MARK: 网络下载测试
    fileprivate func netSpeedDownLoad() {
        let url = URL(string: downloadTestURL)!
        let request = URLRequest(url: url)
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
        downloadTask = session.dataTask(with: request)
        downloadStartTime = CFAbsoluteTimeGetCurrent()
        downloadTask!.resume()
    }

    //MARK: 网络上传测试
    fileprivate func netSpeedUpload() {
        let url = URL(string: uploadTestURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let data = Data(count: fileBytes)
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
        uploadTask = session.uploadTask(with: request, from: data)
        uploadStartTime = CFAbsoluteTimeGetCurrent()
        uploadTask!.resume()
    }

    public func readyTest() {
        downloadValueArrs.removeAll()
        uploadValueArrs.removeAll()

        if tapStartTime == nil {
            tapStartTime = CFAbsoluteTimeGetCurrent()
        }
        netSpeedDownLoad()
        netSpeedStateType = .Download
    }
    
    public func suspendTest() {
        uploadTask?.suspend()
        downloadTask?.suspend()
        uploadTask = nil
        downloadTask = nil
    }
    
    public func saveHistory(jsonString:String) {
        let userHistoryModelString = PTCoreUserDefultsWrapper.NetworkSpeedTestFunctionHistoria
        if !userHistoryModelString.stringIsEmpty() {
            var userModelsStringArr = userHistoryModelString.components(separatedBy: "[,]")
            userModelsStringArr.append(jsonString)
            PTCoreUserDefultsWrapper.NetworkSpeedTestFunctionHistoria = userModelsStringArr.joined(separator: "[,]")
        } else {
            PTCoreUserDefultsWrapper.NetworkSpeedTestFunctionHistoria = jsonString
        }
    }
}

// MARK: URLSessionTaskDelegate && URLSessionTaskDelegate methods
extension PTNetworkSpeedTestFunction : URLSessionDataDelegate, URLSessionTaskDelegate {
    public func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        if task == downloadTask {
            let latency = (downloadStartTime! - tapStartTime!) * 1000
            latencyValue = latency
            PTNSLogConsole("Network latency: \(latency) ms",levelType: .Notice,loggerType: .Network)
            netSpeedUpload()
            netSpeedStateType = .Upload
            PTGCDManager.gcdMain {
                self.valueUpdateTask?(PTNetworkSpeedTestType.Latency,latency)
            }
        } else if task == uploadTask {
            
            if testDone != nil {
                PTGCDManager.gcdMain {
                    PTGCDManager.gcdGroup(label: "ValueDone", threadCount: 2, doSomeThing: { semaphore,group,index in
                        if index == 0 {
                            PTGCDManager.gcdAfter(time: 0.35) {
                                self.valueUpdateTask?(PTNetworkSpeedTestType.Download,self.downloadValue)
                                semaphore.signal()
                                group.leave()
                            }
                        } else if index == 1 {
                            PTGCDManager.gcdAfter(time: 0.35) {
                                self.valueUpdateTask?(PTNetworkSpeedTestType.Upload,self.uploadValue)
                                semaphore.signal()
                                group.leave()
                            }
                        }
                    }, jobDoneBlock: {
                        self.testDone!()
                        let historyModel = PTNetworkSpeedHistoriaModel()
                        historyModel.download = String(format: "%.2f", self.downloadValue)
                        historyModel.upload = String(format: "%.2f", self.uploadValue)
                        historyModel.latency = String(format: "%.2f", self.latencyValue)
                        historyModel.networkType = self.netWorkName
                        historyModel.date = Date().toString()
                        
                        let jsonString = historyModel.kj.JSONString(prettyPrinted: true)
                        PTNSLogConsole(jsonString,levelType: .Notice,loggerType: .Network)
                        self.saveHistory(jsonString: jsonString)
                        self.netSpeedStateType = .Free
                    })
                }
            }
        }
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if downloadStartTime == nil {
            downloadStartTime = CFAbsoluteTimeGetCurrent()
        }
        totalBytesDownloaded += Int64(data.count)
        let elapsedTime = CFAbsoluteTimeGetCurrent() - downloadStartTime!
        let currentSpeed = Double(totalBytesDownloaded) / elapsedTime
        PTNSLogConsole("Current download speed: \(currentSpeed) bytes/sec",levelType: .Notice,loggerType: .Network)
        let liveSpeed = self.netFormula(value: currentSpeed)
        downloadValue = self.netFormula(value: currentSpeed)
        downloadValueArrs.append(liveSpeed)
        downloadCurrentTask?(downloadValue)
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        if uploadStartTime == nil {
            uploadStartTime = CFAbsoluteTimeGetCurrent()
        }
        totalBytesUploaded = totalBytesSent
        PTNSLogConsole("totalBytesUploaded: \(totalBytesSent)",levelType: .Notice,loggerType: .Network)
        let elapsedTime = CFAbsoluteTimeGetCurrent() - uploadStartTime!
        let currentSpeed = Double(totalBytesUploaded) / elapsedTime
        PTNSLogConsole("Current upload speed: \(currentSpeed) bytes/sec",levelType: .Notice,loggerType: .Network)
        let liveSpeed = self.netFormula(value: currentSpeed)
        uploadValue = self.netFormula(value: currentSpeed)
        downloadValueArrs.append(liveSpeed)
        uploadCurrentTask?(liveSpeed)
    }
}
