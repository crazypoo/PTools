//
//  BinaryFloatingPoint+InspectorEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

private let binaryFloatingPointFormatter = NumberFormatter().then {
    $0.maximumFractionDigits = 2
    $0.numberStyle = .decimal
}

extension BinaryFloatingPoint {
    func toString(prepending: String? = nil, appending: String? = nil, separator: String = "") -> String {
        guard let formattedNumber = binaryFloatingPointFormatter.string(from: CGFloat(self)) else {
            return String()
        }

        return formattedNumber.string(prepending: prepending, appending: appending, separator: separator)
    }
}
