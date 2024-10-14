//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

@available(*, deprecated, renamed: "InspectorElementSectionDataSource")
public typealias InspectorElementViewModelProtocol = InspectorElementSectionDataSource

/// An object that provides the information necessary to represent an Element Inspector section.
public protocol InspectorElementSectionDataSource: AnyObject {
    /// An optional subtitle that can be shown below the title.
    var title: String { get }
    /// An optional subtitle that can be shown below the title.
    var subtitle: String? { get }
    /// A list of properties to be displayed.
    var properties: [InspectorElementProperty] { get }
    /// To customize how your sections look provide a type that conforms to `InspectorElementFormSectionView`.
    var customClass: InspectorElementSectionView.Type? { get }
    /// Constant describing the currentstate of the section.
    var state: InspectorElementSectionState { get set }
    /// An optional property to be displayed next to the title.
    var titleAccessoryProperty: InspectorElementProperty? { get }
}

public extension InspectorElementSectionDataSource {
    var subtitle: String? { nil }
    var customClass: InspectorElementSectionView.Type? { nil }
    var titleAccessoryProperty: InspectorElementProperty? { nil }
}

extension InspectorElementSectionDataSource {
    func makeView() -> InspectorElementSectionView {
        let aClass = customClass ?? InspectorElementSectionFormView.self

        let view = aClass.makeItemView(with: state)

        return view
    }
}
