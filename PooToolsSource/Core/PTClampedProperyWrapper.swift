//
//  PTClampedProperyWrapper.swift
//  PTChatGPT
//
//  Created by 邓杰豪 on 1/4/23.
//  Copyright © 2023 SexyBoy. All rights reserved.
//

import Foundation

//MARK: 此方法用于设定范围,且不会小于和多于相关数值
@propertyWrapper struct PTClampedProperyWrapper<T: Comparable> {
    let wrappedValue: T

    public init(wrappedValue: T, range: ClosedRange<T>) {
        self.wrappedValue = min(max(wrappedValue, range.lowerBound), range.upperBound)
    }
}
