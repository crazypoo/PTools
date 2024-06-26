//
//  PTCustomHTTPProtocol.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/27.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation
import SwiftDate

protocol PTCustomHTTPProtocolDelegate: AnyObject {
    func customHTTPProtocol(_ proto: PTCustomHTTPProtocol, didReceive response: URLResponse)
    func customHTTPProtocol(_ proto: PTCustomHTTPProtocol, didReceive data: Data)
    func customHTTPProtocolDidFinishLoading(_ proto: PTCustomHTTPProtocol)
    func customHTTPProtocol(_ proto: PTCustomHTTPProtocol, didFailWithError error: Error)
}

final class PTCustomHTTPProtocol: URLProtocol {
    private static let requestProperty = "com.custom.http.protocol"
    static var classDelegate: PTCustomHTTPProtocolDelegate?

    class func clearCache() {
        URLCache.customHttp.removeAllCachedResponses()
    }

    class func start() {
        URLProtocol.registerClass(self)
    }

    class func stop() {
        URLProtocol.unregisterClass(self)
    }

    private class func canServeRequest(_ request: URLRequest) -> Bool {
        if let _ = property(forKey: requestProperty, in: request) { return false }

        if let scheme = request.url?.scheme?.lowercased(), scheme == "http" || scheme == "https" {
            return true
        }
        return false
    }

    override class func canInit(with request: URLRequest) -> Bool {
        canServeRequest(request)
    }

    override class func canInit(with task: URLSessionTask) -> Bool {
        guard let request = task.currentRequest else { return false }
        return canServeRequest(request)
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    private var delegate: PTCustomHTTPProtocolDelegate? { PTCustomHTTPProtocol.classDelegate }

    private var session: URLSession?
    private var dataTask: URLSessionDataTask?
    private var cachePolicy: URLCache.StoragePolicy = .notAllowed
    private var data: Data = .init()
    private var didRetry = false
    private var didReceiveData = false
    private var startTime = Date()
    private var endTime: Date?
    private var response: HTTPURLResponse?
    private var error: Error?
    private var prevUrl: URL?
    private var prevStartTime: Date?

    private var threadOperator: PTThreadOperator?

    private func use(_ cache: CachedURLResponse) {
        delegate?.customHTTPProtocol(self, didReceive: cache.response)
        client?.urlProtocol(self, didReceive: cache.response, cacheStoragePolicy: .allowed)

        delegate?.customHTTPProtocol(self, didReceive: cache.data)
        client?.urlProtocol(self, didLoad: cache.data)

        delegate?.customHTTPProtocolDidFinishLoading(self)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func startLoading() {
        guard let newRequest = (request as NSObject).mutableCopy() as? NSMutableURLRequest else {
            fatalError("Can not convert to NSMutableURLRequest")
        }
        PTNetworkSpeedMonitor.shared.addUploadSpeed(0)
        URLProtocol.setProperty(true, forKey: PTCustomHTTPProtocol.requestProperty, in: newRequest)

        if let cache = URLCache.customHttp.validCache(for: request) {
            use(cache)

            if let name = request.url?.lastPathComponent {
                PTNSLogConsole("Use cache for \(name)")
            } else {
                PTNSLogConsole("Use cache")
            }
            return
        }

        PTNSLogConsole(request.requestId)
        threadOperator = PTThreadOperator()
        startTime = Date()
        prevUrl = request.url
        prevStartTime = startTime
        let config = URLSessionConfiguration.default
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        dataTask = session?.dataTask(with: newRequest as URLRequest)
        dataTask?.resume()
    }

    override func stopLoading() {
        dataTask?.cancel()

        if let task = dataTask {
            task.cancel()
            dataTask = nil
        }

        guard PTNetworkHelper.shared.isNetworkEnable else {
            return
        }

        var model = PTHttpModel()
        model.url = request.url
        model.method = request.httpMethod
        model.mineType = response?.mimeType

        if let requestBody = request.httpBody {
            model.requestData = requestBody
        }

        if let requestBodyStream = request.httpBodyStream {
            model.requestData = requestBodyStream.toData()
        }

        if let httpResponse = response {
            model.statusCode = "\(httpResponse.statusCode)"
        }

        model.responseData = data
        model.size = data.formattedSize()
        model.isImage = (response?.mimeType?.contains("image")) ?? false

        // Time
        let startTimeDouble = startTime.timeIntervalSince1970
        let endTimeDouble = Date().timeIntervalSince1970
        let durationDouble = abs(endTimeDouble - startTimeDouble)
        let formattedDuration = String(format: "%.4f", durationDouble)

        model.startTime = "\(startTime.dateFormat(formatString:"yyyy-MM-dd HH:mm:ss"))"
        model.endTime = "\(Date().dateFormat(formatString:"yyyy-MM-dd HH:mm:ss"))"
        model.totalDuration = "\(formattedDuration) (s)"

        model.errorDescription = error?.localizedDescription ?? ""
        model.errorLocalizedDescription = error?.localizedDescription ?? ""
        model.requestHeaderFields = request.allHTTPHeaderFields

        if let response {
            model.responseHeaderFields = response.allHeaderFields.convertKeysToString()
            model.responseHeaderFields?.updateValue(getCachePolicy(value: request.cachePolicy.rawValue), forKey: "Cache-Policy")
        }

        if let responseDate = model.endTime {
            model.responseHeaderFields?.updateValue(responseDate, forKey: "Response-Date")
        }

        if response?.mimeType == nil {
            model.isImage = false
        }

        if let urlString = model.url?.absoluteString, urlString.count > 4 {
            let str = String(urlString.suffix(4))
            if ["png", "PNG", "jpg", "JPG", "gif", "GIF"].contains(str) {
                model.isImage = true
            }
        }

        if let urlString = model.url?.absoluteString, urlString.count > 5 {
            let str = String(urlString.suffix(5))
            if ["jpeg", "JPEG"].contains(str) {
                model.isImage = true
            }
        }

        model.requestId = request.requestId
        model = PTErrorHelper.handle(error, model: model)
        if PTHttpDatasource.shared.addHttpRequest(model) {
            NotificationCenter.default.post(name: NSNotification.Name("reloadHttp_PooTools"), object: model.isSuccess)
        }
    }
}

extension PTCustomHTTPProtocol: URLSessionDataDelegate {
    func urlSession(_: URLSession, task _: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        threadOperator?.execute { [weak self] in
            guard let self else { return }
            PTNSLogConsole("willPerformHTTPRedirection")
            self.client?.urlProtocol(self, wasRedirectedTo: request, redirectResponse: response)
            self.response = response
            completionHandler(request)
        }
    }

    func urlSession( _ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        threadOperator?.execute { [weak self] in
            guard let self else { return }
            if let response = response as? HTTPURLResponse, let request = dataTask.originalRequest {
                self.cachePolicy = PTCacheStoragePolicy.cacheStoragePolicy(for: request, and: response)
            }
            self.delegate?.customHTTPProtocol(self, didReceive: response)
            self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: self.cachePolicy)
            self.response = response as? HTTPURLResponse
            self.endTime = Date()
                        
            if let requestData = dataTask.currentRequest?.httpBody {
                let elapsedTime = self.endTime!.timeIntervalSince(self.startTime)
                let uploadSpeed = Double(requestData.count) / elapsedTime
                PTNetworkSpeedMonitor.shared.addUploadSpeed(uploadSpeed)
            } else if let dataString = dataTask.currentRequest?.url?.absoluteString {
                let elapsedTime = self.endTime!.timeIntervalSince(self.startTime)
                let uploadSpeed = Double(dataString.data(using: .utf8)!.count) / elapsedTime
                PTNetworkSpeedMonitor.shared.addUploadSpeed(uploadSpeed)
            }
            completionHandler(.allow)
        }
    }

    func urlSession(_ session: URLSession, dataTask task: URLSessionDataTask, didReceive data: Data) {
        threadOperator?.execute { [weak self] in
            guard let self else { return }

            var hasAddedData = false
            if self.cachePolicy == .allowed {
                self.data.append(data)
                hasAddedData = true
            }

            self.delegate?.customHTTPProtocol(self, didReceive: data)
            self.client?.urlProtocol(self, didLoad: data)
            self.didReceiveData = true
            if prevUrl == response?.url, prevStartTime == startTime {
                if !hasAddedData { self.data.append(data) }
            } else {
                self.data = data
            }
            
            self.endTime = Date()
            if let endTime = self.endTime {
                let elapsedTime = endTime.timeIntervalSince(self.startTime)
                let downloadSpeed = Double(data.count) / elapsedTime
                PTNetworkSpeedMonitor.shared.addDownloadSpeed(downloadSpeed)
            }
        }
    }

    private func canRetry(error: NSError) -> Bool {
        guard error.code == Int(CFNetworkErrors.cfurlErrorNetworkConnectionLost.rawValue),
              !didRetry,
              !didReceiveData
        else {
            return false
        }

        PTNSLogConsole("Retry download...")
        return true
    }

    private func getCachePolicy(value: UInt?) -> String {
        switch value {
        case 0:
            return "useProtocolCachePolicy"
        case 1:
            return "reloadIgnoringLocalCacheData"
        case 4:
            return "reloadIgnoringLocalAndRemoteCacheData"
        case 3:
            return "returnCacheDataDontLoad"
        case 2:
            return "returnCacheDataElseLoad"
        case 5:
            return "reloadRevalidatingCacheData"
        default:
            return "reloadIgnoringCacheData"
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        threadOperator?.execute { [weak self] in
            guard let self else { return }
            if let error {
                self.error = error
                if self.canRetry(error: error as NSError), let request = task.originalRequest {
                    self.didRetry = true
                    self.dataTask = session.dataTask(with: request)
                    self.dataTask?.resume()
                    return
                }
                self.delegate?.customHTTPProtocol(self, didFailWithError: error)
                self.client?.urlProtocol(self, didFailWithError: error)
                return
            }

            self.delegate?.customHTTPProtocolDidFinishLoading(self)
            self.client?.urlProtocolDidFinishLoading(self)
            if self.cachePolicy == .allowed {
                PTNetworkSpeedMonitor.shared.downloadSpeeds.removeAll()
                PTNetworkSpeedMonitor.shared.addDownloadSpeed(0)
                PTNetworkSpeedMonitor.shared.uploadSpeeds.removeAll()
                PTNetworkSpeedMonitor.shared.addUploadSpeed(0)
                URLCache.customHttp.storeIfNeeded(for: task, data: self.data)
            }
        }
    }
}

public class PTNetworkSpeedMonitor {
    
    public static let shared = PTNetworkSpeedMonitor()
    
    public var downloadSpeeds: [Double] = []
    public var uploadSpeeds: [Double] = []
    
    private init() {}
    
    public func addDownloadSpeed(_ speed: Double) {
        downloadSpeeds.append(speed)
    }
    
    public func addUploadSpeed(_ speed: Double) {
        uploadSpeeds.append(speed)
    }
    
    public func averageDownloadSpeed() -> Double {
        return downloadSpeeds.reduce(0, +) / Double(downloadSpeeds.count)
    }
    
    public func averageUploadSpeed() -> Double {
        return uploadSpeeds.reduce(0, +) / Double(uploadSpeeds.count)
    }
}
