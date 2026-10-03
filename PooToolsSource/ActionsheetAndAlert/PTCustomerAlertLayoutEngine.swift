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
    let rowHeight: CGFloat
    let compactLayout: PTCustomerAlertCompactActionLayout
}

enum PTCustomerAlertMeasurement {
    static func compactActionLayout(
        buttons: [String],
        width: CGFloat,
        separatorThickness: CGFloat,
        font: UIFont,
        isAccessibilityCategory: Bool
    ) -> PTCustomerAlertCompactActionLayout {
        guard buttons.count == 2 else { return .horizontal }
        guard !isAccessibilityCategory else { return .vertical }

        let buttonWidth = max(1, (width - separatorThickness) / 2)
        let availableTitleWidth = max(1, buttonWidth - 24)
        let titlesFit = buttons.allSatisfy { title in
            (title as NSString).size(withAttributes: [.font: font]).width <= availableTitleWidth
        }
        return titlesFit ? .horizontal : .vertical
    }

    static func buttonRowHeight(
        buttons: [String],
        width: CGFloat,
        layout: PTCustomerAlertCompactActionLayout,
        separatorThickness: CGFloat,
        minimumButtonRowHeight: CGFloat,
        font: UIFont
    ) -> CGFloat {
        let buttonWidth = layout == .horizontal && buttons.count == 2
            ? max(1, (width - separatorThickness) / 2)
            : max(1, width)
        let availableTitleWidth = max(1, buttonWidth - 24)
        let maximumTitleHeight = buttons.map { title in
            (title as NSString).boundingRect(
                with: CGSize(width: availableTitleWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [.font: font],
                context: nil
            ).height
        }.max() ?? font.lineHeight

        guard maximumTitleHeight.isFinite else { return minimumButtonRowHeight }
        return max(minimumButtonRowHeight, ceil(maximumTitleHeight + 20))
    }

    static func compactActionHeight(
        buttonCount: Int,
        layout: PTCustomerAlertCompactActionLayout,
        rowHeight: CGFloat,
        separatorThickness: CGFloat
    ) -> CGFloat {
        guard buttonCount > 0 else { return 0 }
        switch layout {
        case .horizontal:
            return separatorThickness + rowHeight
        case .vertical:
            let rowsHeight = CGFloat(buttonCount) * rowHeight
            let separatorsHeight = CGFloat(max(0, buttonCount - 1)) * separatorThickness
            return separatorThickness + rowsHeight + separatorsHeight
        }
    }

    static func actionsContentHeight(
        buttonCount: Int,
        rowHeight: CGFloat,
        separatorThickness: CGFloat
    ) -> CGFloat {
        CGFloat(buttonCount) * rowHeight + CGFloat(max(0, buttonCount - 1)) * separatorThickness
    }
}
