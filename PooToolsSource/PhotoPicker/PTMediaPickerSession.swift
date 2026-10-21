//
//  PTMediaPickerSession.swift
//  PooTools
//
//  English: Owns immutable picker options and the lifecycle of picker state.
//  Español: Posee las opciones inmutables y el ciclo de vida del estado del selector.
//  中文：统一持有不可变 Picker 配置和选择状态生命周期。
//

import Photos

@MainActor
final class PTMediaPickerSession {
    enum State: Sendable, Equatable {
        case idle
        case loading
        case ready
        case submitting
        case completed
        case cancelled
    }

    let options: PTMediaLibSelectionOptions
    let selectionStore: PTMediaSelectionStore
    let albumRepository: PTMediaAlbumRepository
    private(set) var currentAlbum: PTMediaLibListModel?
    private(set) var state: State = .idle

    init(options: PTMediaLibSelectionOptions,
         selectionStore: PTMediaSelectionStore = PTMediaSelectionStore()) {
        self.options = options
        self.selectionStore = selectionStore
        self.albumRepository = PTMediaAlbumRepository(options: options)
    }

    func beginLoading() { state = .loading }
    func setCurrentAlbum(_ album: PTMediaLibListModel?) {
        currentAlbum = album
        albumRepository.setCurrentAlbum(album)
    }
    func markReady() { state = .ready }
    func beginSubmitting() -> Bool {
        guard state != .submitting else { return false }
        state = .submitting
        return true
    }
    func markCompleted() { state = .completed }
    func markCancelled() { state = .cancelled }
}
