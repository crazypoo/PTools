//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation

enum InspectorCommand {
    case execute(Closure)
    case inspect(ViewHierarchyElementReference)
}
