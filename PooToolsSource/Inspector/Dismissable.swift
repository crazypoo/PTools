//
//  Dismissable.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation

public protocol Dismissable: AnyObject {
    var dismissHandler: ((Self) -> Void)? { get set }
}
