# PTools Studio · Debug Agent integration

The macOS desktop project is [DevNetworkWatcher](https://github.com/crazypoo/DevNetworkWatcher) (product: PTools Studio).
This integration is **opt-in for developer-authorized Debug builds only**. Shipping a diagnostic agent in
a production configuration, opening arbitrary SQL consoles or exporting all UserDefaults is not supported.

## Target boundaries

- `PToolsStudioProtocolCore`: Foundation-only shared Codable, Sendable snapshots and commands
- `PToolsInspectorRuntime`: UIKit hierarchy snapshot, highlight and explicitly authorized property editing
- `PToolsStudioStorageRuntime`: sandbox file metadata, selected UserDefaults keys, read-only SQLite schema
- `PToolsStudioTelemetryRuntime`: selected redacted logging records and explicitly supplied performance metrics
- `PToolsDebugStudioBridge`: existing pinned TLS network capture plus opt-in diagnostic polling

These capabilities are **not** automatically enabled by importing `PooToolsDEBUG` or `PooToolsAll`.
Legacy network schema v1 and /v1/events remain unchanged; diagnostics are a separate schema v2 command channel.

## Example: host-owned consent and routing

```swift
#if DEBUG
import PToolsStudioProtocolCore
import PToolsInspectorRuntime
import PToolsStudioStorageRuntime
import PToolsStudioTelemetryRuntime
import PToolsDebugStudioBridge

@MainActor
final class DebugStudioSession {
    private let agent = PTStudioDiagnosticAgent()
    private let inspector = PTStudioUIKitInspector()
    private let storage = PTStudioStorageInspector(
        allowedRoot: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
        allowedDefaultKeys: ["debug.showBorders"])
    private let telemetry = PTStudioTelemetryInspector()

    func connect(transport: PTStudioHTTPSPushTransport) {
        agent.start(transport: transport) { [inspector, storage, telemetry] command in
            switch command.domain {
            case .inspector: return inspector.handle(command)
            case .storage, .defaults, .database: return storage.handle(command)
            case .logging, .performance: return await telemetry.handle(command)
            }
        }
    }

    func allowEditingAfterLocalConsent() { inspector.permitsRemoteMutation = true }
    func disconnect() {
        inspector.permitsRemoteMutation = false
        agent.stop()
    }
}
#endif
```

Create the pinned transport with your existing explicitly paired Mac host/token/certificate fingerprint.
The iOS app must separately opt into `PTStudioDiagnosticAgent.start`; starting the network Bridge alone does not grant diagnostics.
Use a separate transport instance if network capture is already using one.

For live performance, feed `PTStudioTelemetryInspector.recordMetric(...)` using existing
`PTInstruments` samples; this avoids coupling the Foundation-only telemetry module to UIKit.
For logs, explicitly configure an existing `PTMemoryLogDestination` and pass approved categories.
Both are disabled by default. On-device consent should be revoked on disconnect.

**Privacy:** Accessibility labels/identifiers are withheld by default. Restrict all allowed
file roots and UserDefaults keys to non-sensitive debug fixtures. Never put auth tokens,
cookies or payment data in the remote inspection stream. Remote editing requires local consent.

## Validation / limitations

- Verify on a real iPhone and macOS: pinned TLS, Bonjour reconnect, multiple scenes, UIView reuse,
  read-only mode, editing/revert, oversized snapshots, and dismissal while connected.
- macOS 2D/3D are bounded wireframes, not pixel-perfect view screenshots.
- iOS UICollectionView/SwiftUI internal views may change between snapshots. Unsupported
  SwiftUI view internals are not claimed as public remote inspection features.
- iPhone cannot be inspected merely by being on the same Wi-Fi: explicit integration and pairing are required.
