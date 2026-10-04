//
//  PTApplicationDirectories.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/27.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation

enum PTApplicationDirectories {
    static var support: URL {
        // English: Diagnostics must remain usable even when the sandbox does not expose Application Support.
        // Español: Las herramientas de diagnóstico deben seguir funcionando aunque el sandbox no exponga Application Support.
        // 中文：即使沙盒无法提供 Application Support，诊断工具也必须继续可用。
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory.appendingPathComponent("PTools", isDirectory: true)
    }
}
