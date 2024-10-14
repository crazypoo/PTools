//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension ElementInspectorViewCode {
    struct Content {
        enum `Type`: Hashable, Swift.CaseIterable {
            case panelView, scrollView, backgroundView
        }

        let view: UIView

        let type: `Type`

        private init(type: Type, view: UIView) {
            self.type = type
            self.view = view
        }

        static func panelView(_ panelView: UIView) -> Content {
            .init(type: .panelView, view: panelView)
        }

        static func scrollView(_ scrollView: UIView) -> Content {
            .init(type: .scrollView, view: scrollView)
        }

        static func empty(withMessage message: String) -> Content {
            let label = UILabel()
            label.text = message
            label.font = .preferredFont(forTextStyle: .body)
            label.directionalLayoutMargins = Inspector.sharedInstance.appearance.elementInspector.directionalInsets
            label.textAlignment = .center
            label.textColor = label.colorStyle.tertiaryTextColor

            return .init(type: .backgroundView, view: label)
        }

        static var loadingIndicator: Content {
            let activityIndicator = UIActivityIndicatorView()
            activityIndicator.style = .large
            activityIndicator.hidesWhenStopped = true
            activityIndicator.color = activityIndicator.colorStyle.secondaryTextColor
            activityIndicator.startAnimating()

            activityIndicator.alpha = 0
            activityIndicator.transform = .init(scaleX: 0, y: 0)

            activityIndicator.animate(withDuration: .long, delay: .long) {
                activityIndicator.alpha = 1
                activityIndicator.transform = .identity
            }

            return .init(type: .backgroundView, view: activityIndicator.wrappedInside(UIView.self))
        }
    }
}
