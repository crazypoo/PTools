// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct Documents: PTExternalApplication {
        
        public typealias ActionType = Applications.Documents.Action
        
        public let scheme = "rdocs:"
        public let fallbackURL = "https://readdle.com/products/documents/"
        public let appStoreId = "364901807"
        
        public init() {}
    }
}


public extension Applications.Documents {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.Documents.Action: PTExternalApplicationAction {
    
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
