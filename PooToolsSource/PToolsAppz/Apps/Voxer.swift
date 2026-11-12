// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct Voxer: PTExternalApplication {
        
        public typealias ActionType = Applications.Voxer.Action
        
        public let scheme = "voxer:"
        public let fallbackURL = "http://www.voxer.com"
        public let appStoreId = "377304531"
        
        public init() {}
    }
}


public extension Applications.Voxer {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.Voxer.Action: PTExternalApplicationAction {
    
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
