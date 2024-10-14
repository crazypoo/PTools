//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension DefaultElementAttributesLibrary {
    final class ViewControllerAttributesSectionDataSource: InspectorElementSectionDataSource {
        var state: InspectorElementSectionState = .collapsed

        let title = "View Controller"

        private weak var viewController: UIViewController?

        private lazy var isInitialViewController: Bool? = {
            guard
                let viewController = viewController,
                let initialViewController = viewController.storyboard?.instantiateInitialViewController()
            else {
                return nil
            }

            return type(of: initialViewController) == type(of: viewController)
        }()

        init?(with object: NSObject) {
            guard let viewController = object as? UIViewController else {
                return nil
            }

            self.viewController = viewController
        }

        private enum Property: String, Swift.CaseIterable {
            case title = "Title"
            case initialViewController = "Is Initial View Controller"
            case separator0
            case groupLayout = "Layout"
            case hidesBottomBarWhenPushed = "Hide Bottom Bar on Push"
            case groupExtendEdges = "Extend Edges"
            case topBars = "Under Top Bars"
            case bottomBars = "Under Bottom Bars"
            case opaqueBars = "Under Opaque Bars"
            case separator1
            case modalTransitionStyle = "Transition Style"
            case presentationStyle = "Presentation"
            case definesPresentationContext = "Defines Context"
            case providesPresentationContextTransitionStyle = "Provides Context"
            case contentSize = "Preferred Content Size"
        }

        var properties: [InspectorElementProperty] {
            guard let viewController = viewController else { return [] }

            return Property.allCases.compactMap { property in
                switch property {
                case .separator0, .separator1:
                    return .separator

                case .groupLayout, .groupExtendEdges:
                    return .group(title: property.rawValue)

                case .title:
                    return .textField(
                        title: property.rawValue,
                        placeholder: nil,
                        axis: .horizontal,
                        value: { viewController.title },
                        handler: { viewController.title = $0 }
                    )
                case .initialViewController:
                    guard let isInitialViewController = isInitialViewController else { return nil }

                    return .switch(
                        title: property.rawValue,
                        isOn: { isInitialViewController },
                        handler: nil
                    )

                case .hidesBottomBarWhenPushed:
                    return .switch(
                        title: property.rawValue,
                        isOn: { viewController.hidesBottomBarWhenPushed },
                        handler: { viewController.hidesBottomBarWhenPushed = $0 }
                    )
                case .topBars:
                    return .switch(
                        title: property.rawValue,
                        isOn: { viewController.edgesForExtendedLayout.contains(.top) },
                        handler: {
                            switch $0 {
                            case true:
                                viewController.edgesForExtendedLayout.insert(.top)
                            case false:
                                viewController.edgesForExtendedLayout.remove(.top)
                            }
                        }
                    )
                case .bottomBars:
                    return .switch(
                        title: property.rawValue,
                        isOn: { viewController.edgesForExtendedLayout.contains(.bottom) },
                        handler: {
                            switch $0 {
                            case true:
                                viewController.edgesForExtendedLayout.insert(.bottom)
                            case false:
                                viewController.edgesForExtendedLayout.remove(.bottom)
                            }
                        }
                    )
                case .opaqueBars:
                    return .switch(
                        title: property.rawValue,
                        isOn: { viewController.extendedLayoutIncludesOpaqueBars },
                        handler: { viewController.extendedLayoutIncludesOpaqueBars = $0 }
                    )
                case .modalTransitionStyle:
                    return .optionsList(
                        title: property.rawValue,
                        emptyTitle: "Default",
                        axis: .horizontal,
                        options: UIModalTransitionStyle.allCases.map(\.description),
                        selectedIndex: { UIModalTransitionStyle.allCases.firstIndex(of: viewController.modalTransitionStyle) },
                        handler: {
                            guard let newIndex = $0 else { return }

                            let modalTransitionStyle = UIModalTransitionStyle.allCases[newIndex]
                            viewController.modalTransitionStyle = modalTransitionStyle
                        }
                    )
                case .presentationStyle:
                    return .optionsList(
                        title: property.rawValue,
                        emptyTitle: "Default",
                        axis: .horizontal,
                        options: UIModalPresentationStyle.allCases.map(\.description),
                        selectedIndex: { UIModalPresentationStyle.allCases.firstIndex(of: viewController.modalPresentationStyle) },
                        handler: {
                            guard let newIndex = $0 else { return }

                            let modalPresentationStyle = UIModalPresentationStyle.allCases[newIndex]
                            viewController.modalPresentationStyle = modalPresentationStyle
                        }
                    )
                case .definesPresentationContext:
                    return .switch(
                        title: property.rawValue,
                        isOn: { viewController.definesPresentationContext },
                        handler: { viewController.definesPresentationContext = $0 }
                    )
                case .providesPresentationContextTransitionStyle:
                    return .switch(
                        title: property.rawValue,
                        isOn: { viewController.providesPresentationContextTransitionStyle },
                        handler: { viewController.providesPresentationContextTransitionStyle = $0 }
                    )
                case .contentSize:
                    return .cgSize(
                        title: property.rawValue,
                        size: { viewController.preferredContentSize },
                        handler: {
                            guard let preferredContentSize = $0 else { return }
                            viewController.preferredContentSize = preferredContentSize
                        }
                    )
                }
            }
        }
    }
}
