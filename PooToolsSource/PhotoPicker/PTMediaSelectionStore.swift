//
//  PTMediaSelectionStore.swift
//  PooTools
//
//  English: One MainActor-owned source of truth for PhotoPicker media selection.
//  Español: Una única fuente de verdad protegida por MainActor para la selección multimedia.
//  中文：由 MainActor 保护的 PhotoPicker 媒体选择唯一数据源。
//

import Foundation

// English: The value context keeps selection validation independent from UIKit and PhotoKit objects.
// Español: El contexto de valor mantiene la validación independiente de objetos UIKit y PhotoKit.
// 中文：值类型上下文让选择校验不依赖 UIKit 和 PhotoKit 对象。
struct PTMediaSelectionContext: Sendable {
    let selectedCount: Int
    let selectedTypes: Set<PTMediaModel.MediaType>
    let candidateType: PTMediaModel.MediaType
    let candidateDuration: Int
    let candidateDataSize: CGFloat?
    let options: PTMediaLibSelectionOptions
}

enum PTMediaSelectionViolation: Sendable, Equatable {
    case assetNotAllowed
    case mediaTypeNotAllowed
    case imageFilterNotAllowed
    case maximumSelectionReached
    case mixedMediaNotAllowed
    case videoDurationTooLong
    case videoDurationTooShort
    case videoSizeTooLarge
    case videoSizeTooSmall
}

enum PTMediaSelectionPolicy {
    // English: Validate both directions of mixed-media rules before any async download starts.
    // Español: Valida ambas direcciones de mezcla antes de iniciar cualquier descarga asíncrona.
    // 中文：在开始异步下载前，双向校验图片和视频混选规则。
    static func violation(for context: PTMediaSelectionContext) -> PTMediaSelectionViolation? {
        let options = context.options

        switch context.candidateType {
        case .video:
            guard options.allowSelectVideo else { return .mediaTypeNotAllowed }
        case .image, .livePhoto:
            guard options.allowSelectImage else { return .mediaTypeNotAllowed }
            switch options.imageFilter {
            case .all:
                break
            case .livePhotoOnly where context.candidateType != .livePhoto:
                return .imageFilterNotAllowed
            case .regularImageOnly where context.candidateType != .image && context.candidateType != .gif:
                return .imageFilterNotAllowed
            default:
                break
            }
        case .gif:
            guard options.allowSelectImage, options.allowSelectGif else { return .mediaTypeNotAllowed }
            guard options.imageFilter != .livePhotoOnly else { return .imageFilterNotAllowed }
        case .unknown:
            return .mediaTypeNotAllowed
        }

        guard context.selectedCount < options.maxSelectCount else {
            return .maximumSelectionReached
        }

        if !options.allowMixSelect,
           !context.selectedTypes.isEmpty,
           context.selectedTypes.contains(where: { $0 != context.candidateType }) {
            return .mixedMediaNotAllowed
        }

        guard context.candidateType == .video else { return nil }

        if options.maxSelectVideoDuration > 0,
           context.candidateDuration > options.maxSelectVideoDuration {
            return .videoDurationTooLong
        }
        if context.candidateDuration < options.minSelectVideoDuration {
            return .videoDurationTooShort
        }

        guard options.minSelectVideoDataSize > 0 || options.maxSelectVideoDataSize != .greatestFiniteMagnitude,
              let size = context.candidateDataSize else {
            return nil
        }
        if size > options.maxSelectVideoDataSize { return .videoSizeTooLarge }
        if size < options.minSelectVideoDataSize { return .videoSizeTooSmall }
        return nil
    }
}

@MainActor
final class PTMediaSelectionStore {
    private(set) var models: [PTMediaModel] = []
    private(set) var selectedModels: [PTMediaModel] = []
    private(set) var pendingIdentifiers: Set<String> = []
    private(set) var pendingModels: [String: PTMediaModel] = [:]

    // English: UI observes one change stream instead of mirroring selected arrays in two owners.
    // Español: La UI observa un único flujo de cambios en lugar de duplicar arrays seleccionados.
    // 中文：UI 只监听一个变化流，不再由两个对象各自维护选中数组。
    var onChange: (() -> Void)?

    var selectedCount: Int { selectedModels.count }

    // English: Pending items reserve capacity before an iCloud request completes.
    // Español: Los elementos pendientes reservan capacidad antes de que termine una solicitud de iCloud.
    // 中文：iCloud 请求完成前，待处理资源也要先占用选择名额。
    var reservedCount: Int { selectedModels.count + pendingIdentifiers.count }

    func replaceModels(_ models: [PTMediaModel]) {
        self.models = models
        // English: Keep selections from another album; the displayed album is only a projection of the picker state.
        // Español: Conserva las selecciones de otro álbum; el álbum visible solo proyecta el estado del selector.
        // 中文：切换相册时保留其他相册的选中项；当前相册只负责展示选择状态投影。
        synchronizeModelFlags()
        notifyChange()
    }

    func insertModel(_ model: PTMediaModel, at index: Int) {
        guard !models.contains(where: { $0.ident == model.ident }) else { return }
        let safeIndex = min(max(0, index), models.count)
        models.insert(model, at: safeIndex)
        notifyChange()
    }

    func appendModel(_ model: PTMediaModel) {
        insertModel(model, at: models.count)
    }

    func replaceSelectedModels(_ models: [PTMediaModel]) {
        var seen = Set<String>()
        selectedModels = models.filter { seen.insert($0.ident).inserted }
        pendingIdentifiers.subtract(selectedModels.map(\.ident))
        selectedModels.forEach { pendingModels.removeValue(forKey: $0.ident) }
        synchronizeModelFlags()
        notifyChange()
    }

    func beginSelection(for model: PTMediaModel) -> Bool {
        guard !selectedModels.contains(where: { $0.ident == model.ident }),
              !pendingIdentifiers.contains(model.ident) else {
            return false
        }
        pendingIdentifiers.insert(model.ident)
        pendingModels[model.ident] = model
        notifyChange()
        return true
    }

    func completeSelection(for model: PTMediaModel) {
        pendingIdentifiers.remove(model.ident)
        pendingModels.removeValue(forKey: model.ident)
        guard !selectedModels.contains(where: { $0.ident == model.ident }) else {
            model.isSelected = true
            notifyChange()
            return
        }
        model.isSelected = true
        selectedModels.append(model)
        notifyChange()
    }

    // English: Replace an edited asset without changing the user's selection order.
    // Español: Sustituye un recurso editado sin cambiar el orden elegido por el usuario.
    // 中文：替换编辑后的资源时保持用户原有的选择顺序。
    func replaceSelection(_ original: PTMediaModel, with replacement: PTMediaModel) {
        guard let index = selectedModels.firstIndex(where: { $0.ident == original.ident }) else {
            completeSelection(for: replacement)
            return
        }

        original.isSelected = false
        replacement.isSelected = true
        selectedModels[index] = replacement
        pendingIdentifiers.remove(replacement.ident)
        pendingModels.removeValue(forKey: replacement.ident)
        notifyChange()
    }

    func cancelSelection(for model: PTMediaModel) {
        pendingIdentifiers.remove(model.ident)
        pendingModels.removeValue(forKey: model.ident)
        model.isSelected = selectedModels.contains(where: { $0.ident == model.ident })
        notifyChange()
    }

    func removeSelection(for model: PTMediaModel) {
        pendingIdentifiers.remove(model.ident)
        pendingModels.removeValue(forKey: model.ident)
        selectedModels.removeAll { $0.ident == model.ident }
        model.isSelected = false
        notifyChange()
    }

    func isSelected(_ model: PTMediaModel) -> Bool {
        selectedModels.contains { $0.ident == model.ident }
    }

    func selectionIndex(of model: PTMediaModel) -> Int? {
        selectedModels.firstIndex { $0.ident == model.ident }
    }

    func reset() {
        pendingIdentifiers.removeAll(keepingCapacity: true)
        pendingModels.removeAll(keepingCapacity: true)
        selectedModels.removeAll(keepingCapacity: true)
        synchronizeModelFlags()
        notifyChange()
    }

    // English: Include pending media in type checks so rapid taps cannot bypass the mix policy.
    // Español: Incluye medios pendientes en la comprobación de tipos para que los toques rápidos no eviten la política de mezcla.
    // 中文：类型校验包含待处理资源，避免快速点击绕过混选规则。
    func containsPendingTypeDifferent(from type: PTMediaModel.MediaType) -> Bool {
        pendingModels.values.contains { $0.type != type }
    }

    private func synchronizeModelFlags() {
        let selectedIDs = Set(selectedModels.map(\.ident))
        models.forEach { $0.isSelected = selectedIDs.contains($0.ident) }
    }

    private func notifyChange() {
        onChange?()
    }
}

@MainActor
func ptMediaSelectionContext(for model: PTMediaModel,
                             store: PTMediaSelectionStore,
                             options: PTMediaLibSelectionOptions) -> PTMediaSelectionContext {
    PTMediaSelectionContext(selectedCount: store.reservedCount - (store.pendingIdentifiers.contains(model.ident) ? 1 : 0),
                            selectedTypes: Set(store.selectedModels.map(\.type) + store.pendingModels.values.map(\.type)),
                            candidateType: model.type,
                            candidateDuration: model.second,
                            candidateDataSize: model.type == .video ? model.dataSize : nil,
                            options: options)
}
