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
    // English: Prefer the original file URL so GIF and other formats keep their source bytes.
    // Español: Prefiere la URL del archivo original para conservar los bytes de GIF y otros formatos.
    // 中文：优先读取原始文件 URL，保留 GIF 和其他格式的源数据。
    public static func fetchFromPicker(_ info: [UIImagePickerController.InfoKey : Any]) throws -> Self {
        if let url = info[.imageURL] as? URL {
            do {
                return try Self.init(contentsOf: url)
            } catch {
                throw PTImagePicker.PickerError.ObjConvertFaild(error)
            }
        }

        if let image = info[.originalImage] as? UIImage,
           let data = image.pngData() ?? image.jpegData(compressionQuality: 1) {
            return Self(data)
        }

        throw PTImagePicker.PickerError.ObjFetchFaild
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
    // English: Use the declared media type before falling back to legacy camera metadata.
    // Español: Usa el tipo multimedia declarado antes de recurrir a los metadatos heredados de la cámara.
    // 中文：先依据声明的媒体类型判断，再回退到旧相机 metadata。
    public static func fetchFromPicker(_ info: [UIImagePickerController.InfoKey : Any]) throws -> Self {
        let mediaType = info[.mediaType] as? String
        if let videoURL = info[.mediaURL] as? URL,
           let mediaType,
           mediaType != UTType.image.identifier,
           mediaType != UTType.livePhoto.identifier {
            return Self(imageData: nil, videoURL: videoURL)
        }

        if let imageData = try? Data.fetchFromPicker(info) {
            return Self(imageData: imageData, videoURL: nil)
        }

        if let videoURL = info[.mediaURL] as? URL {
            return Self(imageData: nil, videoURL: videoURL)
        }

        throw PTImagePicker.PickerError.ObjFetchFaild
    }
}

extension PTPhotoObject:PTImagePickerObject {
    // English: Camera results may not provide an image URL, so the URL remains optional.
    // Español: Los resultados de cámara pueden no proporcionar una URL de imagen, por eso la URL sigue siendo opcional.
    // 中文：相机结果可能没有图片 URL，因此这里保留 URL 可选。
    public static func fetchFromPicker(_ info: [UIImagePickerController.InfoKey : Any]) throws -> Self {
        let data = try Data.fetchFromPicker(info)
        guard let image = UIImage(data: data) else {
            throw PTImagePicker.PickerError.ObjConvertFaild(nil)
        }
        return Self.init(image: image, url: info[.imageURL] as? URL)
    }
}
