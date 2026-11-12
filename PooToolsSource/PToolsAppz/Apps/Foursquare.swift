// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct Foursquare: PTExternalApplication {
        
        public typealias ActionType = Applications.Foursquare.Action
        
        public let scheme = "foursquare:"
        public let fallbackURL = "https://foursquare.com/download"
        public let appStoreId = "306934924"
        
        public init() {}
    }
}


public extension Applications.Foursquare {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.Foursquare.Action: PTExternalApplicationAction {
    
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
