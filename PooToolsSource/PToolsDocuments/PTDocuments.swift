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
    public init(allowedContentTypes: [UTType], allowsMultipleSelection: Bool = false, shouldCopyImportedFiles: Bool = false) {
        self.init(allowedTypeIdentifiers: allowedContentTypes.map(\.identifier), allowsMultipleSelection: allowsMultipleSelection, shouldCopyImportedFiles: shouldCopyImportedFiles)
    }

    public var allowedContentTypes: [UTType] { allowedTypeIdentifiers.compactMap { UTType($0) } }
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
        #if os(macOS)
        let options: URL.BookmarkCreationOptions = [.withSecurityScope]
        #else
        let options: URL.BookmarkCreationOptions = []
        #endif
        let data = try url.bookmarkData(options: options, includingResourceValuesForKeys: nil, relativeTo: nil)
        return PTDocumentBookmark(identifier: identifier, data: data, originalURL: url)
    }

    public static func resolve(_ bookmark: PTDocumentBookmark) throws -> (url: URL, isStale: Bool) {
        var stale = false
        #if os(macOS)
        let options: URL.BookmarkResolutionOptions = [.withSecurityScope]
        #else
        let options: URL.BookmarkResolutionOptions = []
        #endif
        let url = try URL(resolvingBookmarkData: bookmark.data, options: options, relativeTo: nil, bookmarkDataIsStale: &stale)
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
public final class PTDocumentAccessLease {
    public let url: URL
    private var isAccessing = false

    public init(url: URL) {
        self.url = url
        if url.isFileURL { isAccessing = url.startAccessingSecurityScopedResource() }
    }

    public func stop() {
        guard isAccessing else { return }
        url.stopAccessingSecurityScopedResource()
        isAccessing = false
    }

    deinit {
        if isAccessing { url.stopAccessingSecurityScopedResource() }
    }
}

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
    private let accessLeases: [PTDocumentAccessLease]
    public init(urls: [URL]) {
        self.urls = urls
        self.accessLeases = urls.map(PTDocumentAccessLease.init)
        super.init(nibName: nil, bundle: nil)
        dataSource = self
    }
    public required init?(coder: NSCoder) {
        urls = []
        accessLeases = []
        super.init(coder: coder)
        dataSource = self
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        accessLeases.forEach { $0.stop() }
    }
    public func numberOfPreviewItems(in controller: QLPreviewController) -> Int { urls.count }
    public func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem { urls[index] as NSURL }
}

@MainActor
public enum PTDocumentShareResult: Sendable, Equatable {
    case completed(String?)
    case cancelled
    case failed(String)
}

@MainActor
public enum PTDocumentShareBridge {
    public static func present(items: [Any], from presenter: UIViewController, sourceView: UIView? = nil) {
        present(items: items, from: presenter, sourceView: sourceView, sourceRect: nil, barButtonItem: nil, completion: nil)
    }

    public static func present(items: [Any],
                               from presenter: UIViewController,
                               sourceView: UIView? = nil,
                               sourceRect: CGRect? = nil,
                               barButtonItem: UIBarButtonItem? = nil,
                               completion: (@MainActor @Sendable (PTDocumentShareResult) -> Void)? = nil) {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let popover = controller.popoverPresentationController {
            popover.barButtonItem = barButtonItem
            if barButtonItem == nil {
                if let view = sourceView ?? presenter.view {
                    popover.sourceView = view
                    popover.sourceRect = sourceRect ?? view.bounds
                } else {
                    completion?(.failed("分享缺少有效的弹出锚点"))
                    return
                }
            }
        }
        controller.completionWithItemsHandler = { activityType, completed, _, error in
            let result: PTDocumentShareResult
            if let error { result = .failed(error.localizedDescription) }
            else if completed { result = .completed(activityType?.rawValue) }
            else { result = .cancelled }
            Task { @MainActor in completion?(result) }
        }
        presenter.present(controller, animated: true)
    }

    public static func present(documents: [PTDocumentSelection],
                               from presenter: UIViewController,
                               sourceView: UIView? = nil,
                               sourceRect: CGRect? = nil,
                               barButtonItem: UIBarButtonItem? = nil,
                               completion: (@MainActor @Sendable (PTDocumentShareResult) -> Void)? = nil) {
        let leases = documents.map { PTDocumentAccessLease(url: $0.url) }
        let controller = UIActivityViewController(activityItems: documents.map(\.url), applicationActivities: nil)
        if let popover = controller.popoverPresentationController {
            popover.barButtonItem = barButtonItem
            if barButtonItem == nil {
                if let view = sourceView ?? presenter.view {
                    popover.sourceView = view
                    popover.sourceRect = sourceRect ?? view.bounds
                } else {
                    completion?(.failed("分享缺少有效的弹出锚点"))
                    leases.forEach { $0.stop() }
                    return
                }
            }
        }
        controller.completionWithItemsHandler = { activityType, completed, _, error in
            let result: PTDocumentShareResult
            if let error { result = .failed(error.localizedDescription) }
            else if completed { result = .completed(activityType?.rawValue) }
            else { result = .cancelled }
            Task { @MainActor in
                completion?(result)
                leases.forEach { $0.stop() }
            }
        }
        presenter.present(controller, animated: true)
    }

    public static func present(document: PTDocumentSelection,
                               from presenter: UIViewController,
                               sourceView: UIView? = nil,
                               completion: (@MainActor @Sendable (PTDocumentShareResult) -> Void)? = nil) {
        present(documents: [document], from: presenter, sourceView: sourceView, completion: completion)
    }
}
#endif
