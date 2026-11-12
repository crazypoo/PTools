// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct Slack: PTExternalApplication {
        
        public typealias ActionType = Applications.Slack.Action
        
        public let scheme = "slack:"
        public let fallbackURL = "https://slack.com"
        public let appStoreId = "803453959"
        
        public init() {}
    }
}


public extension Applications.Slack {
    
    enum Action: Sendable {
        case open
        case channel(team: String, id: String)
        case directMessage(team: String, id: String)
        case openFile(team: String, fileID: String)
        case search(team: String, query: String)
    }
}

extension Applications.Slack.Action: PTExternalApplicationAction {
    
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
            
        case .channel(let team, let id):
            return PTApplicationActionPaths(
                app: PTApplicationPath(
                    pathComponents: ["channel"],
                    queryParameters: [
                        "team": team,
                        "id": id
                    ]
                ),
                web: PTApplicationPath()
            )
            
        case .directMessage(let team, let id):
            return PTApplicationActionPaths(
                app: PTApplicationPath(
                    pathComponents: ["user"],
                    queryParameters: [
                        "team": team,
                        "id": id
                    ]
                ),
                web: PTApplicationPath()
            )
            
        case .openFile(let team, let fileID):
            return PTApplicationActionPaths(
                app: PTApplicationPath(
                    pathComponents: ["file"],
                    queryParameters: [
                        "team": team,
                        "id": fileID
                    ]
                ),
                web: PTApplicationPath()
            )
            
        case .search(let team, let query):
            return PTApplicationActionPaths(
                app: PTApplicationPath(
                    pathComponents: ["search"],
                    queryParameters: [
                        "team": team,
                        "query": query
                    ]
                ),
                web: PTApplicationPath()
            )
        }
    }
}
