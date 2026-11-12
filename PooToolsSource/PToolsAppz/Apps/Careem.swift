// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct Careem: PTExternalApplication {
        
        public typealias ActionType = Applications.Careem.Action
        
        public let scheme = "careem:"
        public let fallbackURL = "https://www.careem.com/dubai/node"
        public let appStoreId = "592978487"
        
        public init() {}
    }
}


public extension Applications.Careem {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.Careem.Action: PTExternalApplicationAction {
    
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
