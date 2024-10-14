//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import MapKit
import UIKit
import WebKit

typealias ViewHierarchyLayer = Inspector.ViewHierarchyLayer

public extension Inspector {
    struct ViewHierarchyLayer: Hashable {
        public typealias Filter = (UIView) -> Bool

        // MARK: - Properties

        public var name: String

        var showLabels: Bool = true

        var allowsInternalViews: Bool = false

        var allowsSystemContainers: Bool = false

        @HashableValue public var filter: Filter

        // MARK: - Init

        public static func layer(name: String, filter: @escaping Filter) -> ViewHierarchyLayer {
            ViewHierarchyLayer(name: name, filter: filter)
        }

        // MARK: - Metods

        func makeKeysForInspectableElements(in snapshot: ViewHierarchySnapshot) -> [ViewHierarchyElementKey] {
            filter(viewHierarchy: snapshot.root.inspectorHostableViewHierarchy).compactMap { ViewHierarchyElementKey(reference: $0) }
        }

        func filter(viewHierarchy: [ViewHierarchyElementReference]) -> [ViewHierarchyElementReference] {
            let filteredViews = viewHierarchy.filter {
                guard
                    let rootView = $0.underlyingView,
                    rootView.isHidden == false,
                    rootView is NonInspectableView == false
                else {
                    return false
                }

                if !allowsInternalViews, $0.isInternalView {
                    return false
                }

                if !allowsSystemContainers, $0.isSystemContainer {
                    return false
                }

                let result = filter(rootView)

                return result
            }

            switch allowsInternalViews {
            case true:
                return filteredViews

            case false:
                return filteredViews.filter { $0.isInternalView == false }
            }
        }
    }
}

// MARK: - Comparable

extension ViewHierarchyLayer: Comparable {
    public static func < (lhs: Inspector.ViewHierarchyLayer, rhs: Inspector.ViewHierarchyLayer) -> Bool {
        lhs.title.localizedLowercase < rhs.title.localizedLowercase
    }
}

// MARK: - Built-in layers

public extension ViewHierarchyLayer {
    /// Highlights activity indicator views
    static let activityIndicators = Inspector.ViewHierarchyLayer(name: "Activity Indicators", allowsInternalViews: true) { $0 is UIActivityIndicatorView }
    /// Highlights buttons
    static let buttons = Inspector.ViewHierarchyLayer(name: "Buttons", allowsInternalViews: true) { $0 is UIButton }
    /// Highlights collection views
    static let collectionViews = Inspector.ViewHierarchyLayer(name: "Collection Views") { $0 is UICollectionView }
    /// Highlights all container views
    static let containerViews = Inspector.ViewHierarchyLayer(name: "Containers", allowsInternalViews: true) { $0.className == "UIView" && $0.children.isEmpty == false }
    /// Highlights all controls
    static let controls = Inspector.ViewHierarchyLayer(name: "Controls", allowsInternalViews: true) { $0 is UIControl }
    /// Highlights all image views
    static let images = Inspector.ViewHierarchyLayer(name: "Images", allowsInternalViews: true) { $0 is UIImageView }
    /// Highlights all map views
    static let maps = Inspector.ViewHierarchyLayer(name: "Maps") { $0 is MKMapView }
    /// Highlights all picker views
    static let pickers = Inspector.ViewHierarchyLayer(name: "Pickers") { $0 is UIPickerView }
    /// Highlights all progress indicator views
    static let progressIndicators = Inspector.ViewHierarchyLayer(name: "Progress Indicators") { $0 is UIProgressView }
    /// Highlights all scroll views
    static let scrollViews = Inspector.ViewHierarchyLayer(name: "Scroll Views") { $0 is UIScrollView }
    /// Highlights all segmented controls
    static let segmentedControls = Inspector.ViewHierarchyLayer(name: "Segmented Controls") { $0 is UISegmentedControl }
    /// Highlights all spacer views
    static let spacerViews = Inspector.ViewHierarchyLayer(name: "Spacers") { $0.className == "UIView" && $0.children.isEmpty }
    /// Highlights all stack views
    static let stackViews = Inspector.ViewHierarchyLayer(name: "Stacks", allowsInternalViews: true) { $0 is UIStackView }
    /// Highlights all table view cells
    static let tableViewCells = Inspector.ViewHierarchyLayer(name: "Table Cells") { $0 is UITableViewCell }
    /// Highlights all collection resusable views
    static let collectionViewReusableView = Inspector.ViewHierarchyLayer(name: "Collection Reusable Views") { $0 is UICollectionReusableView }
    /// Highlights all collection view cells
    static let collectionViewCells = Inspector.ViewHierarchyLayer(name: "Collection Cells") { $0 is UICollectionViewCell }
    /// Highlights all static texts
    static let staticTexts = Inspector.ViewHierarchyLayer(name: "Static Texts", allowsInternalViews: true) { $0 is UILabel || $0._className == "CGDrawingView" }
    /// Highlights all switches
    static let switches = Inspector.ViewHierarchyLayer(name: "Switches") { $0 is UISwitch }
    /// Highlights all table views
    static let tables = Inspector.ViewHierarchyLayer(name: "Tables") { $0 is UITableView }
    /// Highlights all text fields
    static let textFields = Inspector.ViewHierarchyLayer(name: "Text Fields") { $0 is UITextField }
    /// Highlights all text views
    static let textViews = Inspector.ViewHierarchyLayer(name: "Text Views") { $0 is UITextView }
    /// Highlights all text inputs
    static let textInputs = Inspector.ViewHierarchyLayer(name: "Editable Texts") { ($0 as? UITextView)?.isEditable == true || $0 is UITextField }
    /// Highlights all web views
    static let webViews = Inspector.ViewHierarchyLayer(name: "Web Views") { $0 is WKWebView }
    /// Highlights all system containers
    static let systemContainers = Inspector.ViewHierarchyLayer(name: "System Containers", showLabels: true, allowsInternalViews: true, allowsSystemContainers: true) { $0._isSystemContainer }
    /// Highlights views with a valid UI Automation identifier
    static let accessibilityIdentifiers = Inspector.ViewHierarchyLayer(name: "Accessibility Identifier") { $0.accessibilityIdentifier?.trimmed.stringIsEmpty() == false }
    static let accessibilityLabels = Inspector.ViewHierarchyLayer(name: "Accessibility Label") { $0.accessibilityLabel?.trimmed.stringIsEmpty() == false }
    static let accessibilityElements = Inspector.ViewHierarchyLayer(name: "Accessibility Elements") { $0.isAccessibilityElement }
    static let navigationBars = Inspector.ViewHierarchyLayer(name: "Navigation Bars") { $0 is UINavigationBar }
    static let tabBars = Inspector.ViewHierarchyLayer(name: "Tab Bars") { $0 is UITabBar }
    /// Shows frames of all views
    static let wireframes = Inspector.ViewHierarchyLayer(name: "Wireframes", showLabels: false, allowsInternalViews: true) { _ in true }
    /// Highlights all
    static let internalViews = Inspector.ViewHierarchyLayer(name: "Internal Views", showLabels: true, allowsInternalViews: true) { $0._isInternalView }
}
