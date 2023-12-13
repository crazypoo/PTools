//
//  ConverterDegree.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 11/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

enum ConverterDegree: String {
    case degree0
    case degree90
    case degree180
    case degree270

    static func convert(degree: CGFloat) -> ConverterDegree {
        if degree == 0 || degree == 360 {
            return .degree0
        } else if degree == 90 {
            return .degree90
        } else if degree == 180 {
            return .degree180
        } else if degree == 270 {
            return .degree270
        } else {
            return .degree90
        }
    }
}
