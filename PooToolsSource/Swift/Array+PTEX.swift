//
//  Array+PTEX.swift
//  PooTools_Example
//
//  Created by Macmini on 2022/6/14.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

//MARK: 数据根据字段归组
/*
 var appCityModels = [MTCityModelsReset]()
 models.group(by: { $0?.firstLetter}).sorted(by: {($0.key)! < ($1.key)! }).enumerated().forEach { (index,value) in
     let cityNewModel = MTCityModelsReset()
     cityNewModel.key = value.key
     cityNewModel.models = (value.value as! [MTCitysModel])
     appCityModels.append(cityNewModel)
 }
 */
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

public extension Array
{
    // 去重
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
    
    /*排序,例子
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
}

