//
//  Character+PTEX.swift
//  PooTools_Example
//
//  Created by Macmini on 2022/6/14.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

extension Character: PTProtocolCompatible {}

public extension Character {
    //MARK: 简单的emoji是一个标量，以emoji的形式呈现给用户
    ///简单的emoji是一个标量，以emoji的形式呈现给用户
    var isSimpleEmoji: Bool {
        guard let firstProperties = unicodeScalars.first?.properties else {
            return false
        }
        return unicodeScalars.count == 1 &&
        (firstProperties.isEmojiPresentation ||
         firstProperties.generalCategory == .otherSymbol)
    }

    //MARK: 检查标量是否将合并到emoji中
    /// 检查标量是否将合并到emoji中
    var isCombinedIntoEmoji: Bool {
        return unicodeScalars.count > 1 &&
            unicodeScalars.contains { $0.properties.isJoinControl || $0.properties.isVariationSelector }
    }

    //MARK: 是否为emoji表情
    /// 是否为emoji表情
    /// - Note: http://stackoverflow.com/questions/30757193/find-out-if-character-in-string-is-emoji
    var isEmoji: Bool {
        return isSimpleEmoji || isCombinedIntoEmoji
    }
}

//MARK: Character 与其他类型的转换
public extension PTPOP where Base == Character {

    //MARK: Character转String
    ///Character转String
    var charToString: String { return String(self.base) }

    //MARK: Character转Int
    ///Character转Int
    var charToInt: Int? {
        return Int(String(self.base))
    }
}

