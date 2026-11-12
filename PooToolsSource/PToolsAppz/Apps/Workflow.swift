// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct Workflow: PTExternalApplication {
        
        public typealias ActionType = Applications.Workflow.Action
        
        public let scheme = "workflow:"
        public let fallbackURL = "https://workflow.is"
        public let appStoreId = "915249334"
        
        public init() {}
    }
}


public extension Applications.Workflow {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.Workflow.Action: PTExternalApplicationAction {
    
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
