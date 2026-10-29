# Studio PR02–PR06: iOS opt-in Diagnostic Agent

## Existing Network Bridge remains unchanged
- Keep PTools Debug Network schema v1 as the authoritative capture stream.
- Diagnostics uses a separate schema v2 over the same authenticated TLS host and token.
- Default-off. Compiled into Debug iOS only. No automatic filesystem or UI capture on launch.
- Existing Bonjour pairing, ACKs and automatic reconnection continue independently.

## Opt-in procedure
1. Start the secure Mac Bridge and pair the developer iPhone as usual.
2. In the iPhone `PTStudioPairingView` explicitly enable **Allow Inspector, Storage, Console and Performance**.
3. For UI mutations, separately enable **Allow live view property editing and Undo**. This is off by default.
4. For screenshots separately enable **Allow screen previews**, because screen contents may reveal private data.
5. Switch to a Mac workspace and press Refresh. Only active authenticated session commands are accepted.
6. Turning off Diagnostics stops the polling worker; revoking pairing stops the transport.

## Integrating another UIKit host
After installing optional `PToolsDebugStudioBridge`, configure the application's existing `PTStudioAutoConnectionManager` callbacks in its Debug settings:

```swift
#if DEBUG
PTStudioAutoConnectionManager.shared.onBridgeStarted = {
    PTDebugManager.shared.start(identifier: "network")
    Task { await PTStudioDiagnosticAgent.shared.startIfAuthorized() }
}
PTStudioAutoConnectionManager.shared.onBridgeStopped = {
    PTDebugManager.shared.stop(identifier: "network")
    Task { await PTStudioDiagnosticAgent.shared.stop() }
}
#endif
```

Present `PTStudioPairingView` from a deliberate Debug UI action. `AppMacNetworkDebugManager` in the example already wires the callback. The Info.plist Bonjour keys used for the Network Bridge remain required.

## Capabilities and limits
- PR02 Inspector: UIView hierarchy, stable ephemeral view IDs, frame, alpha, hidden state; Highlight on device.
- PR03: setHidden, setAlpha (0.1–1.0) and last-edit Undo, with separate consent; no arbitrary KVC/invocation.
- PR04: top-level Documents/Caches/Application Support inventory, database file names, UserDefaults keys and value *types*, never default values, file bytes or raw SQL.
- PR05: explicit `PTStudioDiagnosticAgent.shared.recordLog(_:) ` events only; the feature does not silently hook `os_log`, `print` or `NSLog`. Basic memory/thermal/uptime metrics are snapshots rather than a production profiler.
- PR06: optional compressed preview of visible window (off by default), bounded view count, snapshot export handled on Mac. UI attributes exclude textual contents.
- No background keepalive, no per-widget arbitrary inspectors, no writable storage or SQLite.

## Security / acceptance
- System CA trust + SHA-256 leaf certificate pin + existing Bearer token, nonce and timestamp remain mandatory.
- No transport or agent in Release. View references are weak and cleared on stop.
- Verify Xcode/SPM/CocoaPods compilation and the existing Network Bridge 7/7 checklist after merging.
- Real-device acceptance for edit/undo, cross-scene views, phone rotation, disconnects, token and CA rotation has not been claimed.
