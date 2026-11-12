// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct HootSuite: PTExternalApplication {
        
        public typealias ActionType = Applications.HootSuite.Action
        
        public let scheme = "hootsuite:"
        public let fallbackURL = "https://hootsuite.com/products/mobile-apps/hootsuite-mobile-app"
        public let appStoreId = "341249709"
        
        public init() {}
    }
}


public extension Applications.HootSuite {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.HootSuite.Action: PTExternalApplicationAction {
    
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
