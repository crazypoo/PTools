//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation

final class MainThreadAsyncOperation: MainThreadOperation {
    override func main() {
        PTGCDManager.gcdMain {
            self.closure()
        }
    }
}
