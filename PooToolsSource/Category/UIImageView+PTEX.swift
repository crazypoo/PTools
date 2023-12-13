//
//  UIImageView+PTEX.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/4.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import Kingfisher

public extension UIImageView {
    //MARK: 獲取圖片的某像素點的顏色
    ///獲取圖片的某像素點的顏色
    func getImagePointColor(point:CGPoint)->UIColor {
        let thumbSize = CGSize(width: image!.size.width, height: image!.size.height)

        // 当前点在图片中的相对位置
        let pInImage = CGPointMake(point.x * thumbSize.width / self.bounds.size.width,
                                   point.y * thumbSize.height / self.bounds.size.height)
        return image!.getImgePointColor(point: pInImage)
    }
    
    func pt_SDWebImage(imageString:String) {
        kf.setImage(with: URL.init(string: imageString),placeholder: PTAppBaseConfig.share.defaultPlaceholderImage,options: PTAppBaseConfig.share.gobalWebImageLoadOption())
    }
    
    func blur(withStyle style: UIBlurEffect.Style) {
        let blurEffect = UIBlurEffect(style: style)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(blurEffectView)
        clipsToBounds = true
    }
    
    func loadImage(contentData:Any,
                   iCloudDocumentName:String = "",
                   borderWidth:CGFloat = 1.5,
                   borderColor:UIColor = UIColor.purple,
                   showValueLabel:Bool = false,
                   valueLabelFont:UIFont = .appfont(size: 16,bold: true),
                   valueLabelColor:UIColor = .white,
                   uniCount:Int = 0,
                   emptyImage:UIImage = PTAppBaseConfig.share.defaultEmptyImage) {
        if contentData is UIImage {
            let image = (contentData as! UIImage)
            self.image = image
        } else if contentData is String {
            let dataUrlString = contentData as! String
            if FileManager.pt.judgeFileOrFolderExists(filePath: dataUrlString) {
                let image = UIImage(contentsOfFile: dataUrlString)!
                self.image = image
            } else if dataUrlString.isURL() {
                if dataUrlString.contains("file://") {
                    if iCloudDocumentName.stringIsEmpty() {
                        let image = UIImage(contentsOfFile: dataUrlString)!
                        self.image = image
                    } else {
                        if let icloudURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent(iCloudDocumentName) {
                            let imageURL = icloudURL.appendingPathComponent(dataUrlString.lastPathComponent)
                            if let imageData = try? Data(contentsOf: imageURL) {
                                let image = UIImage(data: imageData)!
                                self.image = image
                            }
                        } else {
                            let image = UIImage(contentsOfFile: dataUrlString)!
                            self.image = image
                        }
                    }
                } else {
                    ImageDownloader.default.downloadImage(with: URL(string: dataUrlString)!, options: PTAppBaseConfig.share.gobalWebImageLoadOption(),progressBlock: { receivedSize, totalSize in
                        PTGCDManager.gcdMain {
                            self.layerProgress(value: CGFloat((receivedSize / totalSize)),borderWidth: borderWidth,borderColor: borderColor,showValueLabel: showValueLabel,valueLabelFont:valueLabelFont,valueLabelColor:valueLabelColor,uniCount:uniCount)
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
                                self.image = UIImage.animatedImage(with: frames, duration: 2)
                            } else {
                                self.image = value.image
                            }
                        case .failure(let error):
                            PTNSLogConsole(error)
                            self.image = emptyImage
                        }
                    }
                }
            } else if dataUrlString.isSingleEmoji {
                let emojiImage = dataUrlString.emojiToImage()
                image = emojiImage
            } else {
                if let image = UIImage(named: dataUrlString) {
                    self.image = image
                } else if let systemImage = UIImage(systemName: dataUrlString) {
                    image = systemImage
                } else {
                    image = emptyImage
                }
            }
        } else if contentData is Data {
            let dataImage = UIImage(data: contentData as! Data)!
            image = dataImage
        } else {
            image = emptyImage
        }
    }
    
    //MARK: 視頻剪輯
    var frameForImageInImageViewAspectFit: CGRect {
        if  let img = self.image {
            let imageRatio = img.size.width / img.size.height
            let viewRatio = self.frame.size.width / self.frame.size.height
            if(imageRatio < viewRatio) {
                let scale = self.frame.size.height / img.size.height
                let width = scale * img.size.width
                let topLeftX = (self.frame.size.width - width) * 0.5
                return CGRect(x: topLeftX, y: 0, width: width, height: self.frame.size.height)
            } else {
                let scale = self.frame.size.width / img.size.width
                let height = scale * img.size.height
                let topLeftY = (self.frame.size.height - height) * 0.5
                return CGRect(x: 0, y: topLeftY, width: self.frame.size.width, height: height)
            }
        }
        return CGRect(x: 0, y: 0, width: 0, height: 0)
    }
    
    var imageFrame: CGRect {
        let imageViewSize = self.frame.size
        guard let imageSize = self.image?.size else { return CGRect.zero }
        let imageRatio = imageSize.width / imageSize.height
        let imageViewRatio = imageViewSize.width / imageViewSize.height
        if imageRatio < imageViewRatio {
            let scaleFactor = imageViewSize.height / imageSize.height
            let width = imageSize.width * scaleFactor
            let topLeftX = (imageViewSize.width - width) * 0.5
            return CGRect(x: topLeftX, y: 0, width: width, height: imageViewSize.height)
        } else {
            let scalFactor = imageViewSize.width / imageSize.width
            let height = imageSize.height * scalFactor
            let topLeftY = (imageViewSize.height - height) * 0.5
            return CGRect(x: 0, y: topLeftY, width: imageViewSize.width, height: height)
        }
    }

}
