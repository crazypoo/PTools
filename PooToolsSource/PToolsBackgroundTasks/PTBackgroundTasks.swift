// English: Typed background task registration and cancellation for iOS 17+.
// Español: Registro y cancelación tipados de tareas en segundo plano para iOS 17+.
// 中文：面向 iOS 17+ 的类型化后台任务注册与取消能力。

import Foundation

#if (os(iOS) || os(tvOS)) && canImport(BackgroundTasks)
import BackgroundTasks
#endif

public enum PTBackgroundTaskKind: String, Codable, Sendable, Hashable {
    case appRefresh
    case processing
    case transfer
}

public struct PTBackgroundTaskRegistration: Codable, Sendable, Hashable {
    public let identifier: String
    public let kind: PTBackgroundTaskKind

    public init(identifier: String, kind: PTBackgroundTaskKind) {
        self.identifier = identifier
        self.kind = kind
    }
}

public enum PTBackgroundTaskError: Error, Sendable, Equatable {
    case invalidIdentifier
    case unavailable
    case submissionFailed
    case unsupportedKind
}

public enum PTBackgroundTaskState: String, Codable, Sendable, Hashable {
    case registered
    case scheduled
    case launched
    case completed
    case expired
}

public struct PTBackgroundTaskDiagnosticsSnapshot: Codable, Sendable, Equatable {
    public let registration: PTBackgroundTaskRegistration
    public let state: PTBackgroundTaskState
    public let lastScheduledDate: Date?
    public let lastLaunchedDate: Date?
    public let lastCompletedDate: Date?
    public let lastExpirationDate: Date?
    public let lastResult: Bool?

    public init(registration: PTBackgroundTaskRegistration,
                state: PTBackgroundTaskState,
                lastScheduledDate: Date? = nil,
                lastLaunchedDate: Date? = nil,
                lastCompletedDate: Date? = nil,
                lastExpirationDate: Date? = nil,
                lastResult: Bool? = nil) {
        self.registration = registration
        self.state = state
        self.lastScheduledDate = lastScheduledDate
        self.lastLaunchedDate = lastLaunchedDate
        self.lastCompletedDate = lastCompletedDate
        self.lastExpirationDate = lastExpirationDate
        self.lastResult = lastResult
    }
}

@MainActor
public final class PTBackgroundTasks {
    public static let shared = PTBackgroundTasks()

    public typealias Operation = @Sendable () async -> Bool

    private var operations: [String: Operation] = [:]
    private var diagnosticsByIdentifier: [String: PTBackgroundTaskDiagnosticsSnapshot] = [:]

    public init() {}

    @discardableResult
    public func register(_ registration: PTBackgroundTaskRegistration,
                         operation: @escaping Operation) -> Bool {
        guard !registration.identifier.isEmpty else { return false }
        operations[registration.identifier] = operation
#if (os(iOS) || os(tvOS)) && canImport(BackgroundTasks)
        let didRegister = BGTaskScheduler.shared.register(forTaskWithIdentifier: registration.identifier,
                                                           using: nil) { [weak self] task in
            self?.execute(task, identifier: registration.identifier)
        }
        if didRegister { record(registration, state: .registered) }
        return didRegister
#else
        return false
#endif
    }

    public func schedule(_ registration: PTBackgroundTaskRegistration,
                         earliestBeginDate: Date? = nil,
                         requiresNetworkConnectivity: Bool = false,
                         requiresExternalPower: Bool = false) throws {
#if (os(iOS) || os(tvOS)) && canImport(BackgroundTasks)
        guard !registration.identifier.isEmpty else { throw PTBackgroundTaskError.invalidIdentifier }
        let request: BGTaskRequest
        switch registration.kind {
        case .appRefresh:
            request = BGAppRefreshTaskRequest(identifier: registration.identifier)
        case .processing:
            let processing = BGProcessingTaskRequest(identifier: registration.identifier)
            processing.requiresNetworkConnectivity = requiresNetworkConnectivity
            processing.requiresExternalPower = requiresExternalPower
            request = processing
        case .transfer:
            throw PTBackgroundTaskError.unsupportedKind
        }
        request.earliestBeginDate = earliestBeginDate
        do {
            try BGTaskScheduler.shared.submit(request)
            record(registration, state: .scheduled)
        } catch {
            throw PTBackgroundTaskError.submissionFailed
        }
#else
        throw PTBackgroundTaskError.unavailable
#endif
    }

    public func cancel(identifier: String) {
#if (os(iOS) || os(tvOS)) && canImport(BackgroundTasks)
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: identifier)
#endif
    }

    public func diagnostics(for identifier: String) -> PTBackgroundTaskDiagnosticsSnapshot? {
        diagnosticsByIdentifier[identifier]
    }

    public func diagnosticsSnapshot() -> [String: PTBackgroundTaskDiagnosticsSnapshot] {
        diagnosticsByIdentifier
    }

#if (os(iOS) || os(tvOS)) && canImport(BackgroundTasks)
    private func execute(_ task: BGTask, identifier: String) {
        guard let operation = operations[identifier] else {
            task.setTaskCompleted(success: false)
            return
        }
        if let registration = diagnosticsByIdentifier[identifier]?.registration {
            record(registration, state: .launched)
        }
        let work = Task { @MainActor in
            let success = await operation()
            guard !Task.isCancelled else {
                if let registration = self.diagnosticsByIdentifier[identifier]?.registration {
                    self.record(registration, state: .expired, result: false)
                }
                task.setTaskCompleted(success: false)
                return
            }
            if let registration = self.diagnosticsByIdentifier[identifier]?.registration {
                self.record(registration, state: .completed, result: success)
            }
            task.setTaskCompleted(success: success)
        }
        task.expirationHandler = { [weak self] in
            work.cancel()
            Task { @MainActor in
                guard let registration = self?.diagnosticsByIdentifier[identifier]?.registration else { return }
                self?.record(registration, state: .expired, result: false)
            }
        }
    }
#endif

    private func record(_ registration: PTBackgroundTaskRegistration,
                        state: PTBackgroundTaskState,
                        result: Bool? = nil) {
        let old = diagnosticsByIdentifier[registration.identifier]
        let now = Date()
        diagnosticsByIdentifier[registration.identifier] = PTBackgroundTaskDiagnosticsSnapshot(
            registration: registration,
            state: state,
            lastScheduledDate: state == .scheduled ? now : old?.lastScheduledDate,
            lastLaunchedDate: state == .launched ? now : old?.lastLaunchedDate,
            lastCompletedDate: state == .completed ? now : old?.lastCompletedDate,
            lastExpirationDate: state == .expired ? now : old?.lastExpirationDate,
            lastResult: result ?? old?.lastResult
        )
    }
}

@MainActor
public final class PTBackgroundTransferCoordinator {
    public let sessionIdentifier: String
    private var eventsCompletion: (@MainActor () -> Void)?

    public init(sessionIdentifier: String) {
        self.sessionIdentifier = sessionIdentifier
    }

#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
    public func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.background(withIdentifier: sessionIdentifier)
        configuration.sessionSendsLaunchEvents = true
        return URLSession(configuration: configuration)
    }
#else
    public func makeSession() -> URLSession? { nil }
#endif

    public func setEventsCompletion(_ completion: (@MainActor () -> Void)?) {
        eventsCompletion = completion
    }

    public func completeRestoredEvents() {
        eventsCompletion?()
        eventsCompletion = nil
    }
}
