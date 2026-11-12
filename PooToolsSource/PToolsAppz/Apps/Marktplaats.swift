// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct Marktplaats: PTExternalApplication {
        
        public typealias ActionType = Applications.Marktplaats.Action
        
        public let scheme = "marktplaats:"
        public let fallbackURL = "http://www.marktplaats.nl"
        public let appStoreId = "373963365"
        
        public init() {}
    }
}


public extension Applications.Marktplaats {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.Marktplaats.Action: PTExternalApplicationAction {
    
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
