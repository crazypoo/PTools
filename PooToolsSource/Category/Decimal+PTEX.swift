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
}
