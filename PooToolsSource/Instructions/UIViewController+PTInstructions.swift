// English: Convenience entry point for presenting a typed instruction tour from a visible controller.
// Español: Entrada conveniente para presentar un tutorial tipado desde un controlador visible.
// 中文：从当前可见控制器展示类型化引导的便捷入口。

import UIKit

@MainActor
public extension UIViewController {
    func presentInstructions(_ tour: PTInstructionTour,
                             configuration: PTInstructionConfiguration = .init()) async throws -> PTInstructionResult {
        try await PTInstructionCenter.shared.present(tour,
                                                      in: self,
                                                      configuration: configuration)
    }
}
