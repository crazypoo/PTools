//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import MapKit
import UIKit
import WebKit
import SafeSFSymbols

extension ViewHierarchyElementIconProvider {
    static let `default` = ViewHierarchyElementIconProvider { object in

        guard let object = object else { return .missingSymbol }

        guard let view = object as? UIView else {
            switch object {
            case is UISearchController:
                return .searchController

            case is UIPageViewController:
                return .pageViewController

            case is UINavigationController:
                return .navigationController

            case is UICollectionViewController:
                return .collectionViewController

            case is UITableViewController:
                return .tableViewController

            case is UITabBarController:
                return .tabBarController

            default:
                return .nsObject
            }
        }

        guard view.isHidden == false else { return .hiddenViewSymbol }

        switch view {
        case let window as UIWindow:
            if window._className.contains("Keyboard") { return .keyboardWindow }
            if window.isKeyWindow { return .keyWindow }
            return .window

        case is UIActivityIndicatorView:
            return .activityIndicatorView

        case is UISlider:
            return .slider

        case is UIDatePicker:
            return .datePicker

        case is UISwitch:
            return .toggle

        case is UIButton,
             is UIControl where view.className.contains("Button"):
            return .button

        case let imageView as UIImageView:
            guard let image = imageView.isHighlighted ? imageView.highlightedImage : imageView.image else {
                return .imageView
            }
            return image

        case is UISegmentedControl:
            return .segmentedControl

        case let stackView as UIStackView:
            return stackView.axis == .horizontal ? .horizontalStack : .verticalStack

        case is UILabel:
            return .staticText

        case is UITextField:
            return .textField

        case is UITextView:
            return .textView

        case is WKWebView:
            return .webView

        case is UICollectionView:
            return .collectionView

        case is UITableView:
            return .tableView

        case is UIScrollView:
            return .scrollView

        case is UINavigationBar:
            return .navigationBar

        case is UITabBar:
            return .tabBar

        case is UIToolbar:
            return .toolbar

        case is UIControl:
            return .control

        case is MKMapView:
            return .mapView

        case let view:
            if view._className == "CGDrawingView" { return .staticText }
            if view._className.contains("Effects") { return .init(.wand.andStars) }
            if view.children.isEmpty { return .emptyViewSymbol }
            if view.className.contains("Background") { return .icon("BackgroundView-32_Normal") }
            if view.className.contains("DropShadow") { return .icon("DropShadow-32_Normal") }
            if view.className.contains("Label") { return .staticText }
            if view.className.contains("TransitionView") { return .icon("UITransitionView-32_Normal") }
            return .containerViewSymbol
        }
    }
}

private extension UIImage {
    static let activityIndicatorView: UIImage = UIImage(.cursorarrow.rays,weight: .bold)
    static let button: UIImage = UIImage(.hand.tapFill)
    static let collectionView: UIImage = UIImage(systemName: "square.grid.3x1.below.line.grid.1x2")!
    static let collectionViewController: UIImage = UIImage(.square.grid_3x3)
    static let containerViewSymbol: UIImage = .icon("filled-view-32_Normal")!
    static let control: UIImage = UIImage(systemName: "dial.min.fill")!
    static let datePicker: UIImage = .icon("UIDatePicker_32_Normal")!
    static let emptyViewSymbol: UIImage = .icon("EmptyView-32_Normal")!
    static let horizontalStack: UIImage = .icon("HStack-32_Normal")!
    static let imageView: UIImage = UIImage(.photo)
    static let keyWindow: UIImage = .icon("Key-UIWindow-32_Normal")!
    static let keyboardWindow: UIImage = UIImage(.keyboard.macwindow,weight: .regular)
    static let mapView: UIImage = UIImage(.map)
    static let navigationBar: UIImage = .icon("NavigationBar-32_Normal")!
    static let navigationController: UIImage = UIImage(.chevron.leftSquare)
    static let nsObject: UIImage = UIImage(.shippingbox,weight:.regular)
    static let pageViewController: UIImage = .icon("UIPageViewController")!
    static let scrollView: UIImage = .icon("UIScrollView_32_Normal")!
    static let searchController: UIImage = .icon("UISearchController")!
    static let segmentedControl: UIImage = .icon("UISegmentedControl_32_Normal")!
    static let slider: UIImage = .icon("UISlider_32_Normal")!
    static let staticText: UIImage = UIImage(.textformat.abc,weight:.bold)
    static let tabBar: UIImage = .icon("TabbedView-32_Normal")!
    static let tabBarController: UIImage = .icon("TabbedView-32_Normal")!
    static let tableView: UIImage = UIImage(.square.fillTextGrid_1x2)
    static let tableViewController: UIImage = .icon("UITableViewController")!
    static let textField: UIImage = UIImage(systemName: "character.textbox")!.applyingSymbolConfiguration(.init(weight: .bold))!
    static let textView: UIImage = UIImage(.textformat.abcDottedunderline,weight:.bold)
    static let toggle: UIImage = .icon("Toggle-32_Normal")!
    static let toolbar: UIImage = .icon("UIToolbar-32_Normal")!
    static let verticalStack: UIImage = .icon("VStack-32_Normal")!
    static let webView: UIImage = UIImage(.safari)
    static let window: UIImage = UIImage(.macwindow,weight:.regular)
}
