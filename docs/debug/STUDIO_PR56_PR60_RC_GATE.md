# PTools 6.0 / DevNetworkWatcher — PR56–PR60 candidate gate

**Status: NOT RELEASE-APPROVED.** The code in this branch is a candidate,
not a claim that either native SDK builds or two-phone hardware acceptance ran.

| Phase | Implementation | Gate or evidence |
| --- | --- | --- |
| PR56 | Fixed `compare_current_reports.rb` to enumerate changed paths (Ruby `&` operator precedence had hidden the filenames). Minitest fixtures cover content drift, missing/extra report and provenance-only changes. | `ruby Tests/Governance/test_compare_current_reports.rb`, followed by the existing canonical `generate_all_current_reports.sh --check`. |
| PR57 | Added `Scripts/CI/verify_studio_native_targets.sh` to compile the protocol, core, UIKit leaves, Studio Bridge and legacy Debug target using the real iOS 17+ Simulator SDK, with the existing legacy Inspector leaf preserved. | Apple SDK runner must produce a **success** for `inspector-ios-compat`. Separate CocoaPods, strict-concurrency, xcode-build, version-governance and full Quality remain required. |
| PR58 | Mac collector aggregates adjacent sanitized request upserts **only on its private stdout IPC**; iOS Network v1 payload, ACK, TLS and session IDs remain unmodified. | Tests for 24-event batches, legacy single-entry and delete/reset order; 100/500/1000 real flow Instruments baseline must be recorded. |
| PR59 | Studio rejects diagnostic replies with expired pending request / stale heartbeat; serializes per-request stdout chunks from concurrent iPhones. | XCTest timeout/wrong-session negative cases and backend ordering tests; physical revoke/reconnect/replay. |
| PR60 | Complete automated + human evidence checklist, no release or new public tag. | Studio `Docs/Studio_PR55_Release_Evidence.template.json` and fail-closed verifier, full CI and actual two-device/30-minute profile evidence. |

## Known unresolved gate at branch creation

- PR51–PR55 merged into the primary branches on 2026-10-30, but
  its **PTools Quality and PTools Governance concluded failure**.
- Logs for the previous debug-governance-repro job showed
  `FAIL [CURRENT_REPORT_DRIFT]`. This patch corrects its *diagnostic
  detail*, but DOES NOT bypass a stale committed report or automatically
  assert that all remaining jobs passed.
- macOS Studio native workflow was queued at initial inspection. A
  passing Linux backend does not establish SwiftUI/Xcode compatibility.

The `refresh-current-reports-pr46.yml` workflow is deliberately limited
to the current PR feature branch and writes *only generator output* under
`report/current`. Review the generated diff. The independent reproducibility
job remains mandatory, and CI runs must be rechecked on the **newest
feature head** after the report commit. Bot-generated commits may not
automatically trigger every pull-request workflow; never interpret missing
checks as success.

## PTools native verification

```bash
ruby Tests/Governance/test_compare_current_reports.rb
python3 Scripts/validate_debug_studio_pr54.py
bash Scripts/Governance/generate_all_current_reports.sh --check
# macOS with real Xcode / iOS Simulator SDK:
bash Scripts/CI/verify_studio_native_targets.sh
# existing independent strict-concurrency / CocoaPods / Xcode CI gates
```

## Physical release acceptance (all currently **NOT RUN**)

1. Two real iPhones: Bonjour discovery, TLS leaf CA/pinning, pairing consent,
   automatic authorized reconnect, token revoke, reset/delete, ACK/replay.
2. Multi-window `UIWindowScene`, iOS 26/27, iPhone Duo folded/unfolded
   and legacy iOS 13-compatible modules without Debug UI regression.
3. 100/500/1000 flow capture: live sorting/filter/search/selection, clear
   and reset, no lost or reintroduced requests.
4. Inspector 100/500/900 nodes, authorized layout metadata, highlight,
   edit/undo, no cross-device diagnostic data or raw constraint values.
5. 30-minute idle and active Mac Studio Instruments CPU/memory/main-thread
   profile with build SHA, OS, processor, before/after measurements and traces.
6. Console/Storage/Performance privacy and expected single owner; no extra
   sampler, swizzling, hidden window, or untrusted network endpoint.
7. Release metadata, API freeze, generated docs/reports parity and clean
   CocoaPods+SwiftPM Debug/Release build.

**Release decision:** keep PRs as draft or under review while any required
gate is failed, missing, queued or has unreviewed physical evidence. Only
a complete evidence record and separate deliberate version/tag action can
authorize 6.0 GA.

## PR56 generator reconciliation

The canonical report workflow has committed its 43 regenerated
`report/current` files to the feature branch as
`c2e8baded3de1d0767c0cf124fe867bbde886c5e`.
The earlier `Quality` check ran against an older pull-request merge ref,
and therefore reported the previous stale files; that run is **not**
evidence about the later regenerated tree. A fresh PR-head workflow
must validate this regenerated commit without source changes. The
comparison fixture already passed 3 cases / 11 assertions on the
prior job, independently of the stale report failure.
