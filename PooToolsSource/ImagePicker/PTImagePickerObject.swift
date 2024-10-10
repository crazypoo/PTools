//
//  PTImagePickerObject.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 5/1/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import UniformTypeIdentifiers

public protocol PTImagePickerObject {
    static func fetchFromPicker(_ info:[UIImagePickerController.InfoKey:Any]) throws -> Self
}

//MARK:媒體的URL
extension URL:PTImagePickerObject {
    public static func fetchFromPicker(_ info: [UIImagePickerController.InfoKey : Any]) throws -> Self {
        guard let url = info[.mediaURL] as? Self else {
            throw PTImagePicker.PickerError.ObjFetchFaild
        }
        return url
    }
}

//MARK:媒體的Data
extension Data:PTImagePickerObject {
    public static func fetchFromPicker(_ info: [UIImagePickerController.InfoKey : Any]) throws -> Self {
        guard let url = info[.imageURL] as? URL else {
            throw PTImagePicker.PickerError.ObjFetchFaild
        }
        do {
            return try Self.init(contentsOf: url)
        } catch {
            throw PTImagePicker.PickerError.ObjConvertFaild(error)
        }
    }
}

//MARK:媒體的Image
extension UIImage:PTImagePickerObject {
    public static func fetchFromPicker(_ info: [UIImagePickerController.InfoKey : Any]) throws -> Self {
        do {
            let data = try Data.fetchFromPicker(info)
            guard let image = Self.init(data: data) else {
                throw PTImagePicker.PickerError.ObjConvertFaild(nil)
            }
            return image
        } catch PTImagePicker.PickerError.ObjFetchFaild{
            guard let image = info[.originalImage] as? Self else {
                throw PTImagePicker.PickerError.ObjFetchFaild
            }
            return image
        }
    }
}

//MARK: 圖庫對象
public struct PTAlbumObject {
    ///圖片數據
    public let imageData:Data?
    ///視頻URL
    public let videoURL:URL?
}

public struct PTPhotoObject {
    ///圖片
    public let image:UIImage?
    ///圖片URL
    public let url:URL?
}

extension PTAlbumObject:PTImagePickerObject {
    public static func fetchFromPicker(_ info: [UIImagePickerController.InfoKey : Any]) throws -> Self {
        var imageData:Data?
        var videoURL:URL?
        if let mediaType = info[.mediaType] as? String,mediaType == UTType.image.identifier{
            imageData = try Data.fetchFromPicker(info)
        }
        else{
            videoURL = try URL.fetchFromPicker(info)
        }
        return Self.init(imageData: imageData, videoURL: videoURL)
    }
}

extension PTPhotoObject:PTImagePickerObject {
    public static func fetchFromPicker(_ info: [UIImagePickerController.InfoKey : Any]) throws -> Self {
        let data = try Data.fetchFromPicker(info)
        let imageUrl:URL = info[.imageURL] as! URL
        return Self.init(image: UIImage(data: data), url: imageUrl)
    }
}

