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
    public var permitsRemoteMutation = false
    /// Accessibility labels and identifiers may contain user data. Never export them by default.
    public var permitsAccessibilityMetadata = false
    public var permitsHighlight = true
    private enum PreviousValue {
        case alpha(CGFloat)
        case hidden(Bool)
        case frame(CGRect)
    }
    private struct Change {
        let view: WeakView
        let previous: PreviousValue
    }
    private var changes: [UUID: Change] = [:]
    private var changeOrder: [UUID] = []
    private weak var overlay: UIView?

    /// Write permission is granted by the host's explicit Debug UI, never by a remote command.
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
        case "highlight":
            guard permitsHighlight, let id = command.targetID,
                  let view = views[id]?.value, let window = view.window else {
                return failure(command, "Node or highlight capability unavailable")
            }
            showHighlight(view: view, in: window)
            return .init(id: command.id, sessionID: command.sessionID, success: true)
        case "setProperty":
            return setProperty(command)
        case "revert":
            return revert(command)
        default:
            return failure(command, "Unsupported operation")
        }
    }

    private func failure(_ command: PTStudioDiagnosticCommand, _ message: String) -> PTStudioDiagnosticReply {
        .init(id: command.id, sessionID: command.sessionID, success: false, message: message)
    }

    private func setProperty(_ command: PTStudioDiagnosticCommand) -> PTStudioDiagnosticReply {
        guard permitsRemoteMutation else { return failure(command, "Host did not authorize remote editing") }
        guard let id = command.targetID, let view = views[id]?.value,
              let key = command.arguments["key"],
              let text = command.arguments["value"] else {
            return failure(command, "Node or property is unavailable")
        }
        let previous: PreviousValue
        switch key {
        case "alpha":
            guard let value = Double(text), value.isFinite, (0...1).contains(value) else {
                return failure(command, "Alpha must be between 0 and 1")
            }
            previous = .alpha(view.alpha)
            view.alpha = CGFloat(value)
        case "hidden":
            guard text == "true" || text == "false" else {
                return failure(command, "Hidden must be true or false")
            }
            previous = .hidden(view.isHidden)
            view.isHidden = (text == "true")
        case "frame.x", "frame.y", "frame.width", "frame.height":
            guard let value = Double(text), value.isFinite, abs(value) <= 100_000,
                  (!key.hasSuffix("width") && !key.hasSuffix("height") || value >= 0) else {
                return failure(command, "Frame value is outside the safe range")
            }
            previous = .frame(view.frame)
            var frame = view.frame
            switch key {
            case "frame.x": frame.origin.x = CGFloat(value)
            case "frame.y": frame.origin.y = CGFloat(value)
            case "frame.width": frame.size.width = CGFloat(value)
            default: frame.size.height = CGFloat(value)
            }
            view.frame = frame
        default:
            return failure(command, "Property is not allowlisted")
        }
        // A bounded undo stack restores original values even after multiple edits.
        changes[command.id] = Change(view: WeakView(view), previous: previous)
        changeOrder.append(command.id)
        if changeOrder.count > 128 {
            let oldest = changeOrder.removeFirst()
            changes.removeValue(forKey: oldest)
        }
        return .init(id: command.id, sessionID: command.sessionID, success: true,
                     message: "Saved undo token: " + command.id.uuidString,
                     entries: [entry(for: view, parentID: nil, window: view.window)])
    }

    private func revert(_ command: PTStudioDiagnosticCommand) -> PTStudioDiagnosticReply {
        guard permitsRemoteMutation else { return failure(command, "Host did not authorize remote editing") }
        guard let raw = command.arguments["undoID"], let id = UUID(uuidString: raw),
              let change = changes.removeValue(forKey: id),
              let view = change.view.value else {
            return failure(command, "Undo token expired")
        }
        changeOrder.removeAll(where: { $0 == id })
        switch change.previous {
        case .alpha(let value): view.alpha = value
        case .hidden(let value): view.isHidden = value
        case .frame(let value): view.frame = value
        }
        return .init(id: command.id, sessionID: command.sessionID,
                     success: true, entries: [entry(for: view, parentID: nil, window: view.window)])
    }

    private func showHighlight(view: UIView, in window: UIWindow) {
        overlay?.removeFromSuperview()
        let highlight = UIView(frame: view.convert(view.bounds, to: window))
        highlight.isUserInteractionEnabled = false
        highlight.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.12)
        highlight.layer.borderWidth = 2
        highlight.layer.borderColor = UIColor.systemGreen.cgColor
        highlight.accessibilityIdentifier = "PTStudio.DebugHighlight"
        window.addSubview(highlight)
        overlay = highlight
        Task { @MainActor [weak highlight] in
            try? await Task.sleep(for: .seconds(2))
            highlight?.removeFromSuperview()
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
            name: permitsAccessibilityMetadata ? (view.accessibilityLabel ?? String(describing: type(of: view))) : String(describing: type(of: view)),
            detail: permitsAccessibilityMetadata ? view.accessibilityIdentifier : nil,
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
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .filter { !$0.isHidden }
        return capture(roots: windows, maximumNodes: maximumNodes)
    }

    /// An explicit root override is useful for fixture tests without a UIWindowScene.
    public func capture(roots: [UIView], maximumNodes: Int = 2048) -> [PTStudioDiagnosticEntry] {
        let limit = min(4096, max(1, maximumNodes))
        var captured: [PTStudioDiagnosticEntry] = []
        views = views.filter { $0.value.value != nil }
        identifiers = identifiers.filter { views[$0.value]?.value != nil }
        for root in roots {
            let window = (root as? UIWindow) ?? root.window
            var stack: [(UIView, String?, Int)] = [(root, nil, 0)]
            while let (view, parentID, depth) = stack.popLast() {
                guard captured.count < limit else { return captured }
                let item = entry(for: view, parentID: parentID, window: window)
                captured.append(item)
                if depth < 48 {
                    for child in view.subviews.reversed()
                        where child.accessibilityIdentifier != "PTStudio.DebugHighlight" {
                        stack.append((child, item.id, depth + 1))
                    }
                }
            }
        }
        return captured
    }
}
#endif
