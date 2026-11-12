// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct Weibo: PTExternalApplication {
        
        public typealias ActionType = Applications.Weibo.Action
        
        public let scheme = "weibo:"
        public let fallbackURL = "http://weibo.com/login.php"
        public let appStoreId = "350962117"
        
        public init() {}
    }
}


public extension Applications.Weibo {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.Weibo.Action: PTExternalApplicationAction {
    
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
