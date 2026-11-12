// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct Views: PTExternalApplication {
        
        public typealias ActionType = Applications.Views.Action
        
        public let scheme = "views:"
        public let fallbackURL = "http://www.saikambampati.com/views"
        public let appStoreId = "1322754821"
        
        public init() {}
    }
}

public extension Applications.Views {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.Views.Action: PTExternalApplicationAction {
    
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
