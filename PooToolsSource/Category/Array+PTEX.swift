//
//  Array+PTEX.swift
//  PooTools_Example
//
//  Created by Macmini on 2022/6/14.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import Foundation

/*
 示例：分组排序后，请使用条件转换，避免异常数据造成崩溃。
 Example: use conditional casts after grouping and sorting to avoid crashes from invalid data.
 Ejemplo: usa conversiones condicionales después de agrupar y ordenar para evitar fallos por datos inválidos.
 */
//MARK: 数据根据字段归组
///数据根据字段归组
public extension Sequence {
    /// English: Removes duplicates while preserving the first occurrence order.
    /// Español: Elimina duplicados conservando el orden de la primera aparición.
    /// 中文：移除重复元素并保留第一次出现的顺序。
    func removingDuplicates<Key: Hashable>(by key: (Element) throws -> Key) rethrows -> [Element] {
        var seen = Set<Key>()
        var result: [Element] = []
        for element in self {
            let identifier = try key(element)
            if seen.insert(identifier).inserted {
                result.append(element)
            }
        }
        return result
    }

    /// English: Returns the only matching element, or nil when there are zero or multiple matches.
    /// Español: Devuelve el único elemento coincidente o nil si hay cero o varios.
    /// 中文：仅在恰好匹配一个元素时返回，否则返回 nil。
    func single(where predicate: (Element) throws -> Bool) rethrows -> Element? {
        var hasMatch = false
        var match: Element?
        for element in self {
            guard try predicate(element) else { continue }
            guard !hasMatch else { return nil }
            hasMatch = true
            match = element
        }
        return match
    }

    /// English: Splits the sequence into matching and non-matching elements without changing order.
    /// Español: Divide la secuencia en elementos coincidentes y no coincidentes sin cambiar el orden.
    /// 中文：按条件拆分序列，保持原有顺序。
    func divided(by predicate: (Element) throws -> Bool) rethrows -> (matching: [Element], nonMatching: [Element]) {
        var matching: [Element] = []
        var nonMatching: [Element] = []
        for element in self {
            if try predicate(element) {
                matching.append(element)
            } else {
                nonMatching.append(element)
            }
        }
        return (matching, nonMatching)
    }

    /// English: Sums transformed values using the value type's additive identity.
    /// Español: Suma los valores transformados usando el elemento neutro aditivo del tipo.
    /// 中文：使用值类型的加法单位元，对转换后的值求和。
    func sum<Value: AdditiveArithmetic>(for transform: (Element) throws -> Value) rethrows -> Value {
        var result = Value.zero
        for element in self {
            result += try transform(element)
        }
        return result
    }

    func group<U: Hashable>(by key: (Iterator.Element) -> U) -> [U:[Iterator.Element]] {
        var categories: [U: [Iterator.Element]] = [:]
        for element in self {
            let key = key(element)
            if case nil = categories[key]?.append(element) {
                categories[key] = [element]
            }
        }
        return categories
    }
}

public extension Array {
    //MARK: 數組去重
    ///數組去重
    func filterDuplicates<E: Equatable>(_ filter: (Element) -> E) -> [Element] {
        handleFilter(filter)
    }
    
    //MARK: 數組冒泡排序
    ///數組冒泡排序
    func bubbleSort(_ filterCall: (Element) -> Int) -> [Element] {
        guard count > 1 else { return self }
        var temp: [Element] = self
        for i in 0..<(count - 1) {
            for j in (i + 1..<count).reversed() {
                // rs 必须写到内循环里边
                let rs = filterCall(temp[i])
                let js = filterCall(temp[j])
                if rs > js {
                    let t = temp[i]
                    temp[i] = temp[j]
                    temp[j] = t
                }
            }
        }
        return temp
    }
    
/*
     示例：排序时请使用条件转换和 compactMap，避免输入数据异常导致崩溃。
     Example: use conditional casts and compactMap while sorting to avoid crashes from invalid input.
     Ejemplo: usa conversiones condicionales y compactMap al ordenar para evitar fallos por datos inválidos.
*/
    func sorted_oc(by :(Any, Any) -> Bool) -> [Any] {
        guard count > 1 else {
            return self
        }
        
        var arr = self
        //Bubble Sort
        for i in 0..<count-1 {
            for j in 0..<count-1-i {
                let correct = by(arr[j], arr[j+1])
                if !correct {
                    (arr[j], arr[j+1]) = (arr[j+1], arr[j])
                } else {
                    continue
                }
            }
        }
        return arr
    }

    func handleFilter<E: Equatable>(_ filterCall: (Element) -> E) -> [Element] {
        var temp = [Element]()
        for model in self {
            //调用filterCall，获得需要用来判断的属性E
            let identifer = filterCall(model)
            //此处利用map函数 来将model类型数组转换成E类型的数组，以此来判断
            if !temp.contains(where: { filterCall($0) == identifer }) {
                temp.append(model)
            }
        }
        return temp
    }
    
    //MARK: 數組轉字典
    ///數組轉字典
    func toJSON(prettyPrinted:Bool = false) -> String? {
        guard JSONSerialization.isValidJSONObject(self) else {
            PTNSLogConsole("无法解析出JSONString", levelType: .error, loggerType: .array)
            return nil
        }
        do {
            let options: JSONSerialization.WritingOptions = prettyPrinted ? [.prettyPrinted] : []
            let data = try JSONSerialization.data(withJSONObject: self, options: options)
            return String(data: data, encoding: .utf8)
        } catch {
            PTNSLogConsole("JSON 序列化失败: \(error)", levelType: .error, loggerType: .array)
            return nil
        }
    }
    
    /**
        把某个数据插入到某位置
     */
    func rearrange(fromIndex: Int, toIndex: Int) -> [Element] {
        guard indices.contains(fromIndex), toIndex >= 0, toIndex <= count else {
            return self
        }
        var array = self
        let element = array.remove(at: fromIndex)
        array.insert(element, at: Swift.min(toIndex, array.count))
        return array
    }
    
    /**
        数组分组 Example:
     ```
     let array = [1,2,3,4,5,6,7]
     array.chuncked(by: 3) // [[1,2,3], [4,5,6], [7]]
     ```
     - parameter chunkSize: 分多少组
     */
    func chunked(by chunkSize: Int) -> [[Element]] {
        guard chunkSize > 0 else { return [] }
        return stride(from: 0, to: self.count, by: chunkSize).map {
            Array(self[$0..<Swift.min($0 + chunkSize, self.count)])
        }
    }
    
    /// English: Swaps two valid indices and ignores invalid input instead of trapping.
    /// Español: Intercambia dos índices válidos e ignora entradas no válidas sin provocar un fallo.
    /// 中文：交换两个有效下标；遇到无效下标时安全忽略，避免崩溃。
    mutating func safeSwap(from firstIndex: Index, to secondIndex: Index) {
        guard indices.contains(firstIndex), indices.contains(secondIndex) else { return }
        swapAt(firstIndex, secondIndex)
    }

    /// English: Sorts by a derived comparable value.
    /// Español: Ordena usando un valor comparable derivado。
    /// 中文：按照转换得到的可比较值排序。
    func sorted<Key: Comparable>(matching key: (Element) throws -> Key) rethrows -> [Element] {
        try sorted(matching: key, by: <)
    }

    /// English: Sorts by a derived value and caller-provided ordering.
    /// Español: Ordena por un valor derivado y una regla de orden proporcionada por el llamador.
    /// 中文：按照转换值和调用方提供的比较规则排序。
    func sorted<Key>(matching key: (Element) throws -> Key,
                     by areInIncreasingOrder: (Key, Key) throws -> Bool) rethrows -> [Element] {
        var decorated: [(element: Element, key: Key)] = []
        decorated.reserveCapacity(count)
        for element in self {
            decorated.append((element, try key(element)))
        }

        // English: Stable insertion sort keeps the throwing comparator outside Swift's non-throwing sort closure.
        // Español: La ordenación por inserción estable mantiene el comparador que puede lanzar errores fuera del cierre no lanzable de Swift.
        // 中文：使用稳定插入排序，使可抛出比较器不必进入 Swift 的非抛出排序闭包。
        var result: [(element: Element, key: Key)] = []
        result.reserveCapacity(decorated.count)
        for item in decorated {
            var insertionIndex = result.endIndex
            for index in result.indices {
                if try areInIncreasingOrder(item.key, result[index].key) {
                    insertionIndex = index
                    break
                }
            }
            result.insert(item, at: insertionIndex)
        }
        return result.map(\.element)
    }
    
    /// 获取数组中的元素,增加了数组越界的判断
    func safeIndex(_ i:Int) -> Array.Iterator.Element? {
        guard indices.contains(i) else { return nil }
        return self[i]
    }
    
    /// 从前面取 N 个数组元素
    func limit(_ limitCount: Int) -> [Array.Iterator.Element] {
        let maxCount = self.count
        var resultCount: Int = limitCount
        if maxCount < limitCount {
            resultCount = maxCount
        }
        if resultCount <= 0 {
            return []
        }
        return self[0..<resultCount].map { $0 }
    }
    
    /// 从前面取 N 个数组元素
    func fill(_ fillCount: Int) -> [Array.Iterator.Element] {
        var items = self
        while items.count > 0 && items.count < fillCount {
            items = (items + items).limit(fillCount)
        }
        return items.limit(fillCount)
    }
    
    /// 随机取出几个元素
    subscript (randomPick n: Int) -> [Element] {
        guard n <= self.count else { return self }
        var copy = self
        for i in stride(from: count - 1, to: count - n - 1, by: -1) {
            copy.swapAt(i, Int(arc4random_uniform(UInt32(i + 1))))
        }
        return Array(copy.suffix(n))
    }
}

/// English: In-place hashable deduplication preserving the first occurrence order.
/// Español: Elimina duplicados in situ para elementos hashables conservando el primer orden.
/// 中文：对可哈希元素原地去重，并保留第一次出现的顺序。
public extension Array where Element: Hashable {
    mutating func removeDuplicates() {
        self = removingDuplicates(by: { $0 })
    }
}

//MARK: 遵守NSObjectProtocol协议对应数组的扩展方法
public extension Array where Element : NSObjectProtocol {
    //MARK: 删除数组中遵守NSObjectProtocol协议的元素，是否删除重复的元素
    ///删除数组中遵守NSObjectProtocol协议的元素
    /// - Parameters:
    ///   - object: 元素
    ///   - isRepeat: 是否删除重复的元素
    @discardableResult
    mutating func remove(object: NSObjectProtocol,
                         isRepeat: Bool = true) -> Array {
        var removeIndexs: [Int] = []
        for i in 0..<count {
            if self[i].isEqual(object) {
                removeIndexs.append(i)
                if !isRepeat {
                    break
                }
            }
        }
        for index in removeIndexs.reversed() {
            self.remove(at: index)
        }
        return self
    }
    
    //MARK: 删除一个遵守NSObjectProtocol的数组中的元素，支持重复删除
    ///删除一个遵守NSObjectProtocol的数组中的元素，支持重复删除
    /// - Parameters:
    ///   - objects: 遵守NSObjectProtocol的数组
    ///   - isRepeat: 是否删除重复的元素
    @discardableResult
    mutating func removeArray(objects: [NSObjectProtocol], 
                              isRepeat: Bool = true) -> Array {
        for object in objects {
            if contains(where: {$0.isEqual(object)} ) {
                self.remove(object: object, isRepeat: isRepeat)
            }
        }
        return self
    }
}

//MARK: 针对数组元素是 String 的扩展
public extension Array where Self.Element == String {
    
    //MARK: 数组字符串转字符转
    ///数组字符串转字符转
    /// - Parameters:
    ///    - separator: 分隔符(默认没有)
    /// - Returns: 转化后的字符串
    func toStrinig(separator: String = "") -> String {
        joined(separator: separator)
    }
}

public extension Array where Element : Equatable {
        
    //MARK: 获取两个数组的相同元素
    /// 获取两个元素的相同元素
    /// - Parameter array: 数组元素
    /// - Returns: 返回相同的元素
    func sameElement(array: [Element]) -> [Element] {
        return array.filter { contains($0) }
    }
}
