# PTNetwork Studio read-only Bridge (PTools 5.69.x)

> **Status:** PTools-side opt-in protocol, bounded capture consumer and HTTPS push client. **Not** a complete end-to-end macOS integration. The PTNetwork Studio desktop collector must implement the wire contract below and needs independent macOS/Xcode and device acceptance.

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
    leafCertificateSHA256: leafCertSHA256  // 32 raw bytes, not UTF-8 hex
)
// Only if the user approved storing these secrets:
try PTStudioPairingKeychain.save(credentials, account: "my-dev-mac")
let transport = try PTStudioHTTPSPushTransport(
    endpoint: URL(string: "https://my-dev-mac.local:9453/v1/events")!,
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

The host application's `Info.plist` must include `NSLocalNetworkUsageDescription` for local network use. This implementation performs **no Bonjour discovery** and does not require `NSBonjourServices`. Use a host address entered/selected by the user. Apple local-network permission behavior varies by OS and needs a device check.

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

**Decoder note:** JSONEncoder's default Date strategy encodes dates as seconds relative to the Apple reference date (2001-01-01), not ISO8601. The time strings above are human-readable schema illustrations only. The collector must mirror the client's date format or introduce an explicitly negotiated, versioned date strategy.

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
| Mac Collector HTTPS endpoint + nonce/ACK/token server validation | **Not implemented here** |
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
