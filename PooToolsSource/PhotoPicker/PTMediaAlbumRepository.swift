//
//  PTMediaAlbumRepository.swift
//  PooTools
//
//  English: Keep PhotoKit album discovery behind one instance-scoped repository.
//  Español: Mantiene el descubrimiento de álbumes PhotoKit detrás de un repositorio por instancia.
//  中文：将 PhotoKit 相册发现收敛到按实例保存的仓库中。
//

import Photos

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
            completion(album)
        }
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
    }

    func stopObserving() {
        guard isObserving else { return }
        refreshTask?.cancel()
        refreshTask = nil
        albumsGeneration &+= 1
        PHPhotoLibrary.shared().unregisterChangeObserver(changeObserver)
        isObserving = false
    }

    func setCurrentAlbum(_ album: PTMediaLibListModel?) {
        observedAlbum = album
    }

    // English: Coalesce PhotoKit notifications and refetch a safe MainActor snapshot.
    // Español: Agrupa notificaciones de PhotoKit y vuelve a cargar una instantánea segura en MainActor.
    // 中文：合并 PhotoKit 通知，并在 MainActor 重新获取安全快照。
    private func scheduleRefresh() {
        refreshTask?.cancel()
        refreshTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(nanoseconds: 50_000_000)
            } catch {
                return
            }
            guard let self, !Task.isCancelled else { return }
            self.refreshObservedAlbum()
        }
    }

    private func refreshObservedAlbum() {
        guard isObserving else { return }
        if let album = observedAlbum {
            album.refreshResult()
            album.refetchPhotos()
            onCameraRollChange?(album)
        } else {
            cameraRoll { [weak self] album in
                self?.onCameraRollChange?(album)
            }
        }
        guard onAlbumsChange != nil else { return }
        albums { [weak self] albums in
            self?.onAlbumsChange?(albums)
        }
    }
}
