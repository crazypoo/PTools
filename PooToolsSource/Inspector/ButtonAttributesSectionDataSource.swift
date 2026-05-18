//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension DefaultElementAttributesLibrary {
    
    // 1. 添加 @MainActor：确保整个 UI 数据源在 Swift 6 下是严格主线程安全的
    @MainActor
    final class ButtonAttributesSectionDataSource: @MainActor InspectorElementSectionDataSource {
        var state: InspectorElementSectionState = .collapsed

        let title = "Button"

        private weak var button: UIButton?

        init?(with object: NSObject) {
            guard let button = object as? UIButton else { return nil }

            self.button = button
            self.selectedControlState = button.state
        }

        private var selectedControlState: UIControl.State

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
                        placeholder: button.configuration?.title ?? button.title(for: self.selectedControlState) ?? property.rawValue,
                        value: { button.configuration?.title ?? button.title(for: self.selectedControlState) }
                    ) { title in
                        // 🌟 修复点 1：正确修改 Configuration 值类型结构体
                        if var config = button.configuration {
                            config.title = title
                            // 必须重新赋值回 button.configuration 才能生效
                            button.configuration = config
                        } else {
                            button.setTitle(title, for: self.selectedControlState)
                        }
                    }
                    
                case .currentTitleColor:
                    return .colorPicker(
                        title: property.rawValue,
                        color: { button.titleColor(for: self.selectedControlState) }
                    ) { currentTitleColor in
                        // 🌟 修复点 2：修复字体颜色的 Configuration 更新
                        if var config = button.configuration {
                            config.baseForegroundColor = currentTitleColor
                            button.configuration = config
                        } else {
                            button.setTitleColor(currentTitleColor, for: self.selectedControlState)
                        }
                    }
                    
                case .currentTitleShadowColor:
                    return .colorPicker(
                        title: property.rawValue,
                        color: { button.titleShadowColor(for: self.selectedControlState) }
                    ) { currentTitleShadowColor in
                        button.setTitleShadowColor(currentTitleShadowColor, for: self.selectedControlState)
                    }
                    
                case .image:
                    return .imagePicker(
                        title: property.rawValue,
                        image: { button.configuration?.image ?? button.image(for: self.selectedControlState) }
                    ) { image in
                        // 🌟 修复点 3：修复图片的 Configuration 更新
                        if var config = button.configuration {
                            config.image = image
                            button.configuration = config
                        } else {
                            button.setImage(image, for: self.selectedControlState)
                        }
                    }

                case .backgroundImage:
                    return .imagePicker(
                        title: property.rawValue,
                        image: { button.configuration?.background.image ?? button.backgroundImage(for: self.selectedControlState) }
                    ) { backgroundImage in
                        // 🌟 修复点 4：修复背景图片的 Configuration 更新
                        if var config = button.configuration {
                            config.background.image = backgroundImage
                            button.configuration = config
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
