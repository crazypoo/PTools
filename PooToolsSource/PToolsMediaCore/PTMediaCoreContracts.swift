// English: MediaCore contains value-based contracts shared by media features.
// Español: MediaCore contiene contratos basados en valores compartidos por las funciones multimedia.
// 中文：MediaCore 提供媒体功能之间共享的值类型契约。

// English: CocoaPods aggregates legacy media declarations with this opt-in target; SPM keeps the Foundation-only contracts isolated, while CocoaPods uses the existing compatibility surface.
// Español: CocoaPods agrega las declaraciones multimedia heredadas con este target opcional; SPM mantiene aislados los contratos basados solo en Foundation y CocoaPods conserva la superficie compatible existente.
// 中文：CocoaPods 会把旧媒体声明与这个可选 target 聚合，因此 SPM 使用独立的 Foundation 契约，CocoaPods 保留现有兼容 API，避免重复符号。
#if !POOTOOLS_COCOAPODS

import Foundation

// English: A media resource is a Sendable descriptor; platform objects stay in feature adapters.
// Español: Un recurso multimedia es un descriptor Sendable; los objetos de plataforma permanecen en los adaptadores.
// 中文：媒体资源是 Sendable 描述符，平台对象留在具体功能适配器中。
public enum PTMediaResource: Hashable, Sendable {
    case data(Data)
    case localURL(URL)
    case remoteURL(URL)
    case photoAsset(identifier: String)
}

// English: Image sources are transport-neutral and do not require UIKit or a concrete loader.
// Español: Las fuentes de imagen son neutrales al transporte y no requieren UIKit ni un cargador concreto.
// 中文：图片来源与传输实现无关，不依赖 UIKit 或具体加载器。
public enum PTImageSource: Hashable, Sendable {
    case resource(PTMediaResource)
    case named(String)
}

// English: Video sources use the same resource descriptor as images for consistent adapters.
// Español: Las fuentes de vídeo usan el mismo descriptor de recurso que las imágenes para mantener adaptadores coherentes.
// 中文：视频来源复用图片相同的资源描述符，保证适配器行为一致。
public enum PTVideoSource: Hashable, Sendable {
    case resource(PTMediaResource)
}

// English: Progress crosses an async boundary as an immutable value snapshot.
// Español: El progreso cruza los límites asíncronos como una instantánea de valor inmutable.
// 中文：进度通过不可变值快照跨越异步边界。
public struct PTMediaProgressSnapshot: Hashable, Sendable {
    public let completedUnitCount: Int64
    public let totalUnitCount: Int64
    public let fractionCompleted: Double

    public init(completedUnitCount: Int64 = 0,
                totalUnitCount: Int64 = 0,
                fractionCompleted: Double = 0) {
        self.completedUnitCount = completedUnitCount
        self.totalUnitCount = totalUnitCount
        self.fractionCompleted = min(max(fractionCompleted, 0), 1)
    }
}

// English: Image loading options are stable values that can be copied into a task.
// Español: Las opciones de carga de imágenes son valores estables que pueden copiarse a una tarea.
// 中文：图片加载选项是可安全复制到任务中的稳定值。
public struct PTImageLoadingOptions: Hashable, Sendable {
    public let maximumPixelSize: Int?
    public let scale: Double
    public let allowsNetworkAccess: Bool

    public init(maximumPixelSize: Int? = nil,
                scale: Double = 1,
                allowsNetworkAccess: Bool = true) {
        self.maximumPixelSize = maximumPixelSize.map { max(1, $0) }
        self.scale = max(0.1, scale)
        self.allowsNetworkAccess = allowsNetworkAccess
    }
}

// English: The result keeps transport metadata typed and leaves image decoding to the UI layer.
// Español: El resultado mantiene metadatos tipados y deja la decodificación de imagen a la capa UI.
// 中文：结果使用类型化元数据，并将图片解码留给 UI 层。
public struct PTImageLoadResult: Sendable {
    public let data: Data
    public let isDegraded: Bool
    public let source: PTImageSource

    public init(data: Data, isDegraded: Bool = false, source: PTImageSource) {
        self.data = data
        self.isDegraded = isDegraded
        self.source = source
    }
}

// English: Media errors are transport-neutral so feature modules can map them to their own UI.
// Español: Los errores multimedia son neutrales al transporte para que cada función los adapte a su UI.
// 中文：媒体错误与传输实现无关，各功能模块可自行映射到 UI。
public enum PTMediaCoreError: Error, Equatable, Sendable {
    case unsupportedResource
    case resourceUnavailable
    case cancelled
    case invalidData
}

// English: Image adapters implement one async, cancellable contract.
// Español: Los adaptadores de imágenes implementan un único contrato asíncrono y cancelable.
// 中文：图片适配器统一实现一个支持异步和取消的契约。
public protocol PTImageLoading: Sendable {
    func load(_ source: PTImageSource,
              options: PTImageLoadingOptions) async throws -> PTImageLoadResult
}

// English: Video providers resolve descriptors without exposing AVFoundation to MediaCore.
// Español: Los proveedores de vídeo resuelven descriptores sin exponer AVFoundation a MediaCore.
// 中文：视频提供器解析资源描述符，但不让 MediaCore 暴露 AVFoundation。
public protocol PTVideoResourceProviding: Sendable {
    func resolve(_ source: PTVideoSource) async throws -> URL
}

// English: Thumbnail providers return encoded image data and accept a stable request identity.
// Español: Los proveedores de miniaturas devuelven datos de imagen codificados y aceptan una identidad estable.
// 中文：缩略图提供器返回编码后的图片数据，并接收稳定的请求标识。
public protocol PTThumbnailProviding: Sendable {
    func thumbnail(for source: PTVideoSource,
                   at time: TimeInterval,
                   maximumPixelSize: Int?) async throws -> Data
}

// English: Cache access is asynchronous and value-based, preventing feature modules from sharing mutable caches.
// Español: El acceso a la caché es asíncrono y basado en valores para evitar cachés mutables compartidas.
// 中文：缓存访问采用异步值类型接口，避免功能模块共享可变缓存。
public protocol PTMediaCaching: Sendable {
    func data(forKey key: String) async -> Data?
    func insert(_ data: Data, forKey key: String) async
    func removeValue(forKey key: String) async
}

// English: Cancellation is intentionally tiny so PhotoKit, URLSession, and AVFoundation adapters can conform.
// Español: La cancelación es deliberadamente pequeña para que los adaptadores de PhotoKit, URLSession y AVFoundation puedan adoptarla.
// 中文：取消协议保持最小化，方便 PhotoKit、URLSession 和 AVFoundation 适配器实现。
public protocol PTMediaCancellationToken: Sendable {
    var isCancelled: Bool { get }
    func cancel()
}
#endif
