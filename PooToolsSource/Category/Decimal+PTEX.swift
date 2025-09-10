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
        let handler = NSDecimalNumberHandler(roundingMode: .up,           // 無條件進位
                                             scale: 2,                    // 保留兩位小數
                                             raiseOnExactness: false,
                                             raiseOnOverflow: false,
                                             raiseOnUnderflow: false,
                                             raiseOnDivideByZero: false)

        let decimalNumber = NSDecimalNumber(decimal: price)
        let rounded = decimalNumber.rounding(accordingToBehavior: handler)

        return rounded.decimalValue
    }
    
    /*
     把金額分割成小數點前和小數點後
     */
    func priceCut() -> (String,String) {
        var beforeDecimal = ""
        var afterDecimal = ".00"

        // 轉成字串（用 String(describing:) 或 NumberFormatter）
        let numberString = String(describing: self)
        // 找到小數點位置
        if let dotIndex = numberString.firstIndex(of: ".") {
            beforeDecimal = String(numberString[..<dotIndex])      // "46"
            afterDecimal = String(numberString[dotIndex...])        // ".5"
        } else {
            beforeDecimal = numberString
        }
        return (beforeDecimal,afterDecimal)
    }
}
