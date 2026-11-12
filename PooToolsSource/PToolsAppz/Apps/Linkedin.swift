// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct Linkedin: PTExternalApplication {
        
        public typealias ActionType = Applications.Linkedin.Action
        
        public let scheme = "linkedin:"
        public let fallbackURL = "http://www.linkedin.com/"
        public let appStoreId = "288429040"
        
        public init() {}
    }
}


public extension Applications.Linkedin {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.Linkedin.Action: PTExternalApplicationAction {
    
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
