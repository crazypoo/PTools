// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct Ishows: PTExternalApplication {
        
        public typealias ActionType = Applications.Ishows.Action
        
        public let scheme = "ishows:"
        public let fallbackURL = "http://ishowsapp.com"
        public let appStoreId = "992387872"
        
        public init() {}
    }
}


public extension Applications.Ishows {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.Ishows.Action: PTExternalApplicationAction {
    
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
