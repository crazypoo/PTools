//
//  PTPermissionModel.swift
//  PT
//
//  Created by jax on 2022/9/3.
//  Copyright © 2022 Respect. All rights reserved.
//

import UIKit

@MainActor
@objcMembers
public class PTPermissionModel: NSObject {
    public var name:String!
    public var desc:String = ""
    public var type:PTPermission.Kind!
}
