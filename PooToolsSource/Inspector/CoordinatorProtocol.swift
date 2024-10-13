//
//  CoordinatorProtocol.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation
import UIKit

public typealias CoordinatorStartable = CoordinatorProtocol & Startable

public protocol CoordinatorProtocol: AnyObject {
    var parent: CoordinatorProtocol? { get set }

    var children: [CoordinatorProtocol] { get }

    func addChild(_ coordinator: CoordinatorProtocol)

    func removeChild(_ coordinator: CoordinatorProtocol)

    func removeAllChildren()

    func removeFromParent()
}

public extension Sequence where Element == CoordinatorProtocol {
    func filter<AnyCoordinator: CoordinatorProtocol>(type: AnyCoordinator.Type) -> [AnyCoordinator] {
        compactMap { $0 as? AnyCoordinator }
    }

    func forEach<AnyCoordinator: CoordinatorProtocol>(type: AnyCoordinator.Type, body: (AnyCoordinator) throws -> Void) rethrows {
        try filter(type: type).forEach(body)
    }
}

// MARK: - UIViewController based StartResult

public extension Startable where Self: CoordinatorProtocol, StartResult: UIViewController {
    /// Starts a child Coordinator and presents its start view controller modally from the top view controller.
    /// - Parameters:
    ///   - coordinator: A Coordinator to be added as child.
    ///   - animated: Pass true to animate the presentation; otherwise, pass false.
    func start<T: CoordinatorStartable>(presenting coordinator: T,
                                        animated: Bool) where T.StartResult: RootViewControllerProtocol
    {
        addChild(coordinator)

        let startViewController = coordinator.start()

        start().topPresentedViewController.present(startViewController, animated: animated)
    }
}

// MARK: - RootViewControllerProtocol based StartResult

public extension Startable where Self: CoordinatorProtocol, StartResult: RootViewControllerProtocol {
    /// Adds the child Coordinator to its children and then pushes the starting view controller onto the navigation controller's stack and updates the display.
    /// - Parameters:
    ///   - coordinator: A Coordinator to be added as child.
    ///   - navigationController: The navigation controller where the presentation will happen.
    ///   - animated: Pass true to animate the presentation; otherwise, pass false.
    func start<T: CoordinatorStartable>(pushing coordinator: T,
                                        in navigationController: UINavigationController,
                                        animated: Bool) where T.StartResult: UIViewController
    {
        addChild(coordinator)

        let startViewController = coordinator.start()

        navigationController.pushViewController(startViewController, animated: animated)
    }
}

// MARK: - UINavigationController based StartResult

public extension Startable where Self: CoordinatorProtocol, StartResult: UINavigationController {
    /// Adds the child Coordinator to its children and then pushes the starting view controller onto its start navigation controller's stack and updates the display.
    /// - Parameters:
    ///   - coordinator: A Coordinator to be added as child.
    ///   - animated: Pass true to animate the presentation; otherwise, pass false.
    func start<T: CoordinatorStartable>(pushing coordinator: T,
                                        animated: Bool) where T.StartResult: UIViewController
    {
        addChild(coordinator)

        let startViewController = coordinator.start()

        start().pushViewController(startViewController, animated: animated)
    }
}

// MARK: - UIWindow based StartResult

public extension Startable where Self: CoordinatorProtocol, StartResult: UIWindow {
    /// Replaces existing children with the child coordinator and installs the starting view controller’s view as the content view of the window.
    /// - Parameter coordinator: A Coordinator to be added as child.
    func start<T: CoordinatorStartable>(root coordinator: T) where T.StartResult: RootViewControllerProtocol {
        removeAllChildren()

        addChild(coordinator)

        let startRootViewController = coordinator.start()

        start().rootViewController = startRootViewController
        start().makeKeyAndVisible()
    }

    /// Starts a child Coordinator and presents its start view controller modally from the starting window's top view controller.
    /// - Parameters:
    ///   - coordinator: A Coordinator to be added as child.
    ///   - animated: Pass true to animate the presentation; otherwise, pass false.
    func start<T: CoordinatorStartable>(presenting coordinator: T,
                                        animated: Bool) where T.StartResult: RootViewControllerProtocol
    {
        addChild(coordinator)

        let startRootViewController = coordinator.start()

        start().makeKeyAndVisible()
        start().rootViewController?.topPresentedViewController.present(startRootViewController, animated: animated)
    }
}
