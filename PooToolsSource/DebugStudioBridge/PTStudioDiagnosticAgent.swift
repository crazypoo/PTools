import Foundation
#if SWIFT_PACKAGE
import PToolsStudioProtocolCore
#endif

/// Explicit opt-in command dispatcher, intentionally distinct from network capture.
/// A host may pass a UIKit inspector or its own handler. Disabled outside DEBUG builds.
@MainActor
public final class PTStudioDiagnosticAgent {
    public typealias Handler = @MainActor @Sendable (PTStudioDiagnosticCommand) async -> PTStudioDiagnosticReply
    public private(set) var sessionID = UUID()
    private var task: Task<Void, Never>?
    private var replies: [UUID: PTStudioDiagnosticReply] = [:]
    private var replyOrder: [UUID] = []

    public init() {}

    public func start(transport: PTStudioHTTPSPushTransport,
                      handler: @escaping Handler) {
        #if DEBUG
        guard task == nil else { return }
        sessionID = UUID()
        replies.removeAll()
        replyOrder.removeAll()
        let current = sessionID
        task = Task {
            while !Task.isCancelled {
                do {
                    let commands = try await transport.pollDiagnostics(sessionID: current)
                    for command in commands where !Task.isCancelled {
                        let response: PTStudioDiagnosticReply
                        if let prior = replies[command.id] {
                            response = prior
                        } else {
                            response = await handler(command)
                            replies[command.id] = response
                            replyOrder.append(command.id)
                            if replyOrder.count > 256 {
                                replies.removeValue(forKey: replyOrder.removeFirst())
                            }
                        }
                        try await transport.sendDiagnosticReply(response)
                    }
                } catch {
                    // A temporary disconnect must not relax TLS validation or spawn duplicate polling tasks.
                }
                try? await Task.sleep(for: .milliseconds(900))
            }
        }
        #else
        _ = transport; _ = handler
        #endif
    }

    public func stop() {
        task?.cancel()
        task = nil
    }

}
