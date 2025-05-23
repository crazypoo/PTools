//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import UniformTypeIdentifiers

extension ViewHierarchyElement {
    struct Snapshot: ViewHierarchyElementRepresentable, ExpirableProtocol, Equatable {
        static func == (lhs: ViewHierarchyElement.Snapshot, rhs: ViewHierarchyElement.Snapshot) -> Bool {
            lhs.identifier == rhs.identifier
        }

        let identifier = UUID()
        let objectIdentifier: ObjectIdentifier
        let parent: ViewHierarchyElementReference? = nil
        var accessibilityIdentifier: String?
        var canHostInspectorView: Bool
        var canHostContextMenuInteraction: Bool
        var canPresentOnTop: Bool
        var className: String
        var classNameWithoutQualifiers: String
        var constraintElements: [LayoutConstraintElement]
        var depth: Int
        var displayName: String
        var elementDescription: String
        var elementName: String
        var expirationDate: Date = makeExpirationDate()
        var frame: CGRect
        var iconImage: UIImage?
        var isContainer: Bool
        var isHidden: Bool
        var isInternalView: Bool
        var isSystemContainer: Bool
        var isUserInteractionEnabled: Bool
        var issues: [ViewHierarchyIssue]
        var overrideViewHierarchyInterfaceStyle: ViewHierarchyInterfaceStyle
        var shortElementDescription: String
        var traitCollection: UITraitCollection

        init(view: UIView, icon: UIImage?, depth: Int) {
            self.depth = depth

            accessibilityIdentifier = view.accessibilityIdentifier
            canHostContextMenuInteraction = view.canHostContextMenuInteraction
            canHostInspectorView = view.canHostInspectorView
            canPresentOnTop = view.canPresentOnTop
            className = view._className
            classNameWithoutQualifiers = view._classNameWithoutQualifiers
            constraintElements = view.constraintElements
            displayName = view.displayName
            elementDescription = view.elementDescription
            elementName = view.elementName
            frame = view.frame
            iconImage = icon
            isContainer = !view.children.isEmpty
            isHidden = view.isHidden
            isInternalView = view.isInternalView
            isSystemContainer = view.isSystemContainer
            isUserInteractionEnabled = view.isUserInteractionEnabled
            issues = view.issues
            objectIdentifier = view.objectIdentifier
            overrideViewHierarchyInterfaceStyle = view.overrideViewHierarchyInterfaceStyle
            shortElementDescription = view.shortElementDescription
            traitCollection = view.traitCollection
        }

        private static func makeExpirationDate() -> Date {
            let expiration = Inspector.sharedInstance.configuration.snapshotExpirationTimeInterval
            let expirationDate = Date().addingTimeInterval(expiration)

            return expirationDate
        }
    }
}

final class ViewHierarchyElement: CustomDebugStringConvertible {
    var debugDescription: String {
        String(describing: store.latest)
    }

    weak var underlyingView: UIView?

    weak var parent: ViewHierarchyElementReference?

    let iconProvider: ViewHierarchyElementIconProvider?

    private var store: SnapshotStore<Snapshot>

    var isCollapsed: Bool

    var depth: Int {
        didSet {
            children.forEach { $0.depth = depth + 1 }
        }
    }

    lazy var children: [ViewHierarchyElementReference] = makeChildren()

    private(set) lazy var allChildren: [ViewHierarchyElementReference] = children.flatMap(\.viewHierarchy)

    // MARK: - Computed Properties

    var deepestAbsoulteLevel: Int {
        children.map(\.depth).max() ?? depth
    }

    var deepestRelativeLevel: Int {
        deepestAbsoulteLevel - depth
    }

    // MARK: - Init

    init(
        with view: UIView,
        iconProvider: ViewHierarchyElementIconProvider? = .none,
        depth: Int = .zero,
        isCollapsed: Bool = false,
        parent: ViewHierarchyElementReference? = .none
    ) {
        underlyingView = view
        self.depth = depth
        self.parent = parent
        self.iconProvider = iconProvider
        self.isCollapsed = isCollapsed
        isUnderlyingViewUserInteractionEnabled = view.isUserInteractionEnabled

        let initialSnapshot = Snapshot(
            view: view,
            icon: iconProvider?.resizedIcon(for: view),
            depth: depth
        )

        store = SnapshotStore(initialSnapshot)
    }

    var latestSnapshot: Snapshot { store.latest }

    var isUnderlyingViewUserInteractionEnabled: Bool

    private func makeChildren() -> [ViewHierarchyElementReference] {
        guard let underlyingView = underlyingView else { return [] }
        return underlyingView
            .children
            .compactMap {
                ViewHierarchyElement(
                    with: $0,
                    iconProvider: iconProvider,
                    depth: depth + 1,
                    parent: self
                )
            }
    }
}

// MARK: - ViewHierarchyElementReference {

extension ViewHierarchyElement: ViewHierarchyElementReference {
    var canHostContextMenuInteraction: Bool {
        store.latest.canHostContextMenuInteraction
    }

    var isSystemContainer: Bool {
        store.first.isSystemContainer
    }

    var underlyingObject: NSObject? {
        underlyingView
    }

    var underlyingViewController: UIViewController? { nil }

    var isHidden: Bool {
        get {
            underlyingView?.isHidden ?? false
        }
        set {
            underlyingView?.isHidden = newValue
        }
    }

    func hasChanges(inRelationTo identifier: UUID) -> Bool {
        latestSnapshotIdentifier != identifier
    }

    var latestSnapshotIdentifier: UUID {
        latestSnapshot.identifier
    }

    var isUserInteractionEnabled: Bool {
        isUnderlyingViewUserInteractionEnabled
    }

    var overrideViewHierarchyInterfaceStyle: ViewHierarchyInterfaceStyle {
        guard store.latest.isExpired, let rootView = underlyingView else {
            return store.latest.overrideViewHierarchyInterfaceStyle
        }

        if rootView.overrideViewHierarchyInterfaceStyle != store.latest.overrideViewHierarchyInterfaceStyle {
            scheduleSnapshot()
        }

        return rootView.overrideViewHierarchyInterfaceStyle
    }

    var traitCollection: UITraitCollection {
        guard store.latest.isExpired, let rootView = underlyingView else {
            return store.latest.traitCollection
        }

        if rootView.traitCollection != store.latest.traitCollection {
            scheduleSnapshot()
        }

        return rootView.traitCollection
    }

    var iconImage: UIImage? {
        iconProvider?.resizedIcon(for: underlyingView)
    }

    // MARK: - Cached properties

    var cachedIconImage: UIImage? {
        guard store.latest.isExpired, let rootView = underlyingView else {
            return store.latest.iconImage
        }

        let currentIcon = iconProvider?.resizedIcon(for: rootView)

        if currentIcon?.pngData() != store.latest.iconImage?.pngData() {
            scheduleSnapshot()
        }

        return currentIcon
    }

    var isContainer: Bool {
        guard store.latest.isExpired, let rootView = underlyingView else {
            return store.latest.isContainer
        }

        if rootView.isContainer != store.latest.isContainer {
            scheduleSnapshot()
        }

        return rootView.isContainer
    }

    var shortElementDescription: String {
        guard store.latest.isExpired, let rootView = underlyingView else {
            return store.latest.shortElementDescription
        }

        if rootView.shortElementDescription != store.latest.shortElementDescription {
            scheduleSnapshot()
        }

        return rootView.shortElementDescription
    }

    var elementDescription: String {
        guard let rootView = underlyingView else {
            return store.latest.elementDescription
        }

        if rootView.canHostInspectorView != store.latest.canHostInspectorView {
            scheduleSnapshot()
        }

        return rootView.elementDescription
    }

    var canHostInspectorView: Bool {
        guard store.latest.isExpired, let rootView = underlyingView else {
            return store.latest.canHostInspectorView
        }

        if rootView.canHostInspectorView != store.latest.canHostInspectorView {
            scheduleSnapshot()
        }

        return rootView.canHostInspectorView
    }

    var isInternalView: Bool {
        guard store.latest.isExpired, let rootView = underlyingView else {
            return store.latest.isInternalView
        }

        if rootView.isInternalView != store.latest.isInternalView {
            scheduleSnapshot()
        }

        return rootView.isInternalView
    }

    var elementName: String {
        guard store.latest.isExpired, let rootView = underlyingView else {
            return store.latest.elementName
        }

        if rootView.elementName != store.latest.elementName {
            scheduleSnapshot()
        }

        return rootView.elementName
    }

    var displayName: String {
        guard store.latest.isExpired, let rootView = underlyingView else {
            return store.latest.displayName
        }

        if rootView.displayName != store.latest.displayName {
            scheduleSnapshot()
        }

        return rootView.displayName
    }

    var frame: CGRect {
        guard store.latest.isExpired, let rootView = underlyingView else {
            return store.latest.frame
        }

        if rootView.frame != store.latest.frame {
            scheduleSnapshot()
        }

        return rootView.frame
    }

    var accessibilityIdentifier: String? {
        guard store.latest.isExpired, let rootView = underlyingView else {
            return store.latest.accessibilityIdentifier
        }

        if rootView.accessibilityIdentifier != store.latest.accessibilityIdentifier {
            scheduleSnapshot()
        }

        return rootView.accessibilityIdentifier
    }

    var constraintElements: [LayoutConstraintElement] {
        guard store.latest.isExpired, let rootView = underlyingView else {
            return store.latest.constraintElements
        }

        if rootView.constraintElements != store.latest.constraintElements {
            scheduleSnapshot()
        }

        return rootView.constraintElements
    }

    enum SnapshotSchedulingError: Error {
        case dealocatedSelf, lostConnectionToView
    }

    private func scheduleSnapshot(_ handler: ((Result<Snapshot, SnapshotSchedulingError>) -> Void)? = nil) {
        store.scheduleSnapshot(
            .init(closure: { [weak self] in
                guard let self = self else {
                    handler?(.failure(.dealocatedSelf))
                    return nil
                }

                guard let rootView = self.underlyingView else {
                    handler?(.failure(.lostConnectionToView))
                    return nil
                }

                let snapshot = Snapshot(
                    view: rootView,
                    icon: self.iconProvider?.resizedIcon(for: rootView),
                    depth: self.depth
                )

                handler?(.success(snapshot))

                return snapshot
            }
            )
        )
    }

    // MARK: - Live Properties

    var canPresentOnTop: Bool {
        store.first.canPresentOnTop
    }

    var className: String {
        store.first.className
    }

    var classNameWithoutQualifiers: String {
        store.first.classNameWithoutQualifiers
    }

    var issues: [ViewHierarchyIssue] {
        guard let rootView = underlyingView else {
            var issues = store.latest.issues
            issues.append(.lostConnection)

            return issues
        }

        if rootView.issues != store.latest.issues {
            scheduleSnapshot()
        }

        return rootView.issues
    }

    var objectIdentifier: ObjectIdentifier {
        store.first.objectIdentifier
    }
}

// MARK: - Hashable

extension ViewHierarchyElement: Hashable {
    static func == (lhs: ViewHierarchyElement, rhs: ViewHierarchyElement) -> Bool {
        lhs.objectIdentifier == rhs.objectIdentifier
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(objectIdentifier)
    }
}

private extension ViewHierarchyElementIconProvider {
    func resizedIcon(for view: UIView?) -> UIImage? {
        autoreleasepool {
            value(for: view)?.resized(.elementIconSize)
        }
    }
}
