// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct IMDb: PTExternalApplication {
        
        public typealias ActionType = Applications.IMDb.Action
        
        public let scheme = "imdb:"
        public let fallbackURL = "http://www.imdb.com/"
        public let appStoreId = "342792525"
        
        public init() {}
    }
}


public extension Applications.IMDb {
    
    enum Action: Sendable {
        
        case open
        case search(query: String)
        case title(id: String)
        case boxoffice
        case showtimes
        case featureCS
        case featureBP
        case featureBT
        case chartTop
        case moviemeter
    }
}


extension Applications.IMDb.Action: PTExternalApplicationAction {
    
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
                    pathComponents: ["", "find"],
                    queryParameters: ["q": query]
                ),
                web: PTApplicationPath(
                    pathComponents: ["find"],
                    queryParameters: ["q": query]
                )
            )
            
        case .title(let id):
            return PTApplicationActionPaths(
                app: PTApplicationPath(
                    pathComponents: ["", "title", id],
                    queryParameters: [:]
                ),
                web: PTApplicationPath(
                    pathComponents: ["title", id],
                    queryParameters: [:]
                )
            )
            
        case .boxoffice:
            return PTApplicationActionPaths(
                app: PTApplicationPath(
                    pathComponents: ["", "boxoffice"],
                    queryParameters: [:]
                ),
                web: PTApplicationPath(
                    pathComponents: ["boxoffice"],
                    queryParameters: [:])
            )
            
        case .showtimes:
            return PTApplicationActionPaths(
                app: PTApplicationPath(
                    pathComponents: ["", "showtimes"],
                    queryParameters: [:]
                ),
                web: PTApplicationPath(
                    pathComponents: ["showtimes"],
                    queryParameters: [:]
                )
            )
            
        case .featureCS:
            return PTApplicationActionPaths(
                app: PTApplicationPath(
                    pathComponents: ["", "feature", "comingsoon"],
                    queryParameters: [:]
                ),
                web: PTApplicationPath(
                    pathComponents: ["feature", "comingsoon"],
                    queryParameters: [:]
                )
            )
            
        case .featureBP:
            return PTApplicationActionPaths(
                app: PTApplicationPath(
                    pathComponents: ["", "feature", "bestpicture"],
                    queryParameters: [:]
                ),
                web: PTApplicationPath(
                    pathComponents: ["feature", "bestpicture"],
                    queryParameters: [:]
                )
            )
            
        case .featureBT:
            return PTApplicationActionPaths(
                app: PTApplicationPath(
                    pathComponents: ["", "feature", "borntoday"],
                    queryParameters: [:]
                ),
                web: PTApplicationPath(
                    pathComponents: ["feature", "borntoday"],
                    queryParameters: [:]
                )
            )
            
        case .chartTop:
            return PTApplicationActionPaths(
                app: PTApplicationPath(
                    pathComponents: ["", "chart", "top"],
                    queryParameters: [:]
                ),
                web: PTApplicationPath(
                    pathComponents: ["chart", "top"],
                    queryParameters: [:]
                )
            )
            
        case .moviemeter:
            return PTApplicationActionPaths(
                app: PTApplicationPath(
                    pathComponents: ["", "chart", "moviemeter"],
                    queryParameters: [:]
                ),
                web: PTApplicationPath(
                    pathComponents: ["chart", "moviemeter"],
                    queryParameters: [:]
                )
            )
        }
    }
}
