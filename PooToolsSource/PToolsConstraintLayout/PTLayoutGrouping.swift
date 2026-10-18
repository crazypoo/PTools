// English: Batch layout helpers use the native PTLayout engine without owning StackView internals.
// Español: Los helpers por lotes usan el motor PTLayout nativo sin adueñarse de la lógica interna de StackView.
// 中文：批量布局辅助使用原生 PTLayout 引擎，不接管 StackView 内部布局。

#if canImport(UIKit)
import UIKit

@MainActor
public enum PTLayoutAxis: Sendable {
    case horizontal
    case vertical
}

@MainActor
public enum PTLayoutCrossAxisAlignment: Sendable {
    case fill
    case center
    case leading
    case trailing
}

@MainActor
public struct PTLayoutGroupNamespace {
    public let views: [UIView]

    public init(views: [UIView]) {
        self.views = views
    }

    @discardableResult
    public func distribute(axis: PTLayoutAxis,
                           spacing: CGFloat = 0,
                           alignment: PTLayoutCrossAxisAlignment = .fill,
                           file: StaticString = #fileID,
                           line: UInt = #line) -> PTLayoutResult {
        guard views.count > 1 else { return .success(PTLayoutChanges(count: 0)) }
        guard let parent = commonSuperview() else {
            let owner = views.first.map { String(describing: type(of: $0)) } ?? "UIView"
            let issue = PTLayoutIssue(code: .noCommonAncestor,
                                      owner: owner,
                                      anchor: "ptLayoutGroup",
                                      fileID: String(describing: file),
                                      line: line,
                                      reason: "批量布局的 View 没有共同父视图。",
                                      suggestion: "把所有 View 放入同一容器后再分布。")
            PTLayoutDiagnostics.onFailure?(issue)
            return .failure(issue)
        }

        var preparedGroups: [PTLayoutConstraintGroup] = []
        for (index, view) in views.enumerated() {
            let group = view.ptLayout.prepareConstraints(file: file, line: line) { make in
                switch axis {
                case .horizontal:
                    if index == 0 { make.leading.equalTo(parent) }
                    if index > 0 { make.leading.equalTo(views[index - 1].ptLayout.trailing).offset(spacing) }
                    if index == views.count - 1 { make.trailing.equalTo(parent) }
                    if index > 0 { make.width.equalTo(views[0]) }
                    applyCrossAxis(make: make, axis: axis, alignment: alignment, parent: parent)
                case .vertical:
                    if index == 0 { make.top.equalTo(parent) }
                    if index > 0 { make.top.equalTo(views[index - 1].ptLayout.bottom).offset(spacing) }
                    if index == views.count - 1 { make.bottom.equalTo(parent) }
                    if index > 0 { make.height.equalTo(views[0]) }
                    applyCrossAxis(make: make, axis: axis, alignment: alignment, parent: parent)
                }
            }
            if let issue = group.issue {
                return .failure(issue)
            }
            preparedGroups.append(group)
        }
        // English: All groups are validated before any group is activated, preventing partial commits.
        // Español: Todos los grupos se validan antes de activar uno, evitando commits parciales.
        // 中文：先完成全部约束组校验，再统一激活，避免部分提交。
        return PTLayoutConstraintGroup.activateAtomically(preparedGroups)
    }

    @discardableResult
    public func equalSizes(file: StaticString = #fileID,
                           line: UInt = #line) -> PTLayoutResult {
        guard let first = views.first, views.count > 1 else {
            return .success(PTLayoutChanges(count: 0))
        }
        var preparedGroups: [PTLayoutConstraintGroup] = []
        for view in views.dropFirst() {
            let group = view.ptLayout.prepareConstraints(file: file, line: line) { make in
                make.width.equalTo(first)
                make.height.equalTo(first)
            }
            if let issue = group.issue { return .failure(issue) }
            preparedGroups.append(group)
        }
        return PTLayoutConstraintGroup.activateAtomically(preparedGroups)
    }

    private func commonSuperview() -> UIView? {
        guard var current = views.first else { return nil }
        for view in views.dropFirst() {
            guard let next = commonAncestor(current, view) else { return nil }
            current = next
        }
        return current
    }

    private func commonAncestor(_ lhs: UIView?, _ rhs: UIView) -> UIView? {
        guard let lhs else { return nil }
        var set = Set<ObjectIdentifier>()
        var cursor: UIView? = lhs
        while let current = cursor {
            set.insert(ObjectIdentifier(current))
            cursor = current.superview
        }
        cursor = rhs
        while let current = cursor {
            if set.contains(ObjectIdentifier(current)) { return current }
            cursor = current.superview
        }
        return nil
    }

    private func applyCrossAxis(make: PTLayoutMaker,
                                axis: PTLayoutAxis,
                                alignment: PTLayoutCrossAxisAlignment,
                                parent: UIView) {
        switch (axis, alignment) {
        case (.horizontal, .fill):
            make.top.bottom.equalTo(parent)
        case (.horizontal, .center):
            make.centerY.equalTo(parent)
        case (.horizontal, .leading):
            make.top.equalTo(parent)
        case (.horizontal, .trailing):
            make.bottom.equalTo(parent)
        case (.vertical, .fill):
            make.leading.trailing.equalTo(parent)
        case (.vertical, .center):
            make.centerX.equalTo(parent)
        case (.vertical, .leading):
            make.leading.equalTo(parent)
        case (.vertical, .trailing):
            make.trailing.equalTo(parent)
        }
    }
}

@MainActor
public extension Array where Element == UIView {
    var ptLayoutGroup: PTLayoutGroupNamespace {
        PTLayoutGroupNamespace(views: self)
    }
}

@MainActor
public enum PTLayoutAnimation {
    public static func perform(duration: TimeInterval,
                               changes: @MainActor @escaping () -> PTLayoutResult,
                               completion: (@MainActor (Bool) -> Void)? = nil) {
        let resolvedDuration = UIAccessibility.isReduceMotionEnabled ? 0 : max(0, duration)
        var result: PTLayoutResult = .success(PTLayoutChanges(count: 0))
        // English: Execute the transaction inside UIKit's animation block so constant updates animate.
        // Español: Ejecuta la transacción dentro del bloque de animación de UIKit para animar los cambios.
        // 中文：将事务放入 UIKit 动画闭包，确保常量更新真正产生动画。
        UIView.animate(withDuration: resolvedDuration,
                       animations: { result = changes() },
                       completion: { finished in
                           completion?(finished && result.isSuccess)
                       })
    }
}

#endif
