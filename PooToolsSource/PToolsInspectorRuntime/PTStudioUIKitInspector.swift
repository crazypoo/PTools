#if os(iOS)
import UIKit
import Foundation
#if SWIFT_PACKAGE
import PToolsStudioProtocolCore
#endif

/// Read-only, main-actor UIKit hierarchy extraction. No overlays or network hooks.
@MainActor
public final class PTStudioUIKitInspector {
    private final class WeakView {
        weak var value: UIView?
        init(_ value: UIView) { self.value = value }
    }
    private var identifiers: [ObjectIdentifier: String] = [:]
    private var views: [String: WeakView] = [:]

    public init() {}

    public func handle(_ command: PTStudioDiagnosticCommand) -> PTStudioDiagnosticReply {
        guard command.schemaVersion == PTStudioDiagnosticCommand.schemaVersion,
              command.domain == .inspector else {
            return .init(id: command.id, sessionID: command.sessionID,
                         success: false, message: "Unsupported diagnostic command")
        }
        switch command.operation {
        case "snapshot":
            return .init(id: command.id, sessionID: command.sessionID,
                         success: true, entries: snapshot())
        case "node":
            guard let id = command.targetID, let view = views[id]?.value else {
                return .init(id: command.id, sessionID: command.sessionID,
                             success: false, message: "Node is no longer alive")
            }
            return .init(id: command.id, sessionID: command.sessionID,
                         success: true, entries: [entry(for: view, parentID: nil, window: view.window)])
        default:
            return .init(id: command.id, sessionID: command.sessionID,
                         success: false, message: "Operation not enabled in read-only Inspector")
        }
    }

    private func identifier(for view: UIView) -> String {
        let object = ObjectIdentifier(view)
        if let prior = identifiers[object], views[prior]?.value === view { return prior }
        let id = UUID().uuidString
        identifiers[object] = id
        views[id] = WeakView(view)
        return id
    }

    private func entry(for view: UIView, parentID: String?, window: UIWindow?) -> PTStudioDiagnosticEntry {
        let rect: CGRect
        if let window { rect = view.convert(view.bounds, to: window) }
        else { rect = view.frame }
        let geometry = PTStudioRect(x: Double(rect.minX), y: Double(rect.minY),
                                    width: Double(rect.width), height: Double(rect.height))
        return PTStudioDiagnosticEntry(
            id: identifier(for: view), parentID: parentID,
            kind: String(describing: type(of: view)),
            name: view.accessibilityLabel ?? String(describing: type(of: view)),
            detail: view.accessibilityIdentifier,
            frame: geometry,
            attributes: [
                "alpha": String(Double(view.alpha)),
                "hidden": String(view.isHidden),
                "clipsToBounds": String(view.clipsToBounds),
                "userInteractionEnabled": String(view.isUserInteractionEnabled),
                "backgroundColor": view.backgroundColor.map { String(describing: $0) } ?? "nil"
            ])
    }

    public func snapshot(maximumNodes: Int = 2048) -> [PTStudioDiagnosticEntry] {
        let limit = min(4096, max(1, maximumNodes))
        var captured: [PTStudioDiagnosticEntry] = []
        // Weak references are collected each snapshot; never retain a UIView for remote clients.
        views = views.filter { $0.value.value != nil }
        identifiers = identifiers.filter { views[$0.value]?.value != nil }
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .filter { !$0.isHidden }
        for window in windows {
            var stack: [(UIView, String?, Int)] = [(window, nil, 0)]
            while let (view, parentID, depth) = stack.popLast() {
                guard captured.count < limit else { return captured }
                let item = entry(for: view, parentID: parentID, window: window)
                captured.append(item)
                if depth < 48 {
                    for child in view.subviews.reversed() {
                        stack.append((child, item.id, depth + 1))
                    }
                }
            }
        }
        return captured
    }
}
#endif
