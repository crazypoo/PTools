// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct DamaKing: PTExternalApplication {
        
        public typealias ActionType = Applications.DamaKing.Action
        
        public let scheme = "damaking:"
        public let fallbackURL = "http://level3.io"
        public let appStoreId = "442570707"
        
        public init() {}
    }
}


public extension Applications.DamaKing {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.DamaKing.Action: PTExternalApplicationAction {
    
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
