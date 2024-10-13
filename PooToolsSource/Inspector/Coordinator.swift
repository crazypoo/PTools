//
//  Coordinator.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

/// A coordinator is an abstract object that has the sole responsibility to coordinate a fragment of an App's overall navigation.
///
/// Basically which screen should be shown, what screen should be shown next, etc.
open class Coordinator<Dependencies, Presenter, Content>: CoordinatorProtocol, Dismissable, Startable {
    public typealias _Self = Coordinator<Dependencies, Presenter, Content>

    /// The dependencies neeeded for this part of the navigation flow.
    public let dependencies: Dependencies

    /// The entitiy responsible for managing the presentation of the receiver's content.
    public let presenter: Presenter

    /// The parent coordinator of the recipient.
    ///
    /// If the recipient is a child of a container coordinator, this property holds the coordinator it is contained in. If the recipient has no parent, the value in this property is nil.
    /// Prior to iOS 5.0, if a view did not have a parent coordinator and was being presented, the presenting coordinator would be returned. On iOS 5, this behavior no longer occurs. Instead, use the presentingViewController property to access the presenting coordinator.
    open weak var parent: CoordinatorProtocol? {
        didSet {
            if oldValue != nil, parent == nil { dismissHandler?(self) }
        }
    }

    /// An array of view controllers that are children of the current view controller.
    open private(set) var children: [CoordinatorProtocol]

    open var dismissHandler: ((_Self) -> Void)?

    /// The object that will be returned at the start of the navigation flow. Must be injected by overriding the `loadStart()` method on your concrete implementation.
    open var content: Content!

    open private(set) var isStarted = false

    public init(
        _ dependencies: Dependencies,
        presentedBy presenter: Presenter,
        parent: CoordinatorProtocol? = nil,
        children: [CoordinatorProtocol] = []
    ) {
        self.dependencies = dependencies
        self.presenter = presenter
        self.parent = parent
        self.children = children

        children.forEach { addChild($0) }
    }

    public convenience init<WeakPresenter>(
        _ dependencies: Dependencies,
        weaklyPresentedBy presenter: WeakPresenter,
        parent: CoordinatorProtocol? = nil,
        children: [CoordinatorProtocol] = []
    ) where Presenter == Weak<WeakPresenter> {
        self.init(dependencies, presentedBy: Weak(presenter), parent: parent, children: children)
    }

    // MARK: - Start

    /// Creates the flow that the coordinator manages.

    /// This method gets called before `start()` is called for the first time.
    open func loadContent() -> Content? { .none }

    /// Starts the navigation flow and returns its result.
    open func start() -> Content {
        if isStarted == false {
            content = loadContent()

            if Content.self == Void.self {
                content = () as? Content
            }
        }
        isStarted = true
        return content
    }

    // MARK: - Remove From Parent

    /// Removes the coordinator from its parent.
    ///
    /// This method is only intended to be called by an implementation of a custom container coordinator.
    /// If you override this method, you must call super in your implementation.
    open func removeFromParent() {
        guard let parent = parent else { return }
        parent.removeChild(self)
    }

    // MARK: - Add Child

    /// Adds the specified coordinator as a child of the current coordinator.
    ///
    /// This method creates a parent-child relationship between the current coordinator and the object in the childController parameter.
    /// This relationship is necessary when embedding the child coordinator’s view into the current coordinator’s content.
    /// If the new child coordinator is already the child of a container coordinator, it is removed from that container before being added.
    /// If you override this method, you must call super in your implementation.
    open func addChild(_ coordinator: CoordinatorProtocol) {
        coordinator.removeFromParent()
        coordinator.parent = self

        for child in children where child === coordinator {
            return PTNSLogConsole("⚠️", className, "couldn't add child coordinator. \(coordinator.className) is already added")
        }

        children.append(coordinator)
        PTNSLogConsole("✅", className, "added", coordinator.className, "(\(children.count) children total)")
    }

    // MARK: - Remove Child

    /// Removes the specified coordinator as a child of the current coordinator.
    ///
    /// If you override this method, you must call super in your implementation.
    open func removeChild(_ coordinator: CoordinatorProtocol) {
        guard coordinator.parent === self else {
            return PTNSLogConsole("⚠️", className, "can't remove ", coordinator.className, ", it's owned by \(String(describing: coordinator.parent?.className))")
        }

        coordinator.parent = nil

        if let index = children.firstIndex(where: { $0 === coordinator }) {
            children.remove(at: index)
            PTNSLogConsole("🗑", className, "removed", coordinator.className, "\(children.count) children total.")
        }
        else {
            PTNSLogConsole("⚠️", className, "can't remove, coordinator isn't a child", coordinator.className)
        }
    }

    open func removeAllChildren() {
        children.forEach { removeChild($0) }
    }
}

// MARK: - Convenience

public extension Coordinator where Presenter: UIWindow {
    /// The window that is presenting this Coordinator's content.
    var window: Presenter { presenter }
}

public extension Coordinator where Presenter: UINavigationController {
    /// The navigation controller that is presenting this Coordinator's content.
    var navigationController: Presenter { presenter }
}

public extension Coordinator where Presenter: UISplitViewController {
    /// The split view controller that is presenting this Coordinator's content.
    var splitViewController: Presenter { presenter }
}

public extension Coordinator where Presenter: UITabBarController {
    /// The tab bar controller that is presenting this Coordinator's content.
    var tabBarController: Presenter { presenter }
}

public extension Coordinator where Presenter: UIViewController {
    /// The view controller that is presenting this Coordinator's content.
    var presentingViewController: Presenter { presenter }
}

public extension Coordinator where Presenter: UIApplication {
    /// The application delegate that is presenting this Coordinator's content.
    var appDelegate: UIApplicationDelegate? { presenter.delegate }

    /// The application delegate that is presenting this Coordinator's content.
    var application: Presenter { presenter }
}

public extension Coordinator where Presenter: OperationQueue {
    /// A queue that regulates the execution of this Coordinator's operations.
    var operationQueue: OperationQueue { presenter }
}

public extension Coordinator where Presenter == Weak<UIWindow> {
    /// The window that is presenting this Coordinator's content.
    var window: UIWindow? { presenter.weakReference }
}

public extension Coordinator where Presenter == Weak<UINavigationController> {
    /// The navigation controller that is presenting this Coordinator's content.
    var navigationController: UINavigationController? { presenter.weakReference }
}

public extension Coordinator where Presenter == Weak<UISplitViewController> {
    /// The split view controller that is presenting this Coordinator's content.
    var splitViewController: UISplitViewController? { presenter.weakReference }
}

public extension Coordinator where Presenter == Weak<UITabBarController> {
    /// The tab bar controller that is presenting this Coordinator's content.
    var tabBarController: UITabBarController? { presenter.weakReference }
}

public extension Coordinator where Presenter == Weak<UIViewController> {
    /// The view controller that is presenting this Coordinator's content.
    var presentingViewController: UIViewController? { presenter.weakReference }
}

// MARK: - Hashable

extension Coordinator: Hashable {
    public static func == (lhs: Coordinator<Dependencies, Presenter, StartResult>, rhs: Coordinator<Dependencies, Presenter, StartResult>) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

private extension CoordinatorProtocol {
    var className: String { "'\(type(of: self))'" }
}
