//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import MobileCoreServices
import UIKit

extension ElementInspectorCoordinator: ElementInspectorFormPanelDelegate {
    func elementInspectorFormPanel(_ formPanelViewController: ElementInspectorFormPanelViewController,
                                   didUpdateProperty property: InspectorElementProperty,
                                   in section: InspectorElementSection)
    {
        guard let elementInspectorViewController = formPanelViewController.parent as? ElementInspectorViewController else {
            assertionFailure("whaaaat")
            return
        }

        elementInspectorViewController.reloadData()

        elementInspectorViewController.viewModel.element.highlightView?.reloadData()
    }

    func elementInspectorFormPanel(_ formPanelViewController: ElementInspectorFormPanelViewController, didTap colorPreviewControl: ColorPreviewControl) {
        let colorPickerViewController = UIColorPickerViewController().then {
            $0.delegate = colorPicker

            if let selectedColor = colorPreviewControl.selectedColor {
                $0.selectedColor = selectedColor
            }

            if #available(iOS 15.0, *), let sheet = $0.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.selectedDetentIdentifier = .medium
                sheet.prefersGrabberVisible = true
                sheet.sourceView = colorPreviewControl
                sheet.preferredCornerRadius = Inspector.sharedInstance.appearance.elementInspector.horizontalMargins
            }
        }

        formPanelViewController.present(colorPickerViewController, animated: true)
    }

    func elementInspectorFormPanel(_ formPanelViewController: ElementInspectorFormPanelViewController,
                                   didTap imagePreviewControl: ImagePreviewControl)
    {
        let alertController = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet
        ).then {
            $0.view.tintColor = $0.colorStyle.textColor
            setPopoverModalPresentationStyle(for: $0, from: imagePreviewControl.accessoryControl)
        }

        alertController.addAction(
            UIAlertAction(
                title: Texts.cancel,
                style: .cancel,
                handler: nil
            )
        )

        if imagePreviewControl.image != nil {
            alertController.addAction(
                UIAlertAction(
                    title: Texts.clearImage,
                    style: .destructive,
                    handler: { _ in
                        formPanelViewController.selectImage(nil)
                    }
                )
            )
        }

        alertController.addAction(
            UIAlertAction(
                title: Texts.importImage,
                style: .default,
                handler: { [weak self] _ in
                    guard let self = self else {
                        return
                    }

                    let documentPicker = UIDocumentPickerViewController.forImporting(
                        .documentTypes(.image),
                        .asCopy(true),
                        .documentPickerDelegate(self.documentPicker),
                        .viewOptions(
                            .tintColor(Inspector.sharedInstance.configuration.colorStyle.textColor)
                        )
                    ).then {
                        self.setPopoverModalPresentationStyle(for: $0, from: imagePreviewControl.accessoryControl)
                    }

                    formPanelViewController.present(documentPicker, animated: true)
                }
            )
        )

        formPanelViewController.present(alertController, animated: true) {
            alertController.view.tintColor = formPanelViewController.colorStyle.textColor
        }
    }
}
