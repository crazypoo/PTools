//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation
#if SWIFT_PACKAGE
import ptools
#endif

protocol AsyncOperationProtocol {
    var operationQueue: OperationQueue { get }

    func asyncOperation(name: String, execute closure: @escaping Closure)
}

extension AsyncOperationProtocol {
    func asyncOperation(execute closure: @escaping Closure) {
        asyncOperation(name: #function, execute: closure)
    }
}
