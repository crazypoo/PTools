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

    public init() {}

    public func start(transport: PTStudioHTTPSPushTransport,
                      handler: @escaping Handler) {
        #if DEBUG
        guard task == nil else { return }
        sessionID = UUID()
        let current = sessionID
        task = Task {
            while !Task.isCancelled {
                do {
                    let commands = try await transport.pollDiagnostics(sessionID: current)
                    for command in commands where !Task.isCancelled {
                        let response = await handler(command)
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

    deinit { task?.cancel() }
}
