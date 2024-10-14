//
//  UIStackView+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

// MARK: - Horizontal Alignment

public extension UIStackView {
    /// The layout of arranged views vertically to the stack view.
    enum HorizontalAlignment: RawRepresentable {
        public init?(rawValue: UIStackView.Alignment) {
            switch rawValue {
            case .fill:
                self = .fill
            
            case .firstBaseline:
                self = .firstBaseline
            
            case .center:
                self = .center
            
            case .lastBaseline:
                self = .lastBaseline
                
            case .leading, .trailing:
                return nil
                
            @unknown default:
                return nil
            }
        }
        
        /// Align the leading and trailing edges of horizontally stacked items tightly to the container.
        case fill
        /// A layout for horizontal stacks where the stack view aligns the top edge of its arranged views along its top edge. This is equivalent to the UIStackView.Alignment.leading alignment for vertical stacks.
        case top
        /// A layout where the stack view aligns its arranged views based on their first baseline.
        case firstBaseline
        /// A layout where the stack view aligns its arranged views based on their last baseline.
        case lastBaseline
        /// Center the items in a horizontal stack vertically
        case center
        /// A layout for horizontal stacks where the stack view aligns the bottom edge of its arranged views along its bottom edge. This is equivalent to the UIStackView.Alignment.trailing alignment for vertical stacks.
        case bottom
        
        public var rawValue: UIStackView.Alignment {
            switch self {
            case .fill:
                return .fill
                
            case .center:
                return .center
                
            case .top:
                return .top
                
            case .firstBaseline:
                return .firstBaseline
                
            case .lastBaseline:
                return .lastBaseline
                
            case .bottom:
                return .bottom
            }
        }
    }
}

// MARK: - Vertical Alignment

public extension UIStackView {
    /// The layout of arranged views horizontally to the stack view.
    enum VerticalAlignment: RawRepresentable {
        public init?(rawValue: UIStackView.Alignment) {
            switch rawValue {
            case .fill:
                self = .fill
                
            case .leading:
                self = .leading
                
            case .center:
                self = .center
                
            case .trailing:
                self = .trailing
                
            case .firstBaseline, .lastBaseline:
                return nil
                
            @unknown default:
                return nil
            }
        }
        
        /// Align the leading and trailing edges of vertically stacked items tightly to the container.
        case fill
        /// A layout for vertical stacks where the stack view aligns the leading edge of its arranged views along its leading edge. This is equivalent to the top alignment for horizontal stacks.
        case leading
        /// Center the items in a vertical stack horizontally.
        case center
        /// A layout for vertical stacks where the stack view aligns the trailing edge of its arranged views along its trailing edge. This is equivalent to the bottom alignment for horizontal stacks.
        case trailing
        
        public var rawValue: UIStackView.Alignment {
            switch self {
            case .fill:
                return .fill
                
            case .center:
                return .center
                
            case .leading:
                return .leading
                
            case .trailing:
                return .trailing
            }
        }
    }
}

public extension UIStackView {
    convenience init(_ options: Option...) {
        self.init(options)
    }
    
    convenience init(_ options: Options) {
        self.init()
        isLayoutMarginsRelativeArrangement = true
        apply(stackViewOptions: options)
    }
}

public extension UIStackView {
    /// Applies the appeareance options to the stack view instance.
    /// - Parameter options: The stack view appearance options.
    func apply(stackViewOptions: Option...){
        apply(stackViewOptions: stackViewOptions)
    }
    
    /// Applies the appeareance options to the stack view instance.
    /// - Parameter options: The stack view appearance options.
    func apply(stackViewOptions: Options) {
        stackViewOptions.forEach { option in
            switch option {
            case let .axis(axis):
                self.axis = axis
                
            case let .spacing(spacing):
                self.spacing = spacing
                
            case let .verticalAlignment(verticalAlignment):
                self.alignment = verticalAlignment.rawValue
                
            case let .horizontalAlignment(horizontalAlignment):
                self.alignment = horizontalAlignment.rawValue
                
            case let .distribution(distribution):
                self.distribution = distribution
                
            case let .arrangedSubviews(views):
                addArrangedSubviews(views)
                
            case let .isLayoutMarginsRelativeArrangement(isLayoutMarginsRelativeArrangement):
                self.isLayoutMarginsRelativeArrangement = isLayoutMarginsRelativeArrangement
                
            case let .viewOptions(viewOptions):
                apply(viewOptions: viewOptions)
            }
        }
    }
    
    typealias Options = [Option]
    
    /// An object that defines the appearance of a stack view.
    enum Option {
        /// The axis along which the arranged views are laid out.
        case axis(NSLayoutConstraint.Axis)
        
        /// The list of views arranged by the stack view.
        case arrangedSubviews([UIView])
        
        /// The distance in points between the adjacent edges of the stack view’s arranged views.
        case spacing(CGFloat)
        
        /// The alignment of the arranged subviews perpendicular to the stack view’s axis.
        case verticalAlignment(VerticalAlignment)
        
        /// The alignment of the arranged subviews perpendicular to the stack view’s axis.
        case horizontalAlignment(HorizontalAlignment)
        
        /// The distribution of the arranged views along the stack view’s axis.
        case distribution(Distribution)
        
        /// A Boolean value that determines whether the stack view lays out its arranged views relative to its layout margins.
        case isLayoutMarginsRelativeArrangement(Bool)
        
        /// The appearance options of the stack view.
        case viewOptions(UIView.Options)
        
        // MARK: - Convenience
        
        /// The list of views arranged by the stack view.
        public static func arrangedSubviews(_ views: UIView...) -> Self {
            .arrangedSubviews(views)
        }
        
        public static func spacing<T: RawRepresentable>(_ spacing: T) -> Self where T.RawValue == CGFloat {
            .spacing(spacing.rawValue)
        }
        
        /// The appearance options of the stack view.
        public static func viewOptions(_ options: UIView.Option...) -> Self {
            .viewOptions(options)
        }
        
        /// Describes the stack view layer's appearance.
        public static func layerOptions(_ options: CALayer.Option...) -> Self {
            .viewOptions(.layerOptions(options))
        }
        
        /// The priority with which a view resists being made smaller than its intrinsic width or height.
        public static func compressionResistance(_ priority: UILayoutPriority, for axis: NSLayoutConstraint.Axis) -> Self {
            .viewOptions(.layoutCompression(.compressionResistance(priority, for: axis)))
        }
        
        /// The priority with which a view resists being made larger than its intrinsic width or height.
        public static func huggingPriority(_ priority: UILayoutPriority, for axis: NSLayoutConstraint.Axis) -> Self {
            .viewOptions(.layoutCompression(.huggingPriority(priority, for: axis)))
        }
        
        /// The default spacing to use when laying out content in a view, taking into account the current language direction.
        public static func directionalLayoutMargins(_ insets: NSDirectionalEdgeInsets) -> Self {
            .viewOptions(.directionalLayoutMargins(insets))
        }
        
        /// The default spacing to use when laying out content in a view, taking into account the current language direction.
        public static func directionalLayoutMargins(top: CGFloat = .zero, leading: CGFloat = .zero, bottom: CGFloat = .zero, trailing: CGFloat = .zero) -> Self {
            .directionalLayoutMargins(NSDirectionalEdgeInsets(top: top, leading: leading, bottom: bottom, trailing: trailing))
        }
        
        /// The default spacing to use when laying out content in a view, taking into account the current language direction.
        public static func directionalLayoutMargins(horizontal: CGFloat = .zero, vertical: CGFloat = .zero) -> Self {
            .directionalLayoutMargins(top: vertical, leading: horizontal, bottom: vertical, trailing: horizontal)
        }
        
        /// The default spacing to use when laying out content in a view, taking into account the current language direction.
        public static func directionalLayoutMargins<T: RawRepresentable>(top: T? = nil, leading: T? = nil, bottom: T? = nil, trailing: T? = nil) -> Self where T.RawValue == CGFloat {
            .directionalLayoutMargins(top: top?.rawValue ?? .zero, leading: leading?.rawValue ?? .zero, bottom: bottom?.rawValue ?? .zero, trailing: trailing?.rawValue ?? .zero)
        }
        
        /// The default spacing to use when laying out content in a view, taking into account the current language direction.
        public static func directionalLayoutMargins<T: RawRepresentable>(horizontal: T? = nil, vertical: T? = nil) -> Self where T.RawValue == CGFloat {
            .directionalLayoutMargins(top: vertical?.rawValue ?? .zero, leading: horizontal?.rawValue ?? .zero, bottom: vertical?.rawValue ?? .zero, trailing: horizontal?.rawValue ?? .zero)
        }
    }
}

public extension UIStackView {
    
    func addArrangedSubviews(_ views: [UIView]) {
        views.forEach(addArrangedSubview)
    }
    
    func addArrangedSubviews(_ views: UIView...) {
        views.forEach(addArrangedSubview)
    }
    
    func removeAllArrangedSubviews() {
        arrangedSubviews.forEach {
            $0.removeFromSuperview()
        }
    }
    
    func replaceArrangedSubviews(with arrangedSubviews: [UIView]) {
        removeAllArrangedSubviews()
        addArrangedSubviews(arrangedSubviews)
    }
}

extension UIStackView.Alignment: CaseIterable {
    public typealias AllCases = [UIStackView.Alignment]

    public static let allCases: [UIStackView.Alignment] = [
        .fill,
        .leading,
        .firstBaseline,
        .center,
        .trailing,
        .lastBaseline
    ]
}

extension UIStackView.Alignment: CustomStringConvertible {
    public var description: String {
        switch self {
        case .fill:
            return "Fill"

        case .leading:
            return "Leading"

        case .firstBaseline:
            return "First Baseline"

        case .center:
            return "Center"

        case .trailing:
            return "Trailing"

        case .lastBaseline:
            return "Last Baseline"

        @unknown default:
            return "\(self) (unsupported)"
        }
    }
}

extension UIStackView.Distribution: CaseIterable {
    public typealias AllCases = [UIStackView.Distribution]

    public static let allCases: [UIStackView.Distribution] = [
        .fill,
        .fillEqually,
        .fillProportionally,
        .equalSpacing,
        .equalCentering
    ]
}

extension UIStackView.Distribution: CustomStringConvertible {
    public var description: String {
        switch self {
        case .fill:
            return "Fill"

        case .fillEqually:
            return "Fill Equally"

        case .fillProportionally:
            return "Fill Proportionally"

        case .equalSpacing:
            return "Equal Spacing"

        case .equalCentering:
            return "Equal Centering"

        @unknown default:
            return "\(self) (unsupported)"
        }
    }
}

extension UIStackView {
    static func vertical(_ options: Option...) -> UIStackView {
        UIStackView(options + [.axis(.vertical)])
    }

    static func horizontal(_ options: Option...) -> UIStackView {
        UIStackView(options + [.axis(.horizontal)])
    }
}
