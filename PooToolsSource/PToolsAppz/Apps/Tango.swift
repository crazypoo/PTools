// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct Tango: PTExternalApplication {
        
        public typealias ActionType = Applications.Tango.Action
        
        public let scheme = "tango:"
        public let fallbackURL = "http://www.tango.me"
        public let appStoreId = "372513032"
        
        public init() {}
    }
}


public extension Applications.Tango {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.Tango.Action: PTExternalApplicationAction {
    
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
