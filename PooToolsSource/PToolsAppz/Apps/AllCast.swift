// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct AllCast: PTExternalApplication {
        
        public typealias ActionType = Applications.AllCast.Action
        
        public let scheme = "allCast:"
        public let fallbackURL = "http://www.allcast.io"
        public let appStoreId = "943763227"
        
        public init() {}
    }
}


public extension Applications.AllCast {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.AllCast.Action: PTExternalApplicationAction {
    
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
