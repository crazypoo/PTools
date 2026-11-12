// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct Spark: PTExternalApplication {
        
        public typealias ActionType = Applications.Spark.Action
        
        public let scheme = "readdle-spark:"
        public let fallbackURL = "https://readdle.com/products/spark"
        public let appStoreId = "997102246"
        
        public init() {}
    }
}


public extension Applications.Spark {
    
    enum Action: Sendable {
        case compose(subject: String, recipient: String)
    }
}

extension Applications.Spark.Action: PTExternalApplicationAction {
    
    public var paths: PTApplicationActionPaths {
        
        switch self {
        case .compose(let subject, let recipient):
            return PTApplicationActionPaths(
                app: PTApplicationPath(
                    pathComponents: ["compose"],
                    queryParameters: [
                        "subject": subject,
                        "recipient": recipient,
                    ]
                ),
                web: PTApplicationPath()
            )
        }
    }
}
