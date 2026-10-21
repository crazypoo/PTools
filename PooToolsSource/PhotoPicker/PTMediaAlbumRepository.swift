//
//  PTMediaAlbumRepository.swift
//  PooTools
//
//  English: Keep PhotoKit album discovery behind one instance-scoped repository.
//  Español: Mantiene el descubrimiento de álbumes PhotoKit detrás de un repositorio por instancia.
//  中文：将 PhotoKit 相册发现收敛到按实例保存的仓库中。
//

import Photos

@MainActor
final class PTMediaAlbumRepository: NSObject {
    let options: PTMediaLibSelectionOptions
    var onCameraRollChange: (@MainActor @Sendable (PTMediaLibListModel) -> Void)?
    private var isObserving = false
    private weak var observedAlbum: PTMediaLibListModel?

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
        PTMediaLibManager.getPhotoAlbumList(options: options, completion: completion)
    }

    // English: Observe PhotoKit for the repository lifetime instead of unregistering on the first change.
    // Español: Observa PhotoKit durante la vida del repositorio en lugar de cancelar tras el primer cambio.
    // 中文：观察者跟随仓库生命周期管理，不在第一次变更后注销。
    func startObserving() {
        guard !isObserving else { return }
        PHPhotoLibrary.shared().register(self)
        isObserving = true
    }

    func stopObserving() {
        guard isObserving else { return }
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
        isObserving = false
    }

    func setCurrentAlbum(_ album: PTMediaLibListModel?) {
        observedAlbum = album
    }

}

// English: Isolate the PhotoKit observer conformance at the actor boundary.
// Español: Aísla la conformidad del observador de PhotoKit en el límite del actor.
// 中文：将 PhotoKit 观察者协议隔离在 MainActor 边界上。
extension PTMediaAlbumRepository: @MainActor PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        // English: Refetch on the MainActor after PhotoKit publishes its change notification.
        // Español: Vuelve a consultar en MainActor después de que PhotoKit publique el cambio.
        // 中文：PhotoKit 发布变更后回到 MainActor 重新获取相册快照。
        Task { @MainActor [weak self] in
            guard let self else { return }
            if let album = self.observedAlbum,
               let details = changeInstance.changeDetails(for: album.result) {
                album.result = details.fetchResultAfterChanges
                album.refetchPhotos()
                self.onCameraRollChange?(album)
            } else {
                self.cameraRoll { [weak self] album in
                    self?.onCameraRollChange?(album)
                }
            }
        }
    }
}
