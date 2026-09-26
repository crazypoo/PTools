//
//  PTRichTextMedia.swift
//  PToolsUIFoundation
//
// English: Rich-media models, loaders and poster rendering for PTRichText.
// Español: Modelos multimedia, cargadores y renderizado de pósteres para PTRichText.
// 中文：PTRichText 的富媒体模型、加载器和封面渲染实现。
//

import Foundation
import UIKit
import AVFoundation

public struct PTTextAttachmentDescriptor: Codable, Hashable, Sendable {
    public enum Kind: Codable, Hashable, Sendable {
        case imageData(Data)
        case file(URL)
        case remote(URL)
        case viewProvider(String)
    }

    public let id: String
    public let kind: Kind
    public let size: CGSize
    public let accessibilityDescription: String?

    public init(id: String = UUID().uuidString,
                kind: Kind,
                size: CGSize,
                accessibilityDescription: String? = nil) {
        self.id = id
        self.kind = kind
        self.size = ptNormalizedAttachmentSize(size)
        self.accessibilityDescription = accessibilityDescription
    }
}

// English: Classify rich-text media without exposing player or transport objects to the value model.
// Español: Clasifica los medios de texto enriquecido sin exponer reproductores ni transportes al modelo de valor.
// 中文：对富文本媒体进行分类，但不让播放器和传输对象进入值模型。
public enum PTRichTextMediaKind: Sendable, Equatable {
    case image
    case video
}

// English: Keep playback ownership outside PTRichText while allowing a host to choose its presentation policy.
// Español: Mantiene la reproducción fuera de PTRichText y permite al host elegir su política de presentación.
// 中文：播放生命周期不归 PTRichText 所有，同时允许宿主选择展示策略。
public enum PTRichTextVideoPlaybackMode: Sendable {
    case callback
    case system
}

// English: Describe the media box without putting UIKit objects across an actor boundary.
// Español: Describe el contenedor multimedia sin transportar objetos UIKit entre actores.
// 中文：描述媒体容器，不让 UIKit 对象跨越 actor 边界。
@MainActor
public struct PTRichTextMediaDisplayConfiguration {
    public var preferredSize: CGSize?
    public var maxWidth: CGFloat?
    public var maxHeight: CGFloat?
    public var contentMode: UIView.ContentMode
    public var cornerRadius: CGFloat
    public var alignment: PTRichTextAttachmentAlignment
    public var estimatedAspectRatio: CGFloat?
    public var userInfo: [String: String]

    public init(preferredSize: CGSize? = nil,
                maxWidth: CGFloat? = nil,
                maxHeight: CGFloat? = nil,
                contentMode: UIView.ContentMode = .scaleAspectFit,
                cornerRadius: CGFloat = 0,
                alignment: PTRichTextAttachmentAlignment = .baseline,
                estimatedAspectRatio: CGFloat? = nil,
                userInfo: [String: String] = [:]) {
        self.preferredSize = preferredSize
        self.maxWidth = maxWidth
        self.maxHeight = maxHeight
        self.contentMode = contentMode
        self.cornerRadius = max(0, cornerRadius)
        self.alignment = alignment
        self.estimatedAspectRatio = estimatedAspectRatio
        self.userInfo = userInfo
    }

    func placeholderSize(fallback: CGSize = CGSize(width: 24, height: 24)) -> CGSize {
        if let preferredSize {
            return ptNormalizedAttachmentSize(preferredSize)
        }
        if let estimatedAspectRatio,
           estimatedAspectRatio.isFinite,
           estimatedAspectRatio > 0,
           let maxWidth,
           maxWidth.isFinite,
           maxWidth > 0 {
            return ptNormalizedAttachmentSize(CGSize(width: maxWidth,
                                                      height: maxWidth / estimatedAspectRatio))
        }
        return ptNormalizedAttachmentSize(fallback)
    }

    func resolvedSize(for image: UIImage,
                      naturalSize: CGSize? = nil) -> CGSize {
        let sourceSize = naturalSize ?? image.size
        guard sourceSize.width.isFinite,
              sourceSize.height.isFinite,
              sourceSize.width > 0,
              sourceSize.height > 0 else {
            return placeholderSize()
        }
        if let preferredSize {
            return ptNormalizedAttachmentSize(preferredSize)
        }

        var width = sourceSize.width
        var height = sourceSize.height
        if let maxWidth, maxWidth.isFinite, maxWidth > 0, width > maxWidth {
            let scale = maxWidth / width
            width = maxWidth
            height *= scale
        }
        if let maxHeight, maxHeight.isFinite, maxHeight > 0, height > maxHeight {
            let scale = maxHeight / height
            height = maxHeight
            width *= scale
        }
        return ptNormalizedAttachmentSize(CGSize(width: width, height: height))
    }
}

// English: Keep baseline alignment explicit so future renderers can add font-relative placement without changing the API.
// Español: Mantiene explícita la alineación de línea para que futuros renderizadores puedan añadir posición relativa a la fuente.
// 中文：显式保留基线对齐配置，后续渲染器可在不改 API 的情况下加入字体相对定位。
public enum PTRichTextAttachmentAlignment: Sendable {
    case baseline
    case center
    case top
    case bottom
}

// English: Image configuration is UI-bound and keeps compatibility metadata on the MainActor.
// Español: La configuración de imagen está ligada a la UI y mantiene los metadatos compatibles en MainActor.
// 中文：图片配置属于 UI 边界，兼容元数据始终停留在 MainActor。
@MainActor
public struct PTRichTextImageConfiguration {
    public var size: CGSize?
    public var maxSize: CGSize?
    public var placeholder: UIImage?
    public var failureImage: UIImage?
    public var contentMode: UIView.ContentMode
    public var cornerRadius: CGFloat
    public var alignment: PTRichTextAttachmentAlignment
    public var estimatedAspectRatio: CGFloat?
    public var accessibilityLabel: String?
    public var userInfo: [String: String]

    public init(size: CGSize? = nil,
                maxSize: CGSize? = nil,
                placeholder: UIImage? = nil,
                failureImage: UIImage? = nil,
                contentMode: UIView.ContentMode = .scaleAspectFit,
                cornerRadius: CGFloat = 0,
                alignment: PTRichTextAttachmentAlignment = .baseline,
                estimatedAspectRatio: CGFloat? = nil,
                accessibilityLabel: String? = nil,
                userInfo: [String: String] = [:]) {
        self.size = size
        self.maxSize = maxSize
        self.placeholder = placeholder
        self.failureImage = failureImage
        self.contentMode = contentMode
        self.cornerRadius = max(0, cornerRadius)
        self.alignment = alignment
        self.estimatedAspectRatio = estimatedAspectRatio
        self.accessibilityLabel = accessibilityLabel
        self.userInfo = userInfo
    }

    var display: PTRichTextMediaDisplayConfiguration {
        PTRichTextMediaDisplayConfiguration(preferredSize: size,
                                            maxWidth: maxSize?.width,
                                            maxHeight: maxSize?.height,
                                            contentMode: contentMode,
                                            cornerRadius: cornerRadius,
                                            alignment: alignment,
                                            estimatedAspectRatio: estimatedAspectRatio,
                                            userInfo: userInfo)
    }
}

// English: Video configuration describes a poster and interaction policy, never a player lifecycle.
// Español: La configuración de vídeo describe el póster y la interacción, nunca el ciclo de vida del reproductor.
// 中文：视频配置只描述封面和交互策略，不负责播放器生命周期。
@MainActor
public struct PTRichTextVideoConfiguration {
    public var size: CGSize?
    public var maxSize: CGSize?
    public var posterSource: Any?
    public var placeholder: UIImage?
    public var failureImage: UIImage?
    public var contentMode: UIView.ContentMode
    public var cornerRadius: CGFloat
    public var showsPlayIcon: Bool
    public var showsDuration: Bool
    public var thumbnailTime: CMTime?
    public var thumbnailFrameNumber: Int
    public var accessibilityLabel: String?
    public var playbackMode: PTRichTextVideoPlaybackMode
    public var estimatedAspectRatio: CGFloat?

    public init(size: CGSize? = nil,
                maxSize: CGSize? = nil,
                posterSource: Any? = nil,
                placeholder: UIImage? = nil,
                failureImage: UIImage? = nil,
                contentMode: UIView.ContentMode = .scaleAspectFill,
                cornerRadius: CGFloat = 0,
                showsPlayIcon: Bool = true,
                showsDuration: Bool = true,
                thumbnailTime: CMTime? = nil,
                thumbnailFrameNumber: Int = 10,
                accessibilityLabel: String? = nil,
                playbackMode: PTRichTextVideoPlaybackMode = .callback,
                estimatedAspectRatio: CGFloat? = 16.0 / 9.0) {
        self.size = size
        self.maxSize = maxSize
        self.posterSource = posterSource
        self.placeholder = placeholder
        self.failureImage = failureImage
        self.contentMode = contentMode
        self.cornerRadius = max(0, cornerRadius)
        self.showsPlayIcon = showsPlayIcon
        self.showsDuration = showsDuration
        self.thumbnailTime = thumbnailTime
        self.thumbnailFrameNumber = max(1, thumbnailFrameNumber)
        self.accessibilityLabel = accessibilityLabel
        self.playbackMode = playbackMode
        self.estimatedAspectRatio = estimatedAspectRatio
    }

    var display: PTRichTextMediaDisplayConfiguration {
        PTRichTextMediaDisplayConfiguration(preferredSize: size,
                                            maxWidth: maxSize?.width,
                                            maxHeight: maxSize?.height,
                                            contentMode: contentMode,
                                            cornerRadius: cornerRadius,
                                            alignment: .baseline,
                                            estimatedAspectRatio: estimatedAspectRatio)
    }
}

// English: Video metadata is an immutable snapshot safe for diagnostics and UI updates.
// Español: Los metadatos de vídeo son una instantánea inmutable segura para diagnósticos y UI.
// 中文：视频元数据是不可变快照，可安全用于诊断和 UI 更新。
public struct PTRichTextVideoMetadata: Sendable {
    public let duration: TimeInterval?
    public let naturalSize: CGSize?
    public let isLocal: Bool?

    public init(duration: TimeInterval? = nil,
                naturalSize: CGSize? = nil,
                isLocal: Bool? = nil) {
        self.duration = duration
        self.naturalSize = naturalSize
        self.isLocal = isLocal
    }
}

// English: Keep media failures typed so hosts can choose their own fallback UI.
// Español: Mantiene los fallos multimedia tipados para que cada host elija su UI de reserva.
// 中文：将媒体失败类型化，让宿主自行选择失败 UI。
public enum PTRichTextMediaError: Error, LocalizedError, Sendable {
    case unsupportedSource
    case imageLoadFailed
    case videoSourceInvalid
    case thumbnailGenerationFailed
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .unsupportedSource: return "不支持的媒体来源"
        case .imageLoadFailed: return "图片加载失败"
        case .videoSourceInvalid: return "视频来源无效"
        case .thumbnailGenerationFailed: return "视频缩略图生成失败"
        case .cancelled: return "媒体加载已取消"
        }
    }
}

// English: Media actions carry only a stable identifier, so raw Any sources never leave the MainActor store.
// Español: Las acciones multimedia solo llevan un identificador estable y nunca exponen fuentes Any fuera de MainActor.
// 中文：媒体动作只携带稳定 ID，原始 Any 来源不会离开 MainActor 存储。
public enum PTRichTextMediaAction: Sendable {
    case image(id: UUID)
    case video(id: UUID)
}

// English: Unify link and media callbacks without binding RichText to a player or browser module.
// Español: Unifica los callbacks de enlaces y medios sin acoplar RichText a un reproductor o navegador.
// 中文：统一链接和媒体回调，不让 RichText 绑定播放器或浏览器模块。
public enum PTRichTextInteraction: Sendable {
    case link(URL)
    case media(PTRichTextMediaAction)
}

public typealias PTRichTextInteractionHandler = @MainActor @Sendable (PTRichTextInteraction) -> Void

// English: Own a media source on MainActor and expose only immutable status to the renderer.
// Español: Posee la fuente multimedia en MainActor y expone al renderizador solo un estado controlado.
// 中文：在 MainActor 持有媒体来源，只向渲染器暴露受控状态。
@MainActor
public final class PTRichTextMediaAttachment {
    public let id: UUID
    public let kind: PTRichTextMediaKind
    public let source: Any
    public var posterSource: Any?
    public var displayConfiguration: PTRichTextMediaDisplayConfiguration
    public var metadata: PTRichTextVideoMetadata
    public var failureImage: UIImage?
    public var videoConfiguration: PTRichTextVideoConfiguration?
    public var accessibilityLabel: String?
    public var loadState: PTRichTextMediaLoadState = .idle
    public var generation: UInt64 = 0

    public init(id: UUID = UUID(),
                kind: PTRichTextMediaKind,
                source: Any,
                posterSource: Any? = nil,
                displayConfiguration: PTRichTextMediaDisplayConfiguration = .init(),
                metadata: PTRichTextVideoMetadata = .init(),
                failureImage: UIImage? = nil,
                videoConfiguration: PTRichTextVideoConfiguration? = nil,
                accessibilityLabel: String? = nil) {
        self.id = id
        self.kind = kind
        self.source = source
        self.posterSource = posterSource
        self.displayConfiguration = displayConfiguration
        self.metadata = metadata
        self.failureImage = failureImage
        self.videoConfiguration = videoConfiguration
        self.accessibilityLabel = accessibilityLabel
    }
}

// English: Track the lifecycle of one rich-media request without sharing mutable task state.
// Español: Sigue el ciclo de vida de una petición multimedia sin compartir estado mutable de tareas.
// 中文：跟踪单个富媒体请求的生命周期，不共享可变任务状态。
public enum PTRichTextMediaLoadState: Sendable {
    case idle
    case loading
    case loaded
    case failed
    case cancelled
}

// English: Return poster and metadata together so duration and aspect ratio do not require a second request.
// Español: Devuelve el póster y sus metadatos juntos para evitar una segunda petición de duración o proporción.
// 中文：同时返回封面和元数据，避免为时长和比例再次发起请求。
@MainActor
public struct PTRichTextVideoLoadResult {
    public let image: UIImage
    public let metadata: PTRichTextVideoMetadata

    public init(image: UIImage, metadata: PTRichTextVideoMetadata = .init()) {
        self.image = image
        self.metadata = metadata
    }
}

// English: Rendered text attachments retain the media identifier for tap dispatch and the media object for loading.
// Español: Los adjuntos renderizados conservan el identificador para taps y el objeto multimedia para cargar.
// 中文：渲染附件保留媒体 ID 用于点击分发，并保留媒体对象用于加载。
@MainActor
public final class PTRichTextMediaTextAttachment: NSTextAttachment {
    public let media: PTRichTextMediaAttachment
    public let attachmentSize: CGSize

    public init(media: PTRichTextMediaAttachment,
                image: UIImage?,
                size: CGSize) {
        self.media = media
        self.attachmentSize = ptNormalizedAttachmentSize(size)
        super.init(data: nil, ofType: nil)
        self.image = image
        bounds = CGRect(origin: .zero, size: attachmentSize)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    public func resolvedAttachment(with image: UIImage,
                                   size: CGSize? = nil) -> PTRichTextMediaTextAttachment {
        PTRichTextMediaTextAttachment(media: media,
                                      image: image,
                                      size: size ?? attachmentSize)
    }
}

// English: Store a typed remote URL beside its placeholder attachment for later MainActor replacement.
// Español: Guarda una URL remota tipada junto al adjunto de marcador para reemplazarlo después en MainActor.
// 中文：在占位附件旁保存类型化远程 URL，稍后由 MainActor 替换真实图片。
public final class PTRemoteImageTextAttachment: NSTextAttachment {
    public let identifier: String
    public let mediaID: UUID
    public let remoteURL: URL
    public let attachmentSize: CGSize

    public init(identifier: String,
                url: URL,
                size: CGSize,
                placeholder: UIImage? = nil,
                mediaID: UUID = UUID()) {
        self.identifier = identifier
        self.mediaID = mediaID
        self.remoteURL = url
        self.attachmentSize = ptNormalizedAttachmentSize(size)
        super.init(data: nil, ofType: nil)
        image = placeholder ?? PTRichTextMediaPlaceholder.image(video: false)
        bounds = CGRect(origin: .zero, size: attachmentSize)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    // English: Return a plain attachment so a resolved image never starts another remote load.
    // Español: Devuelve un adjunto normal para que una imagen resuelta no vuelva a iniciar una carga remota.
    // 中文：返回普通附件，避免真实图片设置后再次触发远程加载。
    public func resolvedAttachment(with image: UIImage) -> NSTextAttachment {
        let attachment = NSTextAttachment()
        attachment.image = image
        attachment.bounds = CGRect(origin: .zero, size: attachmentSize)
        return attachment
    }
}

// English: Draw dependency-free placeholders so the UI foundation remains independently buildable.
// Español: Dibuja marcadores sin dependencias para que la fundación UI siga siendo compilable por separado.
// 中文：使用无依赖绘制占位图，保证 UI Foundation 可以独立编译。
enum PTRichTextMediaPlaceholder {
    static func image(size: CGSize = CGSize(width: 24, height: 24), video: Bool) -> UIImage {
        let width = max(1, size.width.isFinite ? size.width : 24)
        let height = max(1, size.height.isFinite ? size.height : 24)
        return UIGraphicsImageRenderer(size: CGSize(width: width, height: height)).image { _ in
            let bounds = CGRect(x: 0, y: 0, width: width, height: height)
            UIColor.secondarySystemFill.setFill()
            UIBezierPath(roundedRect: bounds, cornerRadius: min(width, height) * 0.2).fill()
            guard video else { return }

            let triangleSize = min(width, height) * 0.32
            let triangle = UIBezierPath()
            triangle.move(to: CGPoint(x: bounds.midX - triangleSize * 0.35,
                                      y: bounds.midY - triangleSize * 0.5))
            triangle.addLine(to: CGPoint(x: bounds.midX + triangleSize * 0.55,
                                          y: bounds.midY))
            triangle.addLine(to: CGPoint(x: bounds.midX - triangleSize * 0.35,
                                          y: bounds.midY + triangleSize * 0.5))
            triangle.close()
            UIColor.secondaryLabel.setFill()
            triangle.fill()
        }
    }
}

// English: Keep every attachment dimension finite and positive before it reaches TextKit.
// Español: Mantiene cada dimensión del adjunto finita y positiva antes de llegar a TextKit.
// 中文：在进入 TextKit 前确保附件尺寸始终有限且为正数。
func ptNormalizedAttachmentSize(_ size: CGSize) -> CGSize {
    CGSize(width: size.width.isFinite && size.width > 0 ? size.width : 1,
           height: size.height.isFinite && size.height > 0 ? size.height : 1)
}

// English: The descriptor is a Sendable value; only its view factory executes on MainActor.
// Español: El descriptor es un valor Sendable; solo su fábrica de vistas se ejecuta en MainActor.
// 中文：描述符是 Sendable 值类型，只有 View 工厂在 MainActor 上执行。
public struct PTTextViewAttachmentDescriptor: Sendable {
    public let id: String
    public let size: CGSize
    public let accessibilityDescription: String?
    public let makeView: @MainActor @Sendable () -> UIView

    public init(id: String,
                size: CGSize,
                accessibilityDescription: String? = nil,
                makeView: @escaping @MainActor @Sendable () -> UIView) {
        self.id = id
        self.size = ptNormalizedAttachmentSize(size)
        self.accessibilityDescription = accessibilityDescription
        self.makeView = makeView
    }

    // English: Create a TextKit view provider only when the layout manager requests the attachment view.
    // Español: Crea el proveedor de vista TextKit solo cuando el gestor de layout solicita la vista del adjunto.
    // 中文：仅在 TextKit 布局管理器请求附件视图时创建 View Provider。
    @available(iOS 15.0, *)
    public func makeViewProvider(textAttachment: NSTextAttachment,
                                 parentView: UIView?,
                                 textLayoutManager: NSTextLayoutManager?,
                                 location: NSTextLocation) -> PTTextAttachmentViewProvider {
        PTTextAttachmentViewProvider(descriptor: self,
                                     textAttachment: textAttachment,
                                     parentView: parentView,
                                     textLayoutManager: textLayoutManager,
                                     location: location)
    }
}

// English: Keep custom attachment views lazy and sized by the immutable descriptor.
// Español: Mantiene las vistas de adjuntos personalizadas perezosas y dimensionadas por el descriptor inmutable.
// 中文：让自定义附件视图按需创建，并使用不可变描述符确定尺寸。
@available(iOS 15.0, *)
public final class PTTextAttachmentViewProvider: NSTextAttachmentViewProvider {
    private let descriptor: PTTextViewAttachmentDescriptor

    public init(descriptor: PTTextViewAttachmentDescriptor,
                textAttachment: NSTextAttachment,
                parentView: UIView?,
                textLayoutManager: NSTextLayoutManager?,
                location: NSTextLocation) {
        self.descriptor = descriptor
        super.init(textAttachment: textAttachment,
                   parentView: parentView,
                   textLayoutManager: textLayoutManager,
                   location: location)
        tracksTextAttachmentViewBounds = true
    }

    // English: UIKit invokes this callback on the main thread, but the SDK declaration is nonisolated.
    // Español: UIKit invoca este callback en el hilo principal, aunque la declaración del SDK no está aislada.
    // 中文：UIKit 会在主线程调用此回调，但 SDK 声明本身没有 MainActor 隔离。
    public override func loadView() {
        let descriptor = self.descriptor
        let attachmentView: UIView = MainActor.assumeIsolated {
            let attachmentView = descriptor.makeView()
            attachmentView.frame = CGRect(origin: .zero, size: descriptor.size)
            return attachmentView
        }
        view = attachmentView
    }

    public override func attachmentBounds(for attributes: [NSAttributedString.Key: Any],
                                          location: NSTextLocation,
                                          textContainer: NSTextContainer?,
                                          proposedLineFragment lineFrag: CGRect,
                                          position: CGPoint) -> CGRect {
        CGRect(origin: .zero, size: descriptor.size)
    }
}

public protocol PTTextImageLoader: Sendable {
    func image(for url: URL) async throws -> UIImage
}

// English: Keep the Core image pipeline injectable without making UI Foundation depend on Core.
// Español: Mantiene inyectable el canal de imágenes de Core sin hacer que UI Foundation dependa de Core.
// 中文：让 Core 图片管线可以注入，同时避免 UI Foundation 反向依赖 Core。
public typealias PTTextImageLoadHandler = @MainActor @Sendable (_ url: URL,
                                                                 _ targetSize: CGSize) async throws -> UIImage

public struct PTURLSessionTextImageLoader: PTTextImageLoader, Sendable {
    public init() {}

    public func image(for url: URL) async throws -> UIImage {
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode),
              let image = UIImage(data: data) else {
            throw URLError(.cannotDecodeContentData)
        }
        return image
    }
}

// English: Own remote attachment tasks by identifier and discard stale generations on reuse.
// Español: Posee las tareas de adjuntos remotos por identificador y descarta generaciones obsoletas al reutilizar.
// 中文：按标识符管理远程附件任务，并在复用时丢弃过期 generation 的结果。
@MainActor
public final class PTTextAttachmentCoordinator {
    private let imageLoader: PTTextImageLoadHandler
    private var tasks: [String: Task<Void, Never>] = [:]
    private var generations: [String: UInt64] = [:]

    public init(loader: any PTTextImageLoader = PTURLSessionTextImageLoader()) {
        imageLoader = { url, _ in
            try await loader.image(for: url)
        }
    }

    // English: Allow Core to inject PTLoadImageFunction without coupling UI Foundation back to Core.
    // Español: Permite que Core inyecte PTLoadImageFunction sin acoplar UI Foundation de vuelta a Core.
    // 中文：允许 Core 注入 PTLoadImageFunction，避免 UI Foundation 反向依赖 Core。
    public init(imageLoader: @escaping PTTextImageLoadHandler) {
        self.imageLoader = imageLoader
    }

    @discardableResult
    public func loadRemote(_ descriptor: PTTextAttachmentDescriptor,
                           completion: @escaping @MainActor @Sendable (Result<UIImage, Error>) -> Void) -> UInt64 {
        guard case .remote(let url) = descriptor.kind else { return 0 }
        cancel(id: descriptor.id)
        let generation = (generations[descriptor.id] ?? 0) &+ 1
        generations[descriptor.id] = generation
        let identifier = descriptor.id
        let imageLoader = self.imageLoader
        let targetSize = descriptor.size
        let task = Task { @MainActor [weak self, imageLoader, url, identifier, generation, targetSize] in
            do {
                let image = try await imageLoader(url, targetSize)
                guard !Task.isCancelled,
                      let self,
                      self.generations[identifier] == generation else { return }
                self.tasks[identifier] = nil
                completion(.success(image))
            } catch {
                guard !Task.isCancelled,
                      let self,
                      self.generations[identifier] == generation else { return }
                self.tasks[identifier] = nil
                completion(.failure(error))
            }
        }
        tasks[descriptor.id] = task
        return generation
    }

    public func cancel(id: String) {
        tasks[id]?.cancel()
        tasks[id] = nil
        generations[id, default: 0] &+= 1
    }

    public func cancelAll() {
        tasks.values.forEach { $0.cancel() }
        tasks.removeAll(keepingCapacity: false)
        generations.removeAll(keepingCapacity: false)
    }

    deinit {
        tasks.values.forEach { $0.cancel() }
    }
}

// English: Expose cancellation as a tiny host-owned token instead of exposing internal Task storage.
// Español: Expone la cancelación mediante un token pequeño propiedad del host, sin filtrar el almacenamiento Task.
// 中文：通过宿主持有的轻量 token 暴露取消能力，不泄漏内部 Task 存储。
@MainActor
public final class PTRichTextMediaLoadToken {
    private var task: Task<Void, Never>?

    init(task: Task<Void, Never>) {
        self.task = task
    }

    public func cancel() {
        task?.cancel()
        task = nil
    }

    deinit {
        task?.cancel()
    }
}

// English: Centralize image and video-poster loading while keeping source Any inside the MainActor UI boundary.
// Español: Centraliza la carga de imágenes y pósteres de vídeo manteniendo Any dentro del límite UI de MainActor.
// 中文：统一图片和视频封面加载，并让 Any 来源只停留在 MainActor UI 边界。
@MainActor
public final class PTRichTextMediaLoader {
    public typealias ImageLoader = @MainActor @Sendable (_ source: Any,
                                                          _ targetSize: CGSize?) async throws -> UIImage
    public typealias VideoPosterLoader = @MainActor @Sendable (_ source: Any,
                                                                _ frameNumber: Int,
                                                                _ time: CMTime?,
                                                                _ targetSize: CGSize?) async throws -> PTRichTextVideoLoadResult
    public typealias VideoMetadataLoader = @MainActor @Sendable (_ source: Any) async -> PTRichTextVideoMetadata

    private let imageLoader: ImageLoader
    private let videoPosterLoader: VideoPosterLoader
    private let videoMetadataLoader: VideoMetadataLoader
    private let imageCache = NSCache<NSString, UIImage>()
    private let posterCache = NSCache<NSString, UIImage>()
    private var imageTasks: [String: Task<UIImage, Error>] = [:]
    private var posterTasks: [String: Task<PTRichTextVideoLoadResult, Error>] = [:]

    public init(imageLoader: @escaping ImageLoader,
                videoPosterLoader: @escaping VideoPosterLoader,
                videoMetadataLoader: @escaping VideoMetadataLoader = { _ in .init() }) {
        self.imageLoader = imageLoader
        self.videoPosterLoader = videoPosterLoader
        self.videoMetadataLoader = videoMetadataLoader
        imageCache.countLimit = 100
        imageCache.totalCostLimit = 32 * 1024 * 1024
        posterCache.countLimit = 60
        posterCache.totalCostLimit = 24 * 1024 * 1024
    }

    public convenience init(loader: any PTTextImageLoader = PTURLSessionTextImageLoader()) {
        self.init(imageLoader: { source, _ in
            let url: URL?
            if let value = source as? URL {
                url = value
            } else if let value = source as? String {
                url = URL(string: value)
            } else {
                url = nil
            }
            guard let url else { throw PTRichTextMediaError.unsupportedSource }
            return try await loader.image(for: url)
        }, videoPosterLoader: { _, _, _, _ in
            throw PTRichTextMediaError.unsupportedSource
        })
    }

    public func clearCache() {
        imageCache.removeAllObjects()
        posterCache.removeAllObjects()
    }

    public func loadImage(source: Any,
                          targetSize: CGSize? = nil) async throws -> UIImage {
        let key = cacheKey(prefix: "image", source: source, targetSize: targetSize)
        if let cached = imageCache.object(forKey: key as NSString) {
            return cached
        }
        if let task = imageTasks[key] {
            return try await task.value
        }

        let loader = imageLoader
        let task = Task { @MainActor in
            try await loader(source, targetSize)
        }
        imageTasks[key] = task
        do {
            let image = try await task.value
            imageCache.setObject(image, forKey: key as NSString, cost: imageCost(image))
            imageTasks[key] = nil
            return image
        } catch {
            imageTasks[key] = nil
            throw error
        }
    }

    public func loadVideoPoster(source: Any,
                                frameNumber: Int = 10,
                                time: CMTime? = nil,
                                targetSize: CGSize? = nil) async throws -> PTRichTextVideoLoadResult {
        let key = cacheKey(prefix: "poster",
                           source: source,
                           targetSize: targetSize,
                           suffix: "frame:\(max(1, frameNumber))-time:\(time?.seconds ?? -1)")
        if let cached = posterCache.object(forKey: key as NSString) {
            return PTRichTextVideoLoadResult(image: cached)
        }
        if let task = posterTasks[key] {
            return try await task.value
        }

        let loader = videoPosterLoader
        let task = Task { @MainActor in
            try await loader(source, max(1, frameNumber), time, targetSize)
        }
        posterTasks[key] = task
        do {
            let result = try await task.value
            posterCache.setObject(result.image,
                                  forKey: key as NSString,
                                  cost: imageCost(result.image))
            posterTasks[key] = nil
            return result
        } catch {
            posterTasks[key] = nil
            throw error
        }
    }

    // English: Load metadata separately when a caller supplies a custom poster, avoiding redundant thumbnail generation.
    // Español: Carga los metadatos por separado cuando el caller proporciona un póster, evitando generar miniaturas de más.
    // 中文：调用方提供自定义封面时单独加载元数据，避免重复生成缩略图。
    public func loadVideoMetadata(source: Any) async -> PTRichTextVideoMetadata {
        await videoMetadataLoader(source)
    }

    @discardableResult
    public func loadImage(source: Any,
                          targetSize: CGSize? = nil,
                          completion: @escaping @MainActor @Sendable (Result<UIImage, PTRichTextMediaError>) -> Void) -> PTRichTextMediaLoadToken {
        let task = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                completion(.success(try await loadImage(source: source, targetSize: targetSize)))
            } catch is CancellationError {
                completion(.failure(.cancelled))
            } catch let error as PTRichTextMediaError {
                completion(.failure(error))
            } catch {
                completion(.failure(.imageLoadFailed))
            }
        }
        return PTRichTextMediaLoadToken(task: task)
    }

    @discardableResult
    public func loadVideoPoster(source: Any,
                                frameNumber: Int = 10,
                                time: CMTime? = nil,
                                targetSize: CGSize? = nil,
                                completion: @escaping @MainActor @Sendable (Result<PTRichTextVideoLoadResult, PTRichTextMediaError>) -> Void) -> PTRichTextMediaLoadToken {
        let task = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                completion(.success(try await loadVideoPoster(source: source,
                                                               frameNumber: frameNumber,
                                                               time: time,
                                                               targetSize: targetSize)))
            } catch is CancellationError {
                completion(.failure(.cancelled))
            } catch let error as PTRichTextMediaError {
                completion(.failure(error))
            } catch {
                completion(.failure(.thumbnailGenerationFailed))
            }
        }
        return PTRichTextMediaLoadToken(task: task)
    }

    private func cacheKey(prefix: String,
                          source: Any,
                          targetSize: CGSize?,
                          suffix: String = "") -> String {
        let sourceKey: String
        if let url = source as? URL {
            sourceKey = url.absoluteString
        } else if let string = source as? String {
            sourceKey = string
        } else if let object = source as AnyObject? {
            sourceKey = "object:\(ObjectIdentifier(object))"
        } else {
            sourceKey = String(describing: source)
        }
        let sizeKey = targetSize.map { "\($0.width)x\($0.height)" } ?? "auto"
        return "\(prefix):\(sourceKey):\(sizeKey):\(suffix)"
    }

    private func imageCost(_ image: UIImage) -> Int {
        let width = max(1, Int(image.size.width * image.scale))
        let height = max(1, Int(image.size.height * image.scale))
        return min(Int.max / 4, width * height * 4)
    }
}

// English: Compose a cached video poster so UILabel and UITextView can render the same static attachment.
// Español: Compone un póster de vídeo cacheado para que UILabel y UITextView rendericen el mismo adjunto estático.
// 中文：生成带缓存的视频封面，让 UILabel 和 UITextView 使用同一份静态附件。
@MainActor
public enum PTRichTextVideoPosterRenderer {
    private static let cache = NSCache<NSString, UIImage>()
    private static let memoryWarningObserver: NSObjectProtocol = NotificationCenter.default.addObserver(
        forName: UIApplication.didReceiveMemoryWarningNotification,
        object: nil,
        queue: .main
    ) { _ in
        Task { @MainActor in
            clearCache()
        }
    }

    public static func clearCache() {
        cache.removeAllObjects()
    }

    public static func render(image: UIImage,
                              metadata: PTRichTextVideoMetadata,
                              configuration: PTRichTextVideoConfiguration,
                              id: UUID) -> UIImage {
        _ = memoryWarningObserver
        let key = "\(id.uuidString):\(image.size.width)x\(image.size.height):\(configuration.cornerRadius):\(configuration.showsPlayIcon):\(configuration.showsDuration):\(metadata.duration ?? -1)"
        if let cached = cache.object(forKey: key as NSString) {
            return cached
        }

        let size = configuration.display.resolvedSize(for: image, naturalSize: metadata.naturalSize)
        let rendererFormat = UIGraphicsImageRendererFormat.preferred()
        rendererFormat.scale = max(1, image.scale)
        let rendered = UIGraphicsImageRenderer(size: size, format: rendererFormat).image { context in
            let bounds = CGRect(origin: .zero, size: size)
            let radius = min(configuration.cornerRadius, min(size.width, size.height) / 2)
            let path = UIBezierPath(roundedRect: bounds, cornerRadius: radius)
            path.addClip()

            let drawRect = aspectFitRect(image.size, in: bounds, mode: configuration.contentMode)
            image.draw(in: drawRect)

            if configuration.showsPlayIcon {
                let iconSize = min(size.width, size.height) * 0.3
                let iconRect = CGRect(x: bounds.midX - iconSize / 2,
                                      y: bounds.midY - iconSize / 2,
                                      width: iconSize,
                                      height: iconSize)
                UIColor.label.withAlphaComponent(0.92).setFill()
                UIBezierPath(ovalIn: iconRect).fill()
                let triangleSize = iconSize * 0.42
                let triangle = UIBezierPath()
                triangle.move(to: CGPoint(x: iconRect.midX - triangleSize * 0.3,
                                          y: iconRect.midY - triangleSize * 0.5))
                triangle.addLine(to: CGPoint(x: iconRect.midX + triangleSize * 0.55,
                                              y: iconRect.midY))
                triangle.addLine(to: CGPoint(x: iconRect.midX - triangleSize * 0.3,
                                              y: iconRect.midY + triangleSize * 0.5))
                triangle.close()
                UIColor.systemBackground.setFill()
                triangle.fill()
            }

            if configuration.showsDuration,
               let duration = metadata.duration,
               duration.isFinite,
               duration >= 0 {
                let title = Self.format(duration: duration)
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.monospacedDigitSystemFont(ofSize: 11, weight: .semibold),
                    .foregroundColor: UIColor.label
                ]
                let textSize = (title as NSString).size(withAttributes: attributes)
                let badgeSize = CGSize(width: textSize.width + 10, height: textSize.height + 6)
                let badgeRect = CGRect(x: bounds.maxX - badgeSize.width - 6,
                                       y: bounds.maxY - badgeSize.height - 6,
                                       width: badgeSize.width,
                                       height: badgeSize.height)
                UIColor.secondarySystemBackground.withAlphaComponent(0.82).setFill()
                UIBezierPath(roundedRect: badgeRect, cornerRadius: badgeRect.height / 2).fill()
                (title as NSString).draw(at: CGPoint(x: badgeRect.minX + 5,
                                                      y: badgeRect.minY + 3),
                                         withAttributes: attributes)
            }
            _ = context
        }
        cache.setObject(rendered, forKey: key as NSString)
        return rendered
    }

    private static func aspectFitRect(_ imageSize: CGSize,
                                      in bounds: CGRect,
                                      mode: UIView.ContentMode) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else { return bounds }
        switch mode {
        case .scaleAspectFill:
            let scale = max(bounds.width / imageSize.width, bounds.height / imageSize.height)
            let size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
            return CGRect(x: bounds.midX - size.width / 2,
                          y: bounds.midY - size.height / 2,
                          width: size.width,
                          height: size.height)
        case .center:
            return CGRect(x: bounds.midX - imageSize.width / 2,
                          y: bounds.midY - imageSize.height / 2,
                          width: imageSize.width,
                          height: imageSize.height)
        default:
            let scale = min(bounds.width / imageSize.width, bounds.height / imageSize.height)
            let size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
            return CGRect(x: bounds.midX - size.width / 2,
                          y: bounds.midY - size.height / 2,
                          width: size.width,
                          height: size.height)
        }
    }

    private static func format(duration: TimeInterval) -> String {
        let totalSeconds = Int(duration.rounded(.down))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return minutes >= 60
            ? String(format: "%d:%02d:%02d", minutes / 60, minutes % 60, seconds)
            : String(format: "%d:%02d", minutes, seconds)
    }
}
