//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation

extension ElementInspectorCoordinator: OperationQueueManagerProtocol {
    func cancelAllOperations() {
        operationQueue.cancelAllOperations()
    }

    func addOperationToQueue(_ operation: MainThreadOperation) {
        guard operationQueue.operations.contains(operation) == false else {
            return
        }

        operationQueue.addOperation(operation)
    }

    func suspendQueue(_ isSuspended: Bool) {
        operationQueue.isSuspended = isSuspended
    }
}
