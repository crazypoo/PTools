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
    // 默认值让 Interface Builder 和逐字段配置都不会读取到未初始化的隐式可选值。
    // Los valores predeterminados evitan opcionales implícitos sin inicializar al configurar campo por campo.
    // Defaults prevent uninitialized implicitly unwrapped optionals during field-by-field configuration.
    public var name: String = ""
    public var desc:String = ""
    public var type: PTPermission.Kind = .camera
}
