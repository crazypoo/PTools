//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

protocol TextElement: UIView {
    var content: String? { get }
}

extension UILabel: TextElement {
    var content: String? { text?.trimmed }
}

extension UITextView: TextElement {
    var content: String? { text?.trimmed }
}

extension UITextField: TextElement {
    var content: String? { text?.trimmed }
}
