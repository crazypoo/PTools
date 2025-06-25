//
//  PTFileBrowser.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 23/9/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import MobileCoreServices
#if POOTOOLS_NAVBARCONTROLLER
import ZXNavigationBar
#endif
import UniformTypeIdentifiers

public class PTFileBrowser: NSObject {
    
    public static let shared = PTFileBrowser()
    public var rootDirectoryPath = FileManager.pt.getFileDirectory(type: .Directory)
    
    lazy var navigationController: PTBaseNavControl = {
        let rootViewController = PTFileBrowserViewController()
        let navigation = PTBaseNavControl(rootViewController: rootViewController)
#if POOTOOLS_NAVBARCONTROLLER
        rootViewController.zx_navTitleColor = .black
#else
        navigation.navigationBar.barTintColor = .black
#endif
        return navigation
    }()
}

public extension PTFileBrowser {
    func start() {
        navigationController.dismiss(animated: false) {
            PTUtils.getCurrentVC().pt_present(self.navigationController, animated: true, completion: nil)
        }
    }

    func getFileType(filePath: URL?) -> PTFileType {
        guard let filePath = filePath else { return .unknown }
        if (filePath.lastPathComponent.hasPrefix(".")) {
            return .system
        } else if let utType = getFileUTType(filePath: filePath) {
            if utType.conforms(to: .directory) {
                return .folder
            } else if utType.conforms(to: .image) {
                return .image
            } else if utType.conforms(to: .movie) || utType.conforms(to: .video) {
                return .video
            } else if utType.conforms(to: .audio) {
                return .audio
            } else if utType.conforms(to: .application) || utType.conforms(to: .sourceCode) {
                return .application
            } else if utType.conforms(to: .zip) {
                return .zip
            } else if utType.conforms(to: .html) || utType.conforms(to: .url) || utType.conforms(to: .fileURL) {
                return .web
            } else if utType.identifier == "com.apple.log" {
                return .log
            } else if utType == .pdf {
                return .pdf
            } else if utType.conforms(to: .plainText) || utType == .rtf {
                return .txt
            } else {
                let identifier = utType.identifier
                if identifier == "org.openxmlformats.wordprocessingml.document" ||
                    identifier == "com.microsoft.word.doc" {
                    return .word
                } else if identifier == "org.openxmlformats.presentationml.presentation" ||
                            identifier == "com.microsoft.powerpoint.ppt" {
                    return .ppt
                } else if identifier == "org.openxmlformats.spreadsheetml.sheet" ||
                            identifier == "com.microsoft.excel.xls" {
                    return .excel
                } else if filePath.absoluteString.lowercased().hasSuffix(".db") {
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
    func getFileUTType(filePath: URL?) -> UTType? {
        guard let filePath = filePath else { return nil }
        
        // 如果是資料夾
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: filePath.path, isDirectory: &isDirectory),
           isDirectory.boolValue {
            return .folder
        }
        
        // 根據副檔名推斷 UTI
        let fileExt = filePath.pathExtension
        if let utType = UTType(filenameExtension: fileExt) {
            return utType
        }
        
        return nil
    }
}
