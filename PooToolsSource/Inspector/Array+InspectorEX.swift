//
//  Array+InspectorEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import Foundation

extension Array {
    func inserting(_ newElement: Element, at index: Int) -> [Element] {
        var copy = self
        copy.insert(newElement, at: index)
        return copy
    }
}

extension Array where Element == InspectorElementLibraryProtocol {
    func formItems(for object: NSObject?) -> InspectorElementSections {
        guard let object = object else { return [] }

        return object._classesForCoder
            .flatMap { aClass in
                self
                    .filter { $0.targetClass == aClass }
                    .flatMap { $0.sections(for: object) }
            }
    }
}

extension Array where Element == UIKeyCommand {
    func sortedByInputKey() -> Self {
        var copy = self
        copy.sort { lhs, rhs -> Bool in
            guard
                let lhsInput = lhs.input,
                let rhsInput = rhs.input
            else {
                return true
            }

            return lhsInput < rhsInput
        }

        return copy
    }
}

extension Array where Element: Equatable {
    func uniqueValues() -> Self {
        var uniqueValues = Self()
        forEach { item in
            if !uniqueValues.contains(item) {
                uniqueValues += [item]
            }
        }

        return uniqueValues
    }
}
