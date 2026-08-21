//
//  PTMediaRequestCoordinator.swift
//  PooTools
//
//  MainActor-owned cancellation and cell-reuse boundary for PhotoKit requests.
//

import Photos

@MainActor
final class PTMediaRequestCoordinator {
    private struct RequestState {
        var generation: UInt64
        var requestID: PHImageRequestID = PHInvalidImageRequestID
    }

    private var states: [String: RequestState] = [:]

    func begin(_ key: String) -> UInt64 {
        let nextGeneration = (states[key]?.generation ?? 0) &+ 1
        cancel(key)
        states[key] = RequestState(generation: nextGeneration)
        return nextGeneration
    }

    func store(_ requestID: PHImageRequestID, for key: String, generation: UInt64) {
        guard states[key]?.generation == generation else {
            cancel(String(format: "%d", requestID))
            return
        }
        states[key]?.requestID = requestID
    }

    func isCurrent(_ key: String, generation: UInt64) -> Bool {
        states[key]?.generation == generation
    }

    func cancel(_ key: String) {
        guard let state = states.removeValue(forKey: key),
              state.requestID != PHInvalidImageRequestID else { return }
        PHImageManager.default().cancelImageRequest(state.requestID)
    }

    func cancelAll() {
        let requestIDs = states.values
            .map(\.requestID)
            .filter { $0 != PHInvalidImageRequestID }
        states.removeAll(keepingCapacity: true)
        requestIDs.forEach { PHImageManager.default().cancelImageRequest($0) }
    }
}
