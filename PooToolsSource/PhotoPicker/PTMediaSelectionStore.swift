//
//  PTMediaSelectionStore.swift
//  PooTools
//
//  English: One MainActor-owned source of truth for PhotoPicker media selection.
//  Español: Una única fuente de verdad protegida por MainActor para la selección multimedia.
//  中文：由 MainActor 保护的 PhotoPicker 媒体选择唯一数据源。
//

import Foundation

// English: Images, GIFs, and Live Photos share one selection family; videos remain a separate family.
// Español: Las imágenes, GIF y Live Photos comparten una familia; los vídeos permanecen separados.
// 中文：普通图片、GIF 和 Live Photo 属于同一选择族；视频保持独立选择族。
enum PTMediaSelectionFamily: Sendable, Hashable {
    case image
    case video

    init?(mediaType: PTMediaModel.MediaType) {
        switch mediaType {
        case .image, .gif, .livePhoto:
            self = .image
        case .video:
            self = .video
        case .unknown:
            return nil
        }
    }
}

// English: A reservation identifies one asynchronous selection attempt and rejects late callbacks.
// Español: La reserva identifica un intento asíncrono y rechaza callbacks tardíos.
// 中文：预约令牌标识一次异步选择尝试，用于拒绝取消后的迟到回调。
struct PTMediaSelectionReservation: Sendable, Equatable {
    let identifier: String
    let generation: UInt64
}

// English: The value context keeps selection validation independent from UIKit and PhotoKit objects.
// Español: El contexto de valor mantiene la validación independiente de objetos UIKit y PhotoKit.
// 中文：值类型上下文让选择校验不依赖 UIKit 和 PhotoKit 对象。
struct PTMediaSelectionContext: Sendable {
    let selectedCount: Int
    let selectedFamilies: Set<PTMediaSelectionFamily>
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
            case .regularImageOnly where context.candidateType != .image:
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
           let candidateFamily = PTMediaSelectionFamily(mediaType: context.candidateType),
           context.selectedFamilies.contains(where: { $0 != candidateFamily }) {
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
    private var reservations: [String: PTMediaSelectionReservation] = [:]
    private var generations: [String: UInt64] = [:]

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
        let unchanged = self.models.count == models.count && zip(self.models, models).allSatisfy {
            $0.ident == $1.ident && $0.sourceRevisionKey == $1.sourceRevisionKey
        }
        guard !unchanged else {
            return
        }
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
        selectedModels.forEach {
            pendingModels.removeValue(forKey: $0.ident)
            reservations.removeValue(forKey: $0.ident)
        }
        synchronizeModelFlags()
        notifyChange()
    }

    func beginSelection(for model: PTMediaModel) -> Bool {
        reserveSelection(for: model) != nil
    }

    func reserveSelection(for model: PTMediaModel) -> PTMediaSelectionReservation? {
        guard !selectedModels.contains(where: { $0.ident == model.ident }),
              !pendingIdentifiers.contains(model.ident) else {
            return nil
        }

        let generation = (generations[model.ident] ?? 0) &+ 1
        let reservation = PTMediaSelectionReservation(identifier: model.ident, generation: generation)
        generations[model.ident] = generation
        reservations[model.ident] = reservation
        pendingIdentifiers.insert(model.ident)
        pendingModels[model.ident] = model
        notifyChange()
        return reservation
    }

    func completeSelection(for model: PTMediaModel) {
        if let reservation = reservations[model.ident] {
            _ = completeSelection(for: model, reservation: reservation)
            return
        }
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

    @discardableResult
    func completeSelection(for model: PTMediaModel,
                           reservation: PTMediaSelectionReservation) -> Bool {
        guard reservations[model.ident] == reservation else { return false }
        reservations.removeValue(forKey: model.ident)
        pendingIdentifiers.remove(model.ident)
        pendingModels.removeValue(forKey: model.ident)
        guard !selectedModels.contains(where: { $0.ident == model.ident }) else {
            model.isSelected = true
            notifyChange()
            return true
        }
        model.isSelected = true
        selectedModels.append(model)
        notifyChange()
        return true
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
        reservations.removeValue(forKey: replacement.ident)
        notifyChange()
    }

    func cancelSelection(for model: PTMediaModel) {
        if let reservation = reservations[model.ident] {
            _ = cancelSelection(for: model, reservation: reservation)
            return
        }
        pendingIdentifiers.remove(model.ident)
        pendingModels.removeValue(forKey: model.ident)
        model.isSelected = selectedModels.contains(where: { $0.ident == model.ident })
        notifyChange()
    }

    @discardableResult
    func cancelSelection(for model: PTMediaModel,
                         reservation: PTMediaSelectionReservation) -> Bool {
        guard reservations[model.ident] == reservation else { return false }
        reservations.removeValue(forKey: model.ident)
        pendingIdentifiers.remove(model.ident)
        pendingModels.removeValue(forKey: model.ident)
        model.isSelected = selectedModels.contains(where: { $0.ident == model.ident })
        notifyChange()
        return true
    }

    func isReservationActive(_ reservation: PTMediaSelectionReservation) -> Bool {
        reservations[reservation.identifier] == reservation
    }

    func removeSelection(for model: PTMediaModel) {
        reservations.removeValue(forKey: model.ident)
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

    func selectedIndexMap() -> [String: Int] {
        Dictionary(uniqueKeysWithValues: selectedModels.enumerated().map { ($0.element.ident, $0.offset) })
    }

    func reset() {
        reservations.removeAll(keepingCapacity: true)
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
        guard let family = PTMediaSelectionFamily(mediaType: type) else { return true }
        return pendingModels.values.contains {
            guard let pendingFamily = PTMediaSelectionFamily(mediaType: $0.type) else { return true }
            return pendingFamily != family
        }
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
                            selectedFamilies: Set((store.selectedModels + Array(store.pendingModels.values)).compactMap {
                                PTMediaSelectionFamily(mediaType: $0.type)
                            }),
                            candidateType: model.type,
                            candidateDuration: model.second,
                            candidateDataSize: model.type == .video ? model.dataSize : nil,
                            options: options)
}
