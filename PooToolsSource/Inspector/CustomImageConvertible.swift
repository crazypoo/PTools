//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

protocol CustomImageConvertible {
    var image: UIImage? { get }
}

extension Array where Element: CustomImageConvertible {
    var withImages: Self {
        filter { $0.image != nil }
    }
}
