// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct GoogleSlides: PTExternalApplication {
        
        public typealias ActionType = Applications.GoogleSlides.Action
        
        public let scheme = "googleslides:"
        public let fallbackURL = "http://www.google.com/slides/about/"
        public let appStoreId = "879478102"
        
        public init() {}
    }
}


public extension Applications.GoogleSlides {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.GoogleSlides.Action: PTExternalApplicationAction {
    
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
