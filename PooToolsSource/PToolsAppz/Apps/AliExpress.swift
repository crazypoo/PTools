// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct AliExpress: PTExternalApplication {
        
        public typealias ActionType = Applications.AliExpress.Action
        
        public let scheme = "aliexpress:"
        public let fallbackURL = "http://www.aliexpress.com"
        public let appStoreId = "436672029"
        
        public init() {}
    }
}


public extension Applications.AliExpress {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.AliExpress.Action: PTExternalApplicationAction {
    
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
