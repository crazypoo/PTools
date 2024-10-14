//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

@available(iOS 14.0, *)
final class ColorPickerPresenter: NSObject, UIColorPickerViewControllerDelegate {
    let onColorSelectedHandler: (UIColor) -> Void
    let onDimissHandler: () -> Void

    init(
        onColorSelected: @escaping (UIColor) -> Void,
        onDimiss: @escaping () -> Void
    ) {
        onColorSelectedHandler = onColorSelected
        onDimissHandler = onDimiss
    }

    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        onColorSelectedHandler(viewController.selectedColor)
    }

    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        onDimissHandler()
    }
}
