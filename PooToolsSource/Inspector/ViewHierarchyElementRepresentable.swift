//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

/// A protocol that represents the public interface of a UIView.
protocol ViewHierarchyElementRepresentable {
    var canHostContextMenuInteraction: Bool { get }

    var objectIdentifier: ObjectIdentifier { get }

    /// Determines if a view can host an inspector view.
    var canHostInspectorView: Bool { get }

    var isInternalView: Bool { get }

    var isSystemContainer: Bool { get }

    /// String representation of the class name.
    var className: String { get }

    /// /// String representation of the class name without Generics signature.
    var classNameWithoutQualifiers: String { get }

    /// If a view has accessibility identifiers the last component will be shown, otherwise shows the class name.
    var elementName: String { get }

    var displayName: String { get }

    var canPresentOnTop: Bool { get }

    var isUserInteractionEnabled: Bool { get }

    var frame: CGRect { get }

    var accessibilityIdentifier: String? { get }

    // MARK: - Issues

    var issues: [ViewHierarchyIssue] { get }

    // MARK: - Constraints

    var constraintElements: [LayoutConstraintElement] { get }

    // MARK: - Description

    var shortElementDescription: String { get }

    var elementDescription: String { get }

    var overrideViewHierarchyInterfaceStyle: ViewHierarchyInterfaceStyle { get }

    var traitCollection: UITraitCollection { get }

    var isHidden: Bool { get set }
}

extension ViewHierarchyElementRepresentable {
    var hasIssues: Bool { !issues.isEmpty }
}
