// English: Selects the canonical PooToolsPDF bridge with a PDFKit compatibility fallback.
// Español: Selecciona el puente canónico PooToolsPDF con un fallback compatible basado en PDFKit.
// 中文：优先选择 PooToolsPDF canonical bridge，并保留 PDFKit 兼容回退。

#if canImport(UIKit) && canImport(PDFKit)
import UIKit
import PDFKit
#if SWIFT_PACKAGE
import PooToolsPDF
#else
#if canImport(PooToolsPDF)
import PooToolsPDF
#endif
#endif

@MainActor
public protocol PTDocumentPDFProviding {
    func canHandle(_ url: URL) -> Bool
    func makePreviewController(for url: URL) throws -> UIViewController
}

@MainActor
public struct PTDocumentPDFKitAdapter: PTDocumentPDFProviding {
    public init() {}
    public func canHandle(_ url: URL) -> Bool { PTDocumentPDFBridge.isPDF(url) }
    public func makePreviewController(for url: URL) throws -> UIViewController {
        try PTDocumentPDFBridge.makeViewController(for: url)
    }
}

@MainActor
public struct PTDocumentPooToolsPDFAdapter: PTDocumentPDFProviding {
    public init() {}
    public func canHandle(_ url: URL) -> Bool { PTDocumentPDFBridge.isPDF(url) }
    public func makePreviewController(for url: URL) throws -> UIViewController {
#if canImport(PooToolsPDF) || SWIFT_PACKAGE
        return try PTPDFManager.makePreviewController(for: url)
#else
        throw PTDocumentError.unavailable
#endif
    }
}

@MainActor
public extension PTDocumentPDFBridge {
    static func makeCanonicalViewController(for url: URL) throws -> UIViewController {
#if canImport(PooToolsPDF) || SWIFT_PACKAGE
        let pooToolsAdapter = PTDocumentPooToolsPDFAdapter()
        if pooToolsAdapter.canHandle(url) { return try pooToolsAdapter.makePreviewController(for: url) }
#endif
        return try PTDocumentPDFKitAdapter().makePreviewController(for: url)
    }
}
#endif
