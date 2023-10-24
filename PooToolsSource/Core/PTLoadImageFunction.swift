//
//  PTLoadImageFunction.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 21/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import Kingfisher
import SwifterSwift

public class PTLoadImageFunction: NSObject {

    public class func loadImage(contentData:Any,
                                iCloudDocumentName:String? = "",
                                progressHandle:((_ receivedSize: Int64, _ totalSize: Int64)->Void)? = nil,
                                taskHandle:(([UIImage]?,UIImage?)->Void)!) {
        if contentData is UIImage {
            let image = (contentData as! UIImage)
            taskHandle([image],image)
        } else if contentData is String {
            let dataUrlString = contentData as! String
            if FileManager.pt.judgeFileOrFolderExists(filePath: dataUrlString) {
                let image = UIImage(contentsOfFile: dataUrlString)!
                taskHandle([image],image)
            } else if dataUrlString.isURL() {
                if dataUrlString.contains("file://") {
                    if (iCloudDocumentName ?? "").stringIsEmpty() {
                        let image = UIImage(contentsOfFile: dataUrlString)!
                        taskHandle([image],image)
                    } else {
                        if let icloudURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent(iCloudDocumentName!) {
                            let imageURL = icloudURL.appendingPathComponent(dataUrlString.lastPathComponent)
                            if let imageData = try? Data(contentsOf: imageURL) {
                                let image = UIImage(data: imageData)!
                                taskHandle([image],image)
                            }
                        } else {
                            let image = UIImage(contentsOfFile: dataUrlString)!
                            taskHandle([image],image)
                        }
                    }
                } else {
                    ImageDownloader.default.downloadImage(with: URL(string: dataUrlString)!, options: PTAppBaseConfig.share.gobalWebImageLoadOption(),progressBlock: { receivedSize, totalSize in
                        if progressHandle != nil {
                            progressHandle!(receivedSize,totalSize)
                        }
                    }) { result in
                        switch result {
                        case .success(let value):
                            if value.originalData.detectImageType() == .GIF {
                                let source = CGImageSourceCreateWithData(value.originalData as CFData, nil)
                                let frameCount = CGImageSourceGetCount(source!)
                                var frames = [UIImage]()
                                for i in 0...frameCount {
                                    let imageref = CGImageSourceCreateImageAtIndex(source!,i,nil)
                                    let imageName = UIImage.init(cgImage: (imageref ?? UIColor.clear.createImageWithColor().cgImage)!)
                                    frames.append(imageName)
                                }
                                taskHandle(frames,value.image)
                            } else {
                                taskHandle([value.image],value.image)
                            }
                        case .failure(let error):
                            PTNSLogConsole(error)
                            taskHandle([],nil)
                        }
                    }
                }
            } else {
                let image = UIImage(named: dataUrlString)!
                taskHandle([image],image)
            }
        }
    }
}
