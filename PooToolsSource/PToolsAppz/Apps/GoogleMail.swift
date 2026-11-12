// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct GoogleMail: PTExternalApplication {
        
        public typealias ActionType = Applications.GoogleMail.Action
        
        public let scheme = "googlegmail:"
        public let fallbackURL = "https://mail.google.com/"
        public let appStoreId = "422689480"
        
        public init() {}
    }
}


public extension Applications.GoogleMail {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.GoogleMail.Action: PTExternalApplicationAction {
    
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
