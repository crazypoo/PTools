//
//  Collection+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/4/6.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation

public extension Collection {
    subscript(safe index: Self.Index) -> Iterator.Element? {
        (startIndex..<endIndex).contains(index) ? self[index] : nil
    }
}
