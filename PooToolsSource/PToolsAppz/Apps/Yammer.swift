// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct Yammer: PTExternalApplication {
        
        public typealias ActionType = Applications.Yammer.Action
        
        public let scheme = "yammer:"
        public let fallbackURL = "https://products.office.com/en-us/yammer/yammer-mobile-app"
        public let appStoreId = "289559439"
        
        public init() {}
    }
}


public extension Applications.Yammer {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.Yammer.Action: PTExternalApplicationAction {
    
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
