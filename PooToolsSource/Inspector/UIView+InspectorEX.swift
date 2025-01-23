//
//  UIView+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

public extension UIView {
    convenience init(_ options: Option...) {
        self.init(options)
    }
    
    convenience init(_ options: Options) {
        self.init(frame: .zero)
        apply(viewOptions: options)
    }
    
    convenience init(_ layoutCompressionOptions: LayoutCompressionOption...) {
        self.init(layoutCompressionOptions)
    }
    
    convenience init(_ layoutCompressionOptions: LayoutCompressionOptions) {
        self.init(frame: .zero)
        apply(layoutCompressionOptions: layoutCompressionOptions)
    }
    
    convenience init(_ layerOptions: CALayer.Option...) {
        self.init(layerOptions)
    }
    
    convenience init(_ layerOptions: CALayer.Options) {
        self.init(frame: .zero)
        layer.apply(layerOptions: layerOptions)
    }
}

public extension UIView {
    /// Applies the layout compression options to the view instance.
    /// - Parameter layoutCompressionOptions: The view layout compresison options.
    func apply(layoutCompressionOptions: LayoutCompressionOption...) {
        apply(layoutCompressionOptions: layoutCompressionOptions)
    }
    
    /// Applies the layout compression options to the view instance.
    /// - Parameter layoutCompressionOptions: The view layout compresison options.
    func apply(layoutCompressionOptions: LayoutCompressionOptions) {
        layoutCompressionOptions.forEach { option in
            switch option {
            case let .compressionResistance(priority, for: axis):
                setContentCompressionResistancePriority(priority, for: axis)
                
            case let .huggingPriority(priority, for: axis):
                setContentHuggingPriority(priority, for: axis)
            }
        }
    }
    
    typealias LayoutCompressionOptions = [LayoutCompressionOption]
    
    /// Describes the view's layout compression and hugging priorities.
    enum LayoutCompressionOption: Equatable {
        /// The priority with which a view resists being made smaller than its intrinsic width or height.
        case compressionResistance(UILayoutPriority, for: NSLayoutConstraint.Axis)
        
        /// The priority with which a view resists being made larger than its intrinsic width or height.
        case huggingPriority(UILayoutPriority, for: NSLayoutConstraint.Axis)
    }
}

public extension UIView {
    /// Applies the appearance options to the view instance.
    /// - Parameter viewOptions: The view appearance options.
    func apply(viewOptions: Option...) {
        apply(viewOptions: viewOptions)
    }
    
    /// Applies the appearance options to the view instance.
    /// - Parameter viewOptions: The view appearance options.
    func apply(viewOptions: Options) {
        viewOptions.forEach { option in
            switch option {
            case let .backgroundColor(backgroundColor):
                self.backgroundColor = backgroundColor
                
            case let .contentMode(contentMode):
                self.contentMode = contentMode
                
            case let .clipsToBounds(clipsToBounds):
                self.clipsToBounds = clipsToBounds
                
            case let .isHidden(isHidden):
                self.isHidden = isHidden
                
            case let .tintColor(tintColor):
                self.tintColor = tintColor
                
            case let .alpha(alpha):
                self.alpha = alpha
                
            case let .isUserInteractionEnabled(isUserInteractionEnabled):
                self.isUserInteractionEnabled = isUserInteractionEnabled
                
            case let .layoutCompression(layoutCompressionOptions):
                self.apply(layoutCompressionOptions: layoutCompressionOptions)
                
            case let .layerOptions(layerOptions):
                layer.apply(layerOptions: layerOptions)
            
            case let .frame(frame):
                self.frame = frame
                
            case let .bounds(bounds):
                self.bounds = bounds
                
            case let .center(center):
                self.center = center
                
            case let .transform(transform):
                self.transform = transform
                
            case let .directionalLayoutMargins(directionalLayoutMargins):
                self.directionalLayoutMargins = directionalLayoutMargins
                
            case let .preservesSuperviewLayoutMargins(preservesSuperviewLayoutMargins):
                self.preservesSuperviewLayoutMargins = preservesSuperviewLayoutMargins
                
            case let .insetsLayoutMarginsFromSafeArea(insetsLayoutMarginsFromSafeArea):
                self.insetsLayoutMarginsFromSafeArea = insetsLayoutMarginsFromSafeArea
                
            case let .tintAdjustmentMode(tintAdjustmentMode):
                self.tintAdjustmentMode = tintAdjustmentMode
                
            case let .mask(mask):
                self.mask = mask
                
            case let .tag(tag):
                self.tag = tag
                
            case let .semanticContentAttribute(semanticContentAttribute):
                self.semanticContentAttribute = semanticContentAttribute
                
            case let .isOpaque(isOpaque):
                self.isOpaque = isOpaque
                
            case let .translatesAutoresizingMaskIntoConstraints(translatesAutoresizingMaskIntoConstraints):
                self.translatesAutoresizingMaskIntoConstraints = translatesAutoresizingMaskIntoConstraints
                
            case let .accessibilityIdentifier(accessibilityIdentifier):
                self.accessibilityIdentifier = accessibilityIdentifier
            
            case let .focusGroupIdentifier(focusGroupIdentifier):
                self.focusGroupIdentifier = focusGroupIdentifier            
            }
        }
    }
    
    typealias Options = [Option]
    
    /// An object that defines the appearance of a view.
    enum Option {
        /// The frame rectangle, which describes the view’s location and size in its superview’s coordinate system.
        case frame(CGRect)
        
        /// The bounds rectangle, which describes the view’s location and size in its own coordinate system.
        case bounds(CGRect)
        
        /// The center point of the view's frame rectangle.
        case center(CGPoint)
        
        /// Specifies the transform applied to the view, relative to the center of its bounds.
        case transform(CGAffineTransform)
        
        /// The default spacing to use when laying out content in a view, taking into account the current language direction.
        case directionalLayoutMargins(NSDirectionalEdgeInsets)
        
        /// A Boolean value indicating whether the current view also respects the margins of its superview.
        case preservesSuperviewLayoutMargins(Bool)
        
        /// A Boolean value indicating whether the view's layout margins are updated automatically to reflect the safe area.
        case insetsLayoutMarginsFromSafeArea(Bool)
        
        /// The view’s background color.
        case backgroundColor(UIColor?)
        
        /// A flag used to determine how a view lays out its content when its bounds change.
        case contentMode(ContentMode)
        
        /// A Boolean value that determines whether subviews are confined to the bounds of the view.
        case clipsToBounds(Bool)
        
        /// A Boolean value that determines whether the view is hidden.
        case isHidden(Bool)
        
        /// A Boolean value that determines whether the view is opaque.
        case isOpaque(Bool)
        
        /// The view's tint color.
        case tintColor(UIColor)
        
        /// A Boolean value that determines whether the view’s autoresizing mask is translated into Auto Layout constraints.
        case translatesAutoresizingMaskIntoConstraints(Bool)
        
        /// The first non-default tint adjustment mode value in the view’s hierarchy, ascending from and starting with the view itself.
        case tintAdjustmentMode(UIView.TintAdjustmentMode)
        
        /// An optional view whose alpha channel is used to mask a view’s content.
        case mask(UIView?)
        
        /// The view’s alpha value.
        case alpha(CGFloat)
        
        /// An integer that you can use to identify view objects in your application.
        case tag(Int)
        
        /// A string that identifies the element.
        case accessibilityIdentifier(String?)
        
        /// A semantic description of the view’s contents, used to determine whether the view should be flipped when switching between left-to-right and right-to-left layouts.
        case semanticContentAttribute(UISemanticContentAttribute)
        
        /// The identifier of the focus group that this view belongs to. If this is nil, subviews inherit their superview's focus group.
        case focusGroupIdentifier(String?)
        
        /// A Boolean value that determines whether user events are ignored and removed from the event queue.
        case isUserInteractionEnabled(Bool)
        
        /// Describes the view's layout compression and hugging priorities.
        case layoutCompression(LayoutCompressionOptions)
        
        /// Describes the layer's appearance.
        case layerOptions(CALayer.Options)
        
        // MARK: - Convenience
        
        /// The priority with which a view resists being made smaller than its intrinsic width or height.
        public static func compressionResistance(_ priority: UILayoutPriority, for axis: NSLayoutConstraint.Axis) -> Self {
            .layoutCompression(.compressionResistance(priority, for: axis))
        }
        
        /// The priority with which a view resists being made larger than its intrinsic width or height.
        public static func huggingPriority(_ priority: UILayoutPriority, for axis: NSLayoutConstraint.Axis) -> Self {
            .layoutCompression(.huggingPriority(priority, for: axis))
        }
        
        /// Describes the layer's appearance.
        public static func layerOptions(_ layerOptions: CALayer.Option...) -> Self {
            .layerOptions(layerOptions)
        }
        
        /// Describes the view's layout compression and hugging priorities.
        public static func layoutCompression(_ options: LayoutCompressionOption...) -> Self {
            .layoutCompression(options)
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

public extension UIView {
    
    /// Animate changes to one or more views using the keyboard animation's duration and animation curve.
    ///
    /// - Parameters:
    ///   - notification: A notification containing keyboard animation information, others will be ignored.
    ///   - animations: The specified animation block to the animator. The duration, final frame, and animation curve are provided inside.
    ///   - completion: An optional block to execute when the animations finish. This block takes the parameter `finalPosition`, which describes the position where the animations stopped. Use this value to specify whether the animations stopped at their starting point, their end point, or their current position.
    static func animate(withKeyboardNotification notification: Notification,
                        animations: @escaping (KeyboardAnimationInfo) -> Void,
                        completion: ((UIViewAnimatingPosition) -> Void)? = nil) {
        
        guard let keyboardAnimationInfo = notification.keyboardAnimationInfo else { return }
        
        let animator = UIViewPropertyAnimator(
            duration: keyboardAnimationInfo.duration,
            curve: keyboardAnimationInfo.curve
        )
        
        animator.addAnimations {
            animations(keyboardAnimationInfo)
        }
        
        if let completion = completion {
            animator.addCompletion(completion)
        }
        
        animator.startAnimation()
    }
}

extension UIView.AutoresizingMask: @retroactive CaseIterable {
    public typealias AllCases = [UIView.AutoresizingMask]

    public static let allCases: [UIView.AutoresizingMask] = [
        .flexibleLeftMargin,
        .flexibleWidth,
        .flexibleRightMargin,
        .flexibleTopMargin,
        .flexibleHeight,
        .flexibleBottomMargin
    ]
}

extension UIView.AutoresizingMask: CustomStringConvertible {
    var name: String {
        switch self {
        case .flexibleWidth:
            return "Width"
        case .flexibleLeftMargin:
            return "Left Margin"
        case .flexibleWidth:
            return "Width"
        case .flexibleRightMargin:
            return "Right Margin"
        case .flexibleTopMargin:
            return "Top Margin"
        case .flexibleHeight:
            return "Height"
        case .flexibleBottomMargin:
            return "Bottom Margin"
        default:
            return String(describing: rawValue)
        }
    }

    var description: String {
        var strings = [String]()

        for mask in Self.allCases where contains(mask) {
            strings.append(mask.name)
        }

        return "Flexible \(strings.joined(separator: ", "))"
    }
}

extension UIView.ContentMode: @retroactive CaseIterable {
    public typealias AllCases = [UIView.ContentMode]

    public static let allCases: [UIView.ContentMode] = [
        .scaleToFill,
        .scaleAspectFit,
        .scaleAspectFill,
        .redraw,
        .center,
        .top,
        .bottom,
        .left,
        .right,
        .topLeft,
        .topRight,
        .bottomLeft,
        .bottomRight
    ]
}

extension UIView.ContentMode: CustomStringConvertible {
    var description: String {
        switch self {
        case .scaleToFill:
            return "Scale To Fill"

        case .scaleAspectFit:
            return "Scale Aspect Fit"

        case .scaleAspectFill:
            return "Scale Aspect Fill"

        case .redraw:
            return "Redraw"

        case .center:
            return "Center"

        case .top:
            return "Top"

        case .bottom:
            return "Bottom"

        case .left:
            return "Left"

        case .right:
            return "Right"

        case .topLeft:
            return "Top Left"

        case .topRight:
            return "Top Right"

        case .bottomLeft:
            return "Bottom Left"

        case .bottomRight:
            return "Bottom Right"

        @unknown default:
            return "\(self) (unsupported)"
        }
    }
}

enum ViewInstallationPosition {
    case inFront, behind
}

enum ViewBinding {
    case centerX

    case centerXY

    case centerY

    case spacing(
        top: CGFloat? = nil,
        leading: CGFloat? = nil,
        bottom: CGFloat? = nil,
        trailing: CGFloat? = nil
    )

    case autoResizingMask(UIView.AutoresizingMask)

    static let autoResizingMask = ViewBinding.autoResizingMask([.flexibleWidth, .flexibleHeight])

    static func spacing(all: CGFloat) -> ViewBinding {
        .spacing(top: all, leading: all, bottom: all, trailing: all)
    }

    static func spacing(horizontal: CGFloat, vertical: CGFloat) -> ViewBinding {
        .spacing(top: vertical, leading: horizontal, bottom: vertical, trailing: horizontal)
    }

    static func spacing(_ edgeInsets: UIEdgeInsets) -> ViewBinding {
        .spacing(top: edgeInsets.top, leading: edgeInsets.left, bottom: edgeInsets.bottom, trailing: edgeInsets.right)
    }

    static func spacing(_ directionalEdgeInsets: NSDirectionalEdgeInsets) -> ViewBinding {
        .spacing(top: directionalEdgeInsets.top, leading: directionalEdgeInsets.leading, bottom: directionalEdgeInsets.bottom, trailing: directionalEdgeInsets.trailing)
    }
}

extension UIView {
    func wrappedInside<View: UIView>(_ type: View.Type) -> View {
        let view = type.init(frame: .zero)
        view.installView(self, priority: .required)

        return view
    }

    var allSubviews: [UIView] {
        subviews.reversed().flatMap { [$0] + $0.allSubviews }
    }

    var inspectableSubviews: [UIView] {
        subviews.filter { $0 is NonInspectableView == false }
    }

    var allInspectableSubviews: [UIView] {
        inspectableSubviews.reversed().flatMap { [$0] + $0.allInspectableSubviews }
    }

    func installView(
        _ view: UIView,
        _ viewBinding: ViewBinding = .spacing(all: .zero),
        position: ViewInstallationPosition = .inFront,
        priority: UILayoutPriority = .defaultHigh
    ) {
        switch position {
        case .inFront:
            addSubview(view)

        case .behind:
            insertSubview(view, at: .zero)
        }

        switch viewBinding {
        case let .autoResizingMask(mask):
            view.autoresizingMask = mask

        case .centerX,
             .centerY,
             .centerXY,
             .spacing:
            let constraints = viewBinding.constraints(for: view, inside: self)

            view.translatesAutoresizingMaskIntoConstraints = false

            constraints.forEach {
                $0.priority = priority
                $0.isActive = true
            }
        }
    }

    /**
     A Boolean value that determines whether the view is hidden and works around a [UIStackView bug](http://www.openradar.me/25087688) affecting iOS 9.2+.
     */
    var isSafelyHidden: Bool {
        get {
            isHidden
        }
        set {
            isHidden = false
            isHidden = newValue
        }
    }
}

private extension ViewBinding {
    func constraints(for view: UIView, inside superview: UIView) -> [NSLayoutConstraint] {
        switch self {
        case .centerX:
            return [
                view.centerXAnchor.constraint(equalTo: superview.centerXAnchor)
            ]

        case .centerY:
            return [
                view.centerYAnchor.constraint(equalTo: superview.centerYAnchor)
            ]

        case .centerXY:
            return [
                view.centerXAnchor.constraint(equalTo: superview.centerXAnchor),
                view.centerYAnchor.constraint(equalTo: superview.centerYAnchor)
            ]

        case .autoResizingMask:
            return []

        case let .spacing(top, leading, bottom, trailing):
            var constraints = [NSLayoutConstraint]()

            if let top = top {
                constraints.append(view.topAnchor.constraint(equalTo: superview.topAnchor, constant: top))
            }
            if let leading = leading {
                constraints.append(view.leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: leading))
            }
            if let bottom = bottom {
                constraints.append(view.bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: -bottom))
            }
            if let trailing = trailing {
                constraints.append(view.trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: -trailing))
            }

            return constraints
        }
    }
}

extension UIView {
    var _highlightView: InspectorHighlightView? {
        subviews.compactMap { $0 as? InspectorHighlightView }.first
    }

    var _layerView: LayerView? {
        subviews.compactMap { $0 as? LayerView }.first
    }
}

extension UIView {
    func maskFromTop(margin: CGFloat) {
        layer.mask = visibilityMaskWithLocation(location: margin / frame.size.height)
        layer.masksToBounds = true
    }

    func visibilityMaskWithLocation(location: CGFloat) -> CAGradientLayer {
        let mask = CAGradientLayer()
        mask.frame = bounds
        mask.locations = [
            NSNumber(value: Float(location)),
            NSNumber(value: Float(location))
        ]
        mask.colors = [
            UIColor(white: 1, alpha: 0).cgColor,
            UIColor(white: 1, alpha: 1).cgColor
        ]

        return mask
    }
}

extension UIView {
    func enableRasterization(maxScale: CGFloat = 2) {
        layer.rasterizationScale = max(maxScale, UIScreen.main.scale)
        layer.shouldRasterize = true
    }

    func snapshot(afterScreenUpdates: Bool, with size: CGSize? = nil) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: bounds.size)

        let image = renderer.image { _ in
            drawHierarchy(in: bounds, afterScreenUpdates: afterScreenUpdates)
        }

        return image.resized(size ?? bounds.size)
    }
}

extension UIView {
    // MARK: - Did Move To didMoveToWindow

    private static let performSwizzling: Void = sizzle(#selector(didMoveToWindow), with: #selector(swizzled_didMoveToWindow))

    @objc func swizzled_didMoveToWindow() {
        swizzled_didMoveToWindow()

        if window == nil {
            Inspector.sharedInstance.contextMenuPresenter?.removeInteraction(from: self)
        }
        else {
            Inspector.sharedInstance.contextMenuPresenter?.addInteraction(to: self)
        }
    }

    private static func sizzle(_ aSelector: Selector, with otherSelector: Selector) {
        let instance = UIView()

        let aClass: AnyClass! = object_getClass(instance)

        let originalMethod = class_getInstanceMethod(aClass, aSelector)
        let swizzledMethod = class_getInstanceMethod(aClass, otherSelector)

        guard
            let originalMethod = originalMethod,
            let swizzledMethod = swizzledMethod
        else {
            return
        }

        method_exchangeImplementations(originalMethod, swizzledMethod)
    }

    static func startSwizzling() {
        _ = performSwizzling
    }
}

extension UIView: ViewHierarchyElementRepresentable {
    var depth: Int {
        allParents.count
    }

    var parent: UIView? {
        superview
    }

    var isContainer: Bool { !children.isEmpty }

    var allParents: [UIView] {
        allSuperviews
            .filter { $0 is InternalViewProtocol == false }
    }

    var allSuperviews: [UIView] {
        var superviews = [UIView]()
        if let superview = superview {
            superviews.append(superview)
            superviews.append(contentsOf: superview.allSuperviews)
        }
        return superviews
    }

    var children: [UIView] {
        subviews.filter { $0 is InternalViewProtocol == false }
    }

    var allChildren: [UIView] {
        children.reversed().flatMap { [$0] + $0.allChildren }
    }

    var overrideViewHierarchyInterfaceStyle: ViewHierarchyInterfaceStyle {
        .init(rawValue: overrideUserInterfaceStyle) ?? .unspecified
    }

    var isInternalView: Bool {
        _isInternalView
    }

    var isSystemContainer: Bool {
        _isSystemContainer
    }

//    #if !targetEnvironment(macCatalyst)
//    public var className: String {
//        _className
//    }
//    #endif

    var classNameWithoutQualifiers: String {
        _classNameWithoutQualifiers
    }

    var objectIdentifier: ObjectIdentifier {
        ObjectIdentifier(self)
    }

    var isAssociatedToWindow: Bool {
        window != nil || self is UIWindow
    }

    var issues: [ViewHierarchyIssue] { ViewHierarchyIssue.issues(for: self) }

    var constraintElements: [LayoutConstraintElement] {
        constraints
            .compactMap { LayoutConstraintElement(with: $0, in: self) }
            .uniqueValues()
    }

    var canPresentOnTop: Bool {
        switch self {
        case is UITextView:
            return true

        case is UIScrollView:
            return false

        default:
            return true
        }
    }

    var canHostContextMenuInteraction: Bool {
        canHostInspectorView &&
            self is UIWindow == false &&
            className != "UITransitionView" &&
            className != "UIDropShadowView" &&
            className != "_UIModernBarButton"
    }

    var canHostInspectorView: Bool {
        let className = _className
        let superViewClassName = superview?._className ?? ""

        guard
            className != "UIRemoteKeyboardWindow",
            className != "UITextEffectsWindow",
            className != "UIEditingOverlayGestureView",
            className != "UIInputSetContainerView",

            // Avoid breaking UINavigationController large title.
            superViewClassName != "UIViewControllerWrapperView",

            // Adding subviews directly to a UIVisualEffectView throws runtime exception.
            self is UIVisualEffectView == false,

            // Adding subviews to UIPageViewController containers throws runtime exception.
            className != "_UIPageViewControllerContentView",
            subviews.map(\._className).contains("_UIPageViewControllerContentView") == false,
            className != "_UIQueuingScrollView",
            superViewClassName != "_UIQueuingScrollView",

            // Avoid breaking UIButton layout.
            superview is UIButton == false,

            // Avoid breaking UITableView self sizing cells.
            className != "UITableViewCellContentView",

            // Skip non inspectable views
            self is NonInspectableView == false,
            superview is NonInspectableView == false,

            // Skip custom classes
            Inspector.sharedInstance.configuration.nonInspectableClassNames.contains(className) == false,
            Inspector.sharedInstance.configuration.nonInspectableClassNames.contains(superViewClassName) == false
        else {
            return false
        }
        return true
    }

    var elementName: String {
        accessibilityIdentifier?.trimmed ?? _classNameWithoutQualifiers
    }

    var displayName: String {
        let prettyName = accessibilityIdentifier?.trimmed ?? _prettyClassNameWithoutQualifiers

        guard
            let textElement = self as? TextElement,
            let textContent = textElement.content?.replacingOccurrences(of: "\n", with: "\\n")
        else {
            return prettyName
        }

        let limit = 20

        let formattedText: String = {
            guard textContent.count > limit else { return textContent }
            return textContent
                .prefix(limit)
                .appending("…")
        }()

        return "\(prettyName) - \"\(formattedText)\""
    }

    var shortElementDescription: String { [
        _className,
        subviewsDescription,
        frameDescription
    ]
    .compactMap { $0 }
    .joined(separator: .newLine)
    }

    var elementDescription: String {
        let fullDescription = [
            accessibilityIdentifier?.string(prepending: "Accessibility ID: \"", appending: "\""),
            shortElementDescription,
            constraintsDescription,
            issuesDescription?.string(prepending: .newLine)
        ]
        .compactMap { $0 }
        .joined(separator: .newLine)

        guard let accessibilityDescription = accessibilityLabel?.trimmed else {
            return fullDescription
        }
        return "\"\(accessibilityDescription)\"\n\n\(fullDescription)"
    }
}

private extension UIView {
    var subviewsDescription: String? {
        let childrenCount = children.count
        let allChildrenCount = allChildren.count

        let description = childrenCount == 1 ? children.first?._className.string(prepending: "Subview:") : "Subviews: \(childrenCount)"

        guard let description = description else { return .none }

        guard allChildrenCount > childrenCount else {
            return description
        }

        return "\(description) (\(allChildrenCount) Total)"
    }

    private static let frameFormatter = NumberFormatter().then {
        $0.numberStyle = .decimal
        $0.maximumFractionDigits = 1
    }

    var frameDescription: String? {
        ["Origin: (\(Self.frameFormatter.string(from: frame.origin.x)!), \(Self.frameFormatter.string(from: frame.origin.y)!))",
         "Size: \(Self.frameFormatter.string(from: frame.size.width)!) x \(Self.frameFormatter.string(from: frame.size.height)!)"]
            .joined(separator: "  –  ")
    }

    var issuesDescription: String? {
        guard !issues.isEmpty else { return nil }

        if issues.count == 1, let issue = issues.first {
            return "⚠️ \(issue.description)"
        }

        return issues.reduce(into: "") { multipleIssuesDescription, issue in
            if multipleIssuesDescription?.isEmpty == true {
                multipleIssuesDescription = "⚠️ \(issues.count) Issues"
            }
            else {
                multipleIssuesDescription?.append(.newLine)
                multipleIssuesDescription?.append("• \(issue.description)")
            }
        }
    }

    var constraintsDescription: String? {
        guard constraintElements.count > .zero else { return .none }
        return "Constraints: \(constraintElements.count)"
    }
}

extension NSObject {
    var _isInternalView: Bool {
        _className.starts(with: "_")
    }

    var _isSystemContainer: Bool {
        let className = _classNameWithoutQualifiers

        for systemContainer in Inspector.sharedInstance.configuration.knownSystemContainers {
            if className == systemContainer || className.starts(with: "_UI") {
                return true
            }
        }

        return false
    }

    var _className: String {
        String(describing: classForCoder)
    }

    var _prettyClassNameWithoutQualifiers: String {
        _classNameWithoutQualifiers
            .replacingOccurrences(of: "_", with: "")
            .camelCaseToWords()
            .replacingOccurrences(of: " Kit ", with: "Kit ")
            .removingRegexMatches(pattern: "[A-Z]{2} ", options: .anchored)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var _superclassName: String? {
        guard let superclass = superclass else { return nil }
        return String(describing: superclass)
    }

    var _classNameWithoutQualifiers: String {
        guard let nameWithoutQualifiers = _className.split(separator: "<").first else {
            return _className
        }

        return String(nameWithoutQualifiers)
    }
}
