// English: Shared MainActor loading lifecycle for independent UIKit controls.
// Español: Ciclo de carga compartido en MainActor para controles UIKit independientes.
// 中文：为不同 UIKit 控件提供统一的 MainActor 加载生命周期。

import Foundation

#if canImport(UIKit)
import UIKit

@MainActor
internal final class PTControlLoadingCoordinator {
    private let isInteractionEnabled: @MainActor () -> Bool
    private let setInteractionEnabled: @MainActor (Bool) -> Void
    private let beginPresentation: @MainActor () -> Void
    private let endPresentation: @MainActor () -> Void
    private var task: Task<Void, Never>?
    private var previousInteractionEnabled = true

    private(set) var isLoading = false

    init(isInteractionEnabled: @escaping @MainActor () -> Bool,
         setInteractionEnabled: @escaping @MainActor (Bool) -> Void,
         beginPresentation: @escaping @MainActor () -> Void,
         endPresentation: @escaping @MainActor () -> Void) {
        self.isInteractionEnabled = isInteractionEnabled
        self.setInteractionEnabled = setInteractionEnabled
        self.beginPresentation = beginPresentation
        self.endPresentation = endPresentation
    }

    @discardableResult
    func start() -> Bool {
        guard !isLoading else { return false }
        previousInteractionEnabled = isInteractionEnabled()
        isLoading = true
        setInteractionEnabled(false)
        beginPresentation()
        return true
    }

    func stop() {
        guard isLoading else { return }
        task?.cancel()
        task = nil
        isLoading = false
        endPresentation()
        setInteractionEnabled(previousInteractionEnabled)
    }

    @discardableResult
    func perform(_ operation: @escaping @MainActor @Sendable () async throws -> Void,
                 completion: @escaping @MainActor @Sendable (Bool) -> Void) -> Task<Void, Never> {
        guard start() else {
            return Task { @MainActor in }
        }

        let task = Task { @MainActor [weak self] in
            guard let self else { return }
            var succeeded = false
            do {
                try await operation()
                succeeded = !Task.isCancelled
            } catch {
                succeeded = false
            }
            self.stop()
            completion(succeeded)
        }
        self.task = task
        return task
    }

    func cancel() {
        task?.cancel()
        stop()
    }

}
#endif
