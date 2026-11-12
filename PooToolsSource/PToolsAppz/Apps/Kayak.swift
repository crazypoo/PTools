// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct Kayak: PTExternalApplication {
        
        public typealias ActionType = Applications.Kayak.Action
        
        public let scheme = "kayak:"
        public let fallbackURL = "https://www.kayak.ae/"
        public let appStoreId = "305204535"
        
        public init() {}
    }
}


public extension Applications.Kayak {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.Kayak.Action: PTExternalApplicationAction {
    
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
