import Foundation

/// Foundation-only ownership state for optional diagnostics. The caller (e.g.
/// MainActor DebugManager) owns synchronization and all UIKit collectors.
public struct PTDebugSessionOwnerLedger: Sendable, Equatable {
    public enum Transition: Sendable, Equatable {
        case unchanged
        case retained
        case activate
        case deactivate
    }

    private var owners: Set<String> = []

    public init() {}

    public var count: Int { owners.count }
    public var isEmpty: Bool { owners.isEmpty }
    public func contains(_ owner: String) -> Bool { owners.contains(owner) }

    /// Installs shared collectors only for the first unique nonempty owner.
    @discardableResult
    public mutating func acquire(_ owner: String) -> Transition {
        guard !owner.isEmpty, owners.insert(owner).inserted else { return .unchanged }
        return owners.count == 1 ? .activate : .retained
    }

    /// Uninstalls shared collectors only after the last owner is removed.
    @discardableResult
    public mutating func release(_ owner: String) -> Transition {
        guard !owner.isEmpty, owners.remove(owner) != nil else { return .unchanged }
        return owners.isEmpty ? .deactivate : .retained
    }

    @discardableResult
    public mutating func reset() -> Bool {
        let hadOwners = !owners.isEmpty
        owners.removeAll()
        return hadOwners
    }
}
