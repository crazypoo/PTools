// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct Meerkat: PTExternalApplication {
        
        public typealias ActionType = Applications.Meerkat.Action
        
        public let scheme = "meerkat:"
        public let fallbackURL = "http://meerkatapp.co"
        public let appStoreId = "954105918"
        
        public init() {}
    }
}


public extension Applications.Meerkat {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.Meerkat.Action: PTExternalApplicationAction {
    
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
