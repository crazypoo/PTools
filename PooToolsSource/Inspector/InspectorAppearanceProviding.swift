//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation
import UIKit

protocol InspectorAppearanceProviding {
    var inspectorAppearance: InspectorAppearance { get }
}

extension InspectorAppearanceProviding {
    var inspectorAppearance: InspectorAppearance { Inspector.sharedInstance.appearance }
}
