//
//  PTPermissionModel.swift
//  PT
//
//  Created by jax on 2022/9/3.
//  Copyright © 2022 Respect. All rights reserved.
//

import UIKit
#if canImport(Permission)
import Permission
#endif

public class PTPermissionModel: NSObject {
    public var name:String!
    public var desc:String = ""
#if canImport(Permission)
    public var type:Permission.Kind!
#endif
}
