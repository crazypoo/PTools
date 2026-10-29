#if os(iOS) && DEBUG
import Foundation
import UIKit
import Darwin
#if SWIFT_PACKAGE
import PToolsStudioProtocolCore
#endif

@MainActor
private final class PTStudioWeakView {
    weak var view: UIView?
    init(_ view: UIView) { self.view = view }
}

/// The counter runs only while diagnostics is enabled and is destroyed on stop.
@MainActor
private final class PTStudioFrameCounter: NSObject {
    private var link: CADisplayLink?
    private var startTimestamp: CFTimeInterval = 0
    private var frames = 0
    private(set) var fps = 0.0

    func start() {
        guard link == nil else { return }
        let display = CADisplayLink(target: self, selector: #selector(tick(_:)))
        display.add(to: .main, forMode: .common)
        link = display
    }

    @objc private func tick(_ display: CADisplayLink) {
        if startTimestamp == 0 { startTimestamp = display.timestamp; return }
        frames += 1
        let elapsed = display.timestamp - startTimestamp
        if elapsed >= 1 {
            fps = Double(frames) / elapsed
            frames = 0
            startTimestamp = display.timestamp
        }
    }

    func stop() {
        link?.invalidate()
        link = nil
        startTimestamp = 0
        frames = 0
        fps = 0
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
    private var frameCounter: PTStudioFrameCounter?
    private var lastCPUSample: (totalSeconds: Double, uptime: TimeInterval)?
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
            let counter = PTStudioFrameCounter()
            counter.start()
            frameCounter = counter
            worker = Task { [weak self] in
                guard let self else { return }
                while !Task.isCancelled {
                    do {
                        let commands = try await client.poll(sessionID: sessionID)
                        for command in commands {
                            if Task.isCancelled { return }
                            let response = self.execute(command, sessionID: sessionID)
                            try await client.reply(response)
                        }
                    } catch {
                        // No user data or credentials in error logs. The Network
                        // Bridge remains independent and able to reconnect.
                    }
                    do { try await Task.sleep(for: .seconds(1)) }
                    catch { return }
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
        frameCounter?.stop()
        frameCounter = nil
        lastCPUSample = nil
        await previous?.close()
    }

    /// Explicit logging integration point; no intercept of NSLog or os_log.
    public func recordLog(_ message: String) {
        guard UserDefaults.standard.bool(forKey: "PTStudio.diagnosticsEnabled") else { return }
        let value = String(message.prefix(180))
        guard !value.isEmpty else { return }
        logs.append(value)
        if logs.count > 200 { logs.removeFirst(logs.count - 200) }
    }

    private func execute(_ command: PTStudioDiagnosticCommand,
                         sessionID: UUID) -> PTStudioDiagnosticReply {
        guard command.schemaVersion == 2, command.sessionID == sessionID,
              UserDefaults.standard.bool(forKey: "PTStudio.diagnosticsEnabled") else {
            return reply(command, sessionID: sessionID, success: false, message: "Not authorized")
        }
        let editing = UserDefaults.standard.bool(forKey: "PTStudio.editingEnabled")
        switch (command.domain, command.operation) {
        case (.inspector, "snapshot"):
            return reply(command, sessionID: sessionID, entries: snapshot(
                includePreview: UserDefaults.standard.bool(forKey: "PTStudio.previewEnabled")))
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
        case (.storage, "list"):
            return reply(command, sessionID: sessionID, entries: fileInventory(databasesOnly: false))
        case (.database, "list"):
            return reply(command, sessionID: sessionID, entries: fileInventory(databasesOnly: true))
        case (.defaults, "list"):
            return reply(command, sessionID: sessionID, entries: defaultsInventory())
        case (.logging, "snapshot"):
            let data = logs.enumerated().map { idx, message in
                PTStudioDiagnosticEntry(id: "log-\(idx)", kind: "log",
                    name: "Log \(idx + 1)", detail: message)
            }
            return reply(command, sessionID: sessionID, entries: data)
        case (.performance, "snapshot"):
            return reply(command, sessionID: sessionID, entries: performanceInventory())
        default:
            return reply(command, sessionID: sessionID, success: false, message: "Unsupported operation")
        }
    }

    private func reply(_ command: PTStudioDiagnosticCommand, sessionID: UUID,
                       success: Bool = true, message: String? = nil,
                       entries: [PTStudioDiagnosticEntry] = []) -> PTStudioDiagnosticReply {
        PTStudioDiagnosticReply(id: command.id, sessionID: sessionID,
                                success: success, message: message,
                                entries: Array(entries.prefix(1200)))
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
            var preview: String?
            if isWindow && includePreview && view.bounds.width > 0 && view.bounds.height > 0 {
                let size = CGSize(width: min(460, view.bounds.width),
                                  height: min(600, view.bounds.height))
                let renderer = UIGraphicsImageRenderer(size: size)
                let image = renderer.image { _ in
                    view.drawHierarchy(in: CGRect(origin: .zero, size: size),
                                       afterScreenUpdates: false)
                }
                preview = image.jpegData(compressionQuality: 0.45)?.base64EncodedString()
                if (preview?.count ?? 0) > 250_000 { preview = nil }
            }
            result.append(PTStudioDiagnosticEntry(
                id: value, parentID: parentID,
                kind: "UIView", name: String(describing: type(of: view)),
                detail: "depth \(depth) • \(view.subviews.count) subviews",
                frame: PTStudioRect(x: Double(frame.minX), y: Double(frame.minY),
                                    width: Double(frame.width), height: Double(frame.height)),
                attributes: ["isHidden": String(view.isHidden),
                             "alpha": String(format: "%.2f", Double(view.alpha)),
                             "subviewCount": String(view.subviews.count)],
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
        guard let window = view.window else { return }
        let frame = view.convert(view.bounds, to: window)
        let layer = CAShapeLayer()
        layer.frame = frame
        layer.borderColor = UIColor.systemOrange.cgColor
        layer.borderWidth = 3
        layer.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.1).cgColor
        window.layer.addSublayer(layer)
        Task {
            try? await Task.sleep(for: .seconds(2))
            layer.removeFromSuperlayer()
        }
    }

    private func rootFolders() -> [URL] {
        let fm = FileManager.default
        return [
            fm.urls(for: .documentDirectory, in: .userDomainMask).first,
            fm.urls(for: .cachesDirectory, in: .userDomainMask).first,
            fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        ].compactMap { $0 }
    }

    private func fileInventory(databasesOnly: Bool) -> [PTStudioDiagnosticEntry] {
        let fm = FileManager.default
        var result: [PTStudioDiagnosticEntry] = []
        for root in rootFolders() {
            let files = (try? fm.contentsOfDirectory(
                at: root, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
                options: [.skipsHiddenFiles])) ?? []
            for file in files.prefix(200) where result.count < 500 {
                let ext = file.pathExtension.lowercased()
                if databasesOnly && !["db", "sqlite", "sqlite3"].contains(ext) { continue }
                let props = try? file.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey])
                result.append(PTStudioDiagnosticEntry(
                    id: UUID().uuidString, kind: databasesOnly ? "database" : "file",
                    name: file.lastPathComponent,
                    detail: root.lastPathComponent,
                    attributes: ["bytes": String(props?.fileSize ?? 0),
                                 "directory": String(props?.isDirectory ?? false)]))
            }
        }
        return result
    }

    private func defaultsInventory() -> [PTStudioDiagnosticEntry] {
        let filtered = UserDefaults.standard.dictionaryRepresentation()
        return filtered.keys.sorted().filter { key in
            !["token", "secret", "password", "cookie", "auth", "key", "credential"]
                .contains(where: { key.lowercased().contains($0) })
        }.prefix(400).map { key in
            PTStudioDiagnosticEntry(
                id: "default-" + key, kind: "UserDefaults",
                name: key, detail: "Value withheld by default",
                attributes: ["type": String(describing: type(of: filtered[key] as Any))])
        }
    }

    private func performanceInventory() -> [PTStudioDiagnosticEntry] {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size /
                                           MemoryLayout<natural_t>.size)
        let status = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        let bytes = status == KERN_SUCCESS ? UInt64(info.resident_size) : 0
        let process = ProcessInfo.processInfo
        let totalCPU = Double(info.user_time.seconds) +
            Double(info.user_time.microseconds) / 1_000_000 +
            Double(info.system_time.seconds) +
            Double(info.system_time.microseconds) / 1_000_000
        let sample = (totalSeconds: totalCPU, uptime: process.systemUptime)
        let cpuPercent: Double
        if status == KERN_SUCCESS, let previous = lastCPUSample,
           sample.uptime > previous.uptime {
            cpuPercent = max(0, (totalCPU - previous.totalSeconds) /
                             (sample.uptime - previous.uptime) * 100)
        } else {
            cpuPercent = 0 // First sample requires another Refresh to calculate delta.
        }
        lastCPUSample = status == KERN_SUCCESS ? sample : nil
        return [
            PTStudioDiagnosticEntry(id: "cpu", kind: "performance",
                name: "Process CPU (sampled)", detail: String(format: "%.1f%%", cpuPercent)),
            PTStudioDiagnosticEntry(id: "fps", kind: "performance",
                name: "Observed display FPS", detail: String(format: "%.1f", frameCounter?.fps ?? 0)),
            PTStudioDiagnosticEntry(id: "memory", kind: "performance",
                name: "Resident memory", detail: "\(bytes) bytes"),
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
