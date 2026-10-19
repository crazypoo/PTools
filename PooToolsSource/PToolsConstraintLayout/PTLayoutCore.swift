// English: Native, crash-safe and SnapKit-style Auto Layout primitives for PTools.
// Español: Primitivas nativas, seguras y con estilo SnapKit para Auto Layout de PTools.
// 中文：PTools 原生、防崩溃、SnapKit 风格的 Auto Layout 基础能力。

#if canImport(UIKit)
import Foundation
import UIKit

// English: UIKit layout values stay on MainActor because views and NSLayoutConstraint are not Sendable.
// Español: Los valores de layout de UIKit viven en MainActor porque las vistas y NSLayoutConstraint no son Sendable.
// 中文：UIKit 布局值全部位于 MainActor，因为 View 和 NSLayoutConstraint 不是 Sendable。
@MainActor
public enum PTLayoutRelation: String, Hashable {
    case equal
    case lessThanOrEqual
    case greaterThanOrEqual
}

@MainActor
public enum PTLayoutAttribute: String, Hashable {
    case top
    case bottom
    case leading
    case trailing
    case left
    case right
    case centerX
    case centerY
    case width
    case height
    case firstBaseline
    case lastBaseline
}

public struct PTLayoutPriority: Equatable, Sendable {
    public let rawValue: Float

    public init(_ rawValue: Float) {
        self.rawValue = rawValue
    }

    public static let required = PTLayoutPriority(1000)
    public static let high = PTLayoutPriority(750)
    public static let medium = PTLayoutPriority(749)
    public static let low = PTLayoutPriority(250)
}

// English: Stable IDs make diagnostics and update audits readable without exposing object addresses.
// Español: Los IDs estables hacen legibles los diagnósticos y las auditorías sin exponer direcciones de objetos.
// 中文：稳定 ID 让诊断和更新审计可读，同时不暴露对象地址。
public struct PTLayoutID: RawRepresentable, Hashable, Sendable {
    public let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

@MainActor
public enum PTLayoutDiagnosticMode: String, Sendable {
    case strict
    case diagnostic
    case production
}

// English: Make autoresizing-mask ownership explicit for every PTLayout activation.
// Español: Hace explícita la propiedad de la máscara de autoresizing en cada activación de PTLayout.
// 中文：明确每次 PTLayout 激活时 autoresizing mask 的布局所有权。
@MainActor
public enum PTLayoutAutoresizingMaskPolicy: Sendable {
    case automaticForManagedViews
    case preserve
}

// English: Keep the default SnapKit-compatible behavior while allowing controlled mixed-layout escape hatches.
// Español: Mantiene el comportamiento compatible con SnapKit y permite excepciones controladas para layouts mixtos.
// 中文：保持兼容 SnapKit 的默认行为，同时为混合布局提供受控例外。
@MainActor
public enum PTLayoutConfiguration {
    public static var autoresizingMaskPolicy: PTLayoutAutoresizingMaskPolicy = .automaticForManagedViews
}

@MainActor
public enum PTLayoutIssueCode: String, Sendable {
    case missingSuperview = "PTL001"
    case noCommonAncestor = "PTL002"
    case orphanLayoutGuide = "PTL003"
    case signatureMismatch = "PTL004"
    case invalidConstraint = "PTL005"
    case invalidMultiplier = "PTL006"
    case hierarchyChanged = "PTL007"
    case ambiguousMatch = "PTL008"
    case updateNotFound = "PTL009"
}

@MainActor
public struct PTLayoutIssue: Error, Equatable, Sendable {
    public let code: PTLayoutIssueCode
    public let owner: String
    public let anchor: String
    public let relatedTarget: String?
    public let fileID: String
    public let line: UInt
    public let function: String
    public let groupID: String?
    public let reason: String
    public let suggestion: String
    public let recovery: String
    public let sourceType: String
    public let occurrenceCount: Int

    public init(code: PTLayoutIssueCode,
                owner: String,
                anchor: String,
                relatedTarget: String? = nil,
                fileID: String = #fileID,
                line: UInt = #line,
                function: String = #function,
                groupID: String? = nil,
                reason: String,
                suggestion: String,
                recovery: String = "transaction skipped",
                sourceType: String = "PTLayout",
                occurrenceCount: Int = 1) {
        self.code = code
        self.owner = owner
        self.anchor = anchor
        self.relatedTarget = relatedTarget
        self.fileID = fileID
        self.line = line
        self.function = function
        self.groupID = groupID
        self.reason = reason
        self.suggestion = suggestion
        self.recovery = recovery
        self.sourceType = sourceType
        self.occurrenceCount = occurrenceCount
    }

    public var message: String {
        "[PTLayout][\(code.rawValue)][\(code)] \(reason) 建议：\(suggestion)"
    }
}

@MainActor
public struct PTLayoutChanges: Sendable {
    public let count: Int

    public init(count: Int) {
        self.count = count
    }
}

@MainActor
public enum PTLayoutResult {
    case success(PTLayoutChanges)
    case failure(PTLayoutIssue)

    public var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }

    public var issue: PTLayoutIssue? {
        if case let .failure(issue) = self { return issue }
        return nil
    }

    public var changeCount: Int {
        if case let .success(changes) = self { return changes.count }
        return 0
    }
}

@MainActor
public enum PTLayoutDiagnostics {
    public static var mode: PTLayoutDiagnosticMode = .diagnostic
    public static var onFailure: (@MainActor (PTLayoutIssue) -> Void)?

    private static var latestIssues: [ObjectIdentifier: PTLayoutIssue] = [:]
    private static var repeatedIssues: [String: Int] = [:]
    private static var isReporting = false
    private static let maximumLatestIssues = 512
    private static let maximumRepeatedIssueKeys = 1024

    public static func latest(for view: UIView) -> PTLayoutIssue? {
        latestIssues[ObjectIdentifier(view)]
    }

    public static func clear(for view: UIView) {
        latestIssues.removeValue(forKey: ObjectIdentifier(view))
    }

    internal static func report(_ issue: PTLayoutIssue, ownerView: UIView?) {
        let ownerID = ownerView.map { String(ObjectIdentifier($0).hashValue) } ?? "none"
        let key = "\(ownerID)|\(issue.code.rawValue)|\(issue.fileID)|\(issue.line)"
        let count = (repeatedIssues[key] ?? 0) + 1
        repeatedIssues[key] = count
        let updated = PTLayoutIssue(code: issue.code,
                                    owner: issue.owner,
                                    anchor: issue.anchor,
                                    relatedTarget: issue.relatedTarget,
                                    fileID: issue.fileID,
                                    line: issue.line,
                                    function: issue.function,
                                    groupID: issue.groupID,
                                    reason: issue.reason,
                                    suggestion: issue.suggestion,
                                    recovery: issue.recovery,
                                    sourceType: issue.sourceType,
                                    occurrenceCount: count)
        if let ownerView {
            if latestIssues[ObjectIdentifier(ownerView)] == nil,
               latestIssues.count >= maximumLatestIssues,
               let oldestOwner = latestIssues.keys.first {
                latestIssues.removeValue(forKey: oldestOwner)
            }
            latestIssues[ObjectIdentifier(ownerView)] = updated
        }
        if repeatedIssues.count > maximumRepeatedIssueKeys,
           let oldestKey = repeatedIssues.keys.first,
           oldestKey != key {
            repeatedIssues.removeValue(forKey: oldestKey)
        }

        guard !isReporting else { return }
        isReporting = true
        defer { isReporting = false }
        onFailure?(updated)
        // English: Keep the standalone product observable without importing the PTools umbrella.
        // Español: Mantiene observable el producto independiente sin importar el umbrella de PTools.
        // 中文：让独立产品无需导入 PTools umbrella 也能看到诊断信息。
        if mode != .production {
            Swift.print(updated.message + " [\(updated.fileID):\(updated.line)]")
        }
    }
}

@MainActor
internal final class PTLayoutReference {
    weak var view: UIView?
    weak var guide: UILayoutGuide?

    init(view: UIView) {
        self.view = view
    }

    init(guide: UILayoutGuide) {
        self.guide = guide
    }

    var object: AnyObject? {
        view ?? guide
    }

    var owningView: UIView? {
        view ?? guide?.owningView
    }

    var identity: ObjectIdentifier? {
        guard let object else { return nil }
        return ObjectIdentifier(object)
    }

    var displayName: String {
        if let view { return String(describing: type(of: view)) }
        if let guide { return String(describing: type(of: guide)) }
        return "released-object"
    }
}

@MainActor
public struct PTLayoutAnchor {
    fileprivate let reference: PTLayoutReference
    public let attribute: PTLayoutAttribute

    fileprivate init(reference: PTLayoutReference, attribute: PTLayoutAttribute) {
        self.reference = reference
        self.attribute = attribute
    }

}

@MainActor
public struct PTLayoutAnchorGroup {
    fileprivate let anchors: [PTLayoutAnchor]
    fileprivate let transaction: PTLayoutTransaction?

    fileprivate init(_ anchors: [PTLayoutAnchor], transaction: PTLayoutTransaction? = nil) {
        self.anchors = anchors
        self.transaction = transaction
    }

    fileprivate var first: PTLayoutAnchor? { anchors.first }

    public var top: PTLayoutAnchorGroup { appending(.top) }
    public var bottom: PTLayoutAnchorGroup { appending(.bottom) }
    public var leading: PTLayoutAnchorGroup { appending(.leading) }
    public var trailing: PTLayoutAnchorGroup { appending(.trailing) }
    public var left: PTLayoutAnchorGroup { appending(.left) }
    public var right: PTLayoutAnchorGroup { appending(.right) }
    public var centerX: PTLayoutAnchorGroup { appending(.centerX) }
    public var centerY: PTLayoutAnchorGroup { appending(.centerY) }
    public var width: PTLayoutAnchorGroup { appending(.width) }
    public var height: PTLayoutAnchorGroup { appending(.height) }
    public var firstBaseline: PTLayoutAnchorGroup { appending(.firstBaseline) }
    public var lastBaseline: PTLayoutAnchorGroup { appending(.lastBaseline) }

    private func appending(_ attribute: PTLayoutAttribute) -> PTLayoutAnchorGroup {
        guard let first else { return self }
        guard !anchors.contains(where: { $0.attribute == attribute }) else { return self }
        return PTLayoutAnchorGroup(anchors + [PTLayoutAnchor(reference: first.reference, attribute: attribute)],
                                   transaction: transaction)
    }
}

@MainActor
public extension PTLayoutAnchorGroup {
    @discardableResult
    func equalTo(_ target: PTLayoutAnchor) -> PTLayoutRelationMaker {
        relation(.equal, target: .anchor(target))
    }

    @discardableResult
    func equalTo(_ target: PTLayoutAnchorGroup) -> PTLayoutRelationMaker {
        guard anchors.first != nil, let transaction else {
            return PTLayoutRelationMaker(transaction: nil, draftIDs: [])
        }
        guard anchors.count == target.anchors.count else {
            return transaction.add(self, target: .invalid("起点和目标锚点数量不一致"), relation: .equal)
        }
        let ids = zip(anchors, target.anchors).flatMap { firstAnchor, targetAnchor in
            transaction.add(PTLayoutAnchorGroup([firstAnchor]),
                             target: .anchor(targetAnchor),
                             relation: .equal).draftIDs
        }
        return PTLayoutRelationMaker(transaction: transaction, draftIDs: ids)
    }

    @discardableResult
    func equalTo(_ target: UIView) -> PTLayoutRelationMaker {
        relation(.equal, target: .reference(PTLayoutReference(view: target)))
    }

    @discardableResult
    func equalTo(_ target: UILayoutGuide) -> PTLayoutRelationMaker {
        relation(.equal, target: .reference(PTLayoutReference(guide: target)))
    }

    @discardableResult
    func equalTo(_ value: CGFloat) -> PTLayoutRelationMaker {
        relation(.equal, target: .number(value))
    }

    @discardableResult
    func equalTo(_ value: Double) -> PTLayoutRelationMaker {
        equalTo(CGFloat(value))
    }

    @discardableResult
    func equalTo(_ value: Int) -> PTLayoutRelationMaker {
        equalTo(CGFloat(value))
    }

    @discardableResult
    func equalTo(_ value: CGSize) -> PTLayoutRelationMaker {
        relation(.equal, target: .size(value))
    }

    @discardableResult
    func equalTo(_ value: UIEdgeInsets) -> PTLayoutRelationMaker {
        relation(.equal, target: .insets(value))
    }

    @discardableResult
    func lessThanOrEqualTo(_ target: PTLayoutAnchorGroup) -> PTLayoutRelationMaker {
        relationToAnchorGroup(target, relation: .lessThanOrEqual)
    }

    @discardableResult
    func lessThanOrEqualTo(_ target: PTLayoutAnchor) -> PTLayoutRelationMaker {
        relation(.lessThanOrEqual, target: .anchor(target))
    }

    @discardableResult
    func lessThanOrEqualTo(_ target: UIView) -> PTLayoutRelationMaker {
        relation(.lessThanOrEqual, target: .reference(PTLayoutReference(view: target)))
    }

    @discardableResult
    func lessThanOrEqualTo(_ target: UILayoutGuide) -> PTLayoutRelationMaker {
        relation(.lessThanOrEqual, target: .reference(PTLayoutReference(guide: target)))
    }

    @discardableResult
    func lessThanOrEqualTo(_ value: CGFloat) -> PTLayoutRelationMaker {
        relation(.lessThanOrEqual, target: .number(value))
    }

    @discardableResult
    func lessThanOrEqualTo(_ value: Double) -> PTLayoutRelationMaker {
        lessThanOrEqualTo(CGFloat(value))
    }

    @discardableResult
    func lessThanOrEqualTo(_ value: Int) -> PTLayoutRelationMaker {
        lessThanOrEqualTo(CGFloat(value))
    }

    @discardableResult
    func greaterThanOrEqualTo(_ target: PTLayoutAnchorGroup) -> PTLayoutRelationMaker {
        relationToAnchorGroup(target, relation: .greaterThanOrEqual)
    }

    @discardableResult
    func greaterThanOrEqualTo(_ target: PTLayoutAnchor) -> PTLayoutRelationMaker {
        relation(.greaterThanOrEqual, target: .anchor(target))
    }

    @discardableResult
    func greaterThanOrEqualTo(_ target: UIView) -> PTLayoutRelationMaker {
        relation(.greaterThanOrEqual, target: .reference(PTLayoutReference(view: target)))
    }

    @discardableResult
    func greaterThanOrEqualTo(_ target: UILayoutGuide) -> PTLayoutRelationMaker {
        relation(.greaterThanOrEqual, target: .reference(PTLayoutReference(guide: target)))
    }

    @discardableResult
    func greaterThanOrEqualTo(_ value: CGFloat) -> PTLayoutRelationMaker {
        relation(.greaterThanOrEqual, target: .number(value))
    }

    @discardableResult
    func greaterThanOrEqualTo(_ value: Double) -> PTLayoutRelationMaker {
        greaterThanOrEqualTo(CGFloat(value))
    }

    @discardableResult
    func greaterThanOrEqualTo(_ value: Int) -> PTLayoutRelationMaker {
        greaterThanOrEqualTo(CGFloat(value))
    }

    @discardableResult
    func equalToSuperview() -> PTLayoutRelationMaker {
        relation(.equal, target: .superview)
    }

    @discardableResult
    func lessThanOrEqualToSuperview() -> PTLayoutRelationMaker {
        relation(.lessThanOrEqual, target: .superview)
    }

    @discardableResult
    func greaterThanOrEqualToSuperview() -> PTLayoutRelationMaker {
        relation(.greaterThanOrEqual, target: .superview)
    }

    @discardableResult
    func equalToSuperviewSafeArea() -> PTLayoutRelationMaker {
        guard let first else { return relation(.equal, target: .invalid("空锚点组")) }
        guard let transaction else { return PTLayoutRelationMaker(transaction: nil, draftIDs: []) }
        let reference = first.reference
        let target = reference.view?.superview?.safeAreaLayoutGuide
            ?? reference.guide?.owningView?.safeAreaLayoutGuide
        guard let target else {
            return relation(.equal, target: .invalid("无法解析起点对应的 Safe Area"))
        }
        let targetReference = PTLayoutReference(guide: target)
        let ids = anchors.flatMap { anchor in
            transaction.add(PTLayoutAnchorGroup([anchor], transaction: transaction),
                            target: .anchor(PTLayoutAnchor(reference: targetReference,
                                                           attribute: anchor.attribute)),
                            relation: .equal).draftIDs
        }
        return PTLayoutRelationMaker(transaction: transaction, draftIDs: ids)
    }

    private func relation(_ relation: PTLayoutRelation,
                          target: PTLayoutTarget) -> PTLayoutRelationMaker {
        guard transaction != nil else { return PTLayoutRelationMaker(transaction: nil, draftIDs: []) }
        return transaction!.add(self, target: target, relation: relation)
    }

    private func relationToAnchorGroup(_ target: PTLayoutAnchorGroup,
                                      relation: PTLayoutRelation) -> PTLayoutRelationMaker {
        guard anchors.first != nil, let transaction else { return PTLayoutRelationMaker(transaction: nil, draftIDs: []) }
        guard anchors.count == target.anchors.count else {
            return transaction.add(self, target: .invalid("起点和目标锚点数量不一致"), relation: relation)
        }
        let ids = zip(anchors, target.anchors).flatMap { firstAnchor, targetAnchor in
            transaction.add(PTLayoutAnchorGroup([firstAnchor]),
                             target: .anchor(targetAnchor),
                             relation: relation).draftIDs
        }
        return PTLayoutRelationMaker(transaction: transaction, draftIDs: ids)
    }
}

@MainActor
public struct PTLayoutNamespace {
    fileprivate let owner: PTLayoutReference

    fileprivate init(view: UIView) {
        owner = PTLayoutReference(view: view)
    }

    fileprivate init(guide: UILayoutGuide) {
        owner = PTLayoutReference(guide: guide)
    }

    public var top: PTLayoutAnchorGroup { group(.top) }
    public var bottom: PTLayoutAnchorGroup { group(.bottom) }
    public var leading: PTLayoutAnchorGroup { group(.leading) }
    public var trailing: PTLayoutAnchorGroup { group(.trailing) }
    public var left: PTLayoutAnchorGroup { group(.left) }
    public var right: PTLayoutAnchorGroup { group(.right) }
    public var centerX: PTLayoutAnchorGroup { group(.centerX) }
    public var centerY: PTLayoutAnchorGroup { group(.centerY) }
    public var width: PTLayoutAnchorGroup { group(.width) }
    public var height: PTLayoutAnchorGroup { group(.height) }
    public var firstBaseline: PTLayoutAnchorGroup { group(.firstBaseline) }
    public var lastBaseline: PTLayoutAnchorGroup { group(.lastBaseline) }
    public var center: PTLayoutAnchorGroup { group(.centerX, .centerY) }
    public var size: PTLayoutAnchorGroup { group(.width, .height) }
    public var edges: PTLayoutAnchorGroup { group(.top, .leading, .bottom, .trailing) }
    public var horizontalEdges: PTLayoutAnchorGroup { group(.leading, .trailing) }
    public var verticalEdges: PTLayoutAnchorGroup { group(.top, .bottom) }

    @discardableResult
    public func makeConstraints(group: String? = nil,
                                active: Bool = true,
                                file: StaticString = #fileID,
                                line: UInt = #line,
                                _ closure: @MainActor (PTLayoutMaker) -> Void) -> PTLayoutResult {
        let transaction = PTLayoutTransaction(owner: owner,
                                              operation: .make,
                                              groupID: group,
                                              fileID: String(describing: file),
                                              line: line)
        closure(PTLayoutMaker(transaction: transaction))
        let prepared = PTLayoutEngine.prepare(transaction)
        guard case .success = prepared.result else { return prepared.result }
        if active {
            let activated = prepared.group.activate()
            if activated.isSuccess, let group {
                PTLayoutStoreRegistry.store(for: owner)?.register(prepared.group, named: group)
            } else if activated.isSuccess {
                PTLayoutStoreRegistry.store(for: owner)?.register(prepared.group, named: nil)
            }
            return activated
        }
        PTLayoutStoreRegistry.store(for: owner)?.register(prepared.group, named: group)
        return .success(PTLayoutChanges(count: prepared.group.constraints.count))
    }

    @discardableResult
    public func prepareConstraints(file: StaticString = #fileID,
                                   line: UInt = #line,
                                   _ closure: @MainActor (PTLayoutMaker) -> Void) -> PTLayoutConstraintGroup {
        let transaction = PTLayoutTransaction(owner: owner,
                                              operation: .prepare,
                                              groupID: nil,
                                              fileID: String(describing: file),
                                              line: line)
        closure(PTLayoutMaker(transaction: transaction))
        let prepared = PTLayoutEngine.prepare(transaction)
        if case .success = prepared.result {
            return prepared.group
        }
        return PTLayoutConstraintGroup(constraints: [], issue: prepared.result.issue)
    }

    @discardableResult
    public func updateConstraints(file: StaticString = #fileID,
                                  line: UInt = #line,
                                  _ closure: @MainActor (PTLayoutMaker) -> Void) -> PTLayoutResult {
        performUpdate(operation: .update, allowsImplicitMake: true, file: file, line: line, closure: closure)
    }

    @discardableResult
    public func updateIfExists(file: StaticString = #fileID,
                               line: UInt = #line,
                               _ closure: @MainActor (PTLayoutMaker) -> Void) -> PTLayoutResult {
        performUpdate(operation: .update, allowsImplicitMake: false, file: file, line: line, closure: closure)
    }

    @discardableResult
    public func upsertConstraints(file: StaticString = #fileID,
                                  line: UInt = #line,
                                  _ closure: @MainActor (PTLayoutMaker) -> Void) -> PTLayoutResult {
        let update = performUpdate(operation: .update, allowsImplicitMake: false, file: file, line: line, closure: closure)
        guard let issue = update.issue, issue.code == .updateNotFound else { return update }
        guard let store = PTLayoutStoreRegistry.store(for: owner), store.allHandles().isEmpty else {
            // English: Reject partial upserts instead of duplicating matched native constraints.
            // Español: Rechaza upserts parciales para no duplicar restricciones nativas ya coincidentes.
            // 中文：拒绝部分 upsert，避免重复创建已经匹配的原生约束。
            return update
        }
        return makeConstraints(file: file, line: line, closure)
    }

    @discardableResult
    public func remakeConstraints(group: String? = nil,
                                  file: StaticString = #fileID,
                                  line: UInt = #line,
                                  _ closure: @MainActor (PTLayoutMaker) -> Void) -> PTLayoutResult {
        let transaction = PTLayoutTransaction(owner: owner,
                                              operation: .remake,
                                              groupID: group,
                                              fileID: String(describing: file),
                                              line: line)
        closure(PTLayoutMaker(transaction: transaction))
        let prepared = PTLayoutEngine.prepare(transaction)
        guard case .success = prepared.result else { return prepared.result }
        guard let store = PTLayoutStoreRegistry.store(for: owner) else {
            return .failure(PTLayoutIssue(code: .invalidConstraint,
                                          owner: owner.displayName,
                                          anchor: "remake",
                                          fileID: String(describing: file),
                                          line: line,
                                          reason: "无法建立布局所有权存储。",
                                          suggestion: "确认布局对象仍然存活。"))
        }
        let old = store.handles(for: owner)
        let oldConstraints = old.flatMap(\.nativeConstraints)
        let oldActiveStates = oldConstraints.map(\.isActive)
        old.forEach { $0.deactivate() }
        let activated = PTLayoutEngine.activateAtomically([prepared.group], registering: false)
        guard activated.isSuccess else {
            // English: Restore the old owner set when the replacement cannot be installed.
            // Español: Restaura el conjunto anterior si el reemplazo no puede instalarse.
            // 中文：新约束安装失败时恢复原有所有者约束。
            for (constraint, wasActive) in zip(oldConstraints, oldActiveStates) where wasActive {
                constraint.isActive = true
            }
            return activated
        }
        old.forEach { store.remove($0) }
        store.register(prepared.group, named: group)
        return activated
    }

    public func removeConstraints() {
        guard let store = PTLayoutStoreRegistry.store(for: owner) else { return }
        store.handles(for: owner).forEach { handle in
            handle.deactivate()
            store.remove(handle)
        }
    }

    @discardableResult
    public func activate(group: String, deactivating oldGroup: String? = nil) -> PTLayoutResult {
        guard let store = PTLayoutStoreRegistry.store(for: owner),
              let newGroup = store.namedGroup(group) else {
            return .failure(PTLayoutIssue(code: .updateNotFound,
                                          owner: owner.displayName,
                                          anchor: group,
                                          groupID: group,
                                          reason: "找不到命名约束组。",
                                          suggestion: "先使用 makeConstraints(group:active:) 创建约束组。"))
        }
        let result = newGroup.activate()
        guard result.isSuccess else { return result }
        if let oldGroup, oldGroup != group {
            store.namedGroup(oldGroup)?.deactivate()
        }
        return result
    }

    public func inspect() -> PTLayoutInspection {
        PTLayoutStoreRegistry.store(for: owner)?.inspection(for: owner)
            ?? PTLayoutInspection(owner: owner.displayName, constraints: [])
    }

    @discardableResult
    private func performUpdate(operation: PTLayoutOperation,
                               allowsImplicitMake: Bool,
                               file: StaticString,
                               line: UInt,
                               closure: @MainActor (PTLayoutMaker) -> Void) -> PTLayoutResult {
        let transaction = PTLayoutTransaction(owner: owner,
                                              operation: operation,
                                              groupID: nil,
                                              fileID: String(describing: file),
                                              line: line,
                                              allowsImplicitMake: allowsImplicitMake)
        closure(PTLayoutMaker(transaction: transaction))
        return PTLayoutEngine.update(transaction)
    }

    private func group(_ attributes: PTLayoutAttribute...) -> PTLayoutAnchorGroup {
        PTLayoutAnchorGroup(attributes.map { PTLayoutAnchor(reference: owner, attribute: $0) })
    }
}

@MainActor
public extension UIView {
    var ptLayout: PTLayoutNamespace {
        PTLayoutNamespace(view: self)
    }
}

@MainActor
public extension UILayoutGuide {
    var ptLayout: PTLayoutNamespace {
        PTLayoutNamespace(guide: self)
    }
}

@MainActor
public final class PTLayoutMaker {
    fileprivate let transaction: PTLayoutTransaction

    fileprivate init(transaction: PTLayoutTransaction) {
        self.transaction = transaction
    }

    public var top: PTLayoutAnchorGroup { transaction.group(.top) }
    public var bottom: PTLayoutAnchorGroup { transaction.group(.bottom) }
    public var leading: PTLayoutAnchorGroup { transaction.group(.leading) }
    public var trailing: PTLayoutAnchorGroup { transaction.group(.trailing) }
    public var left: PTLayoutAnchorGroup { transaction.group(.left) }
    public var right: PTLayoutAnchorGroup { transaction.group(.right) }
    public var centerX: PTLayoutAnchorGroup { transaction.group(.centerX) }
    public var centerY: PTLayoutAnchorGroup { transaction.group(.centerY) }
    public var width: PTLayoutAnchorGroup { transaction.group(.width) }
    public var height: PTLayoutAnchorGroup { transaction.group(.height) }
    public var firstBaseline: PTLayoutAnchorGroup { transaction.group(.firstBaseline) }
    public var lastBaseline: PTLayoutAnchorGroup { transaction.group(.lastBaseline) }
    public var center: PTLayoutAnchorGroup { transaction.group(.centerX, .centerY) }
    public var size: PTLayoutAnchorGroup { transaction.group(.width, .height) }
    public var edges: PTLayoutAnchorGroup { transaction.group(.top, .leading, .bottom, .trailing) }
    public var horizontalEdges: PTLayoutAnchorGroup { transaction.group(.leading, .trailing) }
    public var verticalEdges: PTLayoutAnchorGroup { transaction.group(.top, .bottom) }

    @discardableResult
    public func aspectRatio(_ ratio: CGFloat,
                            priority: PTLayoutPriority = .required,
                            file: StaticString = #fileID,
                            line: UInt = #line) -> PTLayoutConstraint {
        let relation = transaction.group(.width).equalTo(transaction.group(.height))
        relation.multipliedBy(ratio).priority(priority).labeled("aspect-ratio")
        return relation.constraint
    }

    @discardableResult
    public func relativeWidth(to view: UIView,
                              ratio: CGFloat,
                              file: StaticString = #fileID,
                              line: UInt = #line) -> PTLayoutConstraint {
        let relation = width.equalTo(view.ptLayout.width)
        relation.multipliedBy(ratio)
        return relation.constraint
    }

    @discardableResult
    public func relativeHeight(to view: UIView,
                               ratio: CGFloat,
                               file: StaticString = #fileID,
                               line: UInt = #line) -> PTLayoutConstraint {
        let relation = height.equalTo(view.ptLayout.height)
        relation.multipliedBy(ratio)
        return relation.constraint
    }
}

@MainActor
public final class PTLayoutRelationMaker {
    fileprivate let transaction: PTLayoutTransaction?
    fileprivate let draftIDs: [Int]

    fileprivate init(transaction: PTLayoutTransaction?, draftIDs: [Int]) {
        self.transaction = transaction
        self.draftIDs = draftIDs
    }

    @discardableResult
    public func offset(_ value: CGFloat) -> Self {
        transaction?.update(draftIDs: draftIDs) { draft in
            draft.constant = value
            draft.insetMode = false
        }
        return self
    }

    @discardableResult
    public func inset(_ value: CGFloat) -> Self {
        transaction?.update(draftIDs: draftIDs) { draft in
            draft.constant = PTLayoutEngine.signedInset(value, for: draft.first.attribute)
            draft.insetMode = true
        }
        return self
    }

    @discardableResult
    public func inset(_ value: UIEdgeInsets) -> Self {
        transaction?.update(draftIDs: draftIDs) { draft in
            draft.constant = PTLayoutEngine.signedInset(value, for: draft.first.attribute)
            draft.insetMode = true
        }
        return self
    }

    @discardableResult
    public func directionalInset(_ value: NSDirectionalEdgeInsets) -> Self {
        transaction?.update(draftIDs: draftIDs) { draft in
            draft.constant = PTLayoutEngine.signedDirectionalInset(value, for: draft.first.attribute)
            draft.insetMode = true
        }
        return self
    }

    @discardableResult
    public func multipliedBy(_ value: CGFloat) -> Self {
        transaction?.update(draftIDs: draftIDs) { $0.multiplier = value }
        return self
    }

    @discardableResult
    public func dividedBy(_ value: CGFloat) -> Self {
        transaction?.update(draftIDs: draftIDs) { $0.multiplier = value == 0 ? .nan : 1 / value }
        return self
    }

    @discardableResult
    public func priority(_ value: PTLayoutPriority) -> Self {
        transaction?.update(draftIDs: draftIDs) { $0.priority = value.rawValue }
        return self
    }

    @discardableResult
    public func priority(_ value: UILayoutPriority) -> Self {
        transaction?.update(draftIDs: draftIDs) { $0.priority = value.rawValue }
        return self
    }

    @discardableResult
    public func priority(_ value: Float) -> Self {
        transaction?.update(draftIDs: draftIDs) { $0.priority = value }
        return self
    }

    @discardableResult
    public func labeled(_ value: String) -> Self {
        transaction?.update(draftIDs: draftIDs) { $0.identifier = value }
        return self
    }

    @discardableResult
    public func labeled(_ value: PTLayoutID) -> Self {
        labeled(value.rawValue)
    }

    public var constraint: PTLayoutConstraint {
        let handle = PTLayoutConstraint(owner: transaction?.owner,
                                        draftIDs: draftIDs,
                                        transaction: transaction)
        transaction?.register(handle: handle, draftIDs: draftIDs)
        return handle
    }
}

@MainActor
public enum PTLayoutOperation {
    case make
    case update
    case remake
    case prepare
}

@MainActor
internal enum PTLayoutTarget {
    case superview
    case reference(PTLayoutReference)
    case anchor(PTLayoutAnchor)
    case number(CGFloat)
    case size(CGSize)
    case insets(UIEdgeInsets)
    case invalid(String)
}

@MainActor
internal final class PTLayoutDraft {
    let first: PTLayoutAnchor
    let target: PTLayoutTarget
    var relation: PTLayoutRelation
    var constant: CGFloat = 0
    var multiplier: CGFloat = 1
    var priority: Float = UILayoutPriority.required.rawValue
    var identifier: String?
    var insetMode = false

    init(first: PTLayoutAnchor, target: PTLayoutTarget, relation: PTLayoutRelation) {
        self.first = first
        self.target = target
        self.relation = relation
    }
}

@MainActor
internal final class PTLayoutTransaction {
    let owner: PTLayoutReference
    let operation: PTLayoutOperation
    let groupID: String?
    let fileID: String
    let line: UInt
    let allowsImplicitMake: Bool
    var drafts: [PTLayoutDraft] = []
    private var handles: [PTLayoutConstraint] = []

    init(owner: PTLayoutReference,
         operation: PTLayoutOperation,
         groupID: String?,
         fileID: String,
         line: UInt,
         allowsImplicitMake: Bool = false) {
        self.owner = owner
        self.operation = operation
        self.groupID = groupID
        self.fileID = fileID
        self.line = line
        self.allowsImplicitMake = allowsImplicitMake
    }

    func group(_ attributes: PTLayoutAttribute...) -> PTLayoutAnchorGroup {
        PTLayoutAnchorGroup(attributes.map { PTLayoutAnchor(reference: owner, attribute: $0) }, transaction: self)
    }

    func add(_ firstGroup: PTLayoutAnchorGroup,
             target: PTLayoutTarget,
             relation: PTLayoutRelation) -> PTLayoutRelationMaker {
        var ids: [Int] = []
        if case let .anchor(targetAnchor) = target, targetAnchor.attribute != firstGroup.anchors.first?.attribute,
           firstGroup.anchors.count == 1 {
            // The target anchor carries its own attribute; this is a valid explicit anchor relation.
        }
        for first in firstGroup.anchors {
            let actualTarget: PTLayoutTarget
            if case .anchor = target,
               firstGroup.anchors.count > 1 {
                actualTarget = .invalid("单个目标锚点不能映射多个起点锚点")
            } else {
                actualTarget = target
            }
            drafts.append(PTLayoutDraft(first: first, target: actualTarget, relation: relation))
            ids.append(drafts.count - 1)
        }
        return PTLayoutRelationMaker(transaction: self, draftIDs: ids)
    }

    func update(draftIDs: [Int], _ body: (PTLayoutDraft) -> Void) {
        draftIDs.forEach { index in
            guard drafts.indices.contains(index) else { return }
            body(drafts[index])
        }
    }

    func register(handle: PTLayoutConstraint, draftIDs: [Int]) {
        handles.append(handle)
        handle.attach(drafts: draftIDs.compactMap { drafts.indices.contains($0) ? drafts[$0] : nil })
    }

    func allHandles() -> [PTLayoutConstraint] {
        handles
    }
}

@MainActor
public final class PTLayoutConstraint {
    private(set) public var identifier: String?
    private(set) public var isInvalidated = false
    fileprivate var owner: PTLayoutReference?
    fileprivate weak var transaction: PTLayoutTransaction?
    fileprivate var entries: [PTLayoutEntry] = []
    fileprivate var drafts: [PTLayoutDraft] = []
    fileprivate var draftIDs: [Int] = []

    fileprivate init(owner: PTLayoutReference?,
                     draftIDs: [Int],
                     transaction: PTLayoutTransaction?) {
        self.owner = owner
        self.draftIDs = draftIDs
        self.transaction = transaction
    }

    public var isActive: Bool {
        !entries.isEmpty && entries.allSatisfy { $0.native.isActive }
    }

    public var nativeConstraints: [NSLayoutConstraint] {
        entries.map(\.native)
    }

    public func activate() -> PTLayoutResult {
        PTLayoutEngine.activate(self)
    }

    public func deactivate() {
        guard !entries.isEmpty else { return }
        NSLayoutConstraint.deactivate(entries.map(\.native))
    }

    @discardableResult
    public func update(offset: CGFloat) -> PTLayoutResult {
        PTLayoutEngine.update(self, constants: entries.map { _ in offset }, inset: nil)
    }

    @discardableResult
    public func update(inset: UIEdgeInsets) -> PTLayoutResult {
        PTLayoutEngine.update(self, constants: nil, inset: inset)
    }

    @discardableResult
    public func update(priority: PTLayoutPriority) -> PTLayoutResult {
        PTLayoutEngine.updatePriority(self, priority: priority.rawValue)
    }

    fileprivate func attach(drafts: [PTLayoutDraft]) {
        self.drafts = drafts
        identifier = drafts.compactMap(\.identifier).first
    }

    fileprivate func attach(entries: [PTLayoutEntry]) {
        self.entries = entries
        identifier = entries.compactMap(\.identifier).first ?? identifier
        transaction = nil
        drafts = []
    }

    fileprivate func invalidate() {
        isInvalidated = true
        entries.removeAll()
        drafts.removeAll()
        transaction = nil
    }
}

@MainActor
public final class PTLayoutConstraintGroup {
    public let constraints: [PTLayoutConstraint]
    public private(set) var issue: PTLayoutIssue?

    fileprivate init(constraints: [PTLayoutConstraint], issue: PTLayoutIssue? = nil) {
        self.constraints = constraints
        self.issue = issue
    }

    @discardableResult
    public func activate() -> PTLayoutResult {
        PTLayoutEngine.activate(self)
    }

    public func deactivate() {
        constraints.forEach { $0.deactivate() }
    }

    public var isActive: Bool {
        !constraints.isEmpty && constraints.allSatisfy(\.isActive)
    }
}

@MainActor
internal final class PTLayoutEntry {
    var native: NSLayoutConstraint
    let signature: PTLayoutSignature
    let first: PTLayoutReference
    let second: PTLayoutReference?
    let firstAttribute: PTLayoutAttribute
    let secondAttribute: PTLayoutAttribute
    let relation: PTLayoutRelation
    let multiplier: CGFloat
    var constant: CGFloat
    var priority: Float
    var identifier: String?
    weak var handle: PTLayoutConstraint?

    init(native: NSLayoutConstraint,
         signature: PTLayoutSignature,
         first: PTLayoutReference,
         second: PTLayoutReference?,
         firstAttribute: PTLayoutAttribute,
         secondAttribute: PTLayoutAttribute,
         relation: PTLayoutRelation,
         multiplier: CGFloat,
         constant: CGFloat,
         priority: Float,
         identifier: String?) {
        self.native = native
        self.signature = signature
        self.first = first
        self.second = second
        self.firstAttribute = firstAttribute
        self.secondAttribute = secondAttribute
        self.relation = relation
        self.multiplier = multiplier
        self.constant = constant
        self.priority = priority
        self.identifier = identifier
    }
}

@MainActor
internal struct PTLayoutSignature: Hashable {
    let owner: ObjectIdentifier?
    let first: ObjectIdentifier?
    let firstAttribute: PTLayoutAttribute
    let relation: PTLayoutRelation
    let second: ObjectIdentifier?
    let secondAttribute: PTLayoutAttribute
    let multiplier: CGFloat
}

@MainActor
public struct PTLayoutInspection {
    public let owner: String
    public let constraints: [PTLayoutInspectionConstraint]

    public init(owner: String, constraints: [PTLayoutInspectionConstraint]) {
        self.owner = owner
        self.constraints = constraints
    }

    public func dumpConstraints() -> [[String: String]] {
        constraints.map { constraint in
            [
                "identifier": constraint.identifier ?? "",
                "firstAttribute": constraint.firstAttribute.rawValue,
                "secondAttribute": constraint.secondAttribute.rawValue,
                "relation": constraint.relation.rawValue,
                "constant": String(describing: constraint.constant),
                "priority": String(constraint.priority),
                "active": String(constraint.isActive)
            ]
        }
    }
}

@MainActor
public struct PTLayoutInspectionConstraint {
    public let identifier: String?
    public let firstAttribute: PTLayoutAttribute
    public let secondAttribute: PTLayoutAttribute
    public let relation: PTLayoutRelation
    public let constant: CGFloat
    public let priority: Float
    public let isActive: Bool
}

@MainActor
internal final class PTLayoutConstraintStore {
    weak var view: UIView?
    private var handles: [PTLayoutConstraint] = []
    private var groups: [String: PTLayoutConstraintGroup] = [:]

    init(view: UIView) {
        self.view = view
    }

    func register(_ group: PTLayoutConstraintGroup, named name: String?) {
        for handle in group.constraints where !handles.contains(where: { $0 === handle }) {
            handles.append(handle)
        }
        if let name { groups[name] = group }
        handles = handles.filter { !$0.isInvalidated }
    }

    func remove(_ handle: PTLayoutConstraint) {
        handles.removeAll { $0 === handle || $0.isInvalidated }
        groups = groups.filter { !$0.value.constraints.contains(where: { $0 === handle }) }
        handle.invalidate()
    }

    func handles(for owner: PTLayoutReference) -> [PTLayoutConstraint] {
        handles.filter { $0.owner?.identity == owner.identity && !$0.isInvalidated }
    }

    func allHandles() -> [PTLayoutConstraint] {
        handles.filter { !$0.isInvalidated }
    }

    func namedGroup(_ name: String) -> PTLayoutConstraintGroup? {
        groups[name]
    }

    func inspection(for owner: PTLayoutReference) -> PTLayoutInspection {
        let constraints = handles(for: owner).flatMap { handle in
            handle.entries.map {
                PTLayoutInspectionConstraint(identifier: $0.identifier,
                                             firstAttribute: $0.firstAttribute,
                                             secondAttribute: $0.secondAttribute,
                                             relation: $0.relation,
                                             constant: $0.constant,
                                             priority: $0.priority,
                                             isActive: $0.native.isActive)
            }
        }
        return PTLayoutInspection(owner: owner.displayName, constraints: constraints)
    }
}

@MainActor
internal enum PTLayoutStoreRegistry {
    private static let registry = NSMapTable<UIView, PTLayoutConstraintStore>(keyOptions: .weakMemory,
                                                                                valueOptions: .strongMemory)

    static func store(for reference: PTLayoutReference) -> PTLayoutConstraintStore? {
        guard let view = reference.view ?? reference.guide?.owningView else { return nil }
        if let existing = registry.object(forKey: view) { return existing }
        let created = PTLayoutConstraintStore(view: view)
        registry.setObject(created, forKey: view)
        return created
    }
}

@MainActor
internal enum PTLayoutEngine {
    struct Prepared {
        let result: PTLayoutResult
        let group: PTLayoutConstraintGroup
    }

    struct Resolved {
        let draftID: Int
        let draft: PTLayoutDraft
        let first: PTLayoutReference
        let second: PTLayoutReference?
        let secondAttribute: PTLayoutAttribute
        let native: NSLayoutConstraint
        let signature: PTLayoutSignature
    }

    static func prepare(_ transaction: PTLayoutTransaction) -> Prepared {
        PTLayoutProfiler.record(operation: transaction.operation,
                                count: transaction.drafts.count)
        guard !transaction.drafts.isEmpty else {
            return Prepared(result: .success(PTLayoutChanges(count: 0)),
                            group: PTLayoutConstraintGroup(constraints: []))
        }
        guard let resolved = resolve(transaction.drafts,
                                     owner: transaction.owner,
                                     fileID: transaction.fileID,
                                     line: transaction.line,
                                     groupID: transaction.groupID) else {
            let issue = lastIssue(for: transaction.owner)
                ?? PTLayoutIssue(code: .invalidConstraint,
                                 owner: transaction.owner.displayName,
                                 anchor: "transaction",
                                 fileID: transaction.fileID,
                                 line: transaction.line,
                                 reason: "布局事务校验失败。",
                                 suggestion: "检查约束的目标、层级和属性组合。")
            let group = PTLayoutConstraintGroup(constraints: [], issue: issue)
            return Prepared(result: .failure(issue), group: group)
        }

        let resolvedByID = Dictionary(uniqueKeysWithValues: resolved.map { ($0.draftID, $0) })
        let handles = transaction.allHandles()
        var resultHandles: [PTLayoutConstraint] = []
        var claimedDraftIDs = Set<Int>()
        for handle in handles {
            let handleResolved = handle.draftIDs.compactMap { resolvedByID[$0] }
            guard handleResolved.count == handle.draftIDs.count else {
                let issue = PTLayoutIssue(code: .invalidConstraint,
                                          owner: transaction.owner.displayName,
                                          anchor: "handle",
                                          fileID: transaction.fileID,
                                          line: transaction.line,
                                          reason: "布局句柄引用了不存在的 draft ID。",
                                          suggestion: "不要跨事务复用 PTLayoutConstraint 句柄。")
                PTLayoutDiagnostics.report(issue, ownerView: transaction.owner.owningView)
                let group = PTLayoutConstraintGroup(constraints: [], issue: issue)
                return Prepared(result: .failure(issue), group: group)
            }
            handle.attach(entries: handleResolved.map { entry(from: $0, handle: handle) })
            claimedDraftIDs.formUnion(handle.draftIDs)
            resultHandles.append(handle)
        }
        for item in resolved where !claimedDraftIDs.contains(item.draftID) {
            let handle = PTLayoutConstraint(owner: transaction.owner,
                                            draftIDs: [item.draftID],
                                            transaction: nil)
            handle.attach(entries: [entry(from: item, handle: handle)])
            resultHandles.append(handle)
        }
        let group = PTLayoutConstraintGroup(constraints: resultHandles)
        return Prepared(result: .success(PTLayoutChanges(count: resolved.count)), group: group)
    }

    static func activate(_ group: PTLayoutConstraintGroup) -> PTLayoutResult {
        activateAtomically([group])
    }

    // English: Validate all groups first, then install and register them as one transaction.
    // Español: Valida todos los grupos primero y después los instala y registra como una sola transacción.
    // 中文：先统一校验所有约束组，再作为一个事务安装和登记。
    static func activateAtomically(_ groups: [PTLayoutConstraintGroup],
                                   registering: Bool = true) -> PTLayoutResult {
        if let issue = groups.compactMap(\.issue).first {
            return .failure(issue)
        }
        let activeGroups = groups.filter { !$0.constraints.isEmpty }
        guard !activeGroups.isEmpty else { return .success(PTLayoutChanges(count: 0)) }
        let allEntries = activeGroups.flatMap(\.constraints).flatMap(\.entries)
        guard let firstGroup = activeGroups.first,
              let owner = firstGroup.constraints.first?.owner else {
            return .success(PTLayoutChanges(count: 0))
        }
        guard allEntries.allSatisfy({ entry in
            entry.first.object != nil && (entry.second == nil || entry.second?.object != nil) &&
                hierarchyIsValid(first: entry.first, second: entry.second)
        }) else {
            let issue = PTLayoutIssue(code: .hierarchyChanged,
                                      owner: owner.displayName,
                                      anchor: "activate",
                                      reason: "prepare 之后视图层级发生变化，约束未激活。",
                                      suggestion: "重新调用 ptLayout.makeConstraints 或重新 prepare。")
            PTLayoutDiagnostics.report(issue, ownerView: owner.owningView)
            return .failure(issue)
        }
        prepareManagedViews(allEntries)
        let nativeConstraints = allEntries.map(\.native)
        NSLayoutConstraint.activate(nativeConstraints)
        guard nativeConstraints.allSatisfy(\.isActive) else {
            NSLayoutConstraint.deactivate(nativeConstraints)
            let issue = PTLayoutIssue(code: .invalidConstraint,
                                      owner: owner.displayName,
                                      anchor: "activate",
                                      reason: "原生约束未完整安装。",
                                      suggestion: "检查约束层级和布局所有权。")
            PTLayoutDiagnostics.report(issue, ownerView: owner.owningView)
            return .failure(issue)
        }
        if registering {
            // English: Register prepared groups only after atomic activation succeeds.
            // Español: Registra los grupos preparados solo después de activar atómicamente con éxito.
            // 中文：只有原子激活成功后才登记 prepare 产生的约束组。
            for group in activeGroups {
                if let groupOwner = group.constraints.first?.owner {
                    PTLayoutStoreRegistry.store(for: groupOwner)?.register(group, named: nil)
                }
            }
        }
        PTLayoutProfiler.recordInstalled(count: nativeConstraints.count)
        return .success(PTLayoutChanges(count: nativeConstraints.count))
    }

    static func activate(_ handle: PTLayoutConstraint) -> PTLayoutResult {
        activate(PTLayoutConstraintGroup(constraints: [handle]))
    }

    static func update(_ transaction: PTLayoutTransaction) -> PTLayoutResult {
        guard !transaction.drafts.isEmpty else { return .success(PTLayoutChanges(count: 0)) }
        guard let resolved = resolve(transaction.drafts,
                                     owner: transaction.owner,
                                     fileID: transaction.fileID,
                                     line: transaction.line,
                                     groupID: transaction.groupID) else {
            return .failure(lastIssue(for: transaction.owner)
                ?? PTLayoutIssue(code: .invalidConstraint,
                                 owner: transaction.owner.displayName,
                                 anchor: "update",
                                 fileID: transaction.fileID,
                                 line: transaction.line,
                                 reason: "更新事务校验失败。",
                                 suggestion: "请使用 remakeConstraints 修复结构变化。"))
        }
        guard let store = PTLayoutStoreRegistry.store(for: transaction.owner) else {
            let issue = PTLayoutIssue(code: .updateNotFound,
                                      owner: transaction.owner.displayName,
                                      anchor: "update",
                                      fileID: transaction.fileID,
                                      line: transaction.line,
                                      reason: "没有可更新的 PTLayout 约束。",
                                      suggestion: "先调用 makeConstraints，或明确调用 upsertConstraints。")
            PTLayoutDiagnostics.report(issue, ownerView: transaction.owner.owningView)
            return .failure(issue)
        }
        if store.allHandles().isEmpty {
            guard transaction.allowsImplicitMake else {
                let issue = PTLayoutIssue(code: .updateNotFound,
                                          owner: transaction.owner.displayName,
                                          anchor: "update",
                                          fileID: transaction.fileID,
                                          line: transaction.line,
                                          reason: "没有可更新的 PTLayout 约束。",
                                          suggestion: "先调用 makeConstraints，或使用 updateConstraints 的兼容首次创建语义。")
                PTLayoutDiagnostics.report(issue, ownerView: transaction.owner.owningView)
                return .failure(issue)
            }
            let prepared = prepare(transaction)
            guard prepared.result.isSuccess else { return prepared.result }
            return activate(prepared.group)
        }
        let matches = findMatches(resolved, store: store)
        if let failure = matches.failure {
            PTLayoutDiagnostics.report(failure, ownerView: transaction.owner.owningView)
            return .failure(failure)
        }
        let updates = matches.entries
        let needsRebuild = updates.enumerated().contains { index, entry in
            entry.priority != resolved[index].draft.priority &&
                ((entry.priority >= UILayoutPriority.required.rawValue) !=
                    (resolved[index].draft.priority >= UILayoutPriority.required.rawValue))
        }
        if needsRebuild {
            let replacements = updates.enumerated().map { index, entry in
                makeNative(from: resolved[index], priority: resolved[index].draft.priority)
            }
            NSLayoutConstraint.deactivate(updates.map(\.native))
            NSLayoutConstraint.activate(replacements)
            for (index, entry) in updates.enumerated() {
                entry.native = replacements[index]
                entry.constant = resolved[index].native.constant
                entry.priority = resolved[index].draft.priority
            }
        } else {
            for (index, entry) in updates.enumerated() {
                let canonicalConstant = resolved[index].native.constant
                entry.native.constant = canonicalConstant
                if entry.priority != resolved[index].draft.priority {
                    entry.native.priority = UILayoutPriority(rawValue: resolved[index].draft.priority)
                    entry.priority = resolved[index].draft.priority
                }
                entry.constant = canonicalConstant
            }
        }
        return .success(PTLayoutChanges(count: updates.count))
    }

    static func update(_ handle: PTLayoutConstraint,
                       constants: [CGFloat]?,
                       inset: UIEdgeInsets?) -> PTLayoutResult {
        guard !handle.entries.isEmpty, !handle.isInvalidated else {
            let issue = PTLayoutIssue(code: .updateNotFound,
                                      owner: handle.owner?.displayName ?? "released-object",
                                      anchor: "handle",
                                      reason: "布局句柄已经失效，无法更新。",
                                      suggestion: "重新安装新的约束并保存新的 PTLayoutConstraint。")
            PTLayoutDiagnostics.report(issue, ownerView: handle.owner?.owningView)
            return .failure(issue)
        }
        guard handle.entries.allSatisfy({ hierarchyIsValid(first: $0.first, second: $0.second) }) else {
            let issue = PTLayoutIssue(code: .hierarchyChanged,
                                      owner: handle.owner?.displayName ?? "released-object",
                                      anchor: "handle",
                                      reason: "布局句柄关联的层级已经变化。",
                                      suggestion: "重新构建当前视图的约束。")
            PTLayoutDiagnostics.report(issue, ownerView: handle.owner?.owningView)
            return .failure(issue)
        }
        for (index, entry) in handle.entries.enumerated() {
            let value = constants?[safe: index]
                ?? inset.map { signedInset($0, for: entry.firstAttribute) }
                ?? entry.constant
            entry.native.constant = value
            entry.constant = value
        }
        return .success(PTLayoutChanges(count: handle.entries.count))
    }

    static func updatePriority(_ handle: PTLayoutConstraint, priority: Float) -> PTLayoutResult {
        guard priority.isFinite, priority >= 1, priority <= 1000 else {
            let issue = PTLayoutIssue(code: .invalidConstraint,
                                      owner: handle.owner?.displayName ?? "released-object",
                                      anchor: "priority",
                                      reason: "优先级必须在 1...1000 范围内。",
                                      suggestion: "使用 UILayoutPriority.required/high/low 或合法数值。")
            PTLayoutDiagnostics.report(issue, ownerView: handle.owner?.owningView)
            return .failure(issue)
        }
        let natives = handle.entries.map { entry in
            makeNative(entry: entry, priority: priority)
        }
        NSLayoutConstraint.deactivate(handle.entries.map(\.native))
        NSLayoutConstraint.activate(natives)
        for (index, entry) in handle.entries.enumerated() {
            entry.native = natives[index]
            entry.priority = priority
        }
        return .success(PTLayoutChanges(count: handle.entries.count))
    }

    static func signedInset(_ value: CGFloat, for attribute: PTLayoutAttribute) -> CGFloat {
        switch attribute {
        case .bottom, .trailing, .right: return -value
        default: return value
        }
    }

    static func signedInset(_ value: UIEdgeInsets, for attribute: PTLayoutAttribute) -> CGFloat {
        switch attribute {
        case .top: return value.top
        case .bottom: return -value.bottom
        case .leading: return value.left
        case .trailing: return -value.right
        case .left: return value.left
        case .right: return -value.right
        default: return 0
        }
    }

    static func signedDirectionalInset(_ value: NSDirectionalEdgeInsets,
                                       for attribute: PTLayoutAttribute) -> CGFloat {
        switch attribute {
        case .top: return value.top
        case .bottom: return -value.bottom
        case .leading: return value.leading
        case .trailing: return -value.trailing
        default: return 0
        }
    }

    private static func resolve(_ drafts: [PTLayoutDraft],
                                owner: PTLayoutReference,
                                fileID: String,
                                line: UInt,
                                groupID: String?) -> [Resolved]? {
        var resolved: [Resolved] = []
        for (draftID, draft) in drafts.enumerated() {
            guard draft.first.reference.object != nil else {
                return fail(code: .hierarchyChanged,
                            draft: draft,
                            owner: owner,
                            fileID: fileID,
                            line: line,
                            groupID: groupID,
                            reason: "约束起点对象已经释放。",
                            suggestion: "不要在释放后的 View 或 LayoutGuide 上更新约束。")
            }
            guard draft.priority.isFinite, draft.priority >= 1, draft.priority <= 1000 else {
                return fail(code: .invalidConstraint,
                            draft: draft,
                            owner: owner,
                            fileID: fileID,
                            line: line,
                            groupID: groupID,
                            reason: "优先级必须在 1...1000 范围内。",
                            suggestion: "使用合法 UILayoutPriority。")
            }
            guard draft.multiplier.isFinite, draft.multiplier > 0 else {
                return fail(code: .invalidMultiplier,
                            draft: draft,
                            owner: owner,
                            fileID: fileID,
                            line: line,
                            groupID: groupID,
                            reason: "乘数必须是有限且大于零的数值。",
                            suggestion: "不要除以零，比例变化请使用 remakeConstraints。")
            }

            let target = resolveTarget(draft, owner: owner)
            guard let target else {
                return fail(code: .invalidConstraint,
                            draft: draft,
                            owner: owner,
                            fileID: fileID,
                            line: line,
                            groupID: groupID,
                            reason: "无法解析约束目标。",
                            suggestion: "检查目标 View、LayoutGuide 和属性组合。")
            }
            if target.requiresMissingSuperview {
                return fail(code: .missingSuperview,
                            draft: draft,
                            owner: owner,
                            fileID: fileID,
                            line: line,
                            groupID: groupID,
                            reason: "\(owner.displayName) 尚未加入父视图，无法解析位置约束。",
                            suggestion: "先执行 container.addSubview(view)，再调用 makeConstraints。")
            }
            if target.orphanGuide {
                return fail(code: .orphanLayoutGuide,
                            draft: draft,
                            owner: owner,
                            fileID: fileID,
                            line: line,
                            groupID: groupID,
                            reason: "LayoutGuide 没有有效的 owningView。",
                            suggestion: "把 LayoutGuide 添加到有效容器后再激活。")
            }
            guard draft.constant.isFinite, target.constant.isFinite else {
                return fail(code: .invalidConstraint,
                            draft: draft,
                            owner: owner,
                            fileID: fileID,
                            line: line,
                            groupID: groupID,
                            reason: "约束常量必须是有限数值。",
                            suggestion: "检查 offset、inset、尺寸和浮点计算结果。")
            }
            guard isValidAttributePair(first: draft.first.attribute,
                                       second: target.secondAttribute,
                                       hasSecond: target.reference != nil) else {
                return fail(code: .invalidConstraint,
                            draft: draft,
                            owner: owner,
                            fileID: fileID,
                            line: line,
                            groupID: groupID,
                            reason: "约束两端的 NSLayoutConstraint 属性组合不兼容。",
                            suggestion: "仅连接同轴位置、同维度尺寸或对应 baseline 属性。")
            }
            guard draft.multiplier == 1 || (target.reference != nil && isSize(draft.first.attribute) && isSize(target.secondAttribute)) else {
                return fail(code: .invalidMultiplier,
                            draft: draft,
                            owner: owner,
                            fileID: fileID,
                            line: line,
                            groupID: groupID,
                            reason: "只有 width/height 关系允许使用 multiplier。",
                            suggestion: "使用 width/height 比例或 aspectRatio。")
            }
            if let second = target.reference,
               !hierarchyIsValid(first: draft.first.reference, second: second) {
                return fail(code: .noCommonAncestor,
                            draft: draft,
                            owner: owner,
                            fileID: fileID,
                            line: line,
                            groupID: groupID,
                            reason: "约束两端没有共同的 View 层级。",
                            suggestion: "将两个对象放入同一合法层级，或更换关联目标。")
            }
            let native = makeNative(draft: draft,
                                    first: draft.first.reference,
                                    second: target.reference,
                                    secondAttribute: target.secondAttribute,
                                    constant: target.constant)
            native.identifier = draft.identifier
            let signature = PTLayoutSignature(owner: owner.identity,
                                              first: draft.first.reference.identity,
                                              firstAttribute: draft.first.attribute,
                                              relation: draft.relation,
                                              second: target.reference?.identity,
                                              secondAttribute: target.secondAttribute,
                                              multiplier: draft.multiplier)
            resolved.append(Resolved(draftID: draftID,
                                     draft: draft,
                                     first: draft.first.reference,
                                     second: target.reference,
                                     secondAttribute: target.secondAttribute,
                                     native: native,
                                     signature: signature))
        }
        if hasDuplicateSignatures(resolved) {
            let draft = drafts[0]
            return fail(code: .ambiguousMatch,
                        draft: draft,
                        owner: owner,
                        fileID: fileID,
                        line: line,
                        groupID: groupID,
                        reason: "同一事务内出现重复约束签名。",
                        suggestion: "使用不同的约束组或明确的 identifier。")
        }
        return resolved
    }

    private struct TargetResolution {
        let reference: PTLayoutReference?
        let secondAttribute: PTLayoutAttribute
        let constant: CGFloat
        let requiresMissingSuperview: Bool
        let orphanGuide: Bool
    }

    private static func resolveTarget(_ draft: PTLayoutDraft,
                                      owner: PTLayoutReference) -> TargetResolution? {
        switch draft.target {
        case .invalid:
            return nil
        case .superview:
            guard let parent = owner.view?.superview ?? owner.guide?.owningView else {
                return TargetResolution(reference: nil,
                                        secondAttribute: draft.first.attribute,
                                        constant: draft.constant,
                                        requiresMissingSuperview: true,
                                        orphanGuide: false)
            }
            return TargetResolution(reference: PTLayoutReference(view: parent),
                                    secondAttribute: draft.first.attribute,
                                    constant: draft.constant,
                                    requiresMissingSuperview: false,
                                    orphanGuide: false)
        case let .reference(reference):
            guard reference.object != nil else { return nil }
            guard reference.owningView != nil || reference.view != nil else {
                return TargetResolution(reference: nil,
                                        secondAttribute: draft.first.attribute,
                                        constant: draft.constant,
                                        requiresMissingSuperview: false,
                                        orphanGuide: true)
            }
            return TargetResolution(reference: reference,
                                    secondAttribute: draft.first.attribute,
                                    constant: draft.constant,
                                    requiresMissingSuperview: false,
                                    orphanGuide: false)
        case let .anchor(anchor):
            guard anchor.reference.object != nil else { return nil }
            if anchor.reference.guide != nil && anchor.reference.owningView == nil {
                return TargetResolution(reference: nil,
                                        secondAttribute: anchor.attribute,
                                        constant: draft.constant,
                                        requiresMissingSuperview: false,
                                        orphanGuide: true)
            }
            return TargetResolution(reference: anchor.reference,
                                    secondAttribute: anchor.attribute,
                                    constant: draft.constant,
                                    requiresMissingSuperview: false,
                                    orphanGuide: false)
        case let .number(value):
            if isSize(draft.first.attribute) {
                return TargetResolution(reference: nil,
                                        secondAttribute: draft.first.attribute,
                                        constant: value + draft.constant,
                                        requiresMissingSuperview: false,
                                        orphanGuide: false)
            }
            guard let parent = owner.view?.superview ?? owner.guide?.owningView else {
                return TargetResolution(reference: nil,
                                        secondAttribute: draft.first.attribute,
                                        constant: value + draft.constant,
                                        requiresMissingSuperview: true,
                                        orphanGuide: false)
            }
            return TargetResolution(reference: PTLayoutReference(view: parent),
                                    secondAttribute: draft.first.attribute,
                                    constant: value + draft.constant,
                                    requiresMissingSuperview: false,
                                    orphanGuide: false)
        case let .size(value):
            guard isSize(draft.first.attribute) else { return nil }
            let constant = draft.first.attribute == .width ? value.width : value.height
            return TargetResolution(reference: nil,
                                    secondAttribute: draft.first.attribute,
                                    constant: constant + draft.constant,
                                    requiresMissingSuperview: false,
                                    orphanGuide: false)
        case let .insets(value):
            guard let parent = owner.view?.superview ?? owner.guide?.owningView else {
                return TargetResolution(reference: nil,
                                        secondAttribute: draft.first.attribute,
                                        constant: signedInset(value, for: draft.first.attribute),
                                        requiresMissingSuperview: true,
                                        orphanGuide: false)
            }
            return TargetResolution(reference: PTLayoutReference(view: parent),
                                    secondAttribute: draft.first.attribute,
                                    constant: signedInset(value, for: draft.first.attribute),
                                    requiresMissingSuperview: false,
                                    orphanGuide: false)
        }
    }

    private static func makeNative(draft: PTLayoutDraft,
                                   first: PTLayoutReference,
                                   second: PTLayoutReference?,
                                   secondAttribute: PTLayoutAttribute,
                                   constant: CGFloat) -> NSLayoutConstraint {
        let native = NSLayoutConstraint(item: first.object as Any,
                                         attribute: nativeAttribute(draft.first.attribute),
                                         relatedBy: nativeRelation(draft.relation),
                                         toItem: second?.object,
                                         attribute: second.map { _ in nativeAttribute(secondAttribute) } ?? .notAnAttribute,
                                         multiplier: draft.multiplier,
                                         constant: constant)
        native.priority = UILayoutPriority(rawValue: draft.priority)
        return native
    }

    private static func makeNative(from resolved: Resolved,
                                   priority: Float,
                                   constant: CGFloat? = nil) -> NSLayoutConstraint {
        let draft = resolved.draft
        let native = NSLayoutConstraint(item: resolved.first.object as Any,
                                         attribute: nativeAttribute(draft.first.attribute),
                                         relatedBy: nativeRelation(draft.relation),
                                         toItem: resolved.second?.object,
                                         attribute: resolved.second.map { _ in nativeAttribute(resolved.secondAttribute) } ?? .notAnAttribute,
                                         multiplier: draft.multiplier,
                                         constant: constant ?? resolved.native.constant)
        native.priority = UILayoutPriority(rawValue: priority)
        native.identifier = draft.identifier
        return native
    }

    private static func makeNative(entry: PTLayoutEntry,
                                   priority: Float) -> NSLayoutConstraint {
        let native = NSLayoutConstraint(item: entry.first.object as Any,
                                         attribute: nativeAttribute(entry.firstAttribute),
                                         relatedBy: nativeRelation(entry.relation),
                                         toItem: entry.second?.object,
                                         attribute: entry.second.map { _ in nativeAttribute(entry.secondAttribute) } ?? .notAnAttribute,
                                         multiplier: entry.multiplier,
                                         constant: entry.constant)
        native.priority = UILayoutPriority(rawValue: priority)
        native.identifier = entry.identifier
        return native
    }

    private static func entry(from resolved: Resolved, handle: PTLayoutConstraint) -> PTLayoutEntry {
        let entry = PTLayoutEntry(native: resolved.native,
                                  signature: resolved.signature,
                                  first: resolved.first,
                                  second: resolved.second,
                                  firstAttribute: resolved.draft.first.attribute,
                                  secondAttribute: resolved.secondAttribute,
                                  relation: resolved.draft.relation,
                                  multiplier: resolved.draft.multiplier,
                                  constant: resolved.native.constant,
                                  priority: resolved.draft.priority,
                                  identifier: resolved.draft.identifier)
        entry.handle = handle
        return entry
    }

    private static func findMatches(_ resolved: [Resolved],
                                    store: PTLayoutConstraintStore) -> (entries: [PTLayoutEntry], failure: PTLayoutIssue?) {
        var result: [PTLayoutEntry] = []
        for item in resolved {
            let signatureCandidates = store.allHandles().flatMap(\.entries).filter { $0.signature == item.signature }
            let candidates = signatureCandidates.filter { $0.identifier == item.draft.identifier }
            guard candidates.count == 1, let candidate = candidates.first else {
                let code: PTLayoutIssueCode = candidates.isEmpty ? .updateNotFound : .ambiguousMatch
                let issue = PTLayoutIssue(code: code,
                                          owner: item.first.displayName,
                                          anchor: item.draft.first.attribute.rawValue,
                                          reason: candidates.isEmpty ? "没有找到相同签名和 identifier 的 PTLayout 约束。" : "找到多个相同签名和 identifier 的 PTLayout 约束。",
                                          suggestion: candidates.isEmpty ? "使用 remakeConstraints 或明确调用 upsertConstraints。" : "使用 identifier 或命名约束组消除歧义。")
                return ([], issue)
            }
            result.append(candidate)
        }
        return (result, nil)
    }

    private static func hasDuplicateSignatures(_ resolved: [Resolved]) -> Bool {
        struct Key: Hashable {
            let signature: PTLayoutSignature
            let identifier: String?
        }
        var seen = Set<Key>()
        for item in resolved where !seen.insert(Key(signature: item.signature,
                                                    identifier: item.draft.identifier)).inserted { return true }
        return false
    }

    private static func isValidAttributePair(first: PTLayoutAttribute,
                                             second: PTLayoutAttribute,
                                             hasSecond: Bool) -> Bool {
        guard hasSecond else { return isSize(first) }
        if isSize(first) || isSize(second) {
            return isSize(first) && isSize(second)
        }
        if isBaseline(first) || isBaseline(second) {
            return isBaseline(first) && isBaseline(second)
        }
        return isHorizontal(first) && isHorizontal(second)
            || isVertical(first) && isVertical(second)
    }

    private static func isHorizontal(_ attribute: PTLayoutAttribute) -> Bool {
        switch attribute {
        case .leading, .trailing, .left, .right, .centerX: return true
        default: return false
        }
    }

    private static func isVertical(_ attribute: PTLayoutAttribute) -> Bool {
        switch attribute {
        case .top, .bottom, .centerY: return true
        default: return false
        }
    }

    private static func isBaseline(_ attribute: PTLayoutAttribute) -> Bool {
        attribute == .firstBaseline || attribute == .lastBaseline
    }

    private static func prepareManagedViews(_ entries: [PTLayoutEntry]) {
        guard PTLayoutConfiguration.autoresizingMaskPolicy == .automaticForManagedViews else { return }
        var seen = Set<ObjectIdentifier>()
        for entry in entries {
            guard let view = entry.first.view,
                  seen.insert(ObjectIdentifier(view)).inserted else { continue }
            view.translatesAutoresizingMaskIntoConstraints = false
        }
    }

    private static func fail(code: PTLayoutIssueCode,
                             draft: PTLayoutDraft,
                             owner: PTLayoutReference,
                             fileID: String,
                             line: UInt,
                             groupID: String?,
                             reason: String,
                             suggestion: String) -> [Resolved]? {
        let issue = PTLayoutIssue(code: code,
                                  owner: owner.displayName,
                                  anchor: draft.first.attribute.rawValue,
                                  relatedTarget: targetName(draft.target),
                                  fileID: fileID,
                                  line: line,
                                  groupID: groupID,
                                  reason: reason,
                                  suggestion: suggestion)
        PTLayoutDiagnostics.report(issue, ownerView: owner.owningView)
        return nil
    }

    private static func lastIssue(for owner: PTLayoutReference) -> PTLayoutIssue? {
        owner.owningView.flatMap { PTLayoutDiagnostics.latest(for: $0) }
    }

    private static func targetName(_ target: PTLayoutTarget) -> String? {
        switch target {
        case .superview: return "superview"
        case let .reference(reference): return reference.displayName
        case let .anchor(anchor): return anchor.reference.displayName + "." + anchor.attribute.rawValue
        case .number: return "constant"
        case .size: return "size"
        case .insets: return "insets"
        case let .invalid(reason): return reason
        }
    }

    private static func isSize(_ attribute: PTLayoutAttribute) -> Bool {
        attribute == .width || attribute == .height
    }

    private static func nativeAttribute(_ attribute: PTLayoutAttribute) -> NSLayoutConstraint.Attribute {
        switch attribute {
        case .top: return .top
        case .bottom: return .bottom
        case .leading: return .leading
        case .trailing: return .trailing
        case .left: return .left
        case .right: return .right
        case .centerX: return .centerX
        case .centerY: return .centerY
        case .width: return .width
        case .height: return .height
        case .firstBaseline: return .firstBaseline
        case .lastBaseline: return .lastBaseline
        }
    }

    private static func nativeRelation(_ relation: PTLayoutRelation) -> NSLayoutConstraint.Relation {
        switch relation {
        case .equal: return .equal
        case .lessThanOrEqual: return .lessThanOrEqual
        case .greaterThanOrEqual: return .greaterThanOrEqual
        }
    }

    private static func commonAncestor(_ lhs: UIView, _ rhs: UIView) -> UIView? {
        var ancestors = Set<ObjectIdentifier>()
        var current: UIView? = lhs
        while let view = current {
            ancestors.insert(ObjectIdentifier(view))
            current = view.superview
        }
        current = rhs
        while let view = current {
            if ancestors.contains(ObjectIdentifier(view)) { return view }
            current = view.superview
        }
        return nil
    }

    private static func hierarchyIsValid(first: PTLayoutReference,
                                         second: PTLayoutReference?) -> Bool {
        guard first.object != nil else { return false }
        guard let second else { return true }
        guard second.object != nil,
              let firstView = first.owningView,
              let secondView = second.owningView else { return false }
        return commonAncestor(firstView, secondView) != nil
    }
}

@MainActor
private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#endif
