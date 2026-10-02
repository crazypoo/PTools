//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation

// English: Preserve Foundation Operation's unchecked Sendable compatibility for this UI-bound operation subclass.
// Español: Conserva la compatibilidad Sendable no verificada de Foundation para esta subclase de operación ligada a la UI.
// 中文：保留 Foundation Operation 的未检查 Sendable 兼容性，确保这个 UI 操作子类可用。
final class MainThreadAsyncOperation: MainThreadOperation, @unchecked Sendable {
    override func main() {
        Task { @MainActor in
            self.closure()
        }
    }
}
