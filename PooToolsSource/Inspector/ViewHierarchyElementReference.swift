//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

protocol ViewHierarchyElementReference: ViewHierarchyElementRepresentable & AnyObject {
    var underlyingObject: NSObject? { get }

    var underlyingView: UIView? { get }

    var underlyingViewController: UIViewController? { get }

    func hasChanges(inRelationTo identifier: UUID) -> Bool

    var latestSnapshotIdentifier: UUID { get }

    var iconImage: UIImage? { get }

    var cachedIconImage: UIImage? { get }

    var parent: ViewHierarchyElementReference? { get set }

    var depth: Int { get set }

    var isCollapsed: Bool { get set }

    var children: [ViewHierarchyElementReference] { get set }

    var viewHierarchy: [ViewHierarchyElementReference] { get }
}

extension ViewHierarchyElementReference {
    var inspectorHostableViewHierarchy: [ViewHierarchyElementReference] {
        viewHierarchy.filter(\.canHostInspectorView)
    }

    var viewHierarchyDescription: String {
        let viewHierarchy = viewHierarchy

        var components: [String] = [
            "",
            elementName,
            String(repeating: "=", count: elementName.count),
            "",
            elementDescription
        ]

        guard viewHierarchy.count > 1 else {
            return components.joined(separator: .newLine)
        }

        components.append("")
        components.append("")
        components.append("Views:")
        components.append("------")
        components.append("")

        for child in viewHierarchy {
            let indentation = String(repeating: "﹒", count: child.depth - depth)
            let symbol = child.isContainer ? "▾" : "▸"

            var childComponents: [String] = [symbol]

            if let accessibilityIdentifier = child.accessibilityIdentifier {
                childComponents.append("\(accessibilityIdentifier) (\(child.className))")
            }
            else {
                childComponents.append(child.className)
            }

            let childDescription = childComponents.joined(separator: " ")

            components.append(indentation + childDescription)
        }

        return components.joined(separator: .newLine)
    }

    var isContainer: Bool { !children.isEmpty }

    var viewHierarchy: [ViewHierarchyElementReference] { [self] + allChildren }

    var allChildren: [ViewHierarchyElementReference] {
        children.reversed().flatMap(\.viewHierarchy)
    }

    var allParents: [ViewHierarchyElementReference] {
        var array = [ViewHierarchyElementReference]()

        if let parent = parent {
            array.append(parent)
            array.append(contentsOf: parent.allParents)
        }

        return array
    }

    var summaryInfo: ViewHierarchyElementSummary {
        ViewHierarchyElementSummary(
            iconImage: iconImage,
            isContainer: isContainer,
            subtitle: elementDescription,
            title: displayName
        )
    }

    // MARK: - Layer Views Convenience Methods

    var isShowingLayerWireframeView: Bool {
        underlyingView?.allSubviews.contains { $0 is WireframeView } ?? false
    }

    var isHostingAnyLayerHighlightView: Bool {
        underlyingView?.allSubviews.contains { $0 is InspectorHighlightView } ?? false
    }

    var containsVisibleHighlightViews: Bool {
        underlyingView?.allSubviews.contains { ($0 as? InspectorHighlightView)?.isHidden == false } ?? false
    }

    var highlightView: InspectorHighlightView? {
        underlyingView?._highlightView
    }
}
