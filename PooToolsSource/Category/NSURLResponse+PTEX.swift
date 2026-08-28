//
//  NSURLRepose+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 3/12/22.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import Foundation

extension URLResponse {
    //MARK: 獲取Http的版本
    ///獲取Http的版本
    func getHTTPVersion() -> String? {
        // Foundation 没有公开 HTTP 版本字段；私有 KVC/dlsym 实现既不稳定也可能触发崩溃。
        // Foundation no expone la versión HTTP; se evita KVC/dlsym privado para mantener seguridad y estabilidad.
        // Foundation does not expose the HTTP version; private KVC/dlsym is avoided for safety and stability.
        guard self is HTTPURLResponse else { return nil }
        return "HTTP/1.1"
    }
}
