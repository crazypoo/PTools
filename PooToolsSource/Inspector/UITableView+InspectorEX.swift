//
//  UITableView+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

public extension UITableView {
    convenience init(_ options: Option...) {
        self.init(frame: .zero, style: options.style)
        apply(tableViewOptions: options)
    }
}

public extension UITableView {
    /// Applies the appeareance options to the table view instance.
    /// - Parameter tableViewOptions: The table view appearance options.
    func apply(tableViewOptions: Option...) {
        apply(tableViewOptions: tableViewOptions)
    }
    
    /// Applies the appeareance options to the table view instance.
    /// - Parameter tableViewOptions: The table view appearance options.
    func apply(tableViewOptions: Options) {
        tableViewOptions.forEach { option in
            switch option {
            case let .dataSource(dataSource):
                self.dataSource = dataSource
                
            case let .delegate(delegate):
                self.delegate = delegate
                
            case let .prefetchDataSource(prefetchDataSource):
                self.prefetchDataSource = prefetchDataSource
                
            case let .dragDelegate(dragDelegate):
                self.dragDelegate = dragDelegate
                
            case let .dropDelegate(dropDelegate):
                self.dropDelegate = dropDelegate
                
            case let .rowHeight(rowHeight):
                self.rowHeight = rowHeight
                
            case let .sectionHeaderHeight(sectionHeaderHeight):
                self.sectionHeaderHeight = sectionHeaderHeight
                
            case let .sectionFooterHeight(sectionFooterHeight):
                self.sectionFooterHeight = sectionFooterHeight
                
            case let .estimatedRowHeight(estimatedRowHeight):
                self.estimatedRowHeight = estimatedRowHeight
                
            case let .estimatedSectionHeaderHeight(estimatedSectionHeaderHeight):
                self.estimatedSectionHeaderHeight = estimatedSectionHeaderHeight
                
            case let .estimatedSectionFooterHeight(estimatedSectionFooterHeight):
                self.estimatedSectionFooterHeight = estimatedSectionFooterHeight
                
            case let .separatorInset(separatorInset):
                self.separatorInset = separatorInset
                
            case let .separatorInsetReference(separatorInsetReference):
                self.separatorInsetReference = separatorInsetReference
                
            case let .backgroundView(backgroundView):
                self.backgroundView = backgroundView
                
            case let .allowsSelection(allowsSelection):
                self.allowsSelection = allowsSelection
                
            case let .allowsSelectionDuringEditing(allowsSelectionDuringEditing):
                self.allowsSelectionDuringEditing = allowsSelectionDuringEditing
                
            case let .allowsMultipleSelection(allowsMultipleSelection):
                self.allowsMultipleSelection = allowsMultipleSelection
                
            case let .allowsMultipleSelectionDuringEditing(allowsMultipleSelectionDuringEditing):
                self.allowsMultipleSelectionDuringEditing = allowsMultipleSelectionDuringEditing
                
            case let .sectionIndexMinimumDisplayRowCount(sectionIndexMinimumDisplayRowCount):
                self.sectionIndexMinimumDisplayRowCount = sectionIndexMinimumDisplayRowCount
                
            case let .sectionIndexColor(sectionIndexColor):
                self.sectionIndexColor = sectionIndexColor
                
            case let .sectionIndexBackgroundColor(sectionIndexBackgroundColor):
                self.sectionIndexBackgroundColor = sectionIndexBackgroundColor
                
            case let .sectionIndexTrackingBackgroundColor(sectionIndexTrackingBackgroundColor):
                self.sectionIndexTrackingBackgroundColor = sectionIndexTrackingBackgroundColor
                
            case let .separatorStyle(separatorStyle):
                self.separatorStyle = separatorStyle
                
            case let .separatorColor(separatorColor):
                self.separatorColor = separatorColor
                
            case let .separatorEffect(separatorEffect):
                self.separatorEffect = separatorEffect
                
            case let .cellLayoutMarginsFollowReadableWidth(cellLayoutMarginsFollowReadableWidth):
                self.cellLayoutMarginsFollowReadableWidth = cellLayoutMarginsFollowReadableWidth
                
            case let .insetsContentViewsToSafeArea(insetsContentViewsToSafeArea):
                self.insetsContentViewsToSafeArea = insetsContentViewsToSafeArea
                
            case let .tableHeaderView(tableHeaderView):
                self.tableHeaderView = tableHeaderView
                
            case let .tableFooterView(tableFooterView):
                self.tableFooterView = tableFooterView
                
            case let .remembersLastFocusedIndexPath(remembersLastFocusedIndexPath):
                self.remembersLastFocusedIndexPath = remembersLastFocusedIndexPath
                
            #if swift(>=5.3)
            case let .selectionFollowsFocus(selectionFollowsFocus):
                self.selectionFollowsFocus = selectionFollowsFocus
            #endif
            case let .dragInteractionEnabled(dragInteractionEnabled):
                self.dragInteractionEnabled = dragInteractionEnabled
                
            case let .viewOptions(viewOptions):
                apply(viewOptions: viewOptions)
                
            case let .scrollViewOptions(scrollViewOptions):
                apply(scrollViewOptions: scrollViewOptions)
                
            // used only on init
            case .style:
                break
            }
        }
    }
    
    typealias Options = [Option]
    
    enum Option {
        
        /// A constant that specifies the style of the table view. Can only be applied on init, otherwise is ignored.
        case style(UITableView.Style)
        
        ///The object that acts as the data source of the table view.
        case dataSource(UITableViewDataSource?)
        
        /// The object that acts as the delegate of the table view.
        case delegate(UITableViewDelegate?)
        
        /// The object that acts as the prefetching data source for the table view, receiving notifications of upcoming cell data requirements.
        case prefetchDataSource(UITableViewDataSourcePrefetching?)
        
        /// The delegate object that manages the dragging of items from the table view.
        case dragDelegate(UITableViewDragDelegate?)
        
        /// The delegate object that manages the dropping of content into the table view.
        case dropDelegate(UITableViewDropDelegate?)
        
        /// The default height (in points) of each row in the table view.
        case rowHeight(CGFloat)
        
        /// The height of section headers in the table view.
        case sectionHeaderHeight(CGFloat)
        
        /// The height of section footers in the table view.
        case sectionFooterHeight(CGFloat)
        
        /// The estimated height of rows in the table view.
        case estimatedRowHeight(CGFloat)
        
        /// The estimated height of section headers in the table view.
        case estimatedSectionHeaderHeight(CGFloat)
        
        /// The estimated height of section footers in the table view.
        case estimatedSectionFooterHeight(CGFloat)
        
        /// The default inset of cell separators.
        case separatorInset(UIEdgeInsets)
        
        /// An indicator of how the separator inset value should be interpreted.
        case separatorInsetReference(UITableView.SeparatorInsetReference)
        
        /// The background view of the table view.
        case backgroundView(UIView?)
        
        /// A Boolean value that determines whether users can select a row.
        case allowsSelection(Bool)
        
        /// A Boolean value that determines whether users can select cells while the table view is in editing mode.
        case allowsSelectionDuringEditing(Bool)
        
        /// A Boolean value that determines whether users can select more than one row outside of editing mode.
        case allowsMultipleSelection(Bool)
        
        /// A Boolean value that controls whether users can select more than one cell simultaneously in editing mode.
        case allowsMultipleSelectionDuringEditing(Bool)
        
        /// The number of table rows at which to display the index list on the right edge of the table.
        case sectionIndexMinimumDisplayRowCount(Int)
        
        /// The color to use for the table view’s index text.
        case sectionIndexColor(UIColor?)
        
        /// The color to use for the background of the table view’s section index.
        case sectionIndexBackgroundColor(UIColor?)
        
        /// The color to use for the table view’s index background area.
        case sectionIndexTrackingBackgroundColor(UIColor?)
        
        /// The style for table cells used as separators.
        case separatorStyle(UITableViewCell.SeparatorStyle)
        
        /// The color of separator rows in the table view.
        case separatorColor(UIColor?)
        
        /// The effect applied to table separators.
        case separatorEffect(UIVisualEffect?)
        
        /// A Boolean value that indicates whether the cell margins are derived from the width of the readable content guide.
        case cellLayoutMarginsFollowReadableWidth(Bool)
        
        /// A Boolean value that indicates whether the table view adjusts the content views of its cells, headers, and footers to fit within the safe area.
        case insetsContentViewsToSafeArea(Bool)
        
        /// The view that is displayed above the table's content.
        case tableHeaderView(UIView?)
        
        /// The view that is displayed below the table's content.
        case tableFooterView(UIView?)
        
        /// A Boolean value that indicates whether the table view should automatically return the focus to the cell at the last focused index path.
        case remembersLastFocusedIndexPath(Bool)
        
        /// A Boolean value that triggers an automatic selection when focus moves to a cell.
        #if swift(>=5.3)
        case selectionFollowsFocus(Bool)
        #endif
        
        /// A Boolean value indicating whether the table view supports drags and drops between apps.
        case dragInteractionEnabled(Bool)
        
        
        /// The options for the scroll view.
        case scrollViewOptions(UIScrollView.Options)
        
        /// The options for the table view.
        case viewOptions(UIView.Options)
    }
}

// MARK: - Convenience -

public extension UITableView.Option {
    /// The options for the table view.
    static func indicatorStyle(_ indicatorStyle: UIScrollView.IndicatorStyle) -> Self {
        .scrollViewOptions(.indicatorStyle(indicatorStyle))
    }
    
    /// Sets automatic height for section headers in the table view.
    static var automaticSectionFooterHeight: Self {
        .sectionFooterHeight(UITableView.automaticDimension)
    }
    
    /// Sets automatic height (in points) for each row in the table view.
    static var automaticRowHeight: Self {
        .rowHeight(UITableView.automaticDimension)
    }
    
    /// Sets automatic height for section headers in the table view.
    static var automaticSectionHeaderHeight: Self {
        .sectionHeaderHeight(UITableView.automaticDimension)
    }
    
    // MARK: - Scroll View
    
    /// The options for the table view.
    static func scrollViewOptions(_ scrollViewOptions: UIScrollView.Option...) -> Self {
        .scrollViewOptions(scrollViewOptions)
    }
    
    /// The options for the table view.
    static func keyboardDismissMode(_ keyboardDismissMode: UIScrollView.KeyboardDismissMode) -> Self {
        .scrollViewOptions(.keyboardDismissMode(keyboardDismissMode))
    }
    
    /// A Boolean value that determines whether scrolling is enabled.
    static func isScrollEnabled(_ isScrollEnabled: Bool) -> Self {
        .scrollViewOptions(.isScrollEnabled(isScrollEnabled))
    }
    
    // MARK: - Content Inset
    
    /// The custom distance that the content view is inset from the safe area or scroll view edges.
    static func contentInset(_ contentInset: UIEdgeInsets) -> Self {
        .scrollViewOptions(.contentInset(contentInset))
    }
    
    /// The custom distance that the content view is inset from the safe area or scroll view edges.
    static func contentInset(top: CGFloat = .zero, left: CGFloat = .zero, bottom: CGFloat = .zero, right: CGFloat = .zero) -> Self {
        .contentInset(UIEdgeInsets(top: top, left: left, bottom: bottom, right: right))
    }
    
    /// The custom distance that the content view is inset from the safe area or scroll view edges.
    static func contentInset<T: RawRepresentable>(top: T? = nil, left: T? = nil, bottom: T? = nil, right: T? = nil) -> Self where T.RawValue == CGFloat {
        .contentInset(UIEdgeInsets(top: top, left: left, bottom: bottom, right: right))
    }
    
    // MARK: - Separator Inset
    
    /// The custom distance that the content view is inset from the safe area or scroll view edges.
    static func separatorInset(top: CGFloat = .zero, left: CGFloat = .zero, bottom: CGFloat = .zero, right: CGFloat = .zero) -> Self {
        .separatorInset(UIEdgeInsets(top: top, left: left, bottom: bottom, right: right))
    }
    
    /// The custom distance that the content view is inset from the safe area or scroll view edges.
    static func separatorInset<T: RawRepresentable>(top: T? = nil, left: T? = nil, bottom: T? = nil, right: T? = nil) -> Self where T.RawValue == CGFloat {
        .separatorInset(UIEdgeInsets(top: top, left: left, bottom: bottom, right: right))
    }
    
    // MARK: - Layout Compression
    
    /// The priority with which a view resists being made smaller than its intrinsic width or height.
    static func compressionResistance(_ priority: UILayoutPriority, for axis: NSLayoutConstraint.Axis) -> Self {
        .viewOptions(.layoutCompression(.compressionResistance(priority, for: axis)))
    }
    
    /// The priority with which a view resists being made larger than its intrinsic width or height.
    static func huggingPriority(_ priority: UILayoutPriority, for axis: NSLayoutConstraint.Axis) -> Self {
        .viewOptions(.layoutCompression(.huggingPriority(priority, for: axis)))
    }
    
    // MARK: - View Options
    
    /// The options for the table view.
    static func viewOptions(_ options: UIView.Option...) -> Self {
        .viewOptions(options)
    }
    
    /// The table view’s background color.
    static func backgroundColor(_ color: UIColor?) -> Self {
        .viewOptions(.backgroundColor(color))
    }
    
    /// The table view’s tint color.
    static func tintColor(_ color: UIColor) -> Self {
        .viewOptions(.tintColor(color))
    }
    
    // MARK: - Layer Options
    
    /// Describes the table view layer's appearance.
    static func layerOptions(_ options: CALayer.Option...) -> Self {
        .viewOptions(.layerOptions(options))
    }
}

// MARK: - Convenience

extension Collection where Element == UITableView.Option {
    var style: UITableView.Style {
        for option in self {
            guard case let .style(style) = option else {
                continue
            }
            
            return style
        }
        
        return .plain
    }
}

extension UITableView {
    // MARK: - Cells

    func register<T: UITableViewCell>(_ cellClass: T.Type) {
        register(cellClass.self, forCellReuseIdentifier: String(describing: T.self))
    }

    func dequeueReusableCell<T: UITableViewCell>(_: T.Type = T.self, for indexPath: IndexPath) -> T {
        let identifier = String(describing: T.self)

        guard let cell = dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? T else {
            fatalError("Could not dequeue cell with identifier: \(identifier)")
        }

        return cell
    }

    // MARK: - Headers & Footers

    func registerHeaderFooter<T: UITableViewHeaderFooterView>(_ headerFooterClass: T.Type) {
        register(headerFooterClass.self, forHeaderFooterViewReuseIdentifier: String(describing: T.self))
    }

    func dequeueReusableHeaderFooterView<T: UITableViewHeaderFooterView>(_: T.Type = T.self) -> T {
        let identifier = String(describing: T.self)

        guard let headerFooter = dequeueReusableHeaderFooterView(withIdentifier: String(describing: T.self)) as? T else { fatalError("Could not dequeue header/footer with identifier: \(identifier)")
        }

        return headerFooter
    }
}
