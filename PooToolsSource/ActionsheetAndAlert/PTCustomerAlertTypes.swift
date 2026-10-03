//
//  PTCustomerAlertTypes.swift
//  PooTools
//
//  English: Keep public alert compatibility types independent from controller layout code.
//  Español: Mantiene los tipos públicos compatibles del alert separados del diseño del controlador.
//  中文：将公开 Alert 兼容类型从控制器布局代码中独立出来。
//

import UIKit

public typealias PTCustomerCustomerBlock = (_ alertCustomerView: UIView) -> Void

@objc public enum PTAlertAnimationType: Int {
    case Top
    case Bottom
    case Left
    case Right
    case Normal
}

@objcMembers
public class PTCustomBottomButtonModel: NSObject {
    public var titleName: String? = ""
    public var titleColor: UIColor? = .systemBlue
}
