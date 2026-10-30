# PTools PR46–PR50 — Debug 6.0 candidate acceptance

These stages do **not** change network schema v1, opt-in diagnostics schema v2,
the public Inspector API, Scene windows, Metrics recorder or Debug sampler ownership.

## Implemented / attempted changes

| Stage | Patch | Objective evidence |
| --- | --- | --- |
| PR46 | Dedicated source-of-truth **generator** workflow on this feature branch; regenerate `report/current` with the canonical script, check reproducibility, commit **only** its output. Existing CI check remains blocking. | Previous PR41–45 GitHub Actions reported `FAIL [CURRENT_REPORT_DRIFT]` in `debug-governance-repro`; generator job status must be checked independently. |
| PR47 | Mac Studio projects its large traffic table from a detached, cancellable task; no change to PTools capture batching or bridge protocol. | Companion Studio tests and Apple SDK build required. |
| PR48 | PTools opt-in Debug Inspector snapshot now includes `clipsToBounds` and `translatesAutoresizingMaskIntoConstraints` as read-only attributes, allowing Mac to flag **possible** clipping/zero frames. | No changes to original hierarchy IDs or `PTStudioDiagnosticEntry` wire shape. |
| PR49 | Mac Studio unifies filtering across Inspector/Console/Storage/Metrics and shows local snapshot time. | Companion Swift tests, privacy redaction and multi-device checks. |
| PR50 | Regression and release checklist; **no 6.0 release approval** until actual CI, source reports and two-phone QA succeed. | Collect logs, build metadata and device results. |

## PR46 report governance

The previous PR41–45 `Quality` workflow already proves the Foundation Debug compile and
source ownership smoke passed. The generator comparison failed because checked-in reports
were stale. The PR46 workflow subsequently committed refreshed generator-owned
`report/current` artifacts as commit `9cde6ab2336179514f494a52e16b92918cbcf268`.
That is source-derived output, **not** evidence that the complete Xcode or
governance suite passed. The PR46 workflow repairs the **source files' reports**, not the gate:
```sh
bash Scripts/Governance/generate_all_current_reports.sh --write
bash Scripts/Governance/generate_all_current_reports.sh --check
git diff --check
```
It pushes generated `report/current` back to this **feature branch only**, and exits
without commit when no diff remains. Verify the generated files are reviewable,
ensure the reports' source digest is current, and do not merge with a red CI job.
Do not manually mutate generated reports or adjust the 2000-line limit.

## Blocking validation

1. **Apple SDK:** Xcode Debug/Release builds; Swift 6 strict concurrency; CocoaPods
   plus SwiftPM iOS 17+ Inspector/Console/Metrics/umbrella builds.
2. **Real UI:** iOS 13+ where supported by distribution target, iOS 26/27,
   iPhone Duo/fold transition and multiple independent UIWindowScene instances.
3. **Agent permission:** opt-in, revoke, edit/Undo and redaction; exactly one
   log/recording owner and no new global swizzle.
4. **Performance:** 100/500/1000 flows and Inspector views, 30-minute idle CPU,
   allocations, timeline sampling, responsiveness, and before/after host metrics.
5. **Two physical phones:** Bonjour, CA/pin, pairing/revocation, reconnect,
   batching/ACK, delete/reset, wrong session and replay refusal.
6. **Docs/reports:** generated files exactly match generator, API freeze pass,
   version governance pass and 7/7 physical checklist with evidence.

At patch creation, these physical acceptance cases remain **NOT RUN**.
Automated Apple SDK results and generator repair need fresh CI confirmation.
