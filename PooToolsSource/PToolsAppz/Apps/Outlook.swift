// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct Outlook: PTExternalApplication {
        
        public typealias ActionType = Applications.Outlook.Action
        
        public let scheme = "ms-outlook:"
        public let fallbackURL = "http://www.outlook.com/"
        public let appStoreId = "951937596"
        
        public init() {}
    }
}


public extension Applications.Outlook {
    
    enum Action: Sendable {
        case open
        case compose(to: String, subject: String)
    }
}

extension Applications.Outlook.Action: PTExternalApplicationAction {
    
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
            
        case .compose(let to, let subject):
            return PTApplicationActionPaths(
                app: PTApplicationPath(
                    pathComponents: ["compose"],
                    queryParameters: [
                        "to": to,
                        "subject": subject,
                    ]
                ),
                web: PTApplicationPath()
            )
        }
    }
}
