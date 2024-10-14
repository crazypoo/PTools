//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

/// Element Libraries are entities that conform to `InspectorElementLibraryProtocol` and are each tied to a unique type. *Pro-tip: Enumerations are recommended.*
public protocol InspectorElementLibraryProtocol {
    var targetClass: AnyClass { get }
    func sections(for object: NSObject) -> InspectorElementSections
}
