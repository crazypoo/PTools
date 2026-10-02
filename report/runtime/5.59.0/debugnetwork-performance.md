# PTools 5.59.0 DebugNetwork Runtime Evidence

## Status

`REQUIRES_SIMULATOR_OR_DEVICE`

The repository now contains executable local-fixture coverage for the DebugNetwork capture, body-store, parity, and burst-performance matrices. This report deliberately does not claim runtime timings or real-host behavior until the tests are run on an iOS Simulator/device host.

## Implemented fixture coverage

- GET, JSON POST, form POST, redirect, cancellation, timeout, 4xx, 5xx.
- Large request/response, chunked response, gzip response, and `httpBodyStream` marker.
- Body preview thresholds, file threshold, absolute limit, temporary cleanup, memory/disk budgets.
- 500/1000 record eviction, concurrent insert/finalize, and exactly-once finalization.
- Capture ON/OFF response-contract parity using the same deterministic fixture.
- Burst/performance cases for 100 and 1000 records.

## Verification boundary

- New fixture and test sources pass iOS Simulator frontend parsing.
- The workspace Debug and Release app builds pass with Xcode.
- `swift test` is not a valid runtime gate for this UIKit package on macOS because it resolves the macOS SDK and stops at `UIKit` dependency resolution.
- No CPU, memory, disk, MainActor, multi-scene, Alamofire, upload/download, SSE, WebSocket, or weak-network measurements are invented here.

## 下一步 / Próximo paso / Next step

Run the registered `PToolsDebugTests` target on an iOS Simulator and at least one real device, then append measured JSON/Markdown evidence and change the status only after the real-host matrix is complete.
