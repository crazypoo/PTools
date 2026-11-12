// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct GoogleDrive: PTExternalApplication {
        
        public typealias ActionType = Applications.GoogleDrive.Action
        
        public let scheme = "googledrive:"
        public let fallbackURL = "https://www.google.com/drive/"
        public let appStoreId = "507874739"
        
        public init() {}
    }
}


public extension Applications.GoogleDrive {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.GoogleDrive.Action: PTExternalApplicationAction {
    
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
