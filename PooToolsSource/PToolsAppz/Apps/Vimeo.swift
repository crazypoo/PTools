// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct Vimeo: PTExternalApplication {
        
        public typealias ActionType = Applications.Vimeo.Action
        
        public let scheme = "vimeo:"
        public let fallbackURL = "https://vimeo.com/everywhere"
        public let appStoreId = "425194759"
        
        public init() {}
    }
}


public extension Applications.Vimeo {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.Vimeo.Action: PTExternalApplicationAction {
    
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
