//
//  UIDocumentPickerViewController+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

public extension UIDocumentPickerViewController {
    
    /// Initializes the picker instance for opening a document from a remote location.
    static func forOpening(_ options: Option...) -> UIDocumentPickerViewController {
        let documentTypeOptions = options.documentTypeOptions ?? UTTTypeOptions([.item])
        if options.documentTypeOptions == nil {
            // English: Keep the legacy convenience API safe by falling back to any document type.
            // Español: Mantiene segura la API de conveniencia heredada usando cualquier tipo de documento como reserva.
            // 中文：旧便捷 API 缺少类型时回退到任意文档类型，避免运行时崩溃。
            PTNSLogConsole("⚠️ [UIDocumentPicker] forOpening 未提供 documentTypes，已回退到 UTType.item。")
        }
        
        let viewController: UIDocumentPickerViewController = {
            return UIDocumentPickerViewController(forOpeningContentTypes: documentTypeOptions.uttypes, asCopy: options.asCopy)
        }()
        
        viewController.apply(documentPickerOptions: options)
        
        return viewController
    }
    
    /// Initializes the picker instance for importing a document from a remote location.
    static func forImporting(_ options: Option...) -> UIDocumentPickerViewController {
        let documentTypeOptions = options.documentTypeOptions ?? UTTTypeOptions([.item])
        if options.documentTypeOptions == nil {
            PTNSLogConsole("⚠️ [UIDocumentPicker] forImporting 未提供 documentTypes，已回退到 UTType.item。")
        }
        
        let viewController: UIDocumentPickerViewController = {
            return UIDocumentPickerViewController(forOpeningContentTypes: documentTypeOptions.uttypes, asCopy: options.asCopy)
        }()
        
        viewController.apply(documentPickerOptions: options)
        
        return viewController
    }
    
    /// Initializes the picker for exporting local files to an external location. The new locations will be returned using `didPickDocumentAtURLs:`.
    static func forExporting(_ options: Option...) -> UIDocumentPickerViewController {
        let urls = options.urls ?? []
        if options.urls == nil {
            PTNSLogConsole("⚠️ [UIDocumentPicker] forExporting 未提供 urls，已创建空导出列表。")
        }
        
        let viewController: UIDocumentPickerViewController = {
            return UIDocumentPickerViewController(forExporting: urls, asCopy: options.asCopy)
        }()
        
        viewController.apply(documentPickerOptions: options)
        
        return viewController
    }
    
    /// Initializes the picker for moving local files to an external location. The new locations will be returned using `didPickDocumentAtURLs:`.
    static func forMoving(_ options: Option...) -> UIDocumentPickerViewController {
        let urls = options.urls ?? []
        if options.urls == nil {
            PTNSLogConsole("⚠️ [UIDocumentPicker] forMoving 未提供 urls，已创建空移动列表。")
        }
        
        let viewController: UIDocumentPickerViewController = {
            return UIDocumentPickerViewController(forExporting: urls, asCopy: false)
        }()
        
        viewController.apply(documentPickerOptions: options)
        
        return viewController
    }
    
}

private extension Collection where Element == UIDocumentPickerViewController.Option {
    var asCopy: Bool {
        for option in self {
            if case let .asCopy(copy) = option {
                return copy
            }
        }
        return false
    }
    
    var documentTypeOptions: UTTTypeOptions? {
        var array = UTTTypeOptions()
        
        forEach { element in
            guard case let .documentTypes(typeOptions) = element else {
                return
            }
            
            typeOptions.forEach { typeOption in
                
                guard array.contains(typeOption) == false else {
                    return
                }
                
                array.append(typeOption)
            }
        }
        
        return array.isEmpty ? nil : array
    }
    
    var uttypes: [UTType]? {
        documentTypeOptions?.uttypes
    }
    
    var urls: [URL]? {
        for option in self {
            if case let .urls(urls) = option {
                return urls
            }
        }
        return nil
    }
}

public extension UIDocumentPickerViewController {
    
    func apply(documentPickerOptions: Option...) {
        apply(documentPickerOptions: documentPickerOptions)
    }
    
    func apply(documentPickerOptions: Options) {
        documentPickerOptions.forEach { option in
            switch option {
            case let .documentPickerDelegate(delegate):
                self.delegate = delegate
                
            case let .allowsMultipleSelection(allowsMultipleSelection):
                self.allowsMultipleSelection = allowsMultipleSelection
                
            case let .viewControllerOptions(viewControllerOptions):
                apply(viewControllerOptions: viewControllerOptions)
                
            case let .shouldShowFileExtensions(shouldShowFileExtensions):
                self.shouldShowFileExtensions = shouldShowFileExtensions
                
            case let .directoryURL(directoryURL):
                self.directoryURL = directoryURL
            
            // cases used on init only
            case .asCopy,
                 .documentTypes,
                 .urls:
                break
            }
        }
    }
    
    typealias Options = [Option]
    
    enum Option {
        /// An array of uniform type identifiers (UTIs) that uniquely identify a file’s type.
        case documentTypes(UTTTypeOptions)
        
        /// If true, the picker will give you access to a local copy of the document, otherwise you will have access to the original document.
        case asCopy(Bool)
        
        /// A Boolean value that determines whether the browser always shows file extensions.
        case shouldShowFileExtensions(Bool)
        
        /// The initial directory displayed by the document picker.
        case directoryURL(URL?)
        
        /// An object that adheres to the UIDocumentPickerDelegate protocol.
        case documentPickerDelegate(UIDocumentPickerDelegate?)
        
        /// A Boolean value that determines whether the user can select more than one document at a time.
        case allowsMultipleSelection(Bool)
        
        /// An array of documents to be exported or moved.
        case urls([URL])
        
        case viewControllerOptions(UIViewController.Options)
        
        // MARK: - Convenience
        
        public static func viewOptions(_ options: UIView.Option...) -> Self {
            .viewControllerOptions(.viewOptions(options))
        }
        
        /// An array of documents to be exported or moved.
        public static func urls(_ urls: URL...) -> Self {
            .urls(urls)
        }

        public static func viewControllerOptions(_ options: UIViewController.Option...) -> Self {
            .viewControllerOptions(options)
        }
        
        public static func popoverPresentationControllerOptions(_ options: UIPopoverPresentationController.Option...) -> Self {
            .viewControllerOptions(.popoverPresentationControllerOptions(options))
        }
        
        /// An array of uniform type identifiers (UTIs) that uniquely identify a file’s type.
        public static func documentTypes(_ options: UTTTypeOption...) -> Self {
            .documentTypes(options)
        }
    }
}

extension UIDocumentPickerViewController.Option {
    private var documentTypeOptions: UTTTypeOptions? {
        guard case let .documentTypes(typeOptions) = self else {
            return nil
        }
        return typeOptions
    }
}
