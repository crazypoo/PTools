//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

protocol ElementChildrenPanelItemViewModelProtocol: AnyObject {
    typealias Parent = ElementChildrenPanelItemViewModelProtocol & ElementChildrenPanelTableViewCellViewModelProtocol
    var parent: Parent? { get set }
    var element: ViewHierarchyElementReference { get }
    var isCollapsed: Bool { get set }
    var availablePanels: [ElementInspectorPanel] { get }
}

extension ElementChildrenPanelViewModel {
    final class CellViewModel: ElementInspectorAppearanceProviding {
        weak var parent: Parent?

        private var _isCollapsed: Bool {
            didSet {
                if !_isCollapsed, relativeDepth > .zero {
                    animatedDisplay = true
                }
            }
        }

        let rootDepth: Int

        var iconImage: UIImage?

        // MARK: - Properties

        let element: ViewHierarchyElementReference

        lazy var animatedDisplay: Bool = relativeDepth > .zero

        init(
            element: ViewHierarchyElementReference,
            parent: Parent? = nil,
            rootDepth: Int,
            thumbnailImage: UIImage?,
            isCollapsed: Bool
        ) {
            self.parent = parent
            self.element = element
            self.rootDepth = rootDepth
            iconImage = thumbnailImage
            _isCollapsed = isCollapsed
        }
    }
}

// MARK: - ElementChildrenPanelTableViewCellViewModelProtocol

extension ElementChildrenPanelViewModel.CellViewModel: ElementChildrenPanelTableViewCellViewModelProtocol {
    var summaryInfo: ViewHierarchyElementSummary {
        ViewHierarchyElementSummary(
            automaticallyAdjustIndentation: automaticallyAdjustIndentation,
            hideCollapseButton: hideCollapseButton,
            iconImage: iconImage,
            isCollapseButtonEnabled: isCollapseButtonEnabled,
            isCollapsed: isCollapsed,
            isContainer: isContainer,
            isHidden: isHidden,
            relativeDepth: relativeDepth,
            subtitle: subtitle,
            subtitleFont: subtitleFont,
            title: title,
            titleFont: titleFont
        )
    }

    var availablePanels: [ElementInspectorPanel] {
        ElementInspectorPanel.allCases(for: element)
    }

    var showDisclosureIcon: Bool { relativeDepth > .zero }

    var appearance: (transform: CGAffineTransform, alpha: CGFloat) {
        if animatedDisplay {
            return (transform: Inspector.sharedInstance.appearance.elementInspector.panelInitialTransform, alpha: .zero)
        }
        return (transform: .identity, alpha: 1)
    }

    var isHidden: Bool {
        guard let parent = parent else { return isCollapsed }
        return parent.isCollapsed == true || parent.isHidden == true
    }

    var isCollapsed: Bool {
        get {
            isContainer ? _isCollapsed : true
        }
        set {
            guard isContainer else { return }
            _isCollapsed = newValue
        }
    }

    private var automaticallyAdjustIndentation: Bool { relativeDepth > .zero }

    private var title: String? { relativeDepth > .zero ? element.displayName : nil }

    private var subtitle: String? { relativeDepth > .zero ? element.shortElementDescription : element.elementDescription }

    private var titleFont: UIFont { elementInspectorAppearance.titleFont(forRelativeDepth: relativeDepth) }

    private var subtitleFont: UIFont { elementInspectorAppearance.font(forRelativeDepth: relativeDepth) }

    private var isCollapseButtonEnabled: Bool {
        relativeDepth < Inspector.sharedInstance.configuration.elementInspectorConfiguration.childrenListMaximumInteractiveDepth
    }

    private var hideCollapseButton: Bool {
        if relativeDepth == .zero { return true }
        return !isContainer
    }

    var isContainer: Bool { element.isContainer }

    private var relativeDepth: Int { element.depth - rootDepth }
}

// MARK: - Hashable

extension ElementChildrenPanelViewModel.CellViewModel: Hashable {
    static func == (lhs: ElementChildrenPanelViewModel.CellViewModel, rhs: ElementChildrenPanelViewModel.CellViewModel) -> Bool {
        lhs.element.objectIdentifier == rhs.element.objectIdentifier
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(element.objectIdentifier)
    }
}

// MARK: - Images

private extension ElementChildrenPanelViewModel.CellViewModel {
    static let thumbnailImageLostConnection = IconKit.imageOfWifiExlusionMark(
        CGSize(
            width: Inspector.sharedInstance.appearance.elementInspector.horizontalMargins * 1.5,
            height: Inspector.sharedInstance.appearance.elementInspector.horizontalMargins * 1.5
        )
    ).withRenderingMode(.alwaysTemplate)

    static let thumbnailImageIsHidden = IconKit.imageOfEyeSlashFill(
        CGSize(
            width: Inspector.sharedInstance.appearance.elementInspector.horizontalMargins * 1.5,
            height: Inspector.sharedInstance.appearance.elementInspector.horizontalMargins * 1.5
        )
    ).withRenderingMode(.alwaysTemplate)
}
