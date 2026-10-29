# PTNetwork Studio read-only Bridge (PTools 5.69.x)

> **Status (2026-10-25):** The corresponding DevNetworkWatcher collector now implements the schema-v1 `POST /v1/events` batch and JSON ACK on TCP 9453 (see its protocol-fix branch). Mac/iOS end-to-end physical-device acceptance and macOS Xcode build remain pending. Unlike the old 9443 endpoint, it uses a developer-trusted CA plus a pinned leaf certificate; it does **not** bypass system trust.

## Scope and compatibility

- Git baseline: `119814c1b50d79598a604138273d6446b544d9f9` (`master`, 2026-10-25), `VERSION = 5.69.0`.
- Existing `PooToolsDEBUG` / `PTNetworkCaptureStore`, `PTNetworkHelper`, URLProtocol forwarding, HAR 1.2 and cURL/Text exporters remain in place.
- Extra capture hooks when disabled: **zero**. No observer or background task is created until `start` is explicitly invoked.
- SPM product: `PToolsDebugStudioBridge` (depends on `PooToolsDEBUG`). CocoaPods: `PooTools/DEBUG_StudioBridge`. The default `PooToolsAll` dependency intentionally does **not** include the Studio product.
- iOS 17+; bridge is blocked by `#if !DEBUG` for production binaries, even if a caller sets `isEnabled`.
- No iOS Scene, UIKit layout, screen height, or view-controller dependency is added to the bridge.

## Enabling the Bridge on iOS

```swift
#if DEBUG
import PToolsDebugStudioBridge

// Display an explicit opt-in toggle and a privacy disclosure first.
// Paste a one-time pairing token and a SHA-256 of the collector's *leaf* certificate
// from the collector's verified pairing UI.
let credentials = try PTStudioPairingCredentials(
    bearerToken: pairingToken,
    leafCertificateSHA256Hex: fingerprintHex // 64 chars from Mac UI
)
// Only if the user approved storing these secrets:
try PTStudioPairingKeychain.save(credentials, account: "my-dev-mac")
let transport = try PTStudioHTTPSPushTransport(
    endpoint: URL(string: "https://192.168.1.20:9453/v1/events")!,
    credentials: credentials
)
try await PTStudioBridge.shared.start(
    using: transport,
    configuration: PTStudioBridgeConfiguration(isEnabled: true)
)
// On user toggle off / logout:
await PTStudioBridge.shared.stop()
// On pairing revoke:
PTStudioPairingKeychain.revoke(account: "my-dev-mac")
#endif
```

**Mac setup:** In DevNetworkWatcher choose **iPhone → PTools Live Bridge** and Start Bridge using a stable `.local` TLS hostname (preferred) or a manually entered LAN IPv4. The collector generates a private development root CA and a 90-day leaf with SAN for that address. Use **Reveal Development CA (.cer)** to AirDrop/install the root CA on the authorized iOS test device and enable full trust under **Settings → General → About → Certificate Trust Settings**. Enter the displayed bearer token and leaf fingerprint in the iOS Debug-only pairing UI. Changing the configured TLS hostname (or manually entered IP) rotates the leaf fingerprint; pair again. The root CA is separate from mitmproxy's HTTPS-inspection CA. Never install either CA or token in a distributed app.

**Capture startup:** `@MainActor PTDebugManager.shared.start(identifier: "network")` starts the existing URLProtocol observer; starting `PTStudioBridge` alone does **not** capture traffic. Initiate pairing only after the developer enables a Debug UI action (never unconditionally in `AppDelegate`). The example helper now starts the capture observer **after** successfully subscribing the Bridge, so a failed Bridge start cannot leave unexpected capture enabled. Stop via `PTDebugManager.shared.stop(identifier: "network")` if your Debug UI has no other network-capture owner.

**Connection state:** `isRunning` only means a transport is configured. Inspect `await PTStudioBridge.shared.status()`: `deliveryState == .connected` means at least one valid collector ACK arrived, `.awaitingAcknowledgement` means no ACK yet, and `.retrying` plus `consecutiveSendFailures` indicates delivery failures. A wrong Token, untrusted CA, outdated fingerprint, incorrect LAN IP, denied local network access, or blocked TCP 9453 can all prevent ACKs.

**2026-10-29 pairing migration:** An old example app had a fixed LAN IP and pairing secret committed in source. Those literals are removed and automatic launch-time pairing is disabled. The matching Mac Collector now replaces legacy `bridge-token` with `bridge-token-v2` on first launch, so you **must re-pair** after upgrading. Because the old secret is in Git history, never reuse it.

### Bonjour discovery and paired automatic reconnection (2026-10-29)

The **opt-in** `PTStudioBonjourDiscovery` browses `_ptstudio._tcp.` on the local network. The collector advertises a stable, public installation UUID, protocol version and TLS hostname; it **never** broadcasts the token or fingerprint. `PTStudioAutoConnectionManager` matches advertisements against Keychain credentials stored under that UUID and starts the existing HTTPS transport. Lost services stop the managed bridge; reappearing services and app-foreground `refresh()` can restart it. Existing manual pairing APIs remain supported.

Host app `Info.plist` requirements (in addition to the app's usual Debug capabilities):

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>Discover my paired developer Mac for network debugging.</string>
<key>NSBonjourServices</key>
<array><string>_ptstudio._tcp</string></array>
```

The optional Debug-only SwiftUI `PTStudioPairingView()` supplies the first-pairing UI (Bonjour peer selection, opt-in switch, token + SHA-256 confirmation, Keychain save/revoke). Present it from your app's existing developer/debug settings screen:

```swift
#if DEBUG
import SwiftUI
import PToolsDebugStudioBridge

// Inside a Debug-only settings view:
NavigationStack { PTStudioPairingView() }
#endif
```

The PooTools example exposes `AppMacNetworkDebugManager.shared.presentStudioPairing(from: presenter)` for UIKit projects. The host app must still explicitly include the optional Bridge product and be responsible for turning its capture observer on/off.

Example Debug settings code (on the main actor, never for a Release build):

```swift
#if DEBUG
import PToolsDebugStudioBridge

let connector = PTStudioAutoConnectionManager.shared
connector.onBridgeStarted = {
    // Explicit opt-in: the host owns capture and stops it when disconnected.
    PTDebugManager.shared.start(identifier: "network")
}
connector.onBridgeStopped = {
    PTDebugManager.shared.stop(identifier: "network")
}

// Only after the developer enables an "Auto-connect paired Studio" switch:
try connector.start()
// Show connector.discovery.peers in a Debug pairing picker.
// On first pairing, the developer verifies the Mac's UI and manually enters
// its Token + leaf certificate fingerprint; the token is NEVER in Bonjour TXT.
try connector.approvePairing(
    peerID: selectedPeer.id, token: confirmedToken, fingerprintHex: confirmedPin)

// Later launches may call connector.start() only if that opt-in persists.
// After foreground / Wi-Fi changes:
try connector.refresh()
// On switch off (does not erase Keychain):
connector.stop()
// On explicitly unpairing:
connector.revokePairing(peerID: selectedPeer.id)
#endif
```

**Mac:** In Studio → iPhone, start Bridge with the Mac's stable `.local` hostname (now the default), not a changing IP address. Bonjour only advertises after the Python TLS listener reports ready. Opt into "Start secure Bridge automatically when Studio opens" to advertise on subsequent launches. Installing and explicitly trusting the generated Development CA on the test iPhone is still mandatory. If the host name or leaf certificate changes, verify and re-pair the fingerprint; rotating the token also revokes existing pairings. A forged service advertisement cannot bypass trusted TLS, pinning or Bearer authorization. Bonjour and the network connection require local network permission and working multicast DNS; VPNs and some guest Wi-Fi networks can block discovery.

**Important:** The example AppDelegate scans automatically only after the developer's Debug opt-in preference was set and at least one Mac is Keychain-paired. Discovering an unpaired Mac does not enable capture. `onBridgeStarted` means the transport was configured; verify `PTStudioBridge.status().deliveryState == .connected` to prove the Mac has ACKed events. The example's previous manual connect helper remains usable separately. Physical iPhone + macOS verification is still required.

## Wire contract (schemaVersion = 1)

The iOS client sends `POST /v1/events` over HTTPS. Each batch has the following shape:

```json
{
  "schemaVersion": 1,
  "events": [
    {
      "schemaVersion": 1,
      "sessionID": "UUID",
      "deviceID": "EPHEMERAL-UUID",
      "eventID": "UUID",
      "requestID": "UUID",
      "sequence": 1,
      "monotonicTime": 12989.25,
      "wallTime": "2026-10-25T04:00:00Z",
      "source": "urlProtocol",
      "kind": "recordFinalize",
      "payload": {
        "record": {
          "method": "GET",
          "url": "https://example.com/?token=%5BREDACTED%5D",
          "requestHeaders": {"Authorization": "[REDACTED]"},
          "responseHeaders": {},
          "requestBody": {"totalBytes": 0, "preview": null, "truncated": false, "redacted": true},
          "responseBody": null,
          "status": 200,
          "durationSeconds": 0.12,
          "completion": "completed",
          "errorDomain": null,
          "errorCode": null,
          "redirectCount": 0,
          "fetchSource": "network",
          "recordSequence": 0,
          "startedAt": "2026-10-25T04:00:00Z"
        }
      }
    }
  ]
}
```

**Date contract:** The HTTPS sender sets `JSONEncoder.dateEncodingStrategy = .iso8601`. The collector must decode `wallTime` and `startedAt` as ISO8601 in schema v1. `monotonicTime` remains seconds since system boot and must not be treated as a UTC timestamp.

Request headers: `Authorization: Bearer <pairing token>`, `X-PTStudio-Nonce` (random UUID per POST), and `X-PTStudio-Sent-At` (Unix seconds). Collector must enforce trusted TLS, valid token, nonce uniqueness, a short timestamp TTL, a schema allowlist, bounded request size, and deduplication of `eventID`/`sequence` per `sessionID`. For every accepted batch respond HTTP 200:

```json
{"schemaVersion":1,"sessionID":"same session UUID","acceptedSequence":19}
```

The client requires the `acceptedSequence` to cover the last posted event and retries the exact same `eventID` on failure. Sequence gaps are possible under bounded queue pressure; do not interpret gaps as data reordering or silent end-to-end success. `recordFinalize` is derived from the existing Store's exactly-once state; the desktop deduplicates by `eventID` and `requestID`.

Control `kind` variants: `hello`, `capabilities`, `recordUpsert`, `recordFinalize`, `recordDelete`, `sessionReset`, `heartbeat`, `ack`, `error`. The current sender only emits `hello`, `capabilities`, record changes, `sessionReset` and `heartbeat`; `ack` is a transport response rather than an event in the current protocol.

## Privacy and safety

- The source record is redacted via `PTNetworkPrivacyPolicy` *then* passed through `PTStudioPrivacyGate`, before any queue, transport or serialization.
- Default: method, hostname and status are available; URL credentials, fragments and **all query values** are removed. The URL path is omitted unless the developer explicitly opts in to `includeURLPath`. Header names are retained, all header values removed.
- Only small, valid JSON bodies within 16 KiB can carry a preview after recursive redaction. Text, form, multipart, binary, unknown content types, invalid or truncated JSON and file-backed body paths are **never** forwarded as raw content. Exact raw error strings are also omitted.
- Metadata includes original body byte count and a `truncated` flag. No `PTNetworkBodyCapture.file(url:)` URL is ever serialized.
- HTTPS transport requires system-trusted server TLS **and** a pinned SHA-256 digest of its leaf certificate; no certificate bypass, CA installation, or silent MITM. Pairing credentials reside in Keychain when the host explicitly saves them.
- In-flight batches are ACKed; bounded memory-only queuing and retry are supported. This implementation does not claim durable offline replay, background keepalive, Bonjour, automatic trust provisioning, or fully negotiated bidirectional pairing.

## Verification / remaining boundaries

| Check | Status |
|---|---|
| New SPM target and optional CocoaPods subspec | Implemented in source; macOS/iOS build pending |
| Typed envelope, source/session/request identity and explicit capability flags | Implemented in source |
| Default-off Debug gate and subscriber cleanup | Implemented in source; tests added |
| Conservative redaction, bounded preview, file URL omission | Implemented in source; tests added |
| Bounded Store stream, queue, coalescing, retries, ACK | Implemented in source; load tests pending |
| Mac Collector HTTPS endpoint + nonce/ACK/token server validation | Implemented in DevNetworkWatcher protocol-fix branch; real iOS acceptance pending |
| Actual Mac app import/compose/proxy/MITM/Rewrite/Map Local etc. (P4) | **Separate PTNetwork Studio repository** |
| 10k requests, 100MB response, recovery, multi-Scene / iPhone Duo | **Physical runtime acceptance pending** |
| macOS Tahoe 26 / Apple Silicon Xcode build and proxy curl smoke test | **Not executable from GitHub source inspection** |

Run on a Mac with Xcode before merging:
```bash
swift package dump-package >/dev/null
swift test --filter PTStudioBridgeTests
ruby -c PooTools.podspec
```

Then exercise URLSession.shared/async/ephemeral/Alamofire, status failures/redirects/gzip, 10k requests/100MB fixture, privacy in network captures and exports, reconnection and clock shift, iOS 17+ physical devices, multiple scenes, iPhone Duo folding/rotation, background/foreground and Release disabled behavior. Desktop P4 (HTTPS interception, local CA, URL proxy, rules, etc.) requires separate security audit and explicit consent.

See `DEBUG_NETWORK_ARCHITECTURE.md`, `DEBUG_NETWORK_CAPABILITY_MATRIX.md`, and `DEBUG_NETWORK_PRIVACY.md` for the existing observer boundaries.
