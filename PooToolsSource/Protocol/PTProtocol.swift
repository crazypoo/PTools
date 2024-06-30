//
//  PTProtocol.swift
//  PooTools_Example
//
//  Created by Macmini on 2022/6/15.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import Foundation

public struct PTPOP<Base> {
    let base: Base
    init(_ base: Base) {
        self.base = base
    }
}

public protocol PTProtocolCompatible {}

public extension PTProtocolCompatible {
    
    static var pt: PTPOP<Self>.Type {
        get{ PTPOP<Self>.self }
        set {}
    }
    
    var pt: PTPOP<Self> {
        get { PTPOP(self) }
        set {}
    }
}

/// Define Property protocol
internal protocol PTSwiftPropertyCompatible {
  
    /// Extended type
    associatedtype T
    
    ///Alias for callback function
    typealias SwiftCallBack = (T?) -> ()
    
    ///Define the calculated properties of the closure type
    var swiftCallBack: SwiftCallBack?  { get set }
}

public struct PTNumberValueAdapter {
    public static var share = PTNumberValueAdapter()
        
    /// 记录适配比例
    fileprivate var adapterScale: Double?
}

public protocol PTNumberValueAdapterable {
    associatedtype PTNumberValueAdapterType
    var adapter: PTNumberValueAdapterType { get }
}

extension PTNumberValueAdapterable {
    func adapterScale() -> Double {
        if let scale = PTNumberValueAdapter.share.adapterScale {
            return scale
        } else {
            let isPad = UIDevice.current.userInterfaceIdiom == .pad
            var adjustedScale:Double = 1
            // 如果是 iPad 设备，进一步调整字体大小
            if isPad {
                adjustedScale = 1.5 // iPad 上的字体适当放大
            } else {
                // 根据屏幕宽度调整字体大小
                switch CGFloat.kSCREEN_WIDTH {
                case 0...320:
                    adjustedScale = 0.85 // 适用于较小屏幕
                case 321...375:
                    adjustedScale = 1 // 适用于中等屏幕
                case 376...414:
                    adjustedScale = 1.15 // 适用于较大屏幕
                case 415...:
                    adjustedScale = 1.3 // 适用于最大屏幕
                default:
                    adjustedScale = 1
                }
            }
            return adjustedScale
        }
    }
}
