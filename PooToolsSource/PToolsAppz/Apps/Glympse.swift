// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct Glympse: PTExternalApplication {
        
        public typealias ActionType = Applications.Glympse.Action
        
        public let scheme = "glympse:"
        public let fallbackURL = "https://glympse.com/get-glympse"
        public let appStoreId = "330316698"
        
        public init() {}
    }
}


public extension Applications.Glympse {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.Glympse.Action: PTExternalApplicationAction {
    
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
