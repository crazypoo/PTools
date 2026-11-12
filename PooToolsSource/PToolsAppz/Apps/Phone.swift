// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct Phone: PTExternalApplication {
        
        public typealias ActionType = Applications.Phone.Action
        
        public let scheme = "tel:"
        public let fallbackURL = ""
        public let appStoreId = ""
        
        public init() {}
    }
}


public extension Applications.Phone {
    
    enum Action: Sendable {
        case open(number: String)
    }
}

extension Applications.Phone.Action: PTExternalApplicationAction {
    
    public var paths: PTApplicationActionPaths {
        
        switch self {
        case .open(let number):
            return PTApplicationActionPaths(
                app: PTApplicationPath(
                    pathComponents: [number],
                    queryParameters: [:]
                ),
                web: PTApplicationPath()
            )
        }
    }
}
