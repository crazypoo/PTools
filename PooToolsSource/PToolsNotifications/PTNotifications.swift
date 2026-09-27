// English: Typed local and remote notification contracts for iOS 17 and Swift 6.
// Español: Contratos tipados de notificaciones locales y remotas para iOS 17 y Swift 6.
// 中文：面向 iOS 17 和 Swift 6 的类型化本地与远程通知契约。

import Foundation
#if SWIFT_PACKAGE
import PToolsRouteCore
#endif

#if canImport(UserNotifications)
import UserNotifications
import UniformTypeIdentifiers

public struct PTNotificationID: RawRepresentable, Codable, Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { self.init(rawValue: value) }
}

public struct PTNotificationActionID: RawRepresentable, Codable, Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { self.init(rawValue: value) }
}

public struct PTNotificationCategoryID: RawRepresentable, Codable, Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { self.init(rawValue: value) }
}

public struct PTNotificationActionOptions: OptionSet, Codable, Sendable, Hashable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    public static let authenticationRequired = Self(rawValue: 1 << 0)
    public static let destructive = Self(rawValue: 1 << 1)
    public static let foreground = Self(rawValue: 1 << 2)
}

public struct PTNotificationAction: Codable, Sendable, Hashable {
    public let id: PTNotificationActionID
    public let title: String
    public let options: PTNotificationActionOptions

    public init(id: PTNotificationActionID,
                title: String,
                options: PTNotificationActionOptions = []) {
        self.id = id
        self.title = title
        self.options = options
    }
}

public struct PTNotificationCategory: Codable, Sendable, Hashable {
    public let id: PTNotificationCategoryID
    public let actions: [PTNotificationAction]

    public init(id: PTNotificationCategoryID, actions: [PTNotificationAction] = []) {
        self.id = id
        self.actions = actions
    }
}

public enum PTNotificationPresentationPolicy: String, Codable, Sendable {
    case none
    case banner
    case list
    case sound
    case badge
    case all
}

public struct PTNotificationCalendarComponents: Codable, Sendable, Equatable {
    public let values: [String: Int]
    public init(values: [String: Int]) { self.values = values }
}

public enum PTNotificationTrigger: Codable, Sendable, Equatable {
    case timeInterval(TimeInterval, repeats: Bool)
    case calendar(PTNotificationCalendarComponents, repeats: Bool)
    case remote
}

public struct PTNotificationAttachment: Codable, Sendable, Equatable {
    public let identifier: String
    public let fileURL: URL
    public let typeIdentifier: String?

    public init(identifier: String,
                fileURL: URL,
                typeIdentifier: String? = nil) {
        self.identifier = identifier
        self.fileURL = fileURL
        self.typeIdentifier = typeIdentifier
    }
}

public struct PTNotificationPayload: Codable, Sendable, Equatable {
    public let title: String?
    public let body: String?
    public let badge: Int?
    public let categoryID: PTNotificationCategoryID?
    public let userInfo: [String: String]
    public let route: PTRouteRequest?

    public init(title: String? = nil,
                body: String? = nil,
                badge: Int? = nil,
                categoryID: PTNotificationCategoryID? = nil,
                userInfo: [String: String] = [:],
                route: PTRouteRequest? = nil) {
        self.title = title
        self.body = body
        self.badge = badge
        self.categoryID = categoryID
        self.userInfo = userInfo
        self.route = route
    }
}

public struct PTNotificationRequest: Codable, Sendable, Equatable {
    public let id: PTNotificationID
    public let payload: PTNotificationPayload
    public let trigger: PTNotificationTrigger
    public let attachments: [PTNotificationAttachment]

    public init(id: PTNotificationID,
                payload: PTNotificationPayload,
                trigger: PTNotificationTrigger = .remote,
                attachments: [PTNotificationAttachment] = []) {
        self.id = id
        self.payload = payload
        self.trigger = trigger
        self.attachments = attachments
    }
}

@MainActor
public protocol PTNotificationRouteAdapter: AnyObject {
    func open(route: PTRouteRequest) async
}

private final class PTNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    private let policyLock = NSLock()
    private var policy: PTNotificationPresentationPolicy = .all
    private let routeLock = NSLock()
    private var routeHandler: (@MainActor @Sendable (PTRouteRequest) async -> Void)?

    func setPolicy(_ policy: PTNotificationPresentationPolicy) {
        policyLock.lock()
        self.policy = policy
        policyLock.unlock()
    }

    func setRouteHandler(_ handler: (@MainActor @Sendable (PTRouteRequest) async -> Void)?) {
        routeLock.lock()
        routeHandler = handler
        routeLock.unlock()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        policyLock.lock()
        let currentPolicy = policy
        policyLock.unlock()
        completionHandler(Self.options(for: currentPolicy))
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let routeHandler: (@MainActor @Sendable (PTRouteRequest) async -> Void)?
        routeLock.lock()
        routeHandler = self.routeHandler
        routeLock.unlock()
        completionHandler()

        guard let encodedRoute = response.notification.request.content.userInfo["pt.route"] as? String,
              let data = Data(base64Encoded: encodedRoute),
              let route = try? JSONDecoder().decode(PTRouteRequest.self, from: data) else {
            return
        }
        Task { @MainActor in
            await routeHandler?(route)
        }
    }

    private static func options(for policy: PTNotificationPresentationPolicy) -> UNNotificationPresentationOptions {
        switch policy {
        case .none: return []
        case .banner: return [.banner]
        case .list: return [.list]
        case .sound: return [.sound]
        case .badge: return [.badge]
        case .all: return [.banner, .list, .sound, .badge]
        }
    }
}

@MainActor
public final class PTNotificationCenter: NSObject {
    public static let shared = PTNotificationCenter()
    public var presentationPolicy: PTNotificationPresentationPolicy = .all {
        didSet { delegateProxy.setPolicy(presentationPolicy) }
    }
    public weak var routeAdapter: (any PTNotificationRouteAdapter)? {
        didSet {
            delegateProxy.setRouteHandler { [weak self] route in
                await self?.routeAdapter?.open(route: route)
            }
        }
    }

    public private(set) var deviceToken: String?
    public var onDeviceTokenChange: (@MainActor @Sendable (String) -> Void)?

    private let center: UNUserNotificationCenter
    private let delegateProxy = PTNotificationDelegate()

    public init(center: UNUserNotificationCenter = .current()) {
        self.center = center
        super.init()
        delegateProxy.setPolicy(presentationPolicy)
        delegateProxy.setRouteHandler { [weak self] route in
            await self?.routeAdapter?.open(route: route)
        }
        center.delegate = delegateProxy
    }

    public func requestAuthorization(options: UNAuthorizationOptions = [.alert, .sound, .badge]) async throws -> Bool {
        try await center.requestAuthorization(options: options)
    }

    public func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    public func register(categories: [PTNotificationCategory]) {
        let values = categories.map { category in
            UNNotificationCategory(identifier: category.id.rawValue,
                                   actions: category.actions.map(makeAction),
                                   intentIdentifiers: [],
                                   options: [])
        }
        center.setNotificationCategories(Set(values))
    }

    public func schedule(_ request: PTNotificationRequest) async throws {
        let content = UNMutableNotificationContent()
        content.title = request.payload.title ?? ""
        content.body = request.payload.body ?? ""
        content.badge = request.payload.badge.map(NSNumber.init(value:))
        content.categoryIdentifier = request.payload.categoryID?.rawValue ?? ""
        content.userInfo = request.payload.userInfo.reduce(into: [AnyHashable: Any]()) { result, item in
            result[item.key] = item.value
        }
        if let route = request.payload.route,
           let data = try? JSONEncoder().encode(route) {
            content.userInfo["pt.route"] = data.base64EncodedString()
        }
        content.attachments = try request.attachments.map { attachment in
            let options = attachment.typeIdentifier.map {
                [UNNotificationAttachmentOptionsTypeHintKey: $0] as [AnyHashable: Any]
            }
            return try UNNotificationAttachment(identifier: attachment.identifier,
                                                url: attachment.fileURL,
                                                options: options)
        }

        let notificationTrigger: UNNotificationTrigger?
        switch request.trigger {
        case .remote:
            notificationTrigger = nil
        case .timeInterval(let interval, let repeats):
            guard interval > 0 else { throw PTNotificationError.invalidTrigger }
            notificationTrigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: repeats)
        case .calendar(let components, let repeats):
            var dateComponents = DateComponents()
            for (key, value) in components.values {
                switch key {
                case "era": dateComponents.era = value
                case "year": dateComponents.year = value
                case "month": dateComponents.month = value
                case "day": dateComponents.day = value
                case "hour": dateComponents.hour = value
                case "minute": dateComponents.minute = value
                case "second": dateComponents.second = value
                case "weekday": dateComponents.weekday = value
                default: continue
                }
            }
            notificationTrigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: repeats)
        }

        try await center.add(UNNotificationRequest(identifier: request.id.rawValue,
                                                    content: content,
                                                    trigger: notificationTrigger))
    }

    public func removePending(ids: [PTNotificationID]) {
        center.removePendingNotificationRequests(withIdentifiers: ids.map(\.rawValue))
    }

    public func updateDeviceToken(_ token: Data) -> String {
        let value = token.map { String(format: "%02x", $0) }.joined()
        guard deviceToken != value else { return value }
        deviceToken = value
        onDeviceTokenChange?(value)
        return value
    }

    @available(*, deprecated, renamed: "updateDeviceToken")
    public func setDeviceToken(_ token: Data) -> String {
        updateDeviceToken(token)
    }

    private func makeAction(_ action: PTNotificationAction) -> UNNotificationAction {
        var options: UNNotificationActionOptions = []
        if action.options.contains(.authenticationRequired) { options.insert(.authenticationRequired) }
        if action.options.contains(.destructive) { options.insert(.destructive) }
        if action.options.contains(.foreground) { options.insert(.foreground) }
        return UNNotificationAction(identifier: action.id.rawValue, title: action.title, options: options)
    }
}

public enum PTNotificationError: Error, Sendable, Equatable {
    case invalidTrigger
}

#else

public enum PTNotificationError: Error, Sendable, Equatable { case unavailable }

#endif
