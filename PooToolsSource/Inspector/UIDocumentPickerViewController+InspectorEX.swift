//
//  UIDocumentPickerViewController+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import MobileCoreServices
#if swift(>=5.3)
import UniformTypeIdentifiers
#endif

public extension UIDocumentPickerViewController {
    
    /// Initializes the picker instance for opening a document from a remote location.
    static func forOpening(_ options: Option...) -> UIDocumentPickerViewController {
        guard let documentTypeOptions = options.documentTypeOptions else {
            fatalError("Please provide document types using `.documentTypes()`")
        }
        
        let viewController: UIDocumentPickerViewController = {
#if swift(>=5.3)
            return UIDocumentPickerViewController(forOpeningContentTypes: documentTypeOptions.uttypes, asCopy: options.asCopy)
#endif
        }()
        
        viewController.apply(documentPickerOptions: options)
        
        return viewController
    }
    
    /// Initializes the picker instance for importing a document from a remote location.
    static func forImporting(_ options: Option...) -> UIDocumentPickerViewController {
        guard let documentTypeOptions = options.documentTypeOptions else {
            fatalError("Please provide document types using `.documentTypes()`")
        }
        
        let viewController: UIDocumentPickerViewController = {
#if swift(>=5.3)
            return UIDocumentPickerViewController(forOpeningContentTypes: documentTypeOptions.uttypes, asCopy: options.asCopy)
#endif
        }()
        
        viewController.apply(documentPickerOptions: options)
        
        return viewController
    }
    
    /// Initializes the picker for exporting local files to an external location. The new locations will be returned using `didPickDocumentAtURLs:`.
    static func forExporting(_ options: Option...) -> UIDocumentPickerViewController {
        guard let urls = options.urls else {
            fatalError("Please provide urls using `.urls()`")
        }
        
        let viewController: UIDocumentPickerViewController = {
#if swift(>=5.3)
            return UIDocumentPickerViewController(forExporting: urls, asCopy: options.asCopy)
#endif
        }()
        
        viewController.apply(documentPickerOptions: options)
        
        return viewController
    }
    
    /// Initializes the picker for moving local files to an external location. The new locations will be returned using `didPickDocumentAtURLs:`.
    static func forMoving(_ options: Option...) -> UIDocumentPickerViewController {
        guard let urls = options.urls else {
            fatalError("Please provide urls using `.urls()`")
        }
        
        let viewController: UIDocumentPickerViewController = {
#if swift(>=5.3)
            return UIDocumentPickerViewController(forExporting: urls, asCopy: false)
#endif
        }()
        
        viewController.apply(documentPickerOptions: options)
        
        return viewController
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
                #if swift(>=5.0)
                self.shouldShowFileExtensions = shouldShowFileExtensions
                #endif
                
            case let .directoryURL(directoryURL):
                #if swift(>=5.0)
                self.directoryURL = directoryURL
                #endif
            
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
