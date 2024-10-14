//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import MapKit
import UIKit
import WebKit

enum DefaultElementAttributesLibrary: Swift.CaseIterable, InspectorElementLibraryProtocol {
    case activityIndicator
    case application
    case button
    case control
    case datePicker
    case imageView
    case label
    case mapView
    case navigationBar
    case navigationController
    case scrollView
    case segmentedControl
    case slider
    case stackView
    case `switch`
    case tabBar
    case tableView
    case textField
    case textView
    case view
    case viewController
    case webView
    case window

    // MARK: - InspectorElementLibraryProtocol

    var targetClass: AnyClass {
        switch self {
        case .activityIndicator: return UIActivityIndicatorView.self
        case .application: return UIApplication.self
        case .button: return UIButton.self
        case .control: return UIControl.self
        case .datePicker: return UIDatePicker.self
        case .imageView: return UIImageView.self
        case .label: return UILabel.self
        case .mapView: return MKMapView.self
        case .navigationBar: return UINavigationBar.self
        case .navigationController: return UINavigationController.self
        case .scrollView: return UIScrollView.self
        case .segmentedControl: return UISegmentedControl.self
        case .slider: return UISlider.self
        case .stackView: return UIStackView.self
        case .switch: return UISwitch.self
        case .tabBar: return UITabBar.self
        case .tableView: return UITableView.self
        case .textField: return UITextField.self
        case .textView: return UITextView.self
        case .view: return UIView.self
        case .viewController: return UIViewController.self
        case .webView: return WKWebView.self
        case .window: return UIWindow.self
        }
    }

    func sections(for object: NSObject) -> InspectorElementSections {
        switch self {
        case .application:
            let firstSection = InspectorElementSection(rows: ApplicationAttributesSectionDataSource(with: object))

            guard
                let application = object as? UIApplication,
                let shortcutItems = application.shortcutItems,
                !shortcutItems.isEmpty
            else {
                return [firstSection]
            }

            return [
                firstSection,
                InspectorElementSection(
                    title: "Shortcut Items",
                    rows: shortcutItems.map(ApplicationShortcutItemSectionDataSource.init(with:))
                )
            ]

        case .viewController:
            guard let viewController = object as? UIViewController else { return .empty }

            let firstSection = InspectorElementSection(
                rows:
                ViewControllerAttributesSectionDataSource(with: viewController),
                TabBarItemAttributesSectionDataSource(with: viewController),
                NavigationItemAttributesSectionDataSource(with: viewController)
            )

            guard
                let keyCommands = viewController.keyCommands,
                !keyCommands.isEmpty
            else {
                return [firstSection]
            }

            return [
                firstSection,
                InspectorElementSection(
                    title: "Key Commands",
                    rows: keyCommands.map(KeyCommandsSectionDataSource.init(with:))
                )
            ]

        case .navigationBar:
            var section = InspectorElementSection(
                rows:
                NavigationBarAppearanceAttributesSectionDataSource(with: object, .standard),
                NavigationBarAppearanceAttributesSectionDataSource(with: object, .compact),
                NavigationBarAppearanceAttributesSectionDataSource(with: object, .scrollEdge)
            )

            if #available(iOS 15.0, *) {
                section.append(NavigationBarAppearanceAttributesSectionDataSource(with: object, .compactScrollEdge))
            }

            section.append(NavigationBarAttributesSectionDataSource(with: object))

            return [section]

        case .view: return .init(
                with:
                ViewAttributesSectionDataSource(with: object),
                LayerAttributesSectionDataSource(with: object)
            )

        case .navigationController: return .init(with: NavigationControllerAttributesSectionDataSource(with: object))

        case .tableView: return .init(with: TableViewAttributesSectionDataSource(with: object))

        case .window: return .init(with: WindowAttributesSectionDataSource(with: object))

        case .activityIndicator: return .init(with: ActivityIndicatorViewAttributesSectionDataSource(with: object))

        case .button: return .init(with: ButtonAttributesSectionDataSource(with: object))

        case .control: return .init(with: ControlAttributesSectionDataSource(with: object))

        case .datePicker: return .init(with: DatePickerAttributesSectionDataSource(with: object))

        case .imageView: return .init(with: ImageViewAttributesSectionDataSource(with: object))

        case .label: return .init(with: LabelAttributesSectionDataSource(with: object))

        case .mapView: return .init(with: MapViewAttributesSectionDataSource(with: object))

        case .scrollView: return .init(with: ScrollViewAttributesSectionDataSource(with: object))

        case .segmentedControl: return .init(with: SegmentedControlAttributesSectionDataSource(with: object))

        case .slider: return .init(with: SliderAttributesSectionDataSource(with: object))

        case .switch: return .init(with: SwitchAttributesSectionDataSource(with: object))

        case .stackView: return .init(with: StackViewAttributesSectionDataSource(with: object))

        case .textField: return .init(with: TextFieldAttributesSectionDataSource(with: object))

        case .textView: return .init(with: TextViewAttributesSectionDataSource(with: object))

        case .tabBar: return .init(with: TabBarAttributesSectionDataSource(with: object))

        case .webView: return []
        }
    }
}
