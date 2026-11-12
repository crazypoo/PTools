// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct FaceTimeAudio: PTExternalApplication {
        
        public typealias ActionType = Applications.FaceTimeAudio.Action
        
        public let scheme = "facetime-audio:"
        public let fallbackURL = ""
        public let appStoreId = ""
        
        public init() {}
    }
}


public extension Applications.FaceTimeAudio {
    
    enum Action: Sendable {
        case call(email: String)
    }
}

extension Applications.FaceTimeAudio.Action: PTExternalApplicationAction {
    
    public var paths: PTApplicationActionPaths {
        
        switch self {
        case .call(let email):
            return PTApplicationActionPaths(
                app: PTApplicationPath(
                    pathComponents: [email],
                    queryParameters: [:]
                ),
                web: PTApplicationPath()
            )
        }
    }
}
