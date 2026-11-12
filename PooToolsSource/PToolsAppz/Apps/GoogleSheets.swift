// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct GoogleSheets: PTExternalApplication {
        
        public typealias ActionType = Applications.GoogleSheets.Action
        
        public let scheme = "googlesheets:"
        public let fallbackURL = "http://www.google.com/sheets/about/"
        public let appStoreId = "842849113"
        
        public init() {}
    }
}


public extension Applications.GoogleSheets {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.GoogleSheets.Action: PTExternalApplicationAction {
    
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
