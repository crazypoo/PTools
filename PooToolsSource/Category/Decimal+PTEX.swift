//
//  Decimal+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 4/13/25.
//  Copyright © 2025 crazypoo. All rights reserved.
//

import UIKit

public extension Decimal {
    static func bankPrice(price:Decimal) -> Decimal {
        var newPrice = price
        var roundedTotalDiscountAmount = Decimal()
        NSDecimalRound(&roundedTotalDiscountAmount, &newPrice, 2, .bankers)
        return roundedTotalDiscountAmount
    }
    
    static func bankPriceFor3(price:Decimal) -> Decimal {
        let handler = NSDecimalNumberHandler(
            roundingMode: .up,           // 無條件進位
            scale: 2,                    // 保留兩位小數
            raiseOnExactness: false,
            raiseOnOverflow: false,
            raiseOnUnderflow: false,
            raiseOnDivideByZero: false
        )

        let decimalNumber = NSDecimalNumber(decimal: price)
        let rounded = decimalNumber.rounding(accordingToBehavior: handler)

        return rounded.decimalValue
    }
}
