// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct CNN: PTExternalApplication {
        
        public typealias ActionType = Applications.CNN.Action
        
        public let scheme = "cnn:"
        public let fallbackURL = "http://edition.cnn.com/specials/mobile-apps"
        public let appStoreId = "331786748"
        
        public init() {}
    }
}


public extension Applications.CNN {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.CNN.Action: PTExternalApplicationAction {
    
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
