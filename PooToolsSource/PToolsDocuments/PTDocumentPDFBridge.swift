// English: Optional PDFKit bridge kept inside the document feature boundary.
// Español: Puente opcional de PDFKit mantenido dentro del límite de documentos.
// 中文：将可选 PDFKit 桥接限制在文档功能边界内。

#if canImport(UIKit) && canImport(PDFKit)
import UIKit
import PDFKit
import UniformTypeIdentifiers

@MainActor
public final class PTDocumentPDFViewController: UIViewController {
    public let url: URL
    private let pdfView = PDFView()

    public init(url: URL) throws {
        guard PTDocumentPDFBridge.isPDF(url) else { throw PTDocumentError.invalidURL }
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder: NSCoder) {
        return nil
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(pdfView)
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pdfView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pdfView.topAnchor.constraint(equalTo: view.topAnchor),
            pdfView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.document = PDFDocument(url: url)
    }
}

@MainActor
public enum PTDocumentPDFBridge {
    public static func isPDF(_ url: URL) -> Bool {
        guard url.isFileURL || url.scheme != nil else { return false }
        return UTType(filenameExtension: url.pathExtension)?.conforms(to: .pdf) == true ||
            url.pathExtension.caseInsensitiveCompare("pdf") == .orderedSame
    }

    public static func makeViewController(for url: URL) throws -> PTDocumentPDFViewController {
        try PTDocumentPDFViewController(url: url)
    }

    public static func previewController(for url: URL) throws -> PTDocumentPreviewController {
        guard isPDF(url) else { throw PTDocumentError.invalidURL }
        return PTDocumentPreviewController(urls: [url])
    }
}
#endif
