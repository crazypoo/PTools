//
//  PTMediaAlbumRepository.swift
//  PooTools
//
//  English: Keep PhotoKit album discovery behind one instance-scoped repository.
//  Español: Mantiene el descubrimiento de álbumes PhotoKit detrás de un repositorio por instancia.
//  中文：将 PhotoKit 相册发现收敛到按实例保存的仓库中。
//

import Foundation
import Photos
import os

// English: Keep picker tracing in an already exported source file so CocoaPods and SwiftPM compile the same source set.
// Español: Mantiene el trazado del selector en un archivo ya exportado para que CocoaPods y SwiftPM compilen el mismo conjunto.
// 中文：将 Picker 追踪放在已被导出的源文件中，确保 CocoaPods 和 SwiftPM 编译相同的源码集合。
enum PTMediaPickerTrace {
    private static let log = OSLog(subsystem: "com.pootools.photopicker", category: "lifecycle")

    // English: Keep a trace identifier without logging media bytes or user file names.
    // Español: Mantiene un identificador de traza sin registrar bytes multimedia ni nombres de archivos del usuario.
    // 中文：保留追踪标识，但不记录媒体字节或用户文件名。
    static func makeTraceID() -> String {
        UUID().uuidString
    }

    static func event(_ name: String, traceID: String? = nil, details: String = "") {
        let trace = traceID.map { "trace=\($0)" } ?? "trace=none"
        os_log("%{public}@ %{public}@ %{public}@", log: log, type: .debug, name, trace, details)
    }
}

// English: All PhotoKit refresh causes share one debounced channel.
// Español: Todas las causas de actualización de PhotoKit comparten un único canal con debounce.
// 中文：所有 PhotoKit 刷新原因共用一个防抖通道。
enum PTMediaAlbumRefreshReason: String, Sendable, Hashable {
    case photoKitChange
    case captureSaved
    case screenshot
    case foregroundPermission
    case albumSwitch
    case editSaved
}

// English: PhotoKit invokes this observer on its own queue; only a signal crosses back to MainActor.
// Español: PhotoKit invoca este observador en su propia cola; solo una señal vuelve a MainActor.
// 中文：PhotoKit 会在自己的队列回调观察者；这里只把信号安全地转回 MainActor。
private final class PTMediaAlbumChangeObserver: NSObject, PHPhotoLibraryChangeObserver {
    private let onChange: @MainActor @Sendable () -> Void

    init(onChange: @escaping @MainActor @Sendable () -> Void) {
        self.onChange = onChange
    }

    func photoLibraryDidChange(_ changeInstance: PHChange) {
        PTMainActorBridge.perform { [onChange] in
            onChange()
        }
    }
}

@MainActor
final class PTMediaAlbumRepository: NSObject {
    let options: PTMediaLibSelectionOptions
    var onCameraRollChange: (@MainActor @Sendable (PTMediaLibListModel) -> Void)?
    var onAlbumsChange: (@MainActor @Sendable ([PTMediaLibListModel]) -> Void)?
    private var isObserving = false
    private weak var observedAlbum: PTMediaLibListModel?
    private var albumsGeneration: UInt64 = 0
    private var pendingReasons: Set<PTMediaAlbumRefreshReason> = []
    private var refreshGeneration: UInt64 = 0
    private var notificationSequence: UInt64 = 0
    private var lastAlbumsSignature: String?
    private let traceID = PTMediaPickerTrace.makeTraceID()
    private lazy var changeObserver = PTMediaAlbumChangeObserver { [weak self] in
        self?.scheduleRefresh()
    }
    private var refreshTask: Task<Void, Never>?

    init(options: PTMediaLibSelectionOptions) {
        self.options = options
    }

    func cameraRoll(completion: @escaping @MainActor @Sendable (PTMediaLibListModel) -> Void) {
        PTMediaLibManager.getCameraRollAlbum(options: options) { [weak self] album in
            self?.observedAlbum = album
            _ = album.refetchPhotosIfChanged()
            self?.trace("initialLoad", details: "album=\(album.collection.localIdentifier),count=\(album.models.count)")
            completion(album)
        }
    }

    // English: Prepare a selected album through the repository so callers never refetch PhotoKit directly.
    // Español: Prepara el álbum seleccionado mediante el repositorio para que ningún llamador consulte PhotoKit directamente.
    // 中文：通过 Repository 准备选中的相册，避免调用方直接重新读取 PhotoKit。
    @discardableResult
    func prepare(_ album: PTMediaLibListModel) -> Bool {
        observedAlbum = album
        return album.refetchPhotosIfChanged()
    }

    func albums(completion: @escaping @MainActor @Sendable ([PTMediaLibListModel]) -> Void) {
        albumsGeneration &+= 1
        let generation = albumsGeneration
        PTMediaLibManager.getPhotoAlbumList(options: options) { [weak self] albums in
            guard let self, self.albumsGeneration == generation else { return }
            completion(albums)
        }
    }

    // English: Observe PhotoKit for the repository lifetime instead of unregistering on the first change.
    // Español: Observa PhotoKit durante la vida del repositorio en lugar de cancelar tras el primer cambio.
    // 中文：观察者跟随仓库生命周期管理，不在第一次变更后注销。
    func startObserving() {
        guard !isObserving else { return }
        PHPhotoLibrary.shared().register(changeObserver)
        isObserving = true
        requestRefresh(reason: .foregroundPermission)
    }

    func stopObserving() {
        guard isObserving else { return }
        refreshTask?.cancel()
        refreshTask = nil
        pendingReasons.removeAll(keepingCapacity: true)
        refreshGeneration &+= 1
        albumsGeneration &+= 1
        PHPhotoLibrary.shared().unregisterChangeObserver(changeObserver)
        isObserving = false
    }

    func setCurrentAlbum(_ album: PTMediaLibListModel?) {
        observedAlbum = album
    }

    // English: Coalesce all refresh intents into one bounded MainActor transaction.
    // Español: Agrupa todas las intenciones en una única transacción acotada de MainActor.
    // 中文：将所有刷新意图合并为一个有界的 MainActor 事务。
    func requestRefresh(reason: PTMediaAlbumRefreshReason) {
        pendingReasons.insert(reason)
        notificationSequence &+= 1
        trace("refreshRequested", details: "source=\(reason.rawValue),notification=\(notificationSequence)")
        guard refreshTask == nil else { return }
        refreshGeneration &+= 1
        let generation = refreshGeneration
        refreshTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(nanoseconds: 50_000_000)
            } catch {
                return
            }
            guard let self, !Task.isCancelled, self.refreshGeneration == generation else { return }
            self.refreshTask = nil
            let reasons = self.pendingReasons.map(\.rawValue).sorted().joined(separator: ",")
            self.pendingReasons.removeAll(keepingCapacity: true)
            self.refreshObservedAlbum(reasons: reasons)
        }
    }

    private func scheduleRefresh() {
        requestRefresh(reason: .photoKitChange)
    }

    private func refreshObservedAlbum(reasons: String) {
        guard isObserving else { return }
        let started = CFAbsoluteTimeGetCurrent()
        var didChange = false
        if let album = observedAlbum {
            let resultChanged = album.refreshResult()
            let modelsChanged = resultChanged && album.refetchPhotosIfChanged()
            didChange = resultChanged || modelsChanged
            if didChange {
                onCameraRollChange?(album)
            }
        } else {
            cameraRoll { [weak self] album in
                self?.onCameraRollChange?(album)
            }
            didChange = true
        }
        let albumID = observedAlbum?.collection.localIdentifier ?? "none"
        trace("refresh", details: "album=\(albumID),generation=\(refreshGeneration),reasons=\(reasons),changed=\(didChange),durationMs=\(Int((CFAbsoluteTimeGetCurrent() - started) * 1000))")
        guard onAlbumsChange != nil else { return }
        albums { [weak self] albums in
            guard let self else { return }
            let signature = albums.map {
                "\($0.collection.localIdentifier):\($0.count):\($0.headImageAsset?.localIdentifier ?? "")"
            }.joined(separator: "|")
            guard self.lastAlbumsSignature != signature else { return }
            self.lastAlbumsSignature = signature
            self.onAlbumsChange?(albums)
        }
    }

    // English: Attach generation and album context to every repository event for reproducible refresh diagnosis.
    // Español: Añade generación y álbum a cada evento para diagnosticar refrescos reproducibles.
    // 中文：为 Repository 事件附加 generation 和相册上下文，便于复现刷新来源。
    private func trace(_ name: String, details: String) {
        PTMediaPickerTrace.event(name, traceID: traceID, details: details)
    }
}
