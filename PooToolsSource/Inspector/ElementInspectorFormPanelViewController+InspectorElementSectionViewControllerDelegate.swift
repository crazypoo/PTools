//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension ElementInspectorFormPanelViewController: InspectorElementSectionViewControllerDelegate {
    func inspectorElementSectionViewController(_ sectionViewController: InspectorElementSectionViewController,
                                               willUpdate property: InspectorElementProperty) {}

    func inspectorElementSectionViewController(_ sectionViewController: InspectorElementSectionViewController,
                                               didUpdate property: InspectorElementProperty)
    {
        let updateOperation = MainThreadOperation(name: "update sections") { [weak self] in
            guard
                let self = self,
                let item = self.sections[sectionViewController]
            else {
                return
            }

            self.formPanels.forEach { $0.reloadData() }

            self.formDelegate?.elementInspectorFormPanel(self, didUpdateProperty: property, in: item)
        }

        formDelegate?.addOperationToQueue(updateOperation)
    }

    func inspectorElementSectionViewController(_ sectionViewController: InspectorElementSectionViewController,
                                               willChangeFrom oldState: InspectorElementSectionState?,
                                               to newState: InspectorElementSectionState)
    {
        sectionViewController.setState(newState, animated: true)

        switch newState {
        case .expanded where panelSelectionMode == .singleSelection:
            for aFormItemController in formPanels where aFormItemController !== sectionViewController {
                aFormItemController.setState(.collapsed, animated: true)
            }

        case .expanded, .collapsed:
            break
        }

        itemStateDelegate?.elementInspectorFormPanelItemDidChangeState(self)
    }

    func inspectorElementSectionViewController(_ sectionViewController: InspectorElementSectionViewController,
                                               didTap imagePreviewControl: ImagePreviewControl)
    {
        selectedImagePreviewControl = imagePreviewControl
        formDelegate?.elementInspectorFormPanel(self, didTap: imagePreviewControl)
    }

    func inspectorElementSectionViewController(_ sectionViewController: InspectorElementSectionViewController,
                                               didTap colorPreviewControl: ColorPreviewControl)
    {
        selectedColorPreviewControl = colorPreviewControl
        formDelegate?.elementInspectorFormPanel(self, didTap: colorPreviewControl)
    }
}
