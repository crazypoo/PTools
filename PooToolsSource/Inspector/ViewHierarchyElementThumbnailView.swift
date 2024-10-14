//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import AVFoundation
import UIKit

class ViewHierarchyElementThumbnailView: BaseView {
    enum State {
        case snapshot(UIView)
        case frameIsEmpty(CGRect)
        case isHidden
        case lostConnection
        case noWindow
    }

    // MARK: - Properties

    let element: ViewHierarchyElementReference

    var showEmptyStatusMessage: Bool = true {
        didSet {
            updateViews(afterScreenUpdates: true)
        }
    }

    var backgroundStyle: ThumbnailBackgroundStyle {
        get {
            Inspector.sharedInstance.configuration.elementInspectorConfiguration.thumbnailBackgroundStyle
        }
        set {
            Inspector.sharedInstance.configuration.elementInspectorConfiguration.thumbnailBackgroundStyle = newValue
            backgroundColor = newValue.color
        }
    }

    private lazy var heightConstraint_inspector = snapshotContainerView.heightAnchor.constraint(
        equalToConstant: .zero
    ).then {
        $0.priority = .init(rawValue: 999)
        $0.isActive = true
    }

    // MARK: - Init

    init(with element: ViewHierarchyElementReference) {
        self.element = element
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Componentns

    private lazy var gridImageView = UIImageView(image: IconKit.imageOfColorGrid().resizableImage(withCapInsets: .zero))

    private lazy var statusContentView = UIStackView.vertical(
        .directionalLayoutMargins(contentView.directionalLayoutMargins),
        .spacing(elementInspectorAppearance.verticalMargins / 2),
        .verticalAlignment(.center)
    )

    private lazy var snapshotContainerView = BaseView().then {
        $0.layer.shadowOpacity = Float(colorStyle.disabledAlpha)
        $0.layer.shadowRadius = Self.contentMargins.leading
    }

    static let contentMargins = NSDirectionalEdgeInsets(insets: Inspector.sharedInstance.appearance.elementInspector.horizontalMargins)

    // MARK: - View Lifecycle

    override func setup() {
        super.setup()

        tintColor = colorStyle.secondaryTextColor

        contentView.directionalLayoutMargins = Self.contentMargins

        clipsToBounds = true

        contentMode = .scaleAspectFit

        isOpaque = true

        isUserInteractionEnabled = false

        installView(gridImageView, position: .behind)

        contentView.installView(statusContentView, .centerXY)

        contentView.addArrangedSubview(snapshotContainerView)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundColor = backgroundStyle.color

        let proportionalFrame = calculateFrame(with: element.frame.size)

        guard
            !proportionalFrame.height.isNaN,
            !proportionalFrame.height.isInfinite,
            !proportionalFrame.height.isZero
        else {
            return
        }

        heightConstraint_inspector.constant = proportionalFrame.height
    }

    var aspectRatio: CGFloat {
        switch state {
        case let .snapshot(view):
            return view.frame.width / view.frame.height

        default:
            return 3
        }
    }

    // MARK: - State

    private(set) var state: State = .lostConnection {
        didSet {
            statusContentView.subviews.forEach { $0.removeFromSuperview() }

            let previousSubviews = snapshotContainerView.contentView.arrangedSubviews

            defer {
                previousSubviews.forEach { $0.removeFromSuperview() }
            }

            switch state {
            case let .snapshot(newSnapshot):
                let proportionalFrame = calculateFrame(with: newSnapshot.bounds.size)

                guard proportionalFrame != .zero else {
                    state = .frameIsEmpty(proportionalFrame)
                    return
                }

                newSnapshot.contentMode = contentMode
                snapshotContainerView.contentView.addArrangedSubview(newSnapshot)
                heightConstraint_inspector.constant = proportionalFrame.height

            case .isHidden:
                showEmptyStatus(icon: .eyeSlashFill, message: "View is hidden.")

            case .lostConnection:
                showEmptyStatus(icon: .wifiExlusionMark, message: Texts.lostConnectionToView)

            case let .frameIsEmpty(frame):
                showEmptyStatus(icon: .eyeSlashFill, message: "View frame is empty.\n\(frame)")

            case .noWindow:
                showEmptyStatus(icon: .wifiExlusionMark, message: "Not in the view hierarchy")
            }
        }
    }

    private func showEmptyStatus(icon glyph: Icon.Glyph, message: String) {
        statusContentView.removeAllArrangedSubviews()

        let color = backgroundStyle.contrastingColor

        let icon = Icon(glyph, color: color, size: CGSize(width: 36, height: 36))

        statusContentView.addArrangedSubview(icon)

        guard showEmptyStatusMessage else {
            return
        }

        let label = UILabel(
            .textStyle(.footnote),
            .text(message),
            .textAlignment(.center),
            .textColor(color)
        )

        statusContentView.addArrangedSubview(label)

        heightConstraint_inspector.constant = frame.width
    }

    private func calculateFrame(with snapshotSize: CGSize) -> CGRect {
        Self.calculateFrame(with: snapshotSize, inside: frame)
    }

    private static func calculateFrame(with snapshotSize: CGSize, inside frame: CGRect, margins: NSDirectionalEdgeInsets = contentMargins) -> CGRect {
        let maxWidth = max(0, frame.width - margins.leading - margins.trailing)

        let rect = AVMakeRect(
            aspectRatio: CGSize(
                width: 1,
                height: snapshotSize.height / snapshotSize.width
            ),
            insideRect: CGRect(
                origin: .zero,
                size: CGSize(
                    width: maxWidth,
                    height: maxWidth
                )
            )
        )

        return rect
    }

    func updateViews(afterScreenUpdates: Bool) {
        guard let referenceView = element.underlyingView else {
            state = .lostConnection
            return
        }

        if referenceView.isAssociatedToWindow == false {
            state = .noWindow
            return
        }

        guard
            referenceView.frame.isEmpty == false,
            referenceView.frame != .zero
        else {
            state = .frameIsEmpty(referenceView.frame)
            return
        }

        guard referenceView.isHidden == false else {
            state = .isHidden
            return
        }

        guard let snapshotView = referenceView.snapshotView(afterScreenUpdates: afterScreenUpdates) else {
            state = .lostConnection
            return
        }

        state = .snapshot(snapshotView)
    }
}
