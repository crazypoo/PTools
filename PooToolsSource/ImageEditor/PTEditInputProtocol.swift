//
//  PTEditInputProtocol.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 14/7/2026.
//  Copyright © 2026 crazypoo. All rights reserved.
//

import UIKit

/// 文本输入控制器的协议规范，任何遵守此协议的 UIViewController 都可以被注入到贴纸引擎中
@MainActor
public protocol PTTextEditorConfigurable: UIViewController {
    /// 结束输入时的回调
    var endInput: ((String, UIColor, UIFont, UIImage?, PTInputTextStyle) -> Void)? { get set }
    
    /// 规定的标准初始化方法
    init(image: UIImage?, text: String?, textColor: UIColor?, font: UIFont?, style: PTInputTextStyle)
}
