//
//  Startable.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation
import UIKit

@available(*, renamed: "Startable")
public typealias StartProtocol = Startable

public protocol Startable {
    associatedtype StartResult

    func start() -> StartResult
}
