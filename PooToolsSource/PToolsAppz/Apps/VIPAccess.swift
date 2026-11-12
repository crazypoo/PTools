// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct VIPAccess: PTExternalApplication {
        
        public typealias ActionType = Applications.VIPAccess.Action
        
        public let scheme = "vipsymantec:"
        public let fallbackURL = "https://m.vip.symantec.com"
        public let appStoreId = "307658513"
        
        public init() {}
    }
}


public extension Applications.VIPAccess {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.VIPAccess.Action: PTExternalApplicationAction {
    
    public var paths: PTApplicationActionPaths {
        
        switch self {
        case .open:
            return PTApplicationActionPaths(
                app: PTApplicationPath(
                    pathComponents: ["app"],
                    queryParameters: [:]
                ),
                web: PTApplicationPath()
            )
        }
    }
}
