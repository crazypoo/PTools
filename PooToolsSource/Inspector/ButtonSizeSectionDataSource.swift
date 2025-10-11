//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension DefaultElementSizeLibrary {
    final class ButtonSizeSectionDataSource: InspectorElementSectionDataSource {
        var state: InspectorElementSectionState = .collapsed

        let title: String = "Button"

        private weak var button: UIButton?

        init?(with object: NSObject) {
            guard let button = object as? UIButton else { return nil }
            self.button = button
        }

        private enum Properties: String, Swift.CaseIterable {
            case contentEdgeInsets = "Content Insets"
            case titleEdgeInsets = "Title Insets"
            case imageEdgeInsets = "Image Insets"
        }

        var properties: [InspectorElementProperty] {
            guard let button = button else { return [] }

            return Properties.allCases.map { property in
                switch property {
                case .contentEdgeInsets:
                    return .edgeInsets(title: property.rawValue, insets: {
                        button.configuration?.contentInsets.edgeInsets() ?? .zero
                    },handler: {
                        if var config = button.configuration {
                            config.contentInsets = $0.directionalEdgeInsets()
                            button.configuration = config
                        } else {
                            var config = UIButton.Configuration.plain()
                            config.contentInsets = $0.directionalEdgeInsets()
                            button.configuration = config
                        }
                    })
                case .imageEdgeInsets:
                    return .edgeInsets(title: property.rawValue, insets: {
                        var edges : UIEdgeInsets
                        switch button.configuration?.imagePlacement {
                        case .top:
                            edges = UIEdgeInsets(top: button.configuration?.imagePadding)
                        case .bottom:
                            edges = UIEdgeInsets(bottom: button.configuration?.imagePadding)
                        case .leading:
                            edges = UIEdgeInsets(left: button.configuration?.imagePadding)
                        case .trailing:
                            edges = UIEdgeInsets(right: button.configuration?.imagePadding)
                        default:
                            edges = .zero
                        }
                        return edges
                    }, handler: {
                        var rectEdge : NSDirectionalRectEdge = .all
                        var padding:CGFloat = 0
                        if $0.top != 0 {
                            rectEdge = .top
                            padding = $0.top
                        }
                        if $0.bottom != 0 {
                            rectEdge = .bottom
                            padding = $0.bottom
                        }
                        if $0.left != 0 {
                            rectEdge = .leading
                            padding = $0.left
                        }
                        
                        if $0.right != 0 {
                            rectEdge = .trailing
                            padding = $0.right
                        }
                        if var config = button.configuration {
                            config.imagePlacement = rectEdge
                            config.imagePadding = padding
                            button.configuration = config
                        } else {
                            var config = UIButton.Configuration.plain()
                            config.imagePlacement = rectEdge
                            config.imagePadding = padding
                            button.configuration = config
                        }
                    })
                case .titleEdgeInsets:
                    return .edgeInsets(title: property.rawValue, insets: {
                        button.configuration?.contentInsets.edgeInsets() ?? .zero
                    }, handler: {
                        if var config = button.configuration {
                            config.contentInsets = $0.directionalEdgeInsets()
                            button.configuration = config
                        } else {
                            var config = UIButton.Configuration.plain()
                            config.contentInsets = $0.directionalEdgeInsets()
                            button.configuration = config
                        }
                    })
                }
            }
        }
    }
}
