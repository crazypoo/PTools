// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct Twitterrific: PTExternalApplication {
        
        public typealias ActionType = Applications.Twitterrific.Action
        
        public let scheme = "twitterrific:"
        public let fallbackURL = "http://twitterrific.com/ios"
        public let appStoreId = "580311103"
        
        public init() {}
    }
}



public extension Applications.Twitterrific {
    
    enum Action: Sendable {
        case open
        case mentionsView
        case messagesView
        case favoritesView
        case search(query: String)
        case tweetID(id: String)
        case messageID(id: String)
        case post(message: String)
        case userProfile(screenName: String)
    }
}

extension Applications.Twitterrific.Action: PTExternalApplicationAction {
    
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
            
        case .mentionsView:
            return PTApplicationActionPaths(
                app: PTApplicationPath(
                    pathComponents: ["mentions"],
                    queryParameters: [:]
                ),
                web: PTApplicationPath()
            )
            
        case .messagesView:
            return PTApplicationActionPaths(
                app: PTApplicationPath(
                    pathComponents: ["messages"],
                    queryParameters: [:]
                ),
                web: PTApplicationPath()
            )
            
        case .favoritesView:
            return PTApplicationActionPaths(
                app: PTApplicationPath(
                    pathComponents: ["favorites"],
                    queryParameters: [:]
                ),
                web: PTApplicationPath()
            )
            
        case .search(let query):
            return PTApplicationActionPaths(
                app: PTApplicationPath(
                    pathComponents: ["search"],
                    queryParameters: ["q": query]
                ),
                web: PTApplicationPath()
            )
            
        case .tweetID(let id):
            return PTApplicationActionPaths(
                app: PTApplicationPath(
                    pathComponents: ["tweet"],
                    queryParameters: ["id": id]
                ),
                web: PTApplicationPath()
            )
            
        case .messageID(let id):
            return PTApplicationActionPaths(
                app: PTApplicationPath(
                    pathComponents: ["message"],
                    queryParameters: ["id": id]
                ),
                web: PTApplicationPath()
            )
            
        case .post(let message):
            return PTApplicationActionPaths(
                app: PTApplicationPath(
                    pathComponents: ["post"],
                    queryParameters: [
                        "message": message,
                    ]
                ),
                web: PTApplicationPath()
            )
            
        case .userProfile(let screenName):
            return PTApplicationActionPaths(
                app: PTApplicationPath(
                    pathComponents: ["profile"],
                    queryParameters: ["screen_name": screenName]
                ),
                web: PTApplicationPath()
            )
        }
    }
}
