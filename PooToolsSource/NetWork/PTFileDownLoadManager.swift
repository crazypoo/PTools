//
//  PTFileDownLoadManager.swift
//  Diou
//
//  Created by ken lam on 2021/10/12.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit
import AFNetworking

@objcMembers
public class PTFileDownLoadManager: NSObject {
    class public func fileDownload(fileUrl:String,savePath:String,timeOut:TimeInterval,progress:((_ progress:Progress)->Void)?,completionHandler:((_ response:URLResponse?,_ filePath:URL?,_ error:Error?)->Void)?)
    {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true

        let configuration = URLSessionConfiguration.default
        let manager = AFHTTPSessionManager.init(sessionConfiguration: configuration)
        let url = URL.init(string: fileUrl)
        print("\(url!)")
        var requset = URLRequest.init(url: url!)
        requset.timeoutInterval = timeOut
        
        let task : URLSessionDownloadTask = manager.downloadTask(with: requset, progress: progress, destination: { targetPath, reponse in
            return (URL(string: String(format: "file://%@", savePath))?.appendingPathComponent(reponse.suggestedFilename!))!
        }, completionHandler: { cResponse,cFilepath,cEerror in
            if completionHandler != nil
            {
                completionHandler!(cResponse,cFilepath,cEerror)
            }
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        })
        task.resume()
    }
}
