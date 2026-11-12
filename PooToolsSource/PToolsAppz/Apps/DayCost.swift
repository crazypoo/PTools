// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct DayCost: PTExternalApplication {
        
        public typealias ActionType = Applications.DayCost.Action
        
        public let scheme = "DayCost:"
        public let fallbackURL = "https://www.facebook.com/iDaycost/"
        public let appStoreId = "979953415"
        
        public init() {}
    }
}


public extension Applications.DayCost {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.DayCost.Action: PTExternalApplicationAction {
    
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
