//
//  IndexPath+InspectorEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation

extension IndexPath {
    
    enum InvalidReason: Error {
        case sectionBelowBounds, sectionAboveBounds, rowBelowBounds, rowAboveBounds
    }
    
    static var first = IndexPath(row: .zero, section: .zero)
    var isFirst: Bool { self == .first }
    var isEvenRow: Bool { row % 2 == 0 }

    func previousRow() -> IndexPath {
        IndexPath(row: row - 1, section: section)
    }
    
    func nextRow() -> IndexPath {
        IndexPath(row: row + 1, section: section)
    }
    
    func nextSection() -> IndexPath {
        IndexPath(row: .zero, section: section + 1)
    }
}
