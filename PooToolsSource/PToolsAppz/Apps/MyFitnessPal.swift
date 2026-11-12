// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct MyFitnessPal: PTExternalApplication {
        
        public typealias ActionType = Applications.MyFitnessPal.Action
        
        public let scheme = "mfp:"
        public let fallbackURL = "https://www.myfitnesspal.com"
        public let appStoreId = "341232718"
        
        public init() {}
    }
}


public extension Applications.MyFitnessPal {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.MyFitnessPal.Action: PTExternalApplicationAction {
    
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
