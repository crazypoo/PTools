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
    typealias SwiftCallBack = ((T?) -> ())
    
    ///Define the calculated properties of the closure type
    var swiftCallBack: SwiftCallBack?  { get set }
}
