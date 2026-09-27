// English: Cancellable banner handle with update-in-place and async completion.
// Español: Handle cancelable con actualización en sitio y finalización asíncrona.
// 中文：支持取消、原地更新和异步完成结果的 Banner 句柄。

import Foundation
#if canImport(PToolsOverlay)
import PToolsOverlay
#endif

@MainActor
public final class PTBannerHandle {
    public let id: UUID
    public private(set) var state: PTOverlayState = .idle

    private var resultStorage: PTBannerResult?
    private var continuation: CheckedContinuation<PTBannerResult, Never>?
    private var dismissAction: (@MainActor (PTBannerResult) -> Void)?
    private var updateAction: (@MainActor (PTBanner) -> Void)?

    init(id: UUID) {
        self.id = id
    }

    public func dismiss() {
        dismiss(with: .manuallyDismissed)
    }

    public func update(_ banner: PTBanner) {
        updateAction?(banner)
    }

    public func result() async -> PTBannerResult {
        if let resultStorage {
            return resultStorage
        }
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    func setDismissAction(_ action: @escaping @MainActor (PTBannerResult) -> Void) {
        dismissAction = action
    }

    func setUpdateAction(_ action: @escaping @MainActor (PTBanner) -> Void) {
        updateAction = action
    }

    func setState(_ state: PTOverlayState) {
        self.state = state
    }

    func dismiss(with result: PTBannerResult) {
        dismissAction?(result)
    }

    func finish(_ result: PTBannerResult) {
        guard resultStorage == nil else { return }
        resultStorage = result
        continuation?.resume(returning: result)
        continuation = nil
        dismissAction = nil
        updateAction = nil
        state = .dismissed
    }
}
