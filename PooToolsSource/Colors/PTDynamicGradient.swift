//
//  PTDynamicGradient.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/26.
//  Copyright © 2024 crazypoo. All rights reserved.
//

#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(OSX)
import AppKit
#endif

/**
 Object representing a gradient object. It allows you to manipulate colors inside different gradients and color spaces.
 */
// 🚀 优化 1：改为 public struct，利用值类型提升性能
public struct PTDynamicGradient {
    public let colors: [DynamicColor]

    /**
     Initializes and creates a gradient from a color array.

     - Parameter colors: An array of colors.
     */
    public init(colors: [DynamicColor]) {
        self.colors = colors
    }

    /**
     Returns the color palette of `amount` elements by grabbing equidistant colors.
     */
    public func colorPalette(@PTClampedPropertyWrapper(range: 2...UInt.max) amount: UInt = 2, inColorSpace colorspace: DynamicColorSpace = .rgb) -> [DynamicColor] {
        // 🚀 优化 2：移除 amount > 0 的冗余判断，因为包装器保证了最小为 2
        guard !colors.isEmpty else { return [] }
        guard colors.count > 1 else {
            return (0 ..< amount).map { _ in colors[0] }
        }

        let increment = 1.0 / CGFloat(amount - 1)
        return (0 ..< amount).map { pickColorAt(scale: CGFloat($0) * increment, inColorSpace: colorspace) }
    }

    /**
     Picks up and returns the color at the given scale by interpolating the colors.
     */
    public func pickColorAt(@PTClampedPropertyWrapper(range: 0...1) scale: CGFloat, inColorSpace colorspace: DynamicColorSpace = .rgb) -> DynamicColor {
        guard colors.count > 1 else {
            return colors.first ?? .black
        }

        // 极限值直接返回，提升速度
        if scale <= 0.0 { return colors.first! }
        if scale >= 1.0 { return colors.last! }

        // 🚀 优化 3：O(1) 纯数学映射，彻底取代原来的 map 创建数组 + for 循环
        // 1. 计算总的分段数
        let segmentCount = CGFloat(colors.count - 1)
        
        // 2. 将 0...1 的比例映射到 0...segmentCount 之间
        let scaledIndex = scale * segmentCount
        
        // 3. 取整得到左边颜色的 index
        let leftIndex = Int(scaledIndex)
        
        // 安全保护：防止浮点数精度导致的越界
        guard leftIndex < colors.count - 1 else {
            return colors.last!
        }
        
        let rightIndex = leftIndex + 1
        
        // 4. 小数部分就是混合的权重 (weight)
        let weight = scaledIndex - CGFloat(leftIndex)

        // 5. 直接调用之前优化好的 mixed 方法
        return colors[leftIndex].mixed(withColor: colors[rightIndex], weight: weight, inColorSpace: colorspace)
    }
}
