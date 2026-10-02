//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation

// English: Foundation's Operation is imported with an unchecked Sendable boundary; the work closure is MainActor-isolated and Sendable.
// Español: Operation de Foundation se importa con un límite Sendable no verificado; el cierre de trabajo está aislado en MainActor y es Sendable.
// 中文：Foundation 的 Operation 带有未检查的 Sendable 边界；实际工作闭包由 MainActor 隔离并满足 Sendable。
class MainThreadOperation: Operation, @unchecked Sendable {
    let closure: Closure

    init(name: String, closure: @escaping Closure) {
        self.closure = closure

        super.init()

        self.name = name
    }

    override func main() {
        guard Thread.isMainThread else {
            DispatchQueue.main.sync {
                self.closure()
            }
            return
        }

        Task { @MainActor in
            closure()
        }
    }
}
