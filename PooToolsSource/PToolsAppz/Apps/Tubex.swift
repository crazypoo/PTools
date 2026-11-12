// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct Tubex: PTExternalApplication {
        
        public typealias ActionType = Applications.Tubex.Action
        
        public let scheme = "tubex:"
        public let fallbackURL = "https://www.facebook.com/Tubex-744986562245828/"
        public let appStoreId = "939906112"
        
        public init() {}
    }
}


public extension Applications.Tubex {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.Tubex.Action: PTExternalApplicationAction {
    
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
