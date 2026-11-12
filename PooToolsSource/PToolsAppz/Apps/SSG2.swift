// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct SSG2: PTExternalApplication {
        
        public typealias ActionType = Applications.SSG2.Action
        
        public let scheme = "SSG2:"
        public let fallbackURL = "http://www.noodlecake.com/games/super-stickman-golf-2/"
        public let appStoreId = "585259203"
        
        public init() {}
    }
}


public extension Applications.SSG2 {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.SSG2.Action: PTExternalApplicationAction {
    
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
