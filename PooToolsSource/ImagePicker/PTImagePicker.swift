//
//  PTImagePicker.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 5/1/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import UniformTypeIdentifiers

public enum PTImagePicker {
    
    public enum PickerType {
        ///圖片
        case Photo
        ///視頻
        case Video
        ///選擇全部
        case All
        
        public var types:[String]{
            switch self{
            case .Photo:
                return [UTType.image.identifier,UTType.livePhoto.identifier]
            case .Video:
                return [UTType.movie.identifier,UTType.video.identifier]
            case .All:
                return [UTType.image.identifier,UTType.livePhoto.identifier,UTType.movie.identifier,UTType.video.identifier]
            }
        }
    }
    
    //MARK: Error
    public enum PickerError:Error{
        ///沒有Controller
        case NullParentViewController
        ///找不到對象
        case ObjFetchFaild
        ///對象轉換失敗
        case ObjConvertFaild(_ error:Error?)
        ///其他錯誤
        case Other(_ error:Error?)
        ///取消
        case UserCancel
        
        public func outPutLog(){
            switch self {
            case .NullParentViewController:
                PTNSLogConsole("沒有Controller",levelType: .error,loggerType: .media)
            case .ObjFetchFaild:
                PTNSLogConsole("找不到對象",levelType: .error,loggerType: .media)
            case let .ObjConvertFaild(error):
                PTNSLogConsole("對象轉換失敗:\(String(describing: error))",levelType: .error,loggerType: .media)
            case let .Other(error):
                PTNSLogConsole("其他錯誤:\(String(describing: error))",levelType: .error,loggerType: .media)
            case .UserCancel:
                PTNSLogConsole("用戶取消了",levelType: .error,loggerType: .media)
            }
        }
    }
    
    //MARK: PickerCompletion
    public typealias Completion<T: PTImagePickerObject> = @MainActor (_ result: Result<T, PTImagePicker.PickerError>) -> Void
}

//MARK: 控制器
extension PTImagePicker {
    public class Controller<T:PTImagePickerObject>:UIImagePickerController,UIImagePickerControllerDelegate,UINavigationControllerDelegate {
        //MARK: Block
        private var completion:PTImagePicker.Completion<T>? = nil
        
        deinit {
            PTNSLogConsole("PTImagePicker.controller deinit",levelType: PTLogMode,loggerType: .viewCycle)
        }
        
        public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let result:Result<T,PTImagePicker.PickerError>
            do {
                result = .success(try T.fetchFromPicker(info))
            } catch let pickerError as PTImagePicker.PickerError{
                result = .failure(pickerError)
            } catch {
                result = .failure(.Other(error))
            }
            
            completion?(result)
            dismiss(animated: true)
        }
        
        public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            completion?(.failure(.UserCancel))
            dismiss(animated: true)
        }
    }
}

private struct SendableBox<T>: @unchecked Sendable {
    let value: T
}

// MARK: - 控制器囘調
private extension PTImagePicker.Controller {
    
    @MainActor
    func pickObject(completion: @escaping PTImagePicker.Completion<T>) {
        self.completion = completion
    }
    
    // 🚀 终极修复 2：改造 async 桥接方法，使用 Box 进行装箱和拆箱
    @MainActor
    func pickObject() async throws -> T {
        // 让 continuation 传递我们的安全盒子 (SendableBox)
        let box = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<SendableBox<T>, Error>) in
            
            self.pickObject { result in
                switch result {
                case .success(let obj):
                    // 成功时：把非 Sendable 的 T (如 UIImage) 装进盒子里传递
                    continuation.resume(returning: SendableBox(value: obj))
                case .failure(let error):
                    // 失败时：错误类型通常天然是 Sendable 的，直接抛出
                    continuation.resume(throwing: error)
                }
            }
        }
        // 拆开盒子，返回真实的图片或数据对象
        return box.value
    }
}

// MARK: - 打開相冊
private extension PTImagePicker.Controller {
    static func showAlbumPicker<U>(mediaType: PTImagePicker.PickerType) throws -> PTImagePicker.Controller<U> {
        guard let parentVC = UIApplication.shared.delegate?.window??.rootViewController else {
            throw PTImagePicker.PickerError.NullParentViewController
        }
        let picker = PTImagePicker.Controller<U>()
        picker.modalPresentationStyle = .overFullScreen
        picker.mediaTypes = mediaType.types
        picker.videoQuality = .typeHigh
        picker.delegate = picker
        parentVC.present(picker, animated: true)
        return picker
    }
    
    static func showPhotographPicker() throws -> PTImagePicker.Controller<UIImage> {
        guard let parentVC = UIApplication.shared.delegate?.window??.rootViewController else {
            throw PTImagePicker.PickerError.NullParentViewController
        }
        let picker = PTImagePicker.Controller<UIImage>()
        picker.modalPresentationStyle = .overFullScreen
        picker.sourceType = .camera
        picker.delegate = picker
        parentVC.present(picker, animated: true)
        return picker
    }
}

//MARK: 打開相冊
extension PTImagePicker.Controller {
    @MainActor public static func openAlbum<U:PTImagePickerObject>(_ mediaType:PTImagePicker.PickerType) async throws -> U {
        let picker:PTImagePicker.Controller<U> = try showAlbumPicker(mediaType: mediaType)
        return try await picker.pickObject()
    }
    
    public static func openAlbum<F: PTImagePickerObject>(_ mediaType: PTImagePicker.PickerType, completion: @escaping PTImagePicker.Completion<F>) {
        do {
            let picker: PTImagePicker.Controller<F> = try showAlbumPicker(mediaType: mediaType)
            picker.pickObject(completion: completion)
        } catch let pickerError as PTImagePicker.PickerError {
            completion(.failure(pickerError))
        } catch {
            completion(.failure(.Other(error)))
        }
    }
}

// MARK: 圖片
extension PTImagePicker.Controller {
    public static func photograph() async throws -> UIImage {
        let picker = try showPhotographPicker()
        return try await picker.pickObject()
    }
    
    public static func photograph(completion: @escaping PTImagePicker.Completion<UIImage>) {
        do {
            let picker = try showPhotographPicker()
            picker.pickObject(completion: completion)
        } catch let pickerError as PTImagePicker.PickerError {
            completion(.failure(pickerError))
        } catch {
            completion(.failure(.Other(error)))
        }
    }
}

//MARK: 打開方式
extension PTImagePicker{
    /// Open album -> 圖片
    public static func openAlbum() async throws -> UIImage {
        try await PTImagePicker.Controller<UIImage>.openAlbum(.Photo)
    }
    
    /// Open album -> 圖片/GIF數據
    public static func openAlbum() async throws -> Data {
        try await PTImagePicker.Controller<Data>.openAlbum(.Photo)
    }
    
    /// Open album -> 視頻路徑
    public static func openAlbum() async throws -> URL {
        try await PTImagePicker.Controller<URL>.openAlbum(.Video)
    }
    
    /// Open album -> 圖片/GIF數據 or 視頻路徑
    @MainActor public static func openAlbum() async throws -> PTAlbumObject {
        try await PTImagePicker.Controller<PTAlbumObject>.openAlbum(.All)
    }
    
    /// Photograph -> 相机
    public static func photograph() async throws -> UIImage {
        try await PTImagePicker.Controller<UIImage>.photograph()
    }
    
    /// 圖片 圖片URL
    @MainActor public static func openAlbum() async throws -> PTPhotoObject {
        try await PTImagePicker.Controller<PTPhotoObject>.openAlbum(.Photo)
    }
}

// MARK: 閉包方式
extension PTImagePicker {
    /// Open album -> 圖片
    @MainActor public static func openAlbumForImage(completion: @escaping PTImagePicker.Completion<UIImage>) {
        PTImagePicker.Controller<UIImage>.openAlbum(.Photo, completion: completion)
    }
    
    /// Open album -> 圖片/GIF數據
    @MainActor public static func openAlbumForImageData(completion: @escaping PTImagePicker.Completion<Data>) {
        PTImagePicker.Controller<Data>.openAlbum(.Photo, completion: completion)
    }
    
    /// Open album -> 視頻路徑
    @MainActor public static func openAlbumForVideoURL(completion: @escaping PTImagePicker.Completion<URL>) {
        PTImagePicker.Controller<URL>.openAlbum(.Video, completion: completion)
    }
    
    /// Open album -> 圖片/GIF數據 or 視頻路徑
    @MainActor public static func openAlbumForObject(completion: @escaping PTImagePicker.Completion<PTAlbumObject>) {
        PTImagePicker.Controller<PTAlbumObject>.openAlbum(.All, completion: completion)
    }
    
    /// Photograph -> 圖片
    @MainActor public static func photograph(completion: @escaping PTImagePicker.Completion<UIImage>) {
        PTImagePicker.Controller<UIImage>.photograph(completion: completion)
    }
    
    /// Open album -> 圖片/URL
    @MainActor public static func openAlbumForImageObject(completion: @escaping PTImagePicker.Completion<PTPhotoObject>) {
        PTImagePicker.Controller<PTPhotoObject>.openAlbum(.Photo, completion: completion)
    }
}
