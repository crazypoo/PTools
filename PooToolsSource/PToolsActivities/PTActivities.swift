// English: Small ActivityKit lifecycle coordination with deduplication and diagnostics.
// Español: Coordinación pequeña del ciclo de vida de ActivityKit con deduplicación y diagnósticos.
// 中文：提供带去重和诊断能力的轻量 ActivityKit 生命周期协调。

import Foundation

#if canImport(ActivityKit) && os(iOS)
// English: ActivityKit's iOS SDK currently exposes @concurrent methods whose legacy generic constraints are not fully Sendable-annotated.
// Español: El SDK de iOS de ActivityKit expone métodos @concurrent cuyos límites genéricos heredados aún no están completamente anotados como Sendable.
// 中文：当前 iOS 的 ActivityKit SDK 将部分方法标记为 @concurrent，但旧版泛型约束尚未完整标注 Sendable，因此只在这个系统包装器内兼容导入。
@preconcurrency import ActivityKit
#endif

public struct PTActivityID: RawRepresentable, Codable, Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { self.init(rawValue: value) }
}

public enum PTActivityLifecycle: String, Codable, Hashable, Sendable {
    case idle
    case active
    case ended
    case unsupported
}

public enum PTActivityUpdatePolicy: Codable, Hashable, Sendable {
    case immediate
    case deduplicated
    case throttled(seconds: TimeInterval)
}

public enum PTActivityEndPolicy: String, Codable, Hashable, Sendable {
    case immediate
    case afterStaleDate
}

public struct PTActivityDiagnostics: Codable, Hashable, Sendable {
    public let identifier: PTActivityID?
    public let lifecycle: PTActivityLifecycle
    public let generation: UInt64
    public let lastUpdateAt: Date?
    public let lastError: String?
    public let pushTokenAvailable: Bool
    public let staleDate: Date?

    public init(identifier: PTActivityID? = nil,
                lifecycle: PTActivityLifecycle = .idle,
                generation: UInt64 = 0,
                lastUpdateAt: Date? = nil,
                lastError: String? = nil,
                pushTokenAvailable: Bool = false,
                staleDate: Date? = nil) {
        self.identifier = identifier
        self.lifecycle = lifecycle
        self.generation = generation
        self.lastUpdateAt = lastUpdateAt
        self.lastError = lastError
        self.pushTokenAvailable = pushTokenAvailable
        self.staleDate = staleDate
    }
}

public enum PTActivityError: Error, Sendable, Equatable {
    case unsupported
    case notStarted
    case staleUpdate
    case duplicateUpdate
    case throttled
    case requestFailed(String)
}

// English: Hosts may connect their existing BackgroundTasks or notification scheduler without creating a module cycle.
// Español: El host puede conectar su programador existente de BackgroundTasks o notificaciones sin crear un ciclo de módulos.
// 中文：宿主可以接入现有的 BackgroundTasks 或通知调度器，同时避免 P2 与基础模块形成循环依赖。
@MainActor
public protocol PTActivityBackgroundAdapter: AnyObject {
    func scheduleRefresh(for activityID: PTActivityID, staleDate: Date?) async
    func cancelRefresh(for activityID: PTActivityID) async
}

#if canImport(ActivityKit) && os(iOS)

// English: This narrow box isolates legacy ActivityKit values at the system boundary; it is never exposed to business state.
// Español: Esta caja estrecha aísla los valores heredados de ActivityKit en el límite del sistema; nunca expone estado de negocio.
// 中文：这个窄范围包装器只在 ActivityKit 系统边界隔离旧版值类型，不向业务状态暴露不安全并发。
private final class PTActivityKitSendableBox<Value>: @unchecked Sendable {
    let value: Value

    init(_ value: Value) {
        self.value = value
    }
}

// English: Keep ActivityKit's @concurrent calls outside the MainActor while the coordinator remains UI-safe.
// Español: Mantiene las llamadas @concurrent de ActivityKit fuera de MainActor mientras el coordinador sigue siendo seguro para UI.
// 中文：将 ActivityKit 的 @concurrent 调用移出 MainActor，同时保持协调器的 UI 状态安全。
private enum PTActivityKitConcurrencyBridge {
    static func update<Attributes>(
        activity: PTActivityKitSendableBox<Activity<Attributes>>,
        content: PTActivityKitSendableBox<ActivityContent<Attributes.ContentState>>
    ) async where Attributes: ActivityAttributes, Attributes: Sendable, Attributes.ContentState: Sendable {
        await activity.value.update(content.value)
    }

    static func end<Attributes>(
        activity: PTActivityKitSendableBox<Activity<Attributes>>,
        content: PTActivityKitSendableBox<ActivityContent<Attributes.ContentState>>?,
        dismissalPolicy: ActivityUIDismissalPolicy
    ) async where Attributes: ActivityAttributes, Attributes: Sendable, Attributes.ContentState: Sendable {
        await activity.value.end(content?.value, dismissalPolicy: dismissalPolicy)
    }
}

@available(iOS 16.1, macOS 13.0, watchOS 9.0, tvOS 16.1, *)
@MainActor
public final class PTActivityCoordinator<Attributes>
where Attributes: ActivityAttributes, Attributes: Sendable, Attributes.ContentState: Sendable {
    public private(set) var diagnostics = PTActivityDiagnostics()
    public private(set) var pushToken: Data?
    public private(set) var generation: UInt64 = 0
    public weak var backgroundAdapter: (any PTActivityBackgroundAdapter)?

    private let updatePolicy: PTActivityUpdatePolicy
    private var activity: Activity<Attributes>?
    private var lastStateData: Data?
    private var tokenTask: Task<Void, Never>?
    private var pushTokenContinuations: [UUID: AsyncStream<Data>.Continuation] = [:]

    public init(updatePolicy: PTActivityUpdatePolicy = .deduplicated) {
        self.updatePolicy = updatePolicy
    }

    deinit {
        tokenTask?.cancel()
        pushTokenContinuations.values.forEach { $0.finish() }
    }

    @discardableResult
    public func start(attributes: Attributes,
                      state: Attributes.ContentState,
                      staleDate: Date? = nil,
                      relevanceScore: Double? = nil) async throws -> PTActivityID {
        generation &+= 1
        let content = ActivityContent(state: state,
                                      staleDate: staleDate,
                                      relevanceScore: relevanceScore ?? 0)
        do {
            let activity = try Activity<Attributes>.request(attributes: attributes,
                                                             content: content,
                                                             pushType: nil)
            self.activity = activity
            self.pushToken = nil
            self.lastStateData = try? JSONEncoder().encode(state)
            let identifier = PTActivityID(rawValue: activity.id)
            diagnostics = PTActivityDiagnostics(identifier: identifier,
                                                lifecycle: .active,
                                                generation: generation,
                                                lastUpdateAt: .now,
                                                staleDate: staleDate)
            observePushToken(from: activity)
            await backgroundAdapter?.scheduleRefresh(for: identifier, staleDate: staleDate)
            return identifier
        } catch {
            diagnostics = PTActivityDiagnostics(lifecycle: .idle,
                                                generation: generation,
                                                lastError: error.localizedDescription)
            throw PTActivityError.requestFailed(error.localizedDescription)
        }
    }

    public func update(state: Attributes.ContentState,
                       staleDate: Date? = nil,
                       generation expectedGeneration: UInt64? = nil) async throws {
        guard let activity else { throw PTActivityError.notStarted }
        guard expectedGeneration == nil || expectedGeneration == generation else {
            throw PTActivityError.staleUpdate
        }
        guard staleDate.map({ $0 > .now }) ?? true else {
            throw PTActivityError.staleUpdate
        }
        let updateGeneration = generation
        let encodedState = try JSONEncoder().encode(state)
        if updatePolicy == .deduplicated, encodedState == lastStateData {
            throw PTActivityError.duplicateUpdate
        }
        if case .throttled(let seconds) = updatePolicy,
           let lastUpdateAt = diagnostics.lastUpdateAt,
           Date.now.timeIntervalSince(lastUpdateAt) < seconds {
            throw PTActivityError.throttled
        }
        let activityBox = PTActivityKitSendableBox(activity)
        let contentBox = PTActivityKitSendableBox(ActivityContent(state: state,
                                                                   staleDate: staleDate,
                                                                   relevanceScore: 0))
        await PTActivityKitConcurrencyBridge.update(activity: activityBox, content: contentBox)
        guard updateGeneration == generation, self.activity != nil else {
            throw PTActivityError.staleUpdate
        }
        lastStateData = encodedState
        diagnostics = PTActivityDiagnostics(identifier: diagnostics.identifier,
                                            lifecycle: .active,
                                            generation: generation,
                                            lastUpdateAt: .now,
                                            pushTokenAvailable: pushToken != nil,
                                            staleDate: staleDate)
        await backgroundAdapter?.scheduleRefresh(for: diagnostics.identifier ?? PTActivityID(rawValue: activity.id),
                                                 staleDate: staleDate)
    }

    public func end(state: Attributes.ContentState? = nil,
                    staleDate: Date? = nil,
                    policy: PTActivityEndPolicy = .immediate) async throws {
        guard let activity else { throw PTActivityError.notStarted }
        let identifier = PTActivityID(rawValue: activity.id)
        generation &+= 1
        let dismissal: ActivityUIDismissalPolicy
        switch policy {
        case .immediate:
            dismissal = .immediate
        case .afterStaleDate:
            dismissal = staleDate.map(ActivityUIDismissalPolicy.after) ?? .default
        }
        let activityBox = PTActivityKitSendableBox(activity)
        let content = state.map { PTActivityKitSendableBox(ActivityContent(state: $0, staleDate: staleDate)) }
        await PTActivityKitConcurrencyBridge.end(activity: activityBox,
                                                 content: content,
                                                 dismissalPolicy: dismissal)
        tokenTask?.cancel()
        self.activity = nil
        diagnostics = PTActivityDiagnostics(identifier: diagnostics.identifier,
                                            lifecycle: .ended,
                                            generation: generation,
                                            lastUpdateAt: diagnostics.lastUpdateAt,
                                            pushTokenAvailable: pushToken != nil,
                                            staleDate: staleDate)
        await backgroundAdapter?.cancelRefresh(for: identifier)
    }

    public func pushTokens() -> AsyncStream<Data> {
        let id = UUID()
        return AsyncStream { continuation in
            pushTokenContinuations[id] = continuation
            if let pushToken { continuation.yield(pushToken) }
            continuation.onTermination = { @Sendable [weak self] _ in
                Task { @MainActor in
                    self?.pushTokenContinuations[id] = nil
                }
            }
        }
    }

    private func observePushToken(from activity: Activity<Attributes>) {
        tokenTask?.cancel()
        let activityBox = PTActivityKitSendableBox(activity)
        tokenTask = Task.detached(priority: nil) { [weak self, activityBox] in
            for await token in activityBox.value.pushTokenUpdates {
                guard !Task.isCancelled else { break }
                await self?.receivePushToken(token)
            }
        }
    }

    @MainActor
    private func receivePushToken(_ token: Data) {
        pushToken = token
        pushTokenContinuations.values.forEach { $0.yield(token) }
        diagnostics = PTActivityDiagnostics(identifier: diagnostics.identifier,
                                            lifecycle: diagnostics.lifecycle,
                                            generation: generation,
                                            lastUpdateAt: diagnostics.lastUpdateAt,
                                            lastError: diagnostics.lastError,
                                            pushTokenAvailable: true,
                                            staleDate: diagnostics.staleDate)
    }
}

#else

@MainActor
public final class PTActivityCoordinator<Attributes> {
    public private(set) var diagnostics = PTActivityDiagnostics(lifecycle: .unsupported)
    public private(set) var pushToken: Data?
    public private(set) var generation: UInt64 = 0
    public weak var backgroundAdapter: (any PTActivityBackgroundAdapter)?

    public init(updatePolicy: PTActivityUpdatePolicy = .deduplicated) {
        _ = updatePolicy
    }

    public func start(attributes: Attributes,
                      state: Attributes,
                      staleDate: Date? = nil,
                      relevanceScore: Double? = nil) async throws -> PTActivityID {
        _ = attributes
        _ = state
        _ = staleDate
        _ = relevanceScore
        throw PTActivityError.unsupported
    }
}

#endif
