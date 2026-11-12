// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct Yelp: PTExternalApplication {
        
        public typealias ActionType = Applications.Yelp.Action
        
        public let scheme = "yelp4:"
        public let fallbackURL = "https://m.yelp.com/"
        public let appStoreId = "284910350"
        
        public init() {}
    }
}



public extension Applications.Yelp {
    
    enum Action: Sendable {
        case open
        case search(query: String)
        case searchLocation(query: String, loc: String)
        case searchCategory(cat: String)
        case searchCatLoc(loc: String, cat: String)
        case business(id: String)
    }
}

extension Applications.Yelp.Action: PTExternalApplicationAction {
    
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
            
        case .search(let query):
            return PTApplicationActionPaths(
                app: PTApplicationPath(
                    pathComponents: ["", "search"],
                    queryParameters: ["terms": query]
                ),
                web: PTApplicationPath(
                    pathComponents: ["search"],
                    queryParameters: ["terms": query]
                )
            )
            
        case .searchLocation(let query, let loc):
            return PTApplicationActionPaths(
                app: PTApplicationPath(
                    pathComponents: ["", "search"],
                    queryParameters: [
                        "terms": query,
                        "location": loc,
                    ]
                ),
                web: PTApplicationPath(
                    pathComponents: ["search"],
                    queryParameters: [
                        "terms": query,
                        "location": loc,
                    ]
                )
            )
            
        case .searchCategory(let cat):
            return PTApplicationActionPaths(
                app: PTApplicationPath(
                    pathComponents: ["", "search"],
                    queryParameters: ["category": cat]
                ),
                web: PTApplicationPath(
                    pathComponents: ["search"],
                    queryParameters: ["category": cat]
                )
            )
            
        case .searchCatLoc(let loc, let cat):
            return PTApplicationActionPaths(
                app: PTApplicationPath(
                    pathComponents: ["", "search"],
                    queryParameters: [
                        "category": cat,
                        "location": loc,
                    ]
                ),
                web: PTApplicationPath(
                    pathComponents: ["search"],
                    queryParameters: [
                        "category": cat,
                        "location": loc,
                    ]
                )
            )
            
        case .business(let id):
            return PTApplicationActionPaths(
                app: PTApplicationPath(
                    pathComponents: ["", "biz", id],
                    queryParameters: [:]
                ),
                web: PTApplicationPath(
                    pathComponents: ["biz", id],
                    queryParameters: [:]
                )
            )
        }
    }
}
