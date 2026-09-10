import Foundation
import Alamofire
import os.lock

@MainActor public let AppTestMode = "PT App network environment test".localized()
@MainActor public let AppCustomMode = "PT App network environment custom".localized()
@MainActor public let AppDisMode = "PT App network environment distribution".localized()

public enum NetworkCellularType: String, Sendable {
    case ALL = "Cellular"
    case Cellular2G = "2G"
    case Cellular3G = "3G"
    case Cellular4G = "4G"
    case Cellular5G = "5G"
}

public enum NetWorkStatus: Sendable {
    case unknown
    case notReachable
    case wwan(type: NetworkCellularType)
    case wifi
    case requiresConnection
    case wiredEthernet
    case loopback
    case other
    case checking

    @MainActor public static func valueName(type: NetWorkStatus) -> String {
        switch type {
        case .unknown: return "PT App network status unknow".localized()
        case .notReachable: return "PT App network status disconnect".localized()
        case .wwan(let subType): return subType.rawValue
        case .wifi: return "WIFI"
        case .requiresConnection: return "RequiresConnection"
        case .wiredEthernet: return "WiredEthernet"
        case .loopback: return "loopback"
        case .other: return "Other"
        case .checking: return "Checking"
        }
    }
}

public enum NetWorkEnvironment: Int, Sendable {
    case Development
    case Test
    case Distribution

    @MainActor public static func valueName(type: NetWorkEnvironment) -> String {
        switch type {
        case .Development: return "PT App network environment custom".localized()
        case .Test: return "PT App network environment test".localized()
        case .Distribution: return "PT App network environment distribution".localized()
        }
    }
}

public typealias NetWorkStatusBlock = @Sendable (NetWorkStatus, NetWorkEnvironment) -> Void
public typealias UploadProgress = @MainActor @Sendable (Progress) -> Void
public typealias FileDownloadSuccess = @MainActor @Sendable (AFDownloadResponse<URL?>) -> Void
public typealias FileDownloadFail = @MainActor @Sendable (Error?) -> Void

public var PTBaseURLMode: NetWorkEnvironment {
    guard let sliderValue = PTCoreUserDefultsWrapper.shared.AppServiceIdentifier else { return .Distribution }
    if sliderValue == "1" { return .Distribution }
    if sliderValue == "2" { return .Test }
    if sliderValue == "3" { return .Development }
    return .Distribution
}

public var PTSocketURLMode: NetWorkEnvironment {
    guard let sliderValue = PTCoreUserDefultsWrapper.shared.AppSocketServiceIdentifier else { return .Distribution }
    if sliderValue == "1" { return .Distribution }
    if sliderValue == "2" { return .Test }
    if sliderValue == "3" { return .Development }
    return .Distribution
}

public enum PTNetworkDedupPolicy: Sendable, Equatable {
    case none
    case identical
    case custom(String)

    func getOptionName() -> String {
        switch self {
        case .none: return "none"
        case .identical: return "identical"
        case .custom(let string): return string
        }
    }
}

public struct RequestKey: Hashable, Sendable {
    let url: String
    let method: String
    let paramsHash: String
    let headersHash: String
    let responseType: String

    init<T>(request: URLRequest, responseType: T.Type = Never.self) {
        self.url = request.url?.absoluteString ?? ""
        self.method = request.httpMethod ?? ""
        // English: Swift's hashValue is randomized per process; stable body and header snapshots keep request identity deterministic.
        // Español: Swift's hashValue cambia entre procesos; las instantáneas estables del cuerpo y las cabeceras mantienen la identidad determinista.
        // 中文：Swift 的 hashValue 在不同进程中会变化；稳定的请求体和请求头快照保证请求身份确定。
        let body = request.httpBody?.sortedJSONData() ?? Data()
        self.paramsHash = body.base64EncodedString()
        let headers = (request.allHTTPHeaderFields ?? [:])
            .map { key, value in "\(key.lowercased())=\(value)" }
            .sorted()
            .joined(separator: "\n")
        self.headersHash = Data(headers.utf8).base64EncodedString()
        self.responseType = String(reflecting: responseType)
    }
}

public struct PTNetworkConfig: Sendable {
    public var requestTimeout: TimeInterval = 20
    public var downloadRequestTimeout: TimeInterval = 5
    public var resourceTimeout: TimeInterval = 3600

    public var serverAddress: String = ""
    public var serverAddress_dev: String = ""
    public var socketAddress: String = ""
    public var socketAddress_dev: String = ""

    public var userToken: String = ""
    public var retryTimes: Int = 3
    public var retryDelay: TimeInterval = 1.5
    public var retryAPIStatusCode: Int = 502

    public var networkCacheOption: PTNetworkCachePolicy = .cacheElseNetwork
    public var networkCacheExpiration: String = "600"
    public var networkDedupOption: PTNetworkDedupPolicy = .custom("auto")

    public var maxDiskSize: Int64 = 100 * 1024 * 1024
    public var cleanThreshold: Double = 0.7
    public var cleanCachePreSec: TimeInterval = 60
    public var logMaxCount: Double = 3000

    // English: Deprecated spellings remain as computed adapters while canonical names own the storage.
    // Español: Las grafías obsoletas permanecen como adaptadores calculados y los nombres canónicos poseen el almacenamiento.
    // 中文：旧拼写保留为计算属性适配器，存储统一由正确命名的属性持有。
    @available(*, deprecated, message: "Use requestTimeout instead")
    public var netRequsetTime: TimeInterval {
        get { requestTimeout }
        set { requestTimeout = newValue }
    }

    @available(*, deprecated, message: "Use downloadRequestTimeout instead")
    public var downloadRequsetTime: TimeInterval {
        get { downloadRequestTimeout }
        set { downloadRequestTimeout = newValue }
    }

    @available(*, deprecated, message: "Use resourceTimeout instead")
    public var downloadEndTime: TimeInterval {
        get { resourceTimeout }
        set { resourceTimeout = newValue }
    }

    @available(*, deprecated, message: "Use networkCacheExpiration instead")
    public var networkCacheEXPTime: String {
        get { networkCacheExpiration }
        set { networkCacheExpiration = newValue }
    }

    @available(*, deprecated, message: "Use networkDedupOption instead")
    public var networkDudupOption: PTNetworkDedupPolicy {
        get { networkDedupOption }
        set { networkDedupOption = newValue }
    }

    public var waitsForConnectivity: Bool = true

    public init() {}
}

// English: Freeze the request values needed by an instance before asynchronous execution begins.
// Español: Congela los valores necesarios para una solicitud de instancia antes de iniciar la ejecución asíncrona.
// 中文：在异步执行开始前固定实例请求所需的配置值。
public struct PTNetworkRequestEnvironment: Sendable, Equatable {
    public let serverAddress: String
    public let socketAddress: String
    public let userToken: String
    public let requestTimeout: TimeInterval
    public let downloadRequestTimeout: TimeInterval
    public let resourceTimeout: TimeInterval
    public let cachePolicy: PTNetworkCachePolicy
    public let cacheExpiration: String
    public let dedupPolicy: PTNetworkDedupPolicy
    public let waitsForConnectivity: Bool

    public init(configuration: PTNetworkConfig) {
        serverAddress = configuration.serverAddress
        socketAddress = configuration.socketAddress
        userToken = configuration.userToken
        requestTimeout = configuration.requestTimeout
        downloadRequestTimeout = configuration.downloadRequestTimeout
        resourceTimeout = configuration.resourceTimeout
        cachePolicy = configuration.networkCacheOption
        cacheExpiration = configuration.networkCacheExpiration
        dedupPolicy = configuration.networkDedupOption
        waitsForConnectivity = configuration.waitsForConnectivity
    }
}

// English: Canonical value-type name for new Network integrations; PTNetworkConfig remains source-compatible.
// Español: Nombre canónico basado en valor para nuevas integraciones; PTNetworkConfig conserva la compatibilidad.
// 中文：为新的 Network 集成提供统一值类型名称，同时保留 PTNetworkConfig 兼容性。
public typealias PTNetworkConfiguration = PTNetworkConfig

// English: Keep concurrency support types in an existing Network source file so every build entry includes them.
// Español: Mantiene los tipos de soporte de concurrencia en un archivo existente de Network para que todas las entradas de compilación los incluyan.
// 中文：将并发支撑类型放入已有的 Network 源文件，确保所有构建入口都会编译它们。
public actor RequestDeduplicator {
    public static let shared = RequestDeduplicator()

    private struct RunningTask {
        let id: UUID
        let task: Any
        var waiterCount: Int
    }

    // English: Type erasure stays inside this actor; callers only receive Sendable results.
    // Español: La eliminación de tipos permanece dentro de este actor; los llamadores reciben solo resultados Sendable.
    // 中文：类型擦除只存在于 actor 内部，调用方只会收到 Sendable 结果。
    private var runningTasks: [RequestKey: RunningTask] = [:]

    private init() {}

    public func execute<T: Sendable>(
        request: URLRequest,
        policy: PTNetworkDedupPolicy,
        task: @escaping @Sendable () async throws -> PTBaseStructModel<T>
    ) async throws -> PTBaseStructModel<T> {
        switch policy {
        case .none:
            return try await task()
        default:
            let key = RequestKey(request: request, responseType: T.self)
            let taskID: UUID
            let sharedTask: Task<PTBaseStructModel<T>, Error>

            if var entry = runningTasks[key],
               let existingTask = entry.task as? Task<PTBaseStructModel<T>, Error> {
                entry.waiterCount += 1
                runningTasks[key] = entry
                taskID = entry.id
                sharedTask = existingTask
            } else {
                let newID = UUID()
                let newTask = Task { try await task() }
                runningTasks[key] = RunningTask(id: newID,
                                                task: newTask,
                                                waiterCount: 1)
                taskID = newID
                sharedTask = newTask
            }

            let releaseWaiter: @Sendable () -> Void = {
                Task {
                    let shouldCancel = await self.releaseWaiter(key: key, id: taskID)
                    if shouldCancel {
                        sharedTask.cancel()
                    }
                }
            }
            let releaseGate = PTNetworkOnceGate()
            let releaseOnce: @Sendable () -> Void = {
                releaseGate.run(releaseWaiter)
            }

            do {
                let result = try await withTaskCancellationHandler(operation: {
                    try await sharedTask.value
                }, onCancel: releaseOnce)
                releaseOnce()
                try Task.checkCancellation()
                return result
            } catch {
                releaseOnce()
                throw error
            }
        }
    }

    internal func executeRaw(
        request: URLRequest,
        policy: PTNetworkDedupPolicy,
        task: @escaping @Sendable () async throws -> PTNetworkResponseSnapshot
    ) async throws -> PTNetworkResponseSnapshot {
        switch policy {
        case .none:
            return try await task()
        default:
            let key = RequestKey(request: request, responseType: PTNetworkResponseSnapshot.self)
            let taskID: UUID
            let sharedTask: Task<PTNetworkResponseSnapshot, Error>

            if var entry = runningTasks[key],
               let existingTask = entry.task as? Task<PTNetworkResponseSnapshot, Error> {
                entry.waiterCount += 1
                runningTasks[key] = entry
                taskID = entry.id
                sharedTask = existingTask
            } else {
                let newID = UUID()
                let newTask = Task { try await task() }
                runningTasks[key] = RunningTask(id: newID,
                                                task: newTask,
                                                waiterCount: 1)
                taskID = newID
                sharedTask = newTask
            }

            let releaseWaiter: @Sendable () -> Void = {
                Task {
                    let shouldCancel = await self.releaseWaiter(key: key, id: taskID)
                    if shouldCancel {
                        sharedTask.cancel()
                    }
                }
            }
            let releaseGate = PTNetworkOnceGate()
            let releaseOnce: @Sendable () -> Void = {
                releaseGate.run(releaseWaiter)
            }

            do {
                let result = try await withTaskCancellationHandler(operation: {
                    try await sharedTask.value
                }, onCancel: releaseOnce)
                releaseOnce()
                try Task.checkCancellation()
                return result
            } catch {
                releaseOnce()
                throw error
            }
        }
    }

    private func releaseWaiter(key: RequestKey, id: UUID) -> Bool {
        guard var entry = runningTasks[key], entry.id == id else { return false }
        entry.waiterCount -= 1
        guard entry.waiterCount <= 0 else {
            runningTasks[key] = entry
            return false
        }
        runningTasks.removeValue(forKey: key)
        return true
    }
}

// English: This bridge makes an async download continuation finish exactly once without an actor hop.
// Español: Este puente garantiza que la continuación de una descarga asíncrona termine una sola vez sin cambiar de actor.
// 中文：这个桥接器保证异步下载 continuation 只结束一次，并且不需要切换 actor。
final class PTDownloadCancellationBridge: Sendable {
    private struct State: Sendable {
        var didFinish = false
        var cancellationRequested = false
        var cancelUnderlying: (@Sendable () -> Void)?
        var resumeCancellation: (@Sendable () -> Void)?
    }

    private let state = OSAllocatedUnfairLock(initialState: State())

    func install(resumeCancellation: @escaping @Sendable () -> Void) {
        let callback = state.withLock { state -> (@Sendable () -> Void)? in
            guard !state.didFinish else { return nil }
            state.resumeCancellation = resumeCancellation
            guard state.cancellationRequested else { return nil }
            state.didFinish = true
            state.cancelUnderlying = nil
            state.resumeCancellation = nil
            return resumeCancellation
        }
        callback?()
    }

    func install(cancelUnderlying: @escaping @Sendable () -> Void) {
        let shouldCancel = state.withLock { state -> Bool in
            guard !state.didFinish else { return state.cancellationRequested }
            state.cancelUnderlying = cancelUnderlying
            return state.cancellationRequested
        }
        if shouldCancel {
            cancelUnderlying()
        }
    }

    func finish() -> Bool {
        state.withLock { state in
            guard !state.didFinish else { return false }
            state.didFinish = true
            state.cancelUnderlying = nil
            state.resumeCancellation = nil
            return true
        }
    }

    func cancel() {
        let callbacks = state.withLock { state -> ((@Sendable () -> Void)?, (@Sendable () -> Void)?) in
            guard !state.didFinish else { return (nil, nil) }
            state.cancellationRequested = true
            let cancelUnderlying = state.cancelUnderlying
            state.cancelUnderlying = nil
            guard let resumeCancellation = state.resumeCancellation else {
                return (cancelUnderlying, nil)
            }
            state.didFinish = true
            state.resumeCancellation = nil
            return (cancelUnderlying, resumeCancellation)
        }
        callbacks.0?()
        callbacks.1?()
    }
}

// English: This gate releases one deduplicated waiter exactly once.
// Español: Esta compuerta libera exactamente una vez a cada espera deduplicada.
// 中文：这个闸门保证去重请求的每个等待者只释放一次。
private struct PTNetworkOnceGate: Sendable {
    private let didRun = OSAllocatedUnfairLock(initialState: false)

    func run(_ action: @escaping @Sendable () -> Void) {
        let shouldRun = didRun.withLock { didRun in
            guard !didRun else { return false }
            didRun = true
            return true
        }
        if shouldRun {
            action()
        }
    }
}

// English: This bridge cancels upload preparation and the Alamofire request from stream termination.
// Español: Este puente cancela la preparación y la solicitud de Alamofire al terminar el stream.
// 中文：这个桥接器在流结束时同时取消上传准备任务和 Alamofire 请求。
final class PTNetworkUploadCancellation: Sendable {
    private struct State: Sendable {
        var preparationTask: Task<Void, Never>?
        var request: UploadRequest?
        var isCancelled = false
    }

    private let state = OSAllocatedUnfairLock(initialState: State())

    func install(preparationTask: Task<Void, Never>) {
        let shouldCancel = state.withLock { state -> Bool in
            guard !state.isCancelled else { return true }
            state.preparationTask = preparationTask
            return false
        }
        if shouldCancel {
            preparationTask.cancel()
        }
    }

    func install(request: UploadRequest) {
        let shouldCancel = state.withLock { state -> Bool in
            guard !state.isCancelled else { return true }
            state.request = request
            return false
        }
        if shouldCancel {
            request.cancel()
        }
    }

    func cancel() {
        let resources = state.withLock { state -> (Task<Void, Never>?, UploadRequest?) in
            state.isCancelled = true
            let resources = (state.preparationTask, state.request)
            state.preparationTask = nil
            state.request = nil
            return resources
        }
        resources.0?.cancel()
        resources.1?.cancel()
    }
}
