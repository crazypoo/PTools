// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct Telegram: PTExternalApplication {
        
        public typealias ActionType = Applications.Telegram.Action
        
        public let scheme = "tg:"
        public let fallbackURL = "https://t.me/"
        public let appStoreId = "686449807"
        
        public init() {}
    }
}


public extension Applications.Telegram {
    
    enum Action: Sendable {
        case open
        case msg(message: String, phone: String)
        case openFromID(username: String)
    }
}

extension Applications.Telegram.Action: PTExternalApplicationAction {
    
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
            
        case .msg(let message, let phone):
            return PTApplicationActionPaths(
                app: PTApplicationPath(
                    pathComponents: ["msg"],
                    queryParameters: [
                        "text": message,
                        "to": phone,
                    ]
                ),
                web: PTApplicationPath()
            )
        case .openFromID(let username):
            return PTApplicationActionPaths(
                app: PTApplicationPath(
                    pathComponents: ["resolve"],
                    queryParameters: ["domain":username]
                ),
                web: PTApplicationPath(
                    pathComponents: [username],
                    queryParameters: [:]
                )
            )
        }
    }
}
