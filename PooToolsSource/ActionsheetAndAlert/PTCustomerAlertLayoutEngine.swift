//
//  PTCustomerAlertLayoutEngine.swift
//  PooTools
//
// English: Keep alert layout decisions and text measurement outside the view controller facade.
// Español: Mantiene las decisiones de diseño y medición fuera de la fachada del controlador.
// 中文：将 Alert 布局决策和文本测量从控制器门面中独立出来。
//

import UIKit

enum PTCustomerAlertActionLayoutMode: Equatable {
    case fitted
    case scrollingActions
    case scrollingAll
}

enum PTCustomerAlertCompactActionLayout: Equatable {
    case horizontal
    case vertical
}

struct PTCustomerAlertLayoutSignature: Equatable {
    let width: CGFloat
    let safeHeight: CGFloat
    let bodyHeight: CGFloat
    let buttonCount: Int
    let rowHeights: [CGFloat]
    let compactLayout: PTCustomerAlertCompactActionLayout
    let sectionInsets: UIEdgeInsets
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat
    let titleHorizontalInsets: CGFloat
    let contentSizeCategory: UIContentSizeCategory
    let reduceTransparency: Bool
}

enum PTCustomerAlertMeasurement {

    static func compactActionLayout(
        buttons: [String],
        width: CGFloat,
        sectionInsets: UIEdgeInsets,
        horizontalSpacing: CGFloat,
        titleHorizontalInsets: CGFloat,
        font: UIFont,
        isAccessibilityCategory: Bool
    ) -> PTCustomerAlertCompactActionLayout {
        guard buttons.count == 2, !isAccessibilityCategory else {
            return buttons.count == 2 ? .vertical : .horizontal
        }

        let availableWidth = max(1, width - safeHorizontalInsets(sectionInsets))
        let spacing = safeSpacing(horizontalSpacing, fallback: 12)
        let buttonWidth = max(1, (availableWidth - spacing) / 2)
        let titleWidth = max(
            1,
            buttonWidth - safeTitleInsets(titleHorizontalInsets) * 2
        )
        let singleLineHeight = font.lineHeight * 1.35
        let titlesFit = buttons.allSatisfy { title in
            measuredTitleHeight(title, width: titleWidth, font: font) <= singleLineHeight
        }

        return titlesFit ? .horizontal : .vertical
    }

    static func buttonRowHeights(
        buttons: [String],
        width: CGFloat,
        layout: PTCustomerAlertCompactActionLayout,
        sectionInsets: UIEdgeInsets,
        horizontalSpacing: CGFloat,
        titleHorizontalInsets: CGFloat,
        minimumButtonRowHeight: CGFloat,
        font: UIFont
    ) -> [CGFloat] {
        guard !buttons.isEmpty else { return [] }

        let availableWidth = max(1, width - safeHorizontalInsets(sectionInsets))
        let titleInset = safeTitleInsets(titleHorizontalInsets)
        let titleWidth: CGFloat

        if layout == .horizontal, buttons.count == 2 {
            let spacing = safeSpacing(horizontalSpacing, fallback: 12)
            let buttonWidth = max(1, (availableWidth - spacing) / 2)
            titleWidth = max(1, buttonWidth - titleInset * 2)
        } else {
            titleWidth = max(1, availableWidth - titleInset * 2)
        }

        let minimumHeight = max(
            1,
            minimumButtonRowHeight.isFinite ? minimumButtonRowHeight : 50
        )
        return buttons.map { title in
            max(
                minimumHeight,
                ceil(measuredTitleHeight(title, width: titleWidth, font: font) + 20)
            )
        }
    }

    static func compactActionHeight(
        buttonCount: Int,
        layout: PTCustomerAlertCompactActionLayout,
        rowHeights: [CGFloat],
        sectionInsets: UIEdgeInsets,
        verticalSpacing: CGFloat
    ) -> CGFloat {
        guard buttonCount > 0 else { return 0 }

        let rows = rowHeights.prefix(buttonCount).map { max(1, $0) }
        guard !rows.isEmpty else { return 0 }

        let contentHeight: CGFloat
        switch layout {
        case .horizontal:
            contentHeight = rows.max() ?? 1
        case .vertical:
            contentHeight = rows.reduce(0, +)
                + CGFloat(max(0, rows.count - 1))
                * safeSpacing(verticalSpacing, fallback: 8)
        }

        return safeVerticalInsets(sectionInsets) + contentHeight
    }

    static func actionsContentHeight(
        rowHeights: [CGFloat],
        sectionInsets: UIEdgeInsets,
        verticalSpacing: CGFloat
    ) -> CGFloat {
        guard !rowHeights.isEmpty else { return safeVerticalInsets(sectionInsets) }

        let rows = rowHeights.map { max(1, $0) }
        let spacing = safeSpacing(verticalSpacing, fallback: 8)
        return safeVerticalInsets(sectionInsets)
            + rows.reduce(0, +)
            + CGFloat(max(0, rows.count - 1)) * spacing
    }

    private static func measuredTitleHeight(
        _ title: String,
        width: CGFloat,
        font: UIFont
    ) -> CGFloat {
        let rect = (title as NSString).boundingRect(
            with: CGSize(width: max(1, width), height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        guard rect.height.isFinite, rect.height > 0 else {
            return max(1, font.lineHeight)
        }
        return ceil(rect.height)
    }

    private static func safeHorizontalInsets(_ insets: UIEdgeInsets) -> CGFloat {
        let left = insets.left.isFinite ? max(0, insets.left) : 0
        let right = insets.right.isFinite ? max(0, insets.right) : 0
        return left + right
    }

    private static func safeVerticalInsets(_ insets: UIEdgeInsets) -> CGFloat {
        let top = insets.top.isFinite ? max(0, insets.top) : 0
        let bottom = insets.bottom.isFinite ? max(0, insets.bottom) : 0
        return top + bottom
    }

    private static func safeSpacing(_ value: CGFloat, fallback: CGFloat) -> CGFloat {
        guard value.isFinite else { return fallback }
        return min(48, max(0, value))
    }

    private static func safeTitleInsets(_ value: CGFloat) -> CGFloat {
        guard value.isFinite else { return 16 }
        return min(40, max(8, value))
    }
}
