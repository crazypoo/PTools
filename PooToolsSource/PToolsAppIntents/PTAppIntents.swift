// English: Bridge static AppIntents declarations to the existing typed route contract.
// Español: Conecta las declaraciones estáticas de AppIntents con el contrato de rutas tipado existente.
// 中文：将静态 AppIntents 声明桥接到现有的类型化路由契约。

import Foundation

#if SWIFT_PACKAGE
import PToolsRouteCore
#endif

public enum PTAppIntentExecutionMode: String, Codable, Hashable, Sendable {
    case headless
    case routeToApp
    case hybrid
}

public struct PTAppIntentRouteDescriptor: Codable, Hashable, Sendable {
    public let route: PTRoute
    public let mode: PTAppIntentExecutionMode

    public init(route: PTRoute, mode: PTAppIntentExecutionMode = .routeToApp) {
        self.route = route
        self.mode = mode
    }

    public func request() -> PTRouteRequest {
        PTRouteRequest(route: route, source: .appIntent)
    }
}

@MainActor
public protocol PTAppIntentRouteAdapter: AnyObject {
    func open(request: PTRouteRequest) async throws
}

@MainActor
public final class PTAppIntentRouteBridge {
    public static let shared = PTAppIntentRouteBridge()
    public weak var adapter: (any PTAppIntentRouteAdapter)?

    public init() {}

    public func execute(_ descriptor: PTAppIntentRouteDescriptor) async throws {
        guard descriptor.mode != .headless else { return }
        try await adapter?.open(request: descriptor.request())
    }
}

#if canImport(AppIntents)
import AppIntents

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
public struct PTOpenRouteIntent: AppIntent {
    public static let title: LocalizedStringResource = "Open PTools route"
    public static let description = IntentDescription("Open a typed PTools route in the host application.")
    public static let openAppWhenRun = true

    @Parameter(title: "Route")
    public var routeID: String

    public init() {
        routeID = ""
    }

    public init(routeID: String) {
        self.routeID = routeID
    }

    public func perform() async throws -> some IntentResult {
        guard !routeID.isEmpty else { return .result() }
        let descriptor = PTAppIntentRouteDescriptor(route: PTRoute(id: PTRouteID(rawValue: routeID)))
        try await PTAppIntentRouteBridge.shared.execute(descriptor)
        return .result()
    }
}

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
public struct PTAppShortcuts: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: PTOpenRouteIntent(),
                     phrases: ["Open \(.applicationName) route"],
                     shortTitle: "Open route",
                    systemImageName: "arrow.right")
    }
}
#endif
