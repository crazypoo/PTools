import Foundation

// English: Events use string snapshots so future storage and Instruments consumers do not cross actors with UIKit objects.
// Español: Los eventos usan instantáneas String para que el almacenamiento y futuros consumidores de Instruments no crucen actores con objetos UIKit.
// 中文：事件只携带 String 快照，后续存储和 Instruments 消费者无需跨 actor 传递 UIKit 对象。
public struct PTDebugEvent: Sendable, Equatable {
    public let id: UUID
    public let date: Date
    public let name: String
    public let source: String
    public let payload: [String: String]

    public init(id: UUID = UUID(),
                date: Date = Date(),
                name: String,
                source: String,
                payload: [String: String] = [:]) {
        self.id = id
        self.date = date
        self.name = name
        self.source = source
        self.payload = payload
    }
}

// English: MainActor event delivery makes observer registration, removal, and UI updates deterministic.
// Español: La entrega de eventos en MainActor hace deterministas el registro, la eliminación y las actualizaciones UI.
// 中文：事件统一在 MainActor 投递，让观察者注册、移除和 UI 更新保持确定性。
@MainActor
public final class PTDebugEventCenter {
    public static let shared = PTDebugEventCenter()

    private var observers: [UUID: (PTDebugEvent) -> Void] = [:]

    private init() {}

    @discardableResult
    public func addObserver(_ observer: @escaping (PTDebugEvent) -> Void) -> UUID {
        let token = UUID()
        observers[token] = observer
        return token
    }

    public func removeObserver(_ token: UUID) {
        observers.removeValue(forKey: token)
    }

    public func publish(_ event: PTDebugEvent) {
        observers.values.forEach { $0(event) }
    }
}

