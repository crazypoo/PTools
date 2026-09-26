//
//  DateFormatter+PTEX.swift
//  PooTools_Example
//
//  Created by Macmini on 2022/6/15.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

// MARK: 基本扩展
public extension DateFormatter {

    // MARK: 格式化快捷方式
    /// English: Creates a formatter with an explicit PTools date context.
    /// Español: Crea un formateador con un contexto de fecha explícito de PTools.
    /// 中文：使用 PTools 显式日期语境创建格式化器。
    /// - Parameters:
    ///   - format: 日期格式 / date pattern / patrón de fecha
    ///   - context: 日期语境 / date context / contexto de fecha
    convenience init(format: String, context: PTDateContext = .current) {
        self.init()
        calendar = context.calendar
        timeZone = context.timeZone
        locale = context.locale
        dateFormat = format
    }
}
