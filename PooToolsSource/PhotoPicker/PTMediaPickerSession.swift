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
    let traceID: String
    private(set) var currentAlbum: PTMediaLibListModel?
    private(set) var state: State = .idle

    init(options: PTMediaLibSelectionOptions,
         selectionStore: PTMediaSelectionStore = PTMediaSelectionStore(),
         traceID: String? = nil) {
        self.options = options
        self.selectionStore = selectionStore
        self.traceID = traceID ?? PTMediaPickerTrace.makeTraceID()
        self.albumRepository = PTMediaAlbumRepository(options: options, traceID: self.traceID)
    }

    func beginLoading() {
        guard state == .idle else { return }
        state = .loading
    }
    func setCurrentAlbum(_ album: PTMediaLibListModel?) {
        currentAlbum = album
        albumRepository.setCurrentAlbum(album)
    }
    func markReady() {
        guard state == .loading else { return }
        state = .ready
    }

    func beginSubmitting() -> Bool {
        guard state == .ready else { return false }
        state = .submitting
        return true
    }

    func markCompleted() {
        guard state == .ready || state == .submitting else { return }
        state = .completed
    }

    func markCancelled() {
        guard state != .completed else { return }
        state = .cancelled
    }
}
