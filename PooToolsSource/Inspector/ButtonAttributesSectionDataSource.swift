//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension DefaultElementAttributesLibrary {
    final class ButtonAttributesSectionDataSource: InspectorElementSectionDataSource {
        var state: InspectorElementSectionState = .collapsed

        let title = "Button"

        private weak var button: UIButton?

        init?(with object: NSObject) {
            guard let button = object as? UIButton else { return nil }

            self.button = button
            selectedControlState = button.state
        }

        private var selectedControlState: UIControl.State

        // 步骤 1: 移除 iOS 15 中已废弃的参数
        // 移除了 reversesTitleShadowWhenHighlighted, showsTouchWhenHighlighted,
        // adjustsImageWhenHighlighted, adjustsImageWhenDisabled
        private enum Property: String, Swift.CaseIterable {
            case type = "Type"
            case fontName = "Font Name"
            case fontPointSize = "Font Point Size"
            case groupState = "State"
            case stateConfig = "State Config"
            case titleText = "Title"
            case currentTitleColor = "Text Color"
            case currentTitleShadowColor = "Shadow Color"
            case image = "Image"
            case backgroundImage = "Background Image"
            case isPointerInteractionEnabled = "Pointer Interaction Enabled"
            case adjustsImageSizeForAccessibilityContentSizeCategory = "Adjusts Image Size"
            case groupDrawing = "Drawing"
        }

        var properties: [InspectorElementProperty] {
            guard let button = button else { return [] }

            return Property.allCases.compactMap { property in
                switch property {
                case .type:
                    return .optionsList(
                        title: property.rawValue,
                        options: UIButton.ButtonType.allCases.map(\.description),
                        selectedIndex: { UIButton.ButtonType.allCases.firstIndex(of: button.buttonType) },
                        handler: nil
                    )
                case .fontName:
                    return .fontNamePicker(
                        title: property.rawValue,
                        fontProvider: {
                            button.titleLabel?.font
                        },
                        handler: { font in
                            button.titleLabel?.font = font
                        }
                    )
                case .fontPointSize:
                    return .fontSizeStepper(
                        title: property.rawValue,
                        fontProvider: {
                            button.titleLabel?.font
                        },
                        handler: { font in
                            button.titleLabel?.font = font
                        }
                    )
                case .groupState, .groupDrawing:
                    return .group(title: property.rawValue)

                case .stateConfig:
                    return .optionsList(
                        title: property.rawValue,
                        options: UIControl.State.configurableButtonStates.map(\.description),
                        selectedIndex: { UIControl.State.configurableButtonStates.firstIndex(of: self.selectedControlState) }
                    ) { [weak self] in
                        guard let newIndex = $0 else { return }
                        let selectedStateConfig = UIControl.State.configurableButtonStates[newIndex]
                        self?.selectedControlState = selectedStateConfig
                    }
                    
                case .titleText:
                    return .textField(
                        title: property.rawValue,
                        // 步骤 2: 兼容读取 Configuration 中的标题
                        placeholder: button.configuration?.title ?? button.title(for: self.selectedControlState) ?? property.rawValue,
                        value: { button.configuration?.title ?? button.title(for: self.selectedControlState) }
                    ) { title in
                        // 步骤 2: 如果按钮使用了 iOS 15 的 Configuration，优先更新 Configuration
                        if button.configuration != nil {
                            button.configuration?.title = title
                        } else {
                            button.setTitle(title, for: self.selectedControlState)
                        }
                    }
                    
                case .currentTitleColor:
                    return .colorPicker(
                        title: property.rawValue,
                        color: { button.titleColor(for: self.selectedControlState) }
                    ) { currentTitleColor in
                        if button.configuration != nil {
                            // Configuration 模式下的文字颜色通常由 baseForegroundColor 控制
                            button.configuration?.baseForegroundColor = currentTitleColor
                        } else {
                            button.setTitleColor(currentTitleColor, for: self.selectedControlState)
                        }
                    }
                    
                case .currentTitleShadowColor:
                    return .colorPicker(
                        title: property.rawValue,
                        color: { button.titleShadowColor(for: self.selectedControlState) }
                    ) { currentTitleShadowColor in
                        // 注意：Configuration 模式不直接支持 ShadowColor，这里只保留传统设置
                        button.setTitleShadowColor(currentTitleShadowColor, for: self.selectedControlState)
                    }
                    
                case .image:
                    return .imagePicker(
                        title: property.rawValue,
                        image: { button.configuration?.image ?? button.image(for: self.selectedControlState) }
                    ) { image in
                        if button.configuration != nil {
                            button.configuration?.image = image
                        } else {
                            button.setImage(image, for: self.selectedControlState)
                        }
                    }

                case .backgroundImage:
                    return .imagePicker(
                        title: property.rawValue,
                        image: { button.configuration?.background.image ?? button.backgroundImage(for: self.selectedControlState) }
                    ) { backgroundImage in
                        if button.configuration != nil {
                            button.configuration?.background.image = backgroundImage
                        } else {
                            button.setBackgroundImage(backgroundImage, for: self.selectedControlState)
                        }
                    }
                    
                case .isPointerInteractionEnabled:
                    return .switch(
                        title: property.rawValue,
                        isOn: { button.isPointerInteractionEnabled }
                    ) { isPointerInteractionEnabled in
                        button.isPointerInteractionEnabled = isPointerInteractionEnabled
                    }
                    
                case .adjustsImageSizeForAccessibilityContentSizeCategory:
                    return .switch(
                        title: property.rawValue,
                        isOn: { button.adjustsImageSizeForAccessibilityContentSizeCategory }
                    ) { adjustsImageSizeForAccessibilityContentSizeCategory in
                        button.adjustsImageSizeForAccessibilityContentSizeCategory = adjustsImageSizeForAccessibilityContentSizeCategory
                    }
                }
            }
        }
    }
}

private extension UIControl.State {
    static let configurableButtonStates: [UIControl.State] = [
        .normal,
        .highlighted,
        .selected,
        .disabled
    ]
}
