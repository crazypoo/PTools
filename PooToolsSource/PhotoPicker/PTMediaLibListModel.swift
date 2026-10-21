//
//  PTMediaLibListModel.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 28/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import Photos

#if SWIFT_PACKAGE
import ptools
import PooToolsImagePicker
#endif

// English: Keep one PhotoKit change fact on MainActor before any UI snapshot is published.
// Español: Mantiene un único hecho de cambio de PhotoKit en MainActor antes de publicar un snapshot de UI.
// 中文：在发布 UI 快照前，先在 MainActor 保存一份唯一的 PhotoKit 变化事实。
struct PTMediaAlbumChangeTransaction: Sendable {
    let albumIdentifier: String
    let generation: UInt64
    let oldRevision: UInt64
    let newRevision: UInt64
    let oldCount: Int
    let newCount: Int
    let insertedIDs: [String]
    let removedIDs: [String]
    let changedIDs: [String]
    let movedIDs: [String]
    let orderedIDs: [String]
    let oldModeledResultOffset: Int
    let oldWasFullyModeled: Bool
}

struct PTMediaModelProjectionMetrics: Sendable, Equatable {
    let reusedCount: Int
    let createdCount: Int
    let removedCount: Int
}

@MainActor
public class PTMediaLibListModel: NSObject {
    public let title: String
    
    public var count: Int {
        result.count
    }
    
    public var result: PHFetchResult<PHAsset>
    
    public let collection: PHAssetCollection
    
    public let option: PHFetchOptions
    
    public let isCameraRoll: Bool

    // English: Store the picker behavior with the album so refetches never read mutable global settings.
    // Español: Guarda el comportamiento del selector con el álbum para que las recargas nunca lean ajustes globales mutables.
    // 中文：将选择器行为和相册一起保存，重新获取时不再读取可变的全局配置。
    public let selectionOptions: PTMediaLibSelectionOptions
    
    public var headImageAsset: PHAsset? {
        result.lastObject
    }
    
    public var models: [PTMediaModel] = []

    // English: Expose a monotonic content revision so the picker can reject identical album snapshots.
    // Español: Expone una revisión monótona para que el selector rechace instantáneas de álbum idénticas.
    // 中文：提供单调递增的内容版本，Picker 可以直接跳过完全相同的相册快照。
    public private(set) var contentRevision: UInt64 = 0

    private var resultSignature: String
    private var modeledResultSignature: String?
    private var modelsSignature = ""
    private var nextResultOffset = 0
    private var resultChangeGeneration: UInt64 = 0

    // English: Keep initial PhotoKit work bounded so the first screen does not build every row synchronously.
    // Español: Mantiene acotado el trabajo inicial de PhotoKit para no construir todas las filas de forma síncrona.
    // 中文：限制首次 PhotoKit 工作量，避免同步构建全部 Row 阻塞首屏。
    private let initialBatchSize = 96
    private let subsequentBatchSize = 160

    var isFullyModeled: Bool { nextResultOffset >= result.count }
    
    // 暂未用到
    private var selectedModels: [PTMediaModel] = []
    
    // 暂未用到
    private var selectedCount = 0
    
    public init(title: String,
                result: PHFetchResult<PHAsset>,
                collection: PHAssetCollection,
                option: PHFetchOptions,
                isCameraRoll: Bool,
                selectionOptions: PTMediaLibSelectionOptions? = nil) {
        self.title = title
        self.result = result
        self.collection = collection
        self.option = option
        self.isCameraRoll = isCameraRoll
        self.selectionOptions = selectionOptions ?? .current()
        self.resultSignature = Self.boundarySignature(for: result)
        self.modeledResultSignature = nil
        self.nextResultOffset = 0
    }

    // English: Preserve the public void API and keep the change result internal to the repository.
    // Español: Conserva la API pública sin retorno y mantiene el resultado de cambio dentro del repositorio.
    // 中文：保留公开的无返回值 API，只在 Repository 内部使用变化结果。
    public func refetchPhotos() {
        _ = refetchPhotosIfChanged()
    }

    // English: Reuse unchanged model objects and report whether the modeled snapshot changed.
    // Español: Reutiliza modelos sin cambios e informa si cambió la instantánea modelada.
    // 中文：复用未变化的模型，并返回当前模型快照是否发生变化。
    @MainActor
    @discardableResult
    func refetchPhotosIfChanged() -> Bool {
        let started = CFAbsoluteTimeGetCurrent()
        guard !isFullyModeled || modeledResultSignature != resultSignature else {
            PTMediaPickerTrace.event("modeling", details: "changed=false,reason=version,count=\(models.count)")
            return false
        }
        let existingModels = Dictionary(uniqueKeysWithValues: models.map { ($0.ident, $0) })
        let models = PTMediaLibManager.fetchPhoto(
            in: result,
            ascending: selectionOptions.sortAscending,
            selectionOptions: selectionOptions,
            reusing: existingModels
        )
        let nextSignature = Self.signature(for: models.map(\.sourceRevisionKey))
        guard nextSignature != modelsSignature else {
            modeledResultSignature = resultSignature
            nextResultOffset = result.count
            PTMediaPickerTrace.event("modeling", details: "changed=false,count=\(models.count),durationMs=\(Int((CFAbsoluteTimeGetCurrent() - started) * 1000))")
            return false
        }
        self.models = models
        modelsSignature = nextSignature
        modeledResultSignature = resultSignature
        nextResultOffset = result.count
        contentRevision &+= 1
        PTMediaPickerTrace.event("modeling", details: "changed=true,count=\(models.count),reused=\(existingModels.count),durationMs=\(Int((CFAbsoluteTimeGetCurrent() - started) * 1000))")
        return true
    }

    // English: Return whether the public PhotoKit result actually changed before publishing a refresh.
    // Español: Devuelve si el resultado público de PhotoKit cambió antes de publicar una actualización.
    // 中文：先判断公开 PhotoKit 结果是否真的变化，再发布刷新。
    @MainActor
    @discardableResult
    func refreshResult(knownChanged: Bool = false) -> Bool {
        refreshResultTransaction(knownChanged: knownChanged, generation: resultChangeGeneration &+ 1) != nil
    }

    // English: Refetch PhotoKit once and return an immutable delta without exposing PHChange to async work.
    // Español: Vuelve a consultar PhotoKit una vez y devuelve un delta inmutable sin exponer PHChange a trabajo asíncrono.
    // 中文：只重新读取一次 PhotoKit，并返回不可变变化结果，不把 PHChange 传入异步任务。
    @MainActor
    @discardableResult
    func refreshResultTransaction(knownChanged: Bool = false,
                                  generation: UInt64) -> PTMediaAlbumChangeTransaction? {
        let started = CFAbsoluteTimeGetCurrent()
        let nextResult = PHAsset.fetchAssets(in: collection, options: option)
        let nextSignature = Self.boundarySignature(for: nextResult)
        let previousBoundary = Self.boundarySignature(for: result)
        guard knownChanged || nextSignature != previousBoundary else { return nil }
        if knownChanged, nextSignature == previousBoundary {
            // English: A middle-asset change keeps both boundaries stable, so pay the full-scan cost only for this ambiguous notification.
            // Español: Un cambio en un recurso intermedio mantiene estables ambos límites; el escaneo completo solo se paga en esta notificación ambigua.
            // 中文：中间资源变化会保持首尾不变，因此仅在这类不明确通知中执行一次完整扫描。
            let previousSignature = Self.signature(for: result)
            let currentSignature = Self.signature(for: nextResult)
            guard previousSignature != currentSignature else {
                PTMediaPickerTrace.event("refresh", details: "changed=false,reason=photoKitSameSnapshot,count=\(nextResult.count)")
                return nil
            }
        }

        let oldRevision = contentRevision
        let oldModeledResultOffset = nextResultOffset
        let oldWasFullyModeled = isFullyModeled
        let oldIDs = Self.assetIdentifiers(for: result)
        let newIDs = Self.assetIdentifiers(for: nextResult)
        let oldIDSet = Set(oldIDs)
        let newIDSet = Set(newIDs)
        let oldRevisionMap = Dictionary(uniqueKeysWithValues: (0..<result.count).map {
            let asset = result.object(at: $0)
            return (asset.localIdentifier, PTMediaModel.sourceRevisionKey(for: asset))
        })
        let newRevisionMap = Dictionary(uniqueKeysWithValues: (0..<nextResult.count).map {
            let asset = nextResult.object(at: $0)
            return (asset.localIdentifier, PTMediaModel.sourceRevisionKey(for: asset))
        })

        result = nextResult
        if knownChanged {
            resultChangeGeneration &+= 1
            resultSignature = "\(nextSignature)|change:\(resultChangeGeneration)"
        } else {
            resultSignature = nextSignature
        }
        nextResultOffset = 0
        modeledResultSignature = nil

        let oldIndexMap = Dictionary(uniqueKeysWithValues: oldIDs.enumerated().map { ($0.element, $0.offset) })
        var movedIDs: [String] = []
        movedIDs.reserveCapacity(newIDs.count)
        for (index, identifier) in newIDs.enumerated() {
            guard let oldIndex = oldIndexMap[identifier], oldIndex != index else { continue }
            movedIDs.append(identifier)
        }
        let transaction = PTMediaAlbumChangeTransaction(
            albumIdentifier: collection.localIdentifier,
            generation: generation,
            oldRevision: oldRevision,
            newRevision: oldRevision &+ 1,
            oldCount: oldIDs.count,
            newCount: newIDs.count,
            insertedIDs: newIDs.filter { !oldIDSet.contains($0) },
            removedIDs: oldIDs.filter { !newIDSet.contains($0) },
            changedIDs: newIDs.filter {
                guard let oldValue = oldRevisionMap[$0], let newValue = newRevisionMap[$0] else { return false }
                return oldValue != newValue
            },
            movedIDs: Array(Set(movedIDs)),
            orderedIDs: selectionOptions.sortAscending ? newIDs : Array(newIDs.reversed()),
            oldModeledResultOffset: oldModeledResultOffset,
            oldWasFullyModeled: oldWasFullyModeled
        )
        PTMediaPickerTrace.event("deltaPrepared", details: "albumIDPresent=true,oldCount=\(transaction.oldCount),newCount=\(transaction.newCount),inserted=\(transaction.insertedIDs.count),removed=\(transaction.removedIDs.count),moved=\(transaction.movedIDs.count),changed=\(transaction.changedIDs.count),mainThreadMs=\(Int((CFAbsoluteTimeGetCurrent() - started) * 1000))")
        return transaction
    }

    // English: Project only the visible PhotoKit window and recreate models for changed IDs.
    // Español: Proyecta solo la ventana visible de PhotoKit y recrea modelos para los IDs modificados.
    // 中文：只投影当前可见的 PhotoKit 窗口，仅为变化的 ID 重建模型。
    @discardableResult
    func applyChangeTransaction(_ transaction: PTMediaAlbumChangeTransaction) -> PTMediaModelProjectionMetrics? {
        guard transaction.albumIdentifier == collection.localIdentifier else { return nil }
        let started = CFAbsoluteTimeGetCurrent()
        let previousByID = Dictionary(uniqueKeysWithValues: models.map { ($0.ident, $0) })
        let affectedIDs = Set(transaction.insertedIDs).union(transaction.changedIDs)
        let modeledRawCount: Int
        if transaction.oldWasFullyModeled {
            modeledRawCount = result.count
        } else {
            modeledRawCount = min(result.count,
                                  max(initialBatchSize,
                                      transaction.oldModeledResultOffset,
                                      models.count + transaction.insertedIDs.count))
        }
        let projectedIDs = Array(transaction.orderedIDs.prefix(modeledRawCount))
        let projectedIDSet = Set(projectedIDs)
        let assetsToCreate = affectedIDs.intersection(projectedIDSet)
        var assetsByID: [String: PHAsset] = [:]
        assetsByID.reserveCapacity(assetsToCreate.count)
        if !assetsToCreate.isEmpty {
            // English: Resolve only affected assets instead of walking the entire fetch result again.
            // Español: Resuelve solo los recursos afectados en lugar de recorrer de nuevo todo el resultado.
            // 中文：只解析受影响的资源，避免再次遍历整个 FetchResult。
            let affectedAssets = PHAsset.fetchAssets(withLocalIdentifiers: Array(assetsToCreate), options: nil)
            for index in 0..<affectedAssets.count {
                let asset = affectedAssets.object(at: index)
                assetsByID[asset.localIdentifier] = asset
            }
        }

        var nextModels: [PTMediaModel] = []
        nextModels.reserveCapacity(projectedIDs.count)
        var reusedCount = 0
        var createdCount = 0
        for identifier in projectedIDs {
            let model: PTMediaModel
            if !affectedIDs.contains(identifier), let existing = previousByID[identifier] {
                model = existing
                reusedCount += 1
            } else if let asset = assetsByID[identifier] {
                model = PTMediaModel(asset: asset)
                createdCount += 1
            } else {
                continue
            }
            guard PTMediaLibManager.canDisplay(model, with: selectionOptions) else { continue }
            nextModels.append(model)
        }

        let previousIDs = Set(models.map(\.ident))
        let nextIDs = Set(nextModels.map(\.ident))
        let removedCount = previousIDs.subtracting(nextIDs).count
        let nextSignature = Self.signature(for: nextModels.map(\.sourceRevisionKey))
        let changed = nextSignature != modelsSignature || nextIDs != previousIDs
        models = nextModels
        modelsSignature = nextSignature
        nextResultOffset = modeledRawCount
        modeledResultSignature = transaction.oldWasFullyModeled ? resultSignature : nil
        if changed {
            contentRevision &+= 1
        }
        PTMediaPickerTrace.event("modelProjectionPrepared", details: "reused=\(reusedCount),created=\(createdCount),removed=\(removedCount),modeled=\(nextModels.count),durationMs=\(Int((CFAbsoluteTimeGetCurrent() - started) * 1000))")
        return PTMediaModelProjectionMetrics(reusedCount: reusedCount,
                                             createdCount: createdCount,
                                             removedCount: removedCount)
    }

    private static func assetIdentifiers(for result: PHFetchResult<PHAsset>) -> [String] {
        (0..<result.count).map { result.object(at: $0).localIdentifier }
    }

    // English: Model only the first visible-sized slice and let the repository append later slices.
    // Español: Modela solo el primer lote del tamaño visible y deja que el repositorio añada los siguientes.
    // 中文：先构建接近首屏可见范围的批次，再由 Repository 追加后续批次。
    @discardableResult
    func loadInitialBatch() -> Bool {
        models.removeAll(keepingCapacity: true)
        modelsSignature = ""
        modeledResultSignature = nil
        nextResultOffset = 0
        return loadNextBatch(batchSize: initialBatchSize)
    }

    // English: Append one bounded PhotoKit batch without rescanning already modeled assets.
    // Español: Añade un lote acotado de PhotoKit sin volver a escanear recursos ya modelados.
    // 中文：追加一个有界 PhotoKit 批次，不重新扫描已经建模的资源。
    @discardableResult
    func loadNextBatch(batchSize: Int? = nil) -> Bool {
        guard !isFullyModeled else { return false }
        let started = CFAbsoluteTimeGetCurrent()
        let batch = PTMediaLibManager.fetchPhotoBatch(
            in: result,
            startResultOffset: nextResultOffset,
            ascending: selectionOptions.sortAscending,
            selectionOptions: selectionOptions,
            limitCount: batchSize ?? subsequentBatchSize
        )
        nextResultOffset = batch.nextResultOffset
        guard !batch.models.isEmpty else {
            if isFullyModeled { modeledResultSignature = resultSignature }
            return false
        }
        models.append(contentsOf: batch.models)
        contentRevision &+= 1
        PTMediaPickerTrace.event("modelingBatch", details: "added=\(batch.models.count),total=\(models.count),complete=\(isFullyModeled),durationMs=\(Int((CFAbsoluteTimeGetCurrent() - started) * 1000))")
        if isFullyModeled {
            modelsSignature = Self.signature(for: models.map(\.sourceRevisionKey))
            modeledResultSignature = resultSignature
        }
        return true
    }

    private static func signature(for result: PHFetchResult<PHAsset>) -> String {
        var values: [String] = []
        values.reserveCapacity(result.count)
        for index in 0..<result.count {
            // English: Include only cell-relevant metadata so changed assets rebuild without recreating unchanged models.
            // Español: Incluye solo metadata relevante para la celda para reconstruir únicamente los recursos modificados.
            // 中文：只纳入与 Cell 相关的元数据，让变化的资源更新而不重建未变化模型。
            values.append(PTMediaModel.sourceRevisionKey(for: result.object(at: index)))
        }
        return signature(for: values)
    }

    private static func boundarySignature(for result: PHFetchResult<PHAsset>) -> String {
        guard result.count > 0 else { return "0" }
        let first = PTMediaModel.sourceRevisionKey(for: result.object(at: 0))
        let last = result.count == 1
            ? first
            : PTMediaModel.sourceRevisionKey(for: result.object(at: result.count - 1))
        return signature(for: [first, last, String(result.count)])
    }

    private static func signature(for values: [String]) -> String {
        // English: FNV-1a keeps the snapshot marker compact without storing every identifier twice.
        // Español: FNV-1a mantiene compacto el marcador sin almacenar dos veces cada identificador.
        // 中文：使用 FNV-1a 保存紧凑快照标记，避免重复保存全部资源标识。
        var hash: UInt64 = 14_695_981_039_346_656_037
        for value in values {
            for byte in value.utf8 {
                hash ^= UInt64(byte)
                hash &*= 1_099_511_628_211
            }
            hash ^= 0
            hash &*= 1_099_511_628_211
        }
        return "\(values.count):\(hash)"
    }
}

extension PTMediaLibListModel {
    static func ==(lhs: PTMediaLibListModel, rhs: PTMediaLibListModel) -> Bool {
        lhs.title == rhs.title &&
                lhs.count == rhs.count &&
                lhs.headImageAsset?.localIdentifier == rhs.headImageAsset?.localIdentifier
    }
}

//MARK: MediaModel
// PhotoKit/UIKit state is UI-owned and must stay on MainActor.
@MainActor
public final class PTMediaModel: NSObject {
    public let ident: String
    
    public let asset: PHAsset

    // English: This stable key changes when PhotoKit metadata relevant to the cell changes.
    // Español: Esta clave estable cambia cuando cambia metadata relevante de PhotoKit para la celda.
    // 中文：这个稳定键会在影响 Cell 的 PhotoKit 元数据变化时改变。
    var sourceRevisionKey: String {
        Self.sourceRevisionKey(for: asset)
    }

    static func sourceRevisionKey(for asset: PHAsset) -> String {
        let modification = asset.modificationDate?.timeIntervalSince1970.bitPattern ?? 0
        return [
            asset.localIdentifier,
            String(asset.mediaType.rawValue),
            String(asset.mediaSubtypes.rawValue),
            String(asset.pixelWidth),
            String(asset.pixelHeight),
            String(asset.duration.bitPattern),
            String(modification)
        ].joined(separator: "|")
    }

    public var type: PTMediaModel.MediaType = .unknown
    
    public var duration = ""
    
    public var isSelected = false
    
    private var pri_dataSize: PTMediaLibConfig.KBUnit?
    
    public var dataSize: PTMediaLibConfig.KBUnit? {
        if let pri_dataSize = pri_dataSize {
            return pri_dataSize
        }
        
        let size = PTMediaLibManager.fetchAssetSize(for: asset)
        pri_dataSize = size
        
        return size
    }

    // English: Cache the result of the asynchronous public PhotoKit size request for final selection validation.
    // Español: Guarda el resultado de la solicitud asíncrona pública de tamaño de PhotoKit para validar la selección final.
    // 中文：缓存公开 PhotoKit 异步大小请求结果，用于最终选择校验。
    func setDataSize(_ size: PTMediaLibConfig.KBUnit?) {
        pri_dataSize = size
    }
    
    public var avEditorOutputItem:AVPlayerItem?
    
    private var pri_editImage: UIImage?
    
    public var editImage: UIImage? {
        set {
            pri_editImage = newValue
        }
        get {
#if POOTOOLS_IMAGEEDITOR
            if let _ = editImageModel {
                return pri_editImage
            } else {
                return nil
            }
#else
            return nil
#endif
        }
    }
    
    public var second: Int {
        guard type == .video else {
            return 0
        }
        return Int(round(asset.duration))
    }
    
    public var whRatio: CGFloat {
        guard asset.pixelWidth > 0, asset.pixelHeight > 0 else {
            return 1
        }
        return CGFloat(asset.pixelWidth) / CGFloat(asset.pixelHeight)
    }
    
    /// English: Resolves an image request size from the consuming view's local bounds.
    /// Español: Resuelve el tamaño de la solicitud desde los límites locales de la vista consumidora.
    /// 中文：根据实际使用 View 的局部 bounds 计算图片请求尺寸。
    @MainActor
    public func previewSize(in containerBounds: CGRect,
                            scale: CGFloat? = nil) -> CGSize {
        let localWidth = max(1, containerBounds.width.isFinite ? containerBounds.width : 0)
        let localHeight = max(1, containerBounds.height.isFinite ? containerBounds.height : 0)
        let resolvedScale = max(1, scale ?? PTSceneContext.activeWindow()?.screen.scale ?? 1)
        let referenceLength = min(whRatio > 1 ? localHeight : localWidth, PTMaxImageWidth)
        let baseLength = max(1, referenceLength) * resolvedScale

        if whRatio > 1 {
            return CGSize(width: baseLength * whRatio, height: baseLength)
        }
        return CGSize(width: baseLength, height: baseLength / whRatio)
    }

    /// English: Legacy request-size access remains available, using the active scene only as a fallback.
    /// Español: El acceso heredado sigue disponible y usa la escena activa únicamente como respaldo.
    /// 中文：保留旧的尺寸属性，仅在没有显式容器时使用活动场景作为兜底。
    @available(*, deprecated, message: "Use previewSize(in:scale:) with the consuming view bounds.")
    @MainActor public var previewSize: CGSize {
        let fallbackBounds = PTSceneContext.activeWindow()?.bounds ??
            CGRect(x: 0, y: 0, width: PTMaxImageWidth, height: PTMaxImageWidth)
        return previewSize(in: fallbackBounds,
                           scale: PTSceneContext.activeWindow()?.screen.scale)
    }
    
#if POOTOOLS_IMAGEEDITOR
    // Content of the last edit.
    public var editImageModel: PTEditModel?
#endif
    
    public init(asset: PHAsset) {
        ident = asset.localIdentifier
        self.asset = asset
        super.init()
        
        type = transformAssetType(for: asset)
        if type == .video {
            duration = transformDuration(for: asset)
        }
    }
    
    public func transformAssetType(for asset: PHAsset) -> PTMediaModel.MediaType {
        switch asset.mediaType {
        case .video:
            return .video
        case .image:
            if asset.pt.isGif {
                return .gif
            }
            if asset.mediaSubtypes.contains(.photoLive) {
                return .livePhoto
            }
            return .image
        default:
            return .unknown
        }
    }
    
    public func transformDuration(for asset: PHAsset) -> String {
        let dur = Int(round(asset.duration))
        
        switch dur {
        case 0..<60:
            return String(format: "00:%02d", dur)
        case 60..<3600:
            let m = dur / 60
            let s = dur % 60
            return String(format: "%02d:%02d", m, s)
        case 3600...:
            let h = dur / 3600
            let m = (dur % 3600) / 60
            let s = dur % 60
            return String(format: "%02d:%02d:%02d", h, m, s)
        default:
            return ""
        }
    }
}

public extension PTMediaModel {
    static func == (lhs: PTMediaModel, rhs: PTMediaModel) -> Bool {
        lhs.ident == rhs.ident
    }
}

public extension PTMediaModel {
    enum MediaType: Int, Sendable {
        case unknown = 0
        case image
        case gif
        case livePhoto
        case video
    }
}

//MARK: 结果输出Model
@MainActor
public class PTResultModel: NSObject {
    @objc public let asset: PHAsset
    
    @objc public let image: UIImage
    
    /// Whether the picture has been edited. Always false when `saveNewImageAfterEdit = true`.
    @objc public let isEdited: Bool
    
#if POOTOOLS_IMAGEEDITOR
    /// Content of the last edit. Always nil when `saveNewImageAfterEdit = true`.
    @objc public let editModel: PTEditModel?
#endif
    
    /// The order in which the user selects the models in the album. This index is not necessarily equal to the order of the model's index in the array, as some PHAssets requests may fail.
    @objc public let index: Int
    
    @objc public let avEditorOutputItem:AVPlayerItem?
    
#if POOTOOLS_IMAGEEDITOR
    @objc public init(asset: PHAsset, image: UIImage, isEdited: Bool, editModel: PTEditModel? = nil,avEditorOutputItem: AVPlayerItem? = nil, index: Int) {
        self.asset = asset
        self.image = image
        self.isEdited = isEdited
        self.editModel = editModel
        self.index = index
        self.avEditorOutputItem = avEditorOutputItem
        super.init()
    }
#else
    @objc public init(asset: PHAsset, image: UIImage, isEdited: Bool,avEditorOutputItem: AVPlayerItem? = nil, index: Int) {
        self.asset = asset
        self.image = image
        self.isEdited = isEdited
        self.index = index
        self.avEditorOutputItem = avEditorOutputItem
        super.init()
    }
#endif
}

// English: The typed completion value keeps success ordering and failed indices together.
// Español: El resultado tipado conserva juntos el orden exitoso y los índices fallidos.
// 中文：类型化完成结果同时保留成功顺序和失败下标，避免两个回调数组失配。
@MainActor
public struct PTMediaPickerOutcome {
    public let items: [PTResultModel]
    public let isOriginal: Bool
    public let failedAssetIndices: [Int]

    public init(items: [PTResultModel],
                isOriginal: Bool,
                failedAssetIndices: [Int] = []) {
        self.items = items
        self.isOriginal = isOriginal
        self.failedAssetIndices = failedAssetIndices
    }
}

extension PTResultModel {
    static func ==(lhs: PTResultModel, rhs: PTResultModel) -> Bool {
        lhs.asset == rhs.asset
    }
}
