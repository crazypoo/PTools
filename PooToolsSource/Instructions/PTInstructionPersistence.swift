// English: Main-actor persistence prevents UserDefaults from crossing the concurrency boundary.
// Español: La persistencia en MainActor evita cruzar UserDefaults entre actores.
// 中文：在 MainActor 内持久化，避免 UserDefaults 跨 actor 传递。

import Foundation

@MainActor
public protocol PTInstructionStore: AnyObject {
    func snapshot(for tour: PTInstructionTour) async -> PTInstructionProgressSnapshot?
    func save(_ snapshot: PTInstructionProgressSnapshot) async
    func removeSnapshot(for tour: PTInstructionTour) async
}

// English: Resetting a tour removes only its persisted progress snapshot.
// Español: Reiniciar un tutorial elimina solo su instantánea de progreso persistida.
// 中文：重置引导只删除该引导保存的进度快照。
public extension PTInstructionStore {
    func reset(tour: PTInstructionTour) async {
        await removeSnapshot(for: tour)
    }
}

@MainActor
public final class PTUserDefaultsInstructionStore: PTInstructionStore {
    public static let shared = PTUserDefaultsInstructionStore()

    private let defaults: UserDefaults
    private let keyPrefix = "com.crazypoo.PTools.instructions."

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func snapshot(for tour: PTInstructionTour) async -> PTInstructionProgressSnapshot? {
        guard let data = defaults.data(forKey: key(for: tour)) else { return nil }
        return try? JSONDecoder().decode(PTInstructionProgressSnapshot.self, from: data)
    }

    public func save(_ snapshot: PTInstructionProgressSnapshot) async {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: key(for: snapshot.tourID))
    }

    public func removeSnapshot(for tour: PTInstructionTour) async {
        defaults.removeObject(forKey: key(for: tour))
    }

    private func key(for tour: PTInstructionTour) -> String {
        key(for: tour.id)
    }

    private func key(for id: PTInstructionID) -> String {
        keyPrefix + id.rawValue
    }
}
