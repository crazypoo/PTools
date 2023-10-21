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
                                taskHandle:(([UIImage])->Void)!) {
        if contentData is UIImage {
            taskHandle([(contentData as! UIImage)])
        } else if contentData is String {
            let dataUrlString = contentData as! String
            if FileManager.pt.judgeFileOrFolderExists(filePath: dataUrlString) {
                taskHandle([UIImage(contentsOfFile: dataUrlString)!])
            } else if dataUrlString.isURL() {
                if dataUrlString.contains("file://") {
                    if (iCloudDocumentName ?? "").stringIsEmpty() {
                        taskHandle([UIImage(contentsOfFile: dataUrlString)!])
                    } else {
                        if let icloudURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent(iCloudDocumentName!) {
                            let imageURL = icloudURL.appendingPathComponent(dataUrlString.lastPathComponent)
                            if let imageData = try? Data(contentsOf: imageURL) {
                                taskHandle([UIImage(data: imageData)!])
                            }
                        } else {
                            taskHandle([UIImage(contentsOfFile: dataUrlString)!])
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
                                taskHandle(frames)
                            } else {
                                taskHandle([value.image])
                            }
                        case .failure(let error):
                            PTNSLogConsole(error)
                            taskHandle([])
                        }
                    }
                }
            } else {
                taskHandle([UIImage(named: dataUrlString)!])
            }
        }
    }
}
