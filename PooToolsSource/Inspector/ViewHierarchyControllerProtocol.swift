//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

/// A protocol that maps the public properties of a UIViewController.
protocol ViewHierarchyControllerProtocol {
    var className: String { get }
    var classNameWithoutQualifiers: String { get }
    var additionalSafeAreaInsets: UIEdgeInsets { get }
    var definesPresentationContext: Bool { get }
    var disablesAutomaticKeyboardDismissal: Bool { get }
    var edgesForExtendedLayout: UIRectEdge { get }
    var editButtonItem: UIBarButtonItem { get }
    var extendedLayoutIncludesOpaqueBars: Bool { get }
    var isBeingPresented: Bool { get }
    var isEditing: Bool { get }
    var isModalInPresentation: Bool { get }
    var isSystemContainer: Bool { get }
    var isViewLoaded: Bool { get }
    var modalPresentationStyle: UIModalPresentationStyle { get }
    var modalTransitionStyle: UIModalTransitionStyle { get }
    var navigationItem: UINavigationItem { get }
    var nibName: String? { get }
    var overrideViewHierarchyInterfaceStyle: ViewHierarchyInterfaceStyle { get }
    var performsActionsWhilePresentingModally: Bool { get }
    var preferredContentSize: CGSize { get }
    var preferredScreenEdgesDeferringSystemGestures: UIRectEdge { get }
    var preferredStatusBarStyle: UIStatusBarStyle { get }
    var preferredStatusBarUpdateAnimation: UIStatusBarAnimation { get }
    var prefersHomeIndicatorAutoHidden: Bool { get }
    var prefersPointerLocked: Bool { get }
    var prefersStatusBarHidden: Bool { get }
    var providesPresentationContextTransitionStyle: Bool { get }
    var restorationClassName: String? { get }
    var restorationIdentifier: String? { get }
    var restoresFocusAfterTransition: Bool { get }
    var shouldAutomaticallyForwardAppearanceMethods: Bool { get }
    var systemMinimumLayoutMargins: NSDirectionalEdgeInsets { get }
    var title: String? { get }
    var traitCollection: UITraitCollection { get }
    var viewRespectsSystemMinimumLayoutMargins: Bool { get }
}
