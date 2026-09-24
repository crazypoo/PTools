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
        indices.contains(index) ? self[index] : nil
    }
}

public extension RangeReplaceableCollection {
    /// English: Removes and returns the first element matching the predicate.
    /// Español: Elimina y devuelve el primer elemento que coincide con el predicado.
    /// 中文：移除并返回第一个满足条件的元素。
    @discardableResult
    mutating func removeFirst(where predicate: (Element) throws -> Bool) rethrows -> Element? {
        guard let index = try firstIndex(where: predicate) else { return nil }
        return remove(at: index)
    }
    
    /// Remove all duplicate elements using KeyPath to compare.
    ///
    /// - Parameter path: Key path to compare, the value must be Equatable.
    mutating func removeDuplicates(keyPath path: KeyPath<Element, some Equatable>) {
        var items = [Element]()
        removeAll { element -> Bool in
            guard items.contains(where: { $0[keyPath: path] == element[keyPath: path] }) else {
                items.append(element)
                return false
            }
            return true
        }
    }
}
