//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation
import UIKit

protocol ElementInspectorAppearanceProviding: InspectorAppearanceProviding {
    var elementInspectorAppearance: ElementInspectorAppearance { get }
}

extension ElementInspectorAppearanceProviding {
    var elementInspectorAppearance: ElementInspectorAppearance { inspectorAppearance.elementInspector }
}
