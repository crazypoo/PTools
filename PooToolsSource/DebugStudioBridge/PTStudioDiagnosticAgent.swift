#if os(iOS) && DEBUG
import Foundation
import UIKit
import Darwin
#if SWIFT_PACKAGE
import PToolsStudioProtocolCore
import PToolsDebugInspectorCore
import PToolsDebugInspectorUI
import PToolsDebugStorageCore
import PooToolsDEBUG
#endif

@MainActor
private final class PTStudioWeakView {
    weak var view: UIView?
    init(_ view: UIView) { self.view = view }
}

/// PR52/54: read-only Debug Inspector metadata. Keep all constraint details
/// aggregated; no owner pointers, raw constraint descriptions or custom class
/// member values cross the authorized diagnostics transport.
@MainActor
private enum PTStudioInspectorLayoutMetadata {
    static func attributes(for view: UIView) -> [String: String] {
        let activeCount = view.constraints.reduce(into: 0) { count, constraint in
            if constraint.isActive { count += 1 }
        }
        return [
            "isHidden": String(view.isHidden),
            "alpha": String(format: "%.2f", Double(view.alpha)),
            "subviewCount": String(view.subviews.count),
            "clipsToBounds": String(view.clipsToBounds),
            "translatesAutoresizingMaskIntoConstraints":
                String(view.translatesAutoresizingMaskIntoConstraints),
            "ownActiveConstraints": String(activeCount),
            "ownTotalConstraints": String(view.constraints.count)
        ]
    }
}

/// Opt-in Debug-only diagnostics. This is independent of the established
/// read-only Network schema-v1 Bridge. No method evaluates arbitrary code.
@MainActor
public final class PTStudioDiagnosticAgent {
    public static let shared = PTStudioDiagnosticAgent()

    private struct Edit {
        let reference: PTStudioWeakView
        let hidden: Bool
        let alpha: CGFloat
    }
    private var worker: Task<Void, Never>?
    private var client: PTStudioDiagnosticHTTPSClient?
    private var activePeerID: String?
    private var identifiers: [ObjectIdentifier: UUID] = [:]
    private var referencedViews: [String: PTStudioWeakView] = [:]
    private var edits: [Edit] = []
    private var logs: [String] = []
    private init() {}

    /// Enables only after the developer has opted in and paired this exact Mac.
    /// Call after onBridgeStarted and when the Debug consent switch changes.
    public func startIfAuthorized() async {
        guard UserDefaults.standard.bool(forKey: "PTStudio.diagnosticsEnabled"),
              let peer = PTStudioAutoConnectionManager.shared.currentPeer,
              let credentials = PTStudioPairingKeychain.load(account: peer.id),
              let endpoint = peer.endpoint,
              let sessionID = await PTStudioBridge.shared.diagnosticSessionID() else {
            await stop()
            return
        }
        if activePeerID == peer.id, worker != nil { return }
        await stop()
        do {
            let client = try PTStudioDiagnosticHTTPSClient(endpoint: endpoint, credentials: credentials)
            self.client = client
            activePeerID = peer.id
            worker = Task { [weak self] in
                guard let self else { return }
                var failures = 0
                while !Task.isCancelled {
                    if UIApplication.shared.applicationState != .active {
                        do { try await Task.sleep(for: .seconds(2)) } catch { return }
                        continue
                    }
                    do {
                        let commands = try await client.poll(sessionID: sessionID)
                        failures = 0
                        for command in commands {
                            if Task.isCancelled { return }
                            let response = await self.execute(command, sessionID: sessionID)
                            try await client.reply(response)
                        }
                    } catch {
                        // Bounded reconnect backoff instead of hammering a failed TLS endpoint.
                        failures = min(failures + 1, 5)
                        let backoff = Double(1 << failures)
                        do { try await Task.sleep(for: .seconds(backoff)) } catch { return }
                    }
                    // Successful long polls already wait on the server.
                    if Task.isCancelled { return }
                }
            }
        } catch {
            await stop()
        }
    }

    public func stop() async {
        worker?.cancel()
        worker = nil
        let previous = client
        client = nil
        activePeerID = nil
        referencedViews.removeAll()
        identifiers.removeAll()
        edits.removeAll()
        await PTInstrumentRecorder.shared.releaseStudioSamplerIfOwned()
        await previous?.close()
    }

    /// Explicit logging integration point; no intercept of NSLog or os_log.
    public func recordLog(_ message: String) {
        guard UserDefaults.standard.bool(forKey: "PTStudio.diagnosticsEnabled") else { return }
        let value = PTStudioDiagnosticPrivacy.scrub(String(message.prefix(180)))
        guard !value.isEmpty else { return }
        logs.append(value)
        if logs.count > 200 { logs.removeFirst(logs.count - 200) }
    }

    private func execute(_ command: PTStudioDiagnosticCommand,
                         sessionID: UUID) async -> PTStudioDiagnosticReply {
        guard command.schemaVersion == 2, command.sessionID == sessionID,
              UserDefaults.standard.bool(forKey: "PTStudio.diagnosticsEnabled") else {
            return reply(command, sessionID: sessionID, success: false, message: "Not authorized")
        }
        let editing = UserDefaults.standard.bool(forKey: "PTStudio.editingEnabled")
        switch (command.domain, command.operation) {
        case (.inspector, "snapshot"):
            let previewEnabled = UserDefaults.standard.bool(forKey: "PTStudio.previewEnabled")
            let tree = snapshot(includePreview: previewEnabled)
            // A snapshot still traverses the current UI on MainActor, but unchanged
            // trees avoid JSON image/attribute transfer and Mac list invalidation.
            guard !previewEnabled,
                  let digest = PTDebugInspectorSnapshotSignature.fingerprint(entries: tree) else {
                return reply(command, sessionID: sessionID, entries: tree)
            }
            if command.arguments["knownFingerprint"] == digest {
                return reply(command, sessionID: sessionID, message: "unchanged:" + digest)
            }
            return reply(command, sessionID: sessionID,
                         message: "fingerprint:" + digest, entries: tree)
        case (.inspector, "highlight"):
            guard let view = referencedViews[command.targetID ?? ""]?.view else {
                return reply(command, sessionID: sessionID, success: false, message: "View expired")
            }
            highlight(view)
            return reply(command, sessionID: sessionID, message: "Highlighted")
        case (.inspector, "setHidden"), (.inspector, "setAlpha"):
            guard editing, let view = referencedViews[command.targetID ?? ""]?.view,
                  view.window != nil, !(view is UIWindow) else {
                return reply(command, sessionID: sessionID, success: false,
                             message: "Editing disabled or view expired")
            }
            edits.append(Edit(reference: PTStudioWeakView(view),
                              hidden: view.isHidden, alpha: view.alpha))
            if edits.count > 20 { edits.removeFirst() }
            if command.operation == "setHidden" {
                guard let raw = command.arguments["value"], ["true", "false"].contains(raw) else {
                    edits.removeLast()
                    return reply(command, sessionID: sessionID, success: false, message: "Invalid value")
                }
                view.isHidden = raw == "true"
            } else {
                guard let raw = command.arguments["value"], let alpha = Double(raw),
                      alpha.isFinite, (0.1...1).contains(alpha) else {
                    edits.removeLast()
                    return reply(command, sessionID: sessionID, success: false, message: "Invalid alpha")
                }
                view.alpha = CGFloat(alpha)
            }
            return reply(command, sessionID: sessionID, message: "Applied (Debug only)")
        case (.inspector, "undo"):
            guard editing, let edit = edits.popLast(), let view = edit.reference.view else {
                return reply(command, sessionID: sessionID, success: false, message: "Nothing to undo")
            }
            view.isHidden = edit.hidden
            view.alpha = edit.alpha
            return reply(command, sessionID: sessionID, message: "Restored")
        case (.storage, "list"), (.database, "list"):
            let databasesOnly = command.domain == .database
            let records = await Task.detached(priority: .utility) {
                PTDebugFileInventory.list(databasesOnly: databasesOnly)
            }.value
            let converted = records.map {
                PTStudioDiagnosticEntry(id: $0.id, kind: $0.kind,
                    name: PTStudioDiagnosticPrivacy.scrub($0.name),
                    detail: $0.source,
                    attributes: ["bytes": String($0.byteCount),
                                 "directory": String($0.isDirectory)])
            }
            return reply(command, sessionID: sessionID, entries: converted)
        case (.defaults, "list"):
            let records = await Task.detached(priority: .utility) {
                PTDebugDefaultsInventory.list()
            }.value
            let converted = records.map {
                PTStudioDiagnosticEntry(id: "default-" + $0.key, kind: "UserDefaults",
                    name: $0.key, detail: "Value withheld by default",
                    attributes: ["type": $0.type])
            }
            return reply(command, sessionID: sessionID, entries: converted)
        case (.logging, "snapshot"):
            let data = logs.enumerated().map { idx, message in
                PTStudioDiagnosticEntry(id: "log-\(idx)", kind: "log",
                    name: "Log \(idx + 1)", detail: message)
            }
            return reply(command, sessionID: sessionID, entries: data)
        case (.performance, "snapshot"):
            return reply(command, sessionID: sessionID, entries: await performanceInventory())
        default:
            return reply(command, sessionID: sessionID, success: false, message: "Unsupported operation")
        }
    }

    private func reply(_ command: PTStudioDiagnosticCommand, sessionID: UUID,
                       success: Bool = true, message: String? = nil,
                       entries: [PTStudioDiagnosticEntry] = []) -> PTStudioDiagnosticReply {
        PTStudioDiagnosticPrivacy.sanitize(
            PTStudioDiagnosticReply(id: command.id, sessionID: sessionID,
                                    success: success, message: message,
                                    entries: Array(entries.prefix(1200))))
    }

    private func snapshot(includePreview: Bool) -> [PTStudioDiagnosticEntry] {
        var result: [PTStudioDiagnosticEntry] = []
        var live: [String: PTStudioWeakView] = [:]
        func append(_ view: UIView, parentID: String?, depth: Int, isWindow: Bool) {
            guard result.count < 900, depth < 20 else { return }
            let oid = ObjectIdentifier(view)
            let id = identifiers[oid] ?? UUID()
            identifiers[oid] = id
            let value = id.uuidString.lowercased()
            live[value] = PTStudioWeakView(view)
            let frame = view.convert(view.bounds, to: nil)
            // Offscreen/transition geometry must not poison the entire reply.
            guard [frame.minX, frame.minY, frame.width, frame.height]
                .allSatisfy({ $0.isFinite && abs($0) <= 100_000 }) else { return }
            var preview: String?
            // One bounded preview per snapshot. Multiple full-window previews
            // could exceed the collector's 512 KiB reply limit.
            if isWindow && includePreview && !result.contains(where: { $0.previewBase64 != nil })
                && view.bounds.width > 0 && view.bounds.height > 0 {
                let size = CGSize(width: min(460, view.bounds.width),
                                  height: min(600, view.bounds.height))
                let renderer = UIGraphicsImageRenderer(size: size)
                let image = renderer.image { _ in
                    view.drawHierarchy(in: CGRect(origin: .zero, size: size),
                                       afterScreenUpdates: false)
                }
                preview = image.jpegData(compressionQuality: 0.45)?.base64EncodedString()
                if (preview?.count ?? 0) > 120_000 { preview = nil }
            }
            result.append(PTStudioDiagnosticEntry(
                id: value, parentID: parentID,
                kind: "UIView", name: String(describing: type(of: view)),
                detail: "depth \(depth) • \(view.subviews.count) subviews",
                frame: PTStudioRect(x: Double(frame.minX), y: Double(frame.minY),
                                    width: Double(frame.width), height: Double(frame.height)),
                attributes: PTStudioInspectorLayoutMetadata.attributes(for: view),
                previewBase64: preview
            ))
            for child in view.subviews { append(child, parentID: value, depth: depth + 1, isWindow: false) }
        }
        for scene in UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }) {
            guard scene.activationState == .foregroundActive else { continue }
            for window in scene.windows where !window.isHidden {
                append(window, parentID: nil, depth: 0, isWindow: true)
            }
        }
        referencedViews = live
        if identifiers.count > 2000 {
            let activeIDs = Set(live.keys)
            identifiers = identifiers.filter { activeIDs.contains($0.value.uuidString.lowercased()) }
        }
        return result
    }

    private func highlight(_ view: UIView) {
        PTDebugInspectorHighlight.show(view)
    }

    private func performanceInventory() async -> [PTStudioDiagnosticEntry] {
        let recorder = PTInstrumentRecorder.shared
        recorder.startStudioSamplerIfNeeded()
        let latestValues = await recorder.session?.latestSamples(for: [.fps, .cpu, .memory]) ?? [:]
        func latest(_ kind: PTInstrumentKind) -> Double? {
            latestValues[kind]?.value
        }
        let process = ProcessInfo.processInfo
        let cpu = latest(.cpu)
        let fps = latest(.fps)
        let memory = latest(.memory)
        return [
            PTStudioDiagnosticEntry(id: "cpu", kind: "performance",
                name: "Process CPU", detail: cpu.map { String(format: "%.1f%%", $0) } ?? "Sampling…"),
            PTStudioDiagnosticEntry(id: "fps", kind: "performance",
                name: "Observed display FPS", detail: fps.map { String(format: "%.1f", $0) } ?? "Sampling…"),
            PTStudioDiagnosticEntry(id: "memory", kind: "performance",
                name: "Resident memory", detail: memory.map { String(format: "%.1f MB", $0) } ?? "Sampling…"),
            PTStudioDiagnosticEntry(id: "uptime", kind: "performance",
                name: "System uptime", detail: String(format: "%.1f s", process.systemUptime)),
            PTStudioDiagnosticEntry(id: "thermal", kind: "performance",
                name: "Thermal state", detail: String(describing: process.thermalState)),
            PTStudioDiagnosticEntry(id: "cores", kind: "performance",
                name: "Active processors", detail: String(process.activeProcessorCount))
        ]
    }
}
#endif
