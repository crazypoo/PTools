//
//  Array+PTEX.swift
//  PooTools_Example
//
//  Created by Macmini on 2022/6/14.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import Foundation
import SwifterSwift

/*
 var appCityModels = [MTCityModelsReset]()
 models.group(by: { $0?.firstLetter}).sorted(by: {($0.key)! < ($1.key)! }).enumerated().forEach { (index,value) in
     let cityNewModel = MTCityModelsReset()
     cityNewModel.key = value.key
     cityNewModel.models = (value.value as! [MTCitysModel])
     appCityModels.append(cityNewModel)
 }
 */
//MARK: 数据根据字段归组
///数据根据字段归组
public extension Sequence {
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
        var result = [Element]()
        for value in self {
            let key = filter(value)
            if !result.map({filter($0)}).contains(key) {
                result.append(value)
            }
        }
        return result
    }
    
    //MARK: 數組冒泡排序
    ///數組冒泡排序
    func bubbleSort(_ filterCall: (Element) -> Int) -> [Element] {
        var temp: [Element] = self
        for i in 0...self.count - 1 {
            for j in (i...self.count - 1).reversed() {
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
     排序,例子
     threeLaterRows = threeLaterRows.sorted_oc { (item1, item2) -> Bool in
         let obj1 = (item1 as! PTRows).dataModel as! MNNewFriendModel
         let obj2 = (item2 as! PTRows).dataModel as! MNNewFriendModel
         return (Int(obj1.addTime!) > Int(obj2.addTime!))
     } as! [PTRows]
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
            if !temp.map( { filterCall($0) } ).contains(identifer) {
                temp.append(model)
            }
        }
        return temp
    }
    
    //MARK: 數組轉字典
    ///數組轉字典
    func toJSON()-> String {
        guard JSONSerialization.isValidJSONObject(self) else {
            PTNSLogConsole("无法解析出JSONString",levelType: .Error,loggerType: .Array)
            return ""
        }
        let data : NSData = try! JSONSerialization.data(withJSONObject: self, options: []) as NSData
        let JSONString = NSString(data:data as Data,encoding: String.Encoding.utf8.rawValue)
        return JSONString! as String
    }
    
    /**
        把某个数据插入到某位置
     */
    func rearrange(fromIndex: Int, toIndex: Int) -> [Element] {
        var array = self
        let element = array.remove(at: fromIndex)
        array.insert(element, at: toIndex)
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
        stride(from: 0, to: self.count, by: chunkSize).map {
            Array(self[$0..<Swift.min($0 + chunkSize, self.count)])
        }
    }
    
    subscript(safe index:Index) ->Element? {
        return indices.contains(index) ? self[index] : nil
    }
    
    /// 获取数组中的元素,增加了数组越界的判断
    func safeIndex(_ i:Int) -> Array.Iterator.Element? {
        guard !isEmpty && self.count > abs(i) else {
            return nil
        }
        
        for item in self.enumerated() {
            if item.offset == i {
                return item.element
            }
        }
        return nil
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
            if contains(where: {$0.isEqual(object)} ){
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
