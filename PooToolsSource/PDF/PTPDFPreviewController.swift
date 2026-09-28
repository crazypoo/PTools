// English: Native PDF preview owned by the PooToolsPDF module.
// Español: Vista previa PDF nativa propiedad del módulo PooToolsPDF.
// 中文：由 PooToolsPDF 模块拥有的原生 PDF 预览控制器。

#if canImport(UIKit) && canImport(PDFKit)
import UIKit
import PDFKit
import UniformTypeIdentifiers

@MainActor
public final class PTPDFPreviewController: UIViewController {
    public let url: URL
    private let pdfView = PDFView()

    public init(url: URL) throws {
        guard url.isFileURL,
              UTType(filenameExtension: url.pathExtension)?.conforms(to: .pdf) == true else {
            throw NSError(domain: "PooToolsPDF", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid PDF URL"])
        }
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { nil }

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
public extension PTPDFManager {
    static func makePreviewController(for url: URL) throws -> UIViewController {
        try PTPDFPreviewController(url: url)
    }
}
#endif
