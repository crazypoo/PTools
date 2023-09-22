//
//  PTFileBrowser.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 23/9/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import MobileCoreServices

public class PTFileBrowser: NSObject {
    
    public static let shared = PTFileBrowser()
    public var rootDirectoryPath = FileManager.pt.getFileDirectory(type: .Directory)
    
    lazy var navigationController: UINavigationController = {
        let rootViewController = PTFileBrowserViewController()
        let navigation = PTBaseNavControl(rootViewController: rootViewController)
        navigation.navigationBar.barTintColor = UIColor.white
        return navigation
    }()
}

public extension PTFileBrowser {
    func start() {
        self.navigationController.dismiss(animated: false) {
            PTUtils.getCurrentVC().present(self.navigationController, animated: true, completion: nil)
        }
    }

    func getFileType(filePath: URL?) -> PTFileType {
        guard let filePath = filePath else { return .unknown }
        if (filePath.lastPathComponent.hasPrefix(".")) {
            return .system
        } else if let utType = self.getFileUTType(filePath: filePath) {
            if UTTypeConformsTo(utType, kUTTypeDirectory) {
                return .folder
            } else if UTTypeConformsTo(utType, kUTTypeImage) {
                return .image
            } else if (UTTypeConformsTo(utType, kUTTypeVideo) || UTTypeConformsTo(utType, kUTTypeMovie) || UTTypeConformsTo(utType, kUTTypeMPEG4) || UTTypeConformsTo(utType, kUTTypeAVIMovie) || UTTypeConformsTo(utType, kUTTypeQuickTimeMovie)) {
                return .video
            } else if (UTTypeConformsTo(utType, kUTTypeAudio) || UTTypeConformsTo(utType, kUTTypeMP3) || UTTypeConformsTo(utType, kUTTypeMPEG4Audio)) {
                return .audio
            } else if UTTypeConformsTo(utType, kUTTypeApplication) || UTTypeConformsTo(utType, kUTTypeSourceCode) {
                return .application
            } else if (UTTypeConformsTo(utType, kUTTypeZipArchive) || UTTypeConformsTo(utType, kUTTypeGNUZipArchive) || UTTypeConformsTo(utType, kUTTypeBzip2Archive)) {
                return .zip
            } else if (UTTypeConformsTo(utType, kUTTypeHTML) || UTTypeConformsTo(utType, kUTTypeURL) || UTTypeConformsTo(utType, kUTTypeFileURL)) {
                return .web
            } else if UTTypeConformsTo(utType, kUTTypeLog) {
                return .log
            } else if UTTypeConformsTo(utType, kUTTypePDF) {
                return .pdf
            } else if UTTypeConformsTo(utType, kUTTypeText) || UTTypeConformsTo(utType, kUTTypeRTF) {
                return .txt
            } else {
                if UTTypeConformsTo(utType, "org.openxmlformats.wordprocessingml.document" as CFString) || UTTypeConformsTo(utType, "com.microsoft.word.doc" as CFString) {
                    return .word
                } else if UTTypeConformsTo(utType, "org.openxmlformats.presentationml.presentation" as CFString) || UTTypeConformsTo(utType, "com.microsoft.powerpoint.ppt" as CFString) {
                    return .ppt
                } else if UTTypeConformsTo(utType, "org.openxmlformats.spreadsheetml.sheet" as CFString) || UTTypeConformsTo(utType, "com.microsoft.excel.xls" as CFString) {
                    return .excel
                } else if filePath.pathExtension.lowercased() == "db" {
                    return .db
                } else {
                    return .unknown
                }
            }
        } else {
            return .unknown
        }
    }
}

private extension PTFileBrowser {
    func getFileUTType(filePath: URL?) -> CFString? {
        guard let filePath = filePath else { return nil }
        let fileExt = filePath.pathExtension
        if fileExt.isEmpty {
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: filePath.path, isDirectory: &isDirectory) {
                if isDirectory.boolValue {
                    return kUTTypeFolder
                }
            }
        }
        // 把文件转换成 Uniform Type Identifiers 后获取文件的 tag
        let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExt as CFString, nil)
        if let retainedValue = uti?.takeRetainedValue() {
            return retainedValue
        } else {
            return nil
        }
    }
}
