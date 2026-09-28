// English: Native document picking, security-scoped access, bookmarks and preview.
// Español: Selección de documentos nativa, acceso security-scoped, bookmarks y previsualización.
// 中文：原生文档选择、安全作用域访问、书签和预览能力。

import Foundation

#if canImport(UIKit)
import UIKit
import UniformTypeIdentifiers
import QuickLook
#endif

public struct PTDocumentRequest: Sendable, Codable, Hashable {
    public let allowedTypeIdentifiers: [String]
    public let allowsMultipleSelection: Bool
    public let shouldCopyImportedFiles: Bool

    public init(allowedTypeIdentifiers: [String] = [], allowsMultipleSelection: Bool = false, shouldCopyImportedFiles: Bool = false) {
        self.allowedTypeIdentifiers = allowedTypeIdentifiers; self.allowsMultipleSelection = allowsMultipleSelection; self.shouldCopyImportedFiles = shouldCopyImportedFiles
    }

    #if canImport(UniformTypeIdentifiers)
    public init(allowedContentTypes: [UTType] = [.item], allowsMultipleSelection: Bool = false, shouldCopyImportedFiles: Bool = false) {
        self.init(allowedTypeIdentifiers: allowedContentTypes.map(\.identifier), allowsMultipleSelection: allowsMultipleSelection, shouldCopyImportedFiles: shouldCopyImportedFiles)
    }

    public var allowedContentTypes: [UTType] { allowedTypeIdentifiers.compactMap(UTType.init(identifier:)) }
    #endif
}

public struct PTDocumentSelection: Sendable, Codable, Hashable {
    public let url: URL
    public let isImportedCopy: Bool
    public init(url: URL, isImportedCopy: Bool = false) { self.url = url; self.isImportedCopy = isImportedCopy }
}

public struct PTDocumentBookmark: Sendable, Codable, Hashable {
    public let identifier: String
    public let data: Data
    public let originalURL: URL
    public init(identifier: String, data: Data, originalURL: URL) { self.identifier = identifier; self.data = data; self.originalURL = originalURL }
}

public enum PTDocumentError: Error, LocalizedError, Sendable, Equatable {
    case unavailable
    case cancelled
    case invalidURL
    case securityScopeDenied
    case bookmarkStale
    case exportFailed(String)
    public var errorDescription: String? {
        switch self { case .unavailable: "Document services unavailable"; case .cancelled: "Document operation cancelled"; case .invalidURL: "Invalid document URL"; case .securityScopeDenied: "Security-scoped access denied"; case .bookmarkStale: "Document bookmark is stale"; case .exportFailed(let message): message }
    }
}

public enum PTDocumentAccess {
    public static func withSecurityScopedAccess<T>(_ url: URL, operation: (URL) throws -> T) throws -> T {
        let started = url.startAccessingSecurityScopedResource()
        guard started else { throw PTDocumentError.securityScopeDenied }
        defer { url.stopAccessingSecurityScopedResource() }
        return try operation(url)
    }

    public static func makeBookmark(for url: URL, identifier: String = UUID().uuidString) throws -> PTDocumentBookmark {
        guard url.isFileURL else { throw PTDocumentError.invalidURL }
        let data = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
        return PTDocumentBookmark(identifier: identifier, data: data, originalURL: url)
    }

    public static func resolve(_ bookmark: PTDocumentBookmark) throws -> (url: URL, isStale: Bool) {
        var stale = false
        let url = try URL(resolvingBookmarkData: bookmark.data, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &stale)
        return (url, stale)
    }
}

public actor PTDocumentBookmarkStore {
    private var values: [String: PTDocumentBookmark] = [:]
    public init() {}
    public func save(_ bookmark: PTDocumentBookmark) { values[bookmark.identifier] = bookmark }
    public func remove(identifier: String) { values.removeValue(forKey: identifier) }
    public func bookmark(identifier: String) -> PTDocumentBookmark? { values[identifier] }
    public func resolve(identifier: String) throws -> (url: URL, isStale: Bool)? {
        guard let bookmark = values[identifier] else { return nil }
        return try PTDocumentAccess.resolve(bookmark)
    }
}

public enum PTDocumentExport {
    public static func copy(_ sourceURL: URL, to destinationURL: URL, replaceExisting: Bool = true) throws -> URL {
        guard sourceURL.isFileURL, destinationURL.isFileURL else { throw PTDocumentError.invalidURL }
        let manager = FileManager.default
        try manager.createDirectory(at: destinationURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        if replaceExisting, manager.fileExists(atPath: destinationURL.path) { try manager.removeItem(at: destinationURL) }
        do { try manager.copyItem(at: sourceURL, to: destinationURL); return destinationURL }
        catch { throw PTDocumentError.exportFailed(error.localizedDescription) }
    }
}

#if canImport(UIKit)
@MainActor
public final class PTDocumentPickerCoordinator: NSObject, UIDocumentPickerDelegate {
    public static let shared = PTDocumentPickerCoordinator()
    private weak var presenter: UIViewController?
    private var completion: (@MainActor @Sendable ([PTDocumentSelection]) -> Void)?
    private var request: PTDocumentRequest?

    public func present(from presenter: UIViewController,
                        request: PTDocumentRequest = .init(),
                        completion: @escaping @MainActor @Sendable ([PTDocumentSelection]) -> Void) {
        self.presenter = presenter; self.request = request; self.completion = completion
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: request.allowedContentTypes.isEmpty ? [.item] : request.allowedContentTypes, asCopy: request.shouldCopyImportedFiles)
        picker.allowsMultipleSelection = request.allowsMultipleSelection; picker.delegate = self
        presenter.present(picker, animated: true)
    }

    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        let copy = request?.shouldCopyImportedFiles ?? false
        completion?(urls.map { PTDocumentSelection(url: $0, isImportedCopy: copy) }); clear()
    }

    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) { completion?([]); clear() }
    private func clear() { presenter = nil; completion = nil; request = nil }
}

@MainActor
public final class PTDocumentPreviewController: QLPreviewController, QLPreviewControllerDataSource {
    private let urls: [URL]
    public init(urls: [URL]) { self.urls = urls; super.init(nibName: nil, bundle: nil); dataSource = self }
    public required init?(coder: NSCoder) { urls = []; super.init(coder: coder); dataSource = self }
    public func numberOfPreviewItems(in controller: QLPreviewController) -> Int { urls.count }
    public func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem { urls[index] as NSURL }
}

@MainActor
public enum PTDocumentShareBridge {
    public static func present(items: [Any], from presenter: UIViewController, sourceView: UIView? = nil) {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let popover = controller.popoverPresentationController {
            popover.sourceView = sourceView ?? presenter.view; popover.sourceRect = (sourceView ?? presenter.view).bounds
        }
        presenter.present(controller, animated: true)
    }
}
#endif
