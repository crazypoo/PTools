//
//  PTCustomerAlertController.swift
//  PooTools
//
//  Created by 邓杰豪 on 2024/6/15.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift

public typealias PTCustomerCustomerBlock = (_ alertCustomerView: UIView) -> Void

@objc public enum PTAlertAnimationType: Int {
    case Top
    case Bottom
    case Left
    case Right
    case Normal
}

@objcMembers
public class PTCustomBottomButtonModel: NSObject {
    public var titleName: String? = ""
    public var titleColor: UIColor? = .systemBlue
}

// MARK: - PTCustomerAlertController

public class PTCustomerAlertController: PTAlertController {

    // MARK: Layout Mode

    private enum ActionLayoutMode: Equatable {
        /// 所有内容都可以完整显示
        case fitted
        /// Body 固定，按钮区域滚动
        case scrollingActions
        /// 整体 Body 滚动
        case scrollingAll
    }

    private enum CompactActionLayout: Equatable {
        /// 1~2 个按钮横向
        case horizontal
        /// Dynamic Type / 标题过长时，2 个按钮纵向
        case vertical
    }

    private struct AlertLayoutSignature: Equatable {
        let width: CGFloat
        let safeHeight: CGFloat
        let bodyHeight: CGFloat
        let buttonCount: Int
        let rowHeight: CGFloat
        let compactLayout: CompactActionLayout
    }

    // MARK: Public

    public var bottomButtonTapCallback: ((_ title: String, _ index: Int) -> Void)?

    public var backgroundTapCallback: ((PTCustomerAlertController) -> Void)?

    /// 最大 Alert 宽度
    public var maximumContentWidth: CGFloat = 340 {
        didSet {
            guard maximumContentWidth.isFinite, maximumContentWidth > 0 else {
                maximumContentWidth = Self.defaultMaximumContentWidth
                return
            }
            invalidateContentLayout()
        }
    }

    /// 自定义背景色
    public var contentBackgroundColor: UIColor? {
        didSet {
            updateContentBackgroundIfLoaded()
        }
    }

    /// Alert 材质样式
    public var visualStyle: PTVisualStyle = .automatic {
        didSet {
            updateContentBackgroundIfLoaded()
        }
    }

    /// customView 中的内容动态变化以后，可以主动调用一次。
    ///
    /// 例如：
    /// - messageLabel.text 改变
    /// - 网络回来以后增加内容
    /// - customView 内部隐藏/显示某些视图
    public func invalidateContentLayout() {
        layoutSignature = nil
        guard isViewLoaded else { return }
        view.setNeedsLayout()
    }

    // MARK: Constants

    static let defaultMaximumContentWidth: CGFloat = 340

    /// 系统 Alert 的文字区域不会贴得很靠边。
    /// 相比旧版 10pt，20pt 更接近 UIAlertController 的视觉比例。
    private let titleHorizontalInset: CGFloat = 20

    /// 单一内容（只有 title 或只有 custom/msg）时的最小视觉高度。
    /// 一行文字不会让整个 Alert 显得过扁。
    private let minimumSingleBodyHeight: CGFloat = 76

    /// title + custom/msg 同时存在时的最小视觉高度。
    /// 两边都是一行时仍然保留系统 Alert 风格的呼吸感。
    private let minimumCombinedBodyHeight: CGFloat = 96

    /// 内容区域最少保留的上下间距。
    /// 真正的“最小高度”由 bodyHeaderView 自己承担，
    /// 这里仅保证内容变多以后仍不会贴上下边缘。
    private let singleContentVerticalInset: CGFloat = 14
    private let combinedContentVerticalInset: CGFloat = 14

    /// title 和 custom/msg 的视觉间距。
    private let titleMessageSpacing: CGFloat = 6

    private let minimumButtonRowHeight: CGFloat = 44
    private let minimumAlertVerticalMargin: CGFloat = 16

    private var separatorThickness: CGFloat {
        1 / max(UIScreen.main.scale, 1)
    }

    // MARK: Input

    fileprivate let alertTitle: String
    fileprivate let titleFont: UIFont
    fileprivate let titleColor: UIColor

    fileprivate let buttons: [String]
    fileprivate let buttonsColors: [UIColor]
    fileprivate var buttonsFont: UIFont = .appfont(size: 15)

    fileprivate var customerViewCallback: PTCustomerCustomerBlock?

    /// customView 的兼容 fallback 高度。
    ///
    /// 如果 customView 内部有完整的 Auto Layout 垂直约束，
    /// UILabel / UITextView / 自定义内容的真实高度优先。
    ///
    /// 如果旧调用方仍然依赖 frame 布局，
    /// 则继续使用该高度，避免破坏历史调用。
    fileprivate var customerViewHeight: CGFloat = 100

    @PTClampedPropertyWrapper(range: 25...100)
    fileprivate var contentSpace: CGFloat = 25

    @PTClampedPropertyWrapper(range: 0...15)
    fileprivate var cornerSize: CGFloat = 15

    fileprivate var canTapBackground: Bool = false

    // MARK: State

    fileprivate var buttonModels = [PTCustomBottomButtonModel]()
    fileprivate var contentWidth: CGFloat = 0

    private var actionButtons = [UIButton]()
    private var actionButtonHeightConstraints = [Constraint]()
    private var actionSeparatorViews = [UIView]()

    private var compactHorizontalDividerConstraints = [Constraint]()
    private var compactVerticalDividerConstraints = [Constraint]()

    private var contentWidthConstraint: Constraint?
    private var contentHeightConstraint: Constraint?

    /// legacy customView 的 fallback 高度。
    /// priority 低于 UILabel 默认 vertical hugging，
    /// 因此有完整 Auto Layout 的 message 不会被强行撑高。
    private var customerViewFallbackHeightConstraint: Constraint?

    /// Body 的最小视觉高度。
    /// 注意这不是“文字高度”，只是 Alert 的视觉底座。
    private var bodyHeaderMinimumHeightConstraint: Constraint?

    private var compactActionHeightConstraint: Constraint?
    private var actionViewportHeightConstraint: Constraint?

    private var layoutSignature: AlertLayoutSignature?
    private var actionLayoutMode: ActionLayoutMode = .fitted
    private var compactActionLayout: CompactActionLayout = .horizontal
    private var isHandlingAction = false

    private var traitChangeRegistration: (any UITraitChangeRegistration)?

    // MARK: Content Views

    fileprivate lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = resolvedContentBackgroundColor
        view.alpha = 0
        view.layer.cornerRadius = cornerSize
        view.layer.cornerCurve = .continuous
        view.clipsToBounds = true
        return view
    }()

    private lazy var surfaceEffectView: UIVisualEffectView = {
        let view = UIVisualEffectView(frame: .zero)
        view.isUserInteractionEnabled = true
        view.isAccessibilityElement = false
        return view
    }()

    // MARK: Body

    private let bodyScrollView: UIScrollView = {
        let view = UIScrollView()
        view.backgroundColor = .clear
        view.contentInsetAdjustmentBehavior = .never
        view.showsVerticalScrollIndicator = false
        view.alwaysBounceVertical = false
        return view
    }()

    private let bodyContentView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    /// Body 的实际 Header。
    ///
    /// 这里负责两件事：
    /// 1. 自适应真实内容高度；
    /// 2. 内容过短时提供最小视觉高度。
    private let bodyHeaderView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    /// 真正包住 title + custom/msg 的内容容器。
    ///
    /// 与 bodyHeaderView 分离的原因：
    /// 当 Body 使用最小高度时，把多余空间平均分配到内容上下两边，
    /// 而不是全部堆到 msg 底部。
    private let headerContentView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    fileprivate lazy var titleMessage: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0

        PTUIAccessibility.applyDynamicType(to: label, font: titleFont)

        label.textColor = titleColor
        label.text = alertTitle
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityTraits = .header

        // 避免最小 Body 高度把 UILabel 本身拉高。
        // 多余空间应该留在文字上下，而不是留在 UILabel frame 内部。
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)

        return label
    }()

    fileprivate lazy var customView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    // MARK: > 2 buttons

    private let actionScrollView: UIScrollView = {
        let view = UIScrollView()
        view.backgroundColor = .clear
        view.contentInsetAdjustmentBehavior = .never
        view.showsVerticalScrollIndicator = true
        view.alwaysBounceVertical = false
        return view
    }()

    private let actionStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.alignment = .fill
        view.distribution = .fill
        view.spacing = 0
        return view
    }()

    // MARK: 1~2 buttons

    private let compactActionView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private let compactActionStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.alignment = .fill
        view.distribution = .fillEqually
        view.spacing = 0
        return view
    }()

    private let compactTopSeparatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        return view
    }()

    private let compactDividerView: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        return view
    }()

    // MARK: Computed

    private var hasTitle: Bool {
        !alertTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var hasCustomContent: Bool {
        customerViewCallback != nil
    }

    private var minimumBodyHeight: CGFloat {
        switch (hasTitle, hasCustomContent) {
        case (true, true):
            return minimumCombinedBodyHeight
        case (true, false), (false, true):
            return minimumSingleBodyHeight
        case (false, false):
            return 0
        }
    }

    private var bodyVerticalInset: CGFloat {
        switch (hasTitle, hasCustomContent) {
        case (true, true):
            return combinedContentVerticalInset
        case (true, false), (false, true):
            return singleContentVerticalInset
        case (false, false):
            return 0
        }
    }

    private var resolvedContentBackgroundColor: UIColor {
        if let contentBackgroundColor {
            return contentBackgroundColor
        }

        let effect = PTVisualStyleResolver.makeEffect(
            for: visualStyle,
            blurStyle: .systemMaterial
        )

        return effect == nil ? .secondarySystemBackground : .clear
    }

    // MARK: Init

    public init(
        title: String = "",
        titleFont: UIFont = .appfont(size: 15),
        titleColor: UIColor = .systemBlue,
        customerViewHeight: CGFloat = 100,
        customerViewCallback: PTCustomerCustomerBlock? = nil,
        buttons: [String],
        buttonsColors: [UIColor],
        buttonsFont: UIFont = .appfont(size: 15),
        cornerSize: CGFloat = 15,
        contentSpace: CGFloat = 25,
        canTapBackground: Bool = false
    ) {
        self.alertTitle = title
        self.titleFont = titleFont
        self.titleColor = titleColor
        self.buttons = buttons
        self.buttonsColors = buttonsColors
        self.buttonsFont = buttonsFont
        self.cornerSize = cornerSize
        self.contentSpace = contentSpace
        self.customerViewHeight = max(0, customerViewHeight)
        self.customerViewCallback = customerViewCallback
        self.canTapBackground = canTapBackground

        super.init(nibName: nil, bundle: nil)
    }

    // MARK: Width

    static func resolvedContentWidth(
        containerWidth: CGFloat,
        contentSpace: CGFloat,
        maximumWidth: CGFloat = defaultMaximumContentWidth
    ) -> CGFloat {
        let safeContainerWidth: CGFloat
        if containerWidth.isFinite {
            safeContainerWidth = max(1, containerWidth)
        } else {
            safeContainerWidth = 1
        }

        let safeContentSpace: CGFloat
        if contentSpace.isFinite {
            safeContentSpace = max(0, contentSpace)
        } else {
            safeContentSpace = 25
        }

        let safeMaximumWidth: CGFloat
        if maximumWidth.isFinite, maximumWidth > 0 {
            safeMaximumWidth = maximumWidth
        } else {
            safeMaximumWidth = defaultMaximumContentWidth
        }

        let widthWithMargins = max(1, safeContainerWidth - safeContentSpace * 2)
        return max(1, min(widthWithMargins, safeMaximumWidth))
    }

    // MARK: Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()

        contentWidth = Self.resolvedContentWidth(
            containerWidth: view.bounds.width,
            contentSpace: contentSpace,
            maximumWidth: maximumContentWidth
        )

        configureButtonModels()
        configureRootView()
        configureSurface()
        configureBackgroundTap()
        configureContentHierarchy()
        installSurfaceAppearanceObservers()
        updateSurfaceAppearance()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateAlertLayout()
    }

    public override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        invalidateContentLayout()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Button Models

    private func configureButtonModels() {
        buttonModels = buttons.enumerated().map { index, title in
            let model = PTCustomBottomButtonModel()
            model.titleName = title

            if index < buttonsColors.count {
                model.titleColor = buttonsColors[index]
            } else {
                model.titleColor = .systemBlue
            }

            return model
        }
    }

    // MARK: Root

    private func configureRootView() {
        view.backgroundColor = .clear
        view.addSubview(contentView)

        contentView.snp.makeConstraints { make in
            make.centerX.equalTo(view.safeAreaLayoutGuide.snp.centerX)
            make.centerY.equalTo(view.safeAreaLayoutGuide.snp.centerY)
            contentWidthConstraint = make.width.equalTo(contentWidth).constraint
            contentHeightConstraint = make.height.equalTo(1).constraint
        }
    }

    private func configureSurface() {
        contentView.addSubview(surfaceEffectView)
        surfaceEffectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // MARK: Background Tap

    private func configureBackgroundTap() {
        guard canTapBackground else { return }

        let tap = UITapGestureRecognizer { [weak self] _ in
            guard let self else { return }

            PTGCDManager.shared.runOnMain {
                self.dismissSelf { [weak self = self] in
                    guard let self else { return }
                    PTGCDManager.shared.runOnMain {
                        self.backgroundTapCallback?(self)
                    }
                }
            }
        }

        tap.cancelsTouchesInView = false
        tap.delegate = self
        view.addGestureRecognizer(tap)
    }

    // MARK: Hierarchy

    private func configureContentHierarchy() {
        let surfaceContentView = surfaceEffectView.contentView

        surfaceContentView.addSubview(bodyScrollView)
        bodyScrollView.addSubview(bodyContentView)
        bodyContentView.addSubview(bodyHeaderView)

        bodyScrollView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        bodyContentView.snp.makeConstraints { make in
            make.top.equalTo(bodyScrollView.contentLayoutGuide.snp.top)
            make.leading.equalTo(bodyScrollView.contentLayoutGuide.snp.leading)
            make.trailing.equalTo(bodyScrollView.contentLayoutGuide.snp.trailing)
            make.bottom.equalTo(bodyScrollView.contentLayoutGuide.snp.bottom)
            make.width.equalTo(bodyScrollView.frameLayoutGuide.snp.width)
        }

        bodyHeaderView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            bodyHeaderMinimumHeightConstraint = make
                .height
                .greaterThanOrEqualTo(minimumBodyHeight)
                .constraint
        }

        configureBodyHeader()

        if buttons.count > 2 {
            configureScrollableActions()

            bodyScrollView.snp.makeConstraints { make in
                make.bottom.equalToSuperview()
            }
        } else {
            bodyHeaderView.snp.makeConstraints { make in
                make.bottom.equalToSuperview()
            }

            if buttons.isEmpty {
                bodyScrollView.snp.makeConstraints { make in
                    make.bottom.equalToSuperview()
                }
            } else {
                configureCompactActions(in: surfaceContentView)
            }
        }
    }

    // MARK: Header

    private func configureBodyHeader() {
        titleMessage.isHidden = !hasTitle
        customView.isHidden = !hasCustomContent

        guard hasTitle || hasCustomContent else {
            bodyHeaderMinimumHeightConstraint?.update(offset: 0)
            return
        }

        bodyHeaderView.addSubview(headerContentView)

        // 关键：headerContentView 垂直居中。
        // 当 bodyHeaderView 因 minimumBodyHeight 比真实内容更高时，
        // 多余高度自动平均分到内容上下，而不是全部出现在 msg 下方。
        headerContentView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview().offset(bodyVerticalInset)
            make.bottom.lessThanOrEqualToSuperview().offset(-bodyVerticalInset)
        }

        switch (hasTitle, hasCustomContent) {
        case (true, true):
            headerContentView.addSubview(titleMessage)
            headerContentView.addSubview(customView)

            titleMessage.snp.makeConstraints { make in
                make.top.equalToSuperview()
                make.leading.trailing.equalToSuperview().inset(titleHorizontalInset)
            }

            customView.snp.makeConstraints { make in
                make.top.equalTo(titleMessage.snp.bottom).offset(titleMessageSpacing)
                make.leading.trailing.bottom.equalToSuperview()

                // 兼容旧 frame 布局；Auto Layout 内容本身优先。
                customerViewFallbackHeightConstraint = make
                    .height
                    .equalTo(customerViewHeight)
                    .priority(200)
                    .constraint
            }

        case (true, false):
            headerContentView.addSubview(titleMessage)

            titleMessage.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview()
                make.leading.trailing.equalToSuperview().inset(titleHorizontalInset)
            }

        case (false, true):
            headerContentView.addSubview(customView)

            customView.snp.makeConstraints { make in
                make.edges.equalToSuperview()

                // 兼容旧 frame 布局；Auto Layout 内容本身优先。
                customerViewFallbackHeightConstraint = make
                    .height
                    .equalTo(customerViewHeight)
                    .priority(200)
                    .constraint
            }

        case (false, false):
            break
        }

        // callback 保持原来的调用时机：
        // customView 已经进入 view hierarchy 后再执行。
        customerViewCallback?(customView)
    }

    // MARK: > 2 Actions

    private func configureScrollableActions() {
        bodyContentView.addSubview(actionScrollView)
        actionScrollView.addSubview(actionStackView)

        actionScrollView.snp.makeConstraints { make in
            make.top.equalTo(bodyHeaderView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
            actionViewportHeightConstraint = make.height.equalTo(1).constraint
        }

        actionStackView.snp.makeConstraints { make in
            make.top.equalTo(actionScrollView.contentLayoutGuide.snp.top)
            make.leading.equalTo(actionScrollView.contentLayoutGuide.snp.leading)
            make.trailing.equalTo(actionScrollView.contentLayoutGuide.snp.trailing)
            make.bottom.equalTo(actionScrollView.contentLayoutGuide.snp.bottom)
            make.width.equalTo(actionScrollView.frameLayoutGuide.snp.width)
        }

        buttonModels.enumerated().forEach { index, model in
            let button = makeActionButton(model: model, index: index)
            actionButtons.append(button)
            actionStackView.addArrangedSubview(button)

            button.snp.makeConstraints { make in
                actionButtonHeightConstraints.append(
                    make.height.equalTo(minimumButtonRowHeight).constraint
                )
            }

            guard index < buttonModels.count - 1 else { return }

            let separator = UIView()
            separator.backgroundColor = .separator
            actionStackView.addArrangedSubview(separator)

            separator.snp.makeConstraints { make in
                make.height.equalTo(separatorThickness)
            }

            actionSeparatorViews.append(separator)
        }
    }

    // MARK: 1~2 Actions

    private func configureCompactActions(in surfaceContentView: UIView) {
        surfaceContentView.addSubview(compactActionView)

        compactActionView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(bodyScrollView.snp.bottom)
            compactActionHeightConstraint = make
                .height
                .equalTo(minimumButtonRowHeight + separatorThickness)
                .constraint
        }

        compactActionView.addSubview(compactTopSeparatorView)
        compactActionView.addSubview(compactActionStackView)
        compactActionView.addSubview(compactDividerView)

        compactTopSeparatorView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(separatorThickness)
        }

        compactActionStackView.snp.makeConstraints { make in
            make.top.equalTo(compactTopSeparatorView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        buttonModels.enumerated().forEach { index, model in
            let button = makeActionButton(model: model, index: index)
            actionButtons.append(button)
            compactActionStackView.addArrangedSubview(button)

            button.snp.makeConstraints { make in
                actionButtonHeightConstraints.append(
                    make.height.equalTo(minimumButtonRowHeight).constraint
                )
            }
        }

        configureCompactDivider()
    }

    private func configureCompactDivider() {
        guard buttonModels.count == 2, actionButtons.count == 2 else {
            compactDividerView.isHidden = true
            return
        }

        compactDividerView.isHidden = false

        compactHorizontalDividerConstraints = compactDividerView.snp.prepareConstraints { make in
            make.width.equalTo(separatorThickness)
            make.top.bottom.equalTo(compactActionStackView)
            make.centerX.equalTo(compactActionStackView.snp.centerX)
        }

        compactVerticalDividerConstraints = compactDividerView.snp.prepareConstraints { make in
            make.height.equalTo(separatorThickness)
            make.leading.trailing.equalTo(compactActionStackView)
            make.top.equalTo(actionButtons[0].snp.bottom)
        }

        compactHorizontalDividerConstraints.forEach { $0.activate() }
    }

    // MARK: Button

    private func makeActionButton(
        model: PTCustomBottomButtonModel,
        index: Int
    ) -> UIButton {
        let title = model.titleName ?? ""
        let button = UIButton(type: .custom)

        PTUIAccessibility.applyDynamicType(to: button, font: buttonsFont)

        button.setTitleColor(model.titleColor, for: .normal)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.systemGray, for: .highlighted)
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.titleLabel?.setContentCompressionResistancePriority(.required, for: .vertical)
        button.contentHorizontalAlignment = .center
        button.accessibilityTraits = .button
        button.tag = 100 + index

        button.addAction(
            UIAction { [weak self] _ in
                self?.handleAction(title: title, index: index)
            },
            for: .touchUpInside
        )

        return button
    }

    private func handleAction(title: String, index: Int) {
        guard !isHandlingAction else { return }

        isHandlingAction = true
        actionButtons.forEach { $0.isEnabled = false }

        dismissSelf { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.bottomButtonTapCallback?(title, index)
                self.bottomButtonTapCallback = nil
            }
        }
    }

    // MARK: Body Height

    /// 获取 Auto Layout 的真实 Body 高度。
    ///
    /// 与旧方案不同：
    /// - 不再手工计算 title 高度；
    /// - 不再把最小高度加到 UILabel 本身；
    /// - 最小视觉高度由 bodyHeaderView 的约束承担；
    /// - headerContentView 垂直居中，因此短内容的留白上下对称。
    private func resolvedBodyHeight(for width: CGFloat) -> CGFloat {
        guard hasTitle || hasCustomContent else { return 0 }

        bodyHeaderMinimumHeightConstraint?.update(offset: minimumBodyHeight)

        let safeWidth = max(1, width)
        bodyHeaderView.bounds.size.width = safeWidth
        bodyHeaderView.setNeedsLayout()
        bodyHeaderView.layoutIfNeeded()

        let fittingSize = CGSize(
            width: safeWidth,
            height: UIView.layoutFittingCompressedSize.height
        )

        let size = bodyHeaderView.systemLayoutSizeFitting(
            fittingSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )

        guard size.height.isFinite else {
            return minimumBodyHeight
        }

        return ceil(max(minimumBodyHeight, size.height))
    }

    // MARK: Button Height

    private func resolvedButtonRowHeight() -> CGFloat {
        let actualLineHeight = actionButtons
            .compactMap { $0.titleLabel?.font.lineHeight }
            .max() ?? buttonsFont.lineHeight

        guard actualLineHeight.isFinite else {
            return minimumButtonRowHeight
        }

        return max(
            minimumButtonRowHeight,
            ceil(actualLineHeight + 20)
        )
    }

    private func resolvedCompactActionLayout(for width: CGFloat) -> CompactActionLayout {
        guard buttons.count == 2 else { return .horizontal }

        if traitCollection.preferredContentSizeCategory.isAccessibilityCategory {
            return .vertical
        }

        let buttonWidth = max(1, (width - separatorThickness) / 2)
        let availableTitleWidth = max(1, buttonWidth - 24)
        let actualFont = actionButtons.first?.titleLabel?.font ?? buttonsFont

        let titlesFit = buttons.allSatisfy { title in
            let measuredSize = (title as NSString).size(
                withAttributes: [.font: actualFont]
            )
            return measuredSize.width <= availableTitleWidth
        }

        return titlesFit ? .horizontal : .vertical
    }

    /// 横排的 1~2 个按钮都只占一行。
    /// 这是上一版已经修复的重点，继续保留。
    private func compactActionHeight(
        for layout: CompactActionLayout,
        rowHeight: CGFloat
    ) -> CGFloat {
        guard !buttons.isEmpty else { return 0 }

        switch layout {
        case .horizontal:
            return separatorThickness + rowHeight

        case .vertical:
            let rowsHeight = CGFloat(buttons.count) * rowHeight
            let internalSeparatorsHeight = CGFloat(max(0, buttons.count - 1)) * separatorThickness
            return separatorThickness + rowsHeight + internalSeparatorsHeight
        }
    }

    private func actionsContentHeight(rowHeight: CGFloat) -> CGFloat {
        let rowsHeight = CGFloat(buttons.count) * rowHeight
        let separatorsHeight = CGFloat(max(0, buttons.count - 1)) * separatorThickness
        return rowsHeight + separatorsHeight
    }

    // MARK: Compact Layout

    private func applyCompactActionLayout(_ layout: CompactActionLayout) {
        guard buttons.count == 2 else {
            compactActionStackView.axis = .horizontal
            compactActionStackView.spacing = 0
            compactDividerView.isHidden = true
            return
        }

        compactActionStackView.axis = layout == .horizontal ? .horizontal : .vertical
        compactActionStackView.spacing = layout == .vertical ? separatorThickness : 0

        if layout == .horizontal {
            compactVerticalDividerConstraints.forEach { $0.deactivate() }
            compactHorizontalDividerConstraints.forEach { $0.activate() }
        } else {
            compactHorizontalDividerConstraints.forEach { $0.deactivate() }
            compactVerticalDividerConstraints.forEach { $0.activate() }
        }

        compactDividerView.isHidden = false
    }

    // MARK: Main Layout

    private func updateAlertLayout() {
        guard contentWidthConstraint != nil, contentHeightConstraint != nil else {
            return
        }

        let safeAreaFrame = view.safeAreaLayoutGuide.layoutFrame

        let availableWidth: CGFloat
        if safeAreaFrame.width > 0 {
            availableWidth = safeAreaFrame.width
        } else {
            availableWidth = view.bounds.width
        }

        let width = Self.resolvedContentWidth(
            containerWidth: min(
                max(1, view.bounds.width),
                max(1, availableWidth)
            ),
            contentSpace: contentSpace,
            maximumWidth: maximumContentWidth
        )

        let safeHeight: CGFloat
        if safeAreaFrame.height > 0 {
            safeHeight = safeAreaFrame.height
        } else {
            safeHeight = view.bounds.height
        }

        guard safeHeight > 0 else { return }

        let maximumHeight = max(
            1,
            safeHeight - minimumAlertVerticalMargin * 2
        )

        // Body 高度已经同时包含：
        // 1. 真实内容高度；
        // 2. 单内容 / 双内容的最小视觉高度；
        // 3. 上下最小 padding。
        let bodyHeight = resolvedBodyHeight(for: width)
        let rowHeight = resolvedButtonRowHeight()
        let compactLayout = resolvedCompactActionLayout(for: width)
        let verticalButtonsHeight = actionsContentHeight(rowHeight: rowHeight)
        let compactButtonsHeight = compactActionHeight(
            for: compactLayout,
            rowHeight: rowHeight
        )

        let mode: ActionLayoutMode
        let contentHeight: CGFloat
        let actionViewportHeight: CGFloat

        // MARK: > 2 buttons

        if buttons.count > 2 {
            let requiredHeight = bodyHeight + verticalButtonsHeight

            if requiredHeight <= maximumHeight {
                mode = .fitted
                contentHeight = requiredHeight
                actionViewportHeight = verticalButtonsHeight
            } else if bodyHeight + min(verticalButtonsHeight, rowHeight * 2) <= maximumHeight {
                // Body 本身放得下：只让按钮区滚动。
                mode = .scrollingActions
                contentHeight = maximumHeight
                actionViewportHeight = max(rowHeight, maximumHeight - bodyHeight)
            } else {
                // Body 本身已经很高：整体滚动。
                mode = .scrollingAll
                contentHeight = maximumHeight
                actionViewportHeight = verticalButtonsHeight
            }
        }

        // MARK: 0~2 buttons

        else {
            mode = .fitted
            contentHeight = max(
                1,
                min(bodyHeight + compactButtonsHeight, maximumHeight)
            )
            actionViewportHeight = 0
        }

        let signature = AlertLayoutSignature(
            width: width,
            safeHeight: safeHeight,
            bodyHeight: bodyHeight,
            buttonCount: buttons.count,
            rowHeight: rowHeight,
            compactLayout: compactLayout
        )

        guard signature != layoutSignature ||
                mode != actionLayoutMode ||
                compactLayout != compactActionLayout else {
            return
        }

        let modeChanged = mode != actionLayoutMode ||
            compactLayout != compactActionLayout

        contentWidth = width
        contentWidthConstraint?.update(offset: width)
        contentHeightConstraint?.update(offset: contentHeight)
        actionViewportHeightConstraint?.update(offset: actionViewportHeight)

        actionButtonHeightConstraints.forEach { constraint in
            constraint.update(offset: rowHeight)
        }

        // MARK: Scrolling

        if buttons.count > 2 {
            bodyScrollView.isScrollEnabled = mode == .scrollingAll
            bodyScrollView.showsVerticalScrollIndicator = bodyScrollView.isScrollEnabled

            actionScrollView.isScrollEnabled = mode == .scrollingActions
            actionScrollView.showsVerticalScrollIndicator = actionScrollView.isScrollEnabled
        } else {
            let bodyViewportHeight = max(0, contentHeight - compactButtonsHeight)
            bodyScrollView.isScrollEnabled = bodyHeight > bodyViewportHeight + 0.5
            bodyScrollView.showsVerticalScrollIndicator = bodyScrollView.isScrollEnabled
        }

        // MARK: Compact Action

        if buttons.count <= 2, !buttons.isEmpty {
            applyCompactActionLayout(compactLayout)
            compactActionHeightConstraint?.update(offset: compactButtonsHeight)
        }

        if modeChanged {
            bodyScrollView.setContentOffset(.zero, animated: false)
            actionScrollView.setContentOffset(.zero, animated: false)
        }

        actionLayoutMode = mode
        compactActionLayout = compactLayout
        layoutSignature = signature
    }

    // MARK: Surface

    private func updateContentBackgroundIfLoaded() {
        guard isViewLoaded else { return }
        updateSurfaceAppearance()
    }

    private func updateSurfaceAppearance() {
        guard isViewLoaded else { return }

        contentView.backgroundColor = resolvedContentBackgroundColor

        guard contentBackgroundColor == nil else {
            surfaceEffectView.effect = nil
            surfaceEffectView.backgroundColor = .clear
            return
        }

        PTVisualStyleResolver.apply(
            to: surfaceEffectView,
            style: visualStyle,
            blurStyle: .systemMaterial,
            fallbackColor: .secondarySystemBackground
        )
    }

    private func installSurfaceAppearanceObservers() {
        traitChangeRegistration = registerForTraitChanges([
            UITraitUserInterfaceStyle.self,
            UITraitAccessibilityContrast.self
        ]) { [weak self] (_: PTCustomerAlertController, _: UITraitCollection) in
            guard let self else { return }
            self.updateSurfaceAppearance()
            self.invalidateContentLayout()
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(accessibilityAppearanceDidChange),
            name: UIAccessibility.reduceTransparencyStatusDidChangeNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(accessibilityAppearanceDidChange),
            name: UIContentSizeCategory.didChangeNotification,
            object: nil
        )
    }

    @objc
    private func accessibilityAppearanceDidChange() {
        updateSurfaceAppearance()
        invalidateContentLayout()
    }
}

// MARK: - UIGestureRecognizerDelegate

extension PTCustomerAlertController {

    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
    ) -> Bool {
        // 只允许点击真正的背景区域关闭。
        // 点击 Alert 内容本身：title / msg / button / customView 都不会关闭。
        touch.view === view
    }
}

// MARK: - Animation

extension PTCustomerAlertController {

    public override func showAnimation(completion: PTActionTask?) {
        let reduceMotion = UIAccessibility.isReduceMotionEnabled
        let duration = max(0, config.showAlertDuration)

        contentView.transform = reduceMotion
            ? .identity
            : CGAffineTransform(scaleX: 0.94, y: 0.94)

        let animations = {
            self.view.backgroundColor = UIColor.DevMaskColor
            self.contentView.alpha = 1

            if !reduceMotion {
                self.contentView.transform = .identity
            }
        }

        let finish: (Bool) -> Void = { _ in
            let accessibilityTarget: Any?

            if self.hasTitle {
                accessibilityTarget = self.titleMessage
            } else {
                accessibilityTarget = self.actionButtons.first
            }

            if self.view.window != nil, let accessibilityTarget {
                UIAccessibility.post(
                    notification: .screenChanged,
                    argument: accessibilityTarget
                )
            }

            completion?()
        }

        if reduceMotion {
            UIView.animate(
                withDuration: duration,
                delay: 0,
                options: [
                    .beginFromCurrentState,
                    .allowUserInteraction,
                    .curveEaseOut
                ],
                animations: animations,
                completion: finish
            )
        } else {
            UIView.animate(
                withDuration: duration,
                delay: 0,
                usingSpringWithDamping: 0.92,
                initialSpringVelocity: 0,
                options: [
                    .beginFromCurrentState,
                    .allowUserInteraction,
                    .curveEaseOut
                ],
                animations: animations,
                completion: finish
            )
        }
    }

    public override func dismissAnimation(completion: PTActionTask?) {
        let reduceMotion = UIAccessibility.isReduceMotionEnabled
        let duration = max(0, config.hideAlertDuration)

        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: [
                .beginFromCurrentState,
                .allowUserInteraction,
                .curveEaseIn
            ],
            animations: {
                self.view.backgroundColor = .clear
                self.contentView.alpha = 0

                if !reduceMotion {
                    self.contentView.transform = CGAffineTransform(
                        scaleX: 0.98,
                        y: 0.98
                    )
                }
            },
            completion: { _ in
                completion?()
            }
        )
    }
}
