//
//  PTLocalConsoleFunction.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/1.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

@MainActor
public class PTLocalConsoleFunction: NSObject {
    static public let share = PTLocalConsoleFunction()
    
    @MainActor public var localconsole : LocalConsole = {
        let local = LocalConsole.shared
        return local
    }()
}
