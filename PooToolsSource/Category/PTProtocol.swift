//
//  PTProtocol.swift
//  PooTools_Example
//
//  Created by Macmini on 2022/6/15.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import Foundation

public struct PTProtocol<Base> {
    let base: Base
    init(_ base: Base) {
        self.base = base
    }
}

public protocol PTProtocolCompatible {}

public extension PTProtocolCompatible {
    
    static var pt: PTProtocol<Self>.Type {
        get{ PTProtocol<Self>.self }
        set {}
    }
    
    var pt: PTProtocol<Self> {
        get { PTProtocol(self) }
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
