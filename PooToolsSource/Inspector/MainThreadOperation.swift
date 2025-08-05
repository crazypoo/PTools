//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation

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

        closure()
    }
}
