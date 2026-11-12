// English: Small, typed application specifications cover common integrations without shipping a third-party catalog.
// Español: Especificaciones pequeñas y tipadas cubren integraciones comunes sin enviar un catálogo de terceros.
// 中文：用精简的类型化应用规格覆盖常用集成，不再携带第三方目录。

import Foundation

public extension Applications {
    struct AppStore: PTExternalApplication {
        public typealias ActionType = Action
        public let scheme = "itms-apps:"
        public let fallbackURL = "https:"
        public let appStoreId = ""

        public init() {}

        public enum Action: PTExternalApplicationAction, Sendable {
            case account(id: String)
            case app(id: String)
            case rateApp(id: String)

            public var paths: PTApplicationActionPaths {
                switch self {
                case .account(let id):
                    return .init(app: .init(pathComponents: ["itunes.apple.com", "developer", "id\(id)"]))
                case .app(let id):
                    return .init(app: .init(pathComponents: ["itunes.apple.com", "app", "id\(id)"]))
                case .rateApp(let id):
                    return .init(app: .init(
                        pathComponents: ["itunes.apple.com", "WebObjects", "MZStore.woa", "wa", "viewContentsUserReviews"],
                        queryParameters: ["type": "Purple+Software", "id": id]
                    ))
                }
            }
        }
    }

    struct Instagram: PTExternalApplication {
        public typealias ActionType = Action
        public let scheme = "instagram:"
        public let fallbackURL = "https://instagram.com/"
        public let appStoreId = "389801252"
        public init() {}

        public enum Action: PTExternalApplicationAction, Sendable {
            case open
            case camera
            case library(id: String)
            case media(id: String)
            case username(String)
            case location(id: String)
            case tag(name: String)

            public var paths: PTApplicationActionPaths {
                switch self {
                case .open: return .init(app: .init(pathComponents: ["app"]))
                case .camera: return .init(app: .init(pathComponents: ["camera"]))
                case .library(let id): return .init(app: .init(pathComponents: ["library"], queryParameters: ["LocalIdentifier": id]))
                case .media(let id): return .init(app: .init(pathComponents: ["media"], queryParameters: ["id": id]), web: .init(pathComponents: ["p", id]))
                case .username(let name): return .init(app: .init(pathComponents: ["user"], queryParameters: ["username": name]), web: .init(pathComponents: [name]))
                case .location(let id): return .init(app: .init(pathComponents: ["location"], queryParameters: ["id": id]))
                case .tag(let name): return .init(app: .init(pathComponents: ["tag"], queryParameters: ["name": name]), web: .init(pathComponents: ["explore", "tags", name]))
                }
            }
        }
    }

    struct GoogleMaps: PTExternalApplication {
        public typealias ActionType = Action
        public let scheme = "comgooglemaps:"
        public let fallbackURL = "https://maps.google.com/"
        public let appStoreId = "585027354"
        public init() {}

        public enum Action: PTExternalApplicationAction, Sendable {
            case open
            case displayDirections(saddr: String, daddr: String, directionsmode: String)
            case displayLocation(center: String, zoom: String, views: String)
            case search(q: String)

            public var paths: PTApplicationActionPaths {
                switch self {
                case .open: return .init(app: .init(pathComponents: ["app"]))
                case .displayDirections(let start, let destination, let mode):
                    let values = ["saddr": start, "daddr": destination, "directionsmode": mode]
                    return .init(app: .init(queryParameters: values), web: .init(queryParameters: values))
                case .displayLocation(let center, let zoom, let views):
                    let values = ["center": center, "zoom": zoom, "views": views]
                    return .init(app: .init(queryParameters: values), web: .init(queryParameters: values))
                case .search(let query):
                    return .init(app: .init(queryParameters: ["q": query]), web: .init(queryParameters: ["q": query]))
                }
            }
        }
    }

    struct Twitter: PTExternalApplication {
        public typealias ActionType = Action
        public let scheme = "twitter:"
        public let fallbackURL = "https://twitter.com/"
        public let appStoreId = "333903271"
        public init() {}

        public enum Action: PTExternalApplicationAction, Sendable {
            case status(id: String, screenName: String?)
            case userHandle(String)
            case userId(String)
            case search(query: String)
            case timeline
            case mentions
            case messages

            public var paths: PTApplicationActionPaths {
                switch self {
                case .status(let id, let screenName):
                    return .init(app: .init(pathComponents: ["status"], queryParameters: ["id": id]), web: .init(pathComponents: [screenName ?? "err", "statuses", id]))
                case .userHandle(let handle):
                    return .init(app: .init(pathComponents: ["user"], queryParameters: ["screen_name": handle]), web: .init(pathComponents: [handle]))
                case .userId(let id):
                    return .init(app: .init(pathComponents: ["user"], queryParameters: ["id": id]), web: .init(pathComponents: ["intent", "user"], queryParameters: ["user_id": id]))
                case .search(let query):
                    return .init(app: .init(pathComponents: ["search"], queryParameters: ["query": query]), web: .init(pathComponents: ["search"], queryParameters: ["q": query]))
                case .timeline: return .init(app: .init(pathComponents: ["timeline"]))
                case .mentions: return .init(app: .init(pathComponents: ["mentions"]), web: .init(pathComponents: ["mentions"]))
                case .messages: return .init(app: .init(pathComponents: ["messages"]), web: .init(pathComponents: ["messages"]))
                }
            }
        }
    }

    struct Facebook: PTExternalApplication {
        public typealias ActionType = Action
        public let scheme = "fb:"
        public let fallbackURL = "https://www.facebook.com/"
        public let appStoreId = "284882215"
        public init() {}

        public enum Action: PTExternalApplicationAction, Sendable {
            case open
            case profile(id: String)
            case page(id: String)

            public var paths: PTApplicationActionPaths {
                switch self {
                case .open: return .init(app: .init(pathComponents: ["profile"]))
                case .profile(let id): return .init(app: .init(pathComponents: ["profile"], queryParameters: ["id": id]), web: .init(pathComponents: [id]))
                case .page(let id): return .init(app: .init(pathComponents: ["page"], queryParameters: ["id": id]), web: .init(pathComponents: [id]))
                }
            }
        }
    }

    struct YouTube: PTExternalApplication {
        public typealias ActionType = Action
        public let scheme = "youtube:"
        public let fallbackURL = "https://www.youtube.com/"
        public let appStoreId = "544007664"
        public init() {}

        public enum Action: PTExternalApplicationAction, Sendable {
            case open
            case video(id: String)
            case search(query: String)

            public var paths: PTApplicationActionPaths {
                switch self {
                case .open: return .init(app: .init(pathComponents: ["home"]))
                case .video(let id): return .init(app: .init(pathComponents: ["watch"], queryParameters: ["v": id]), web: .init(pathComponents: ["watch"], queryParameters: ["v": id]))
                case .search(let query): return .init(app: .init(pathComponents: ["results"], queryParameters: ["search_query": query]), web: .init(pathComponents: ["results"], queryParameters: ["search_query": query]))
                }
            }
        }
    }

    struct WeChat: PTExternalApplication {
        public typealias ActionType = Action
        public let scheme = "weixin:"
        public let fallbackURL = "https://weixin.qq.com/"
        public let appStoreId = "414478124"
        public init() {}

        public enum Action: PTExternalApplicationAction, Sendable {
            case open
            public var paths: PTApplicationActionPaths {
                .init(app: .init(pathComponents: ["app"]))
            }
        }
    }

    struct WhatsApp: PTExternalApplication {
        public typealias ActionType = Action
        public let scheme = "whatsapp:"
        public let fallbackURL = "https://www.whatsapp.com/"
        public let appStoreId = "310633997"
        public init() {}

        public enum Action: PTExternalApplicationAction, Sendable {
            case open
            case message(phone: String, text: String?)
            public var paths: PTApplicationActionPaths {
                switch self {
                case .open: return .init(app: .init(pathComponents: ["send"]))
                case .message(let phone, let text):
                    let values = ["phone": phone, "text": text ?? ""]
                    return .init(app: .init(pathComponents: ["send"], queryParameters: values), web: .init(pathComponents: ["send"], queryParameters: values))
                }
            }
        }
    }

    struct Messages: PTExternalApplication {
        public typealias ActionType = Action
        public let scheme = "sms:"
        public let fallbackURL = "sms:"
        public let appStoreId = ""
        public init() {}

        public enum Action: PTExternalApplicationAction, Sendable {
            case compose(to: String, body: String?)
            public var paths: PTApplicationActionPaths {
                switch self {
                case .compose(let recipient, let body):
                    return .init(app: .init(pathComponents: [recipient], queryParameters: ["body": body ?? ""]))
                }
            }
        }
    }

    struct Mail: PTExternalApplication {
        public typealias ActionType = Action
        public let scheme = "mailto:"
        public let fallbackURL = "mailto:"
        public let appStoreId = ""
        public init() {}

        public enum Action: PTExternalApplicationAction, Sendable {
            case compose(to: String?, subject: String?, body: String?)
            public var paths: PTApplicationActionPaths {
                switch self {
                case .compose(let to, let subject, let body):
                    return .init(app: .init(
                        pathComponents: to.map { [$0] } ?? [],
                        queryParameters: ["subject": subject ?? "", "body": body ?? ""]
                    ))
                }
            }
        }
    }
}

/// Common descriptors are available without importing UIKit or a third-party catalog.
/// Los descriptores comunes están disponibles sin UIKit ni un catálogo de terceros.
/// 常用描述器无需引入 UIKit 或第三方目录即可使用。
public enum PTApplicationCatalog {
    public static let appStore = PTApplicationDescriptor(
        identifier: "app-store",
        scheme: "itms-apps:",
        fallbackURL: "https://www.apple.com/app-store/"
    )
    public static let instagram = PTApplicationDescriptor(
        identifier: "instagram",
        scheme: "instagram:",
        fallbackURL: "https://instagram.com/",
        appStoreID: "389801252"
    )
    public static let googleMaps = PTApplicationDescriptor(
        identifier: "google-maps",
        scheme: "comgooglemaps:",
        fallbackURL: "https://maps.google.com/",
        appStoreID: "585027354"
    )
    public static let twitter = PTApplicationDescriptor(
        identifier: "twitter",
        scheme: "twitter:",
        fallbackURL: "https://twitter.com/",
        appStoreID: "333903271"
    )
}
