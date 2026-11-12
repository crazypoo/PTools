// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct Chromecast: PTExternalApplication {
        
        public typealias ActionType = Applications.Chromecast.Action
        
        public let scheme = "chromecast:"
        public let fallbackURL = "https://www.google.com/intl/en_us/chromecast/"
        public let appStoreId = "680819774"
        
        public init() {}
    }
}


public extension Applications.Chromecast {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.Chromecast.Action: PTExternalApplicationAction {
    
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
