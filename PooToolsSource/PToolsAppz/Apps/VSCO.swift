// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct VSCO: PTExternalApplication {
        
        public typealias ActionType = Applications.VSCO.Action
        
        public let scheme = "vsco:"
        public let fallbackURL = "http://vsco.co/store/app"
        public let appStoreId = "588013838"
        
        public init() {}
    }
}


public extension Applications.VSCO {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.VSCO.Action: PTExternalApplicationAction {
    
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
