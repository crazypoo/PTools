# PTools PR51–PR55 — Debug 6.0 stable candidate

Scope: PTools (`master`) and DevNetworkWatcher (`main`), each with an
independent feature branch/PR. No additional public network or diagnostics
schema changes have been requested.

## Change acceptance

| PR | PTools implementation | Studio companion |
| --- | --- | --- |
| PR51 | Bounded Debug Inspector snapshot preallocates capacity and retains a single preview flag rather than scanning already-appended entries. Constraint metadata reuses one `view.constraints` snapshot. | Real filter latency shown in Network footer, 100/500/1000 XCTest median/p95 baseline (non-gating). |
| PR52 | Opt-in iOS Debug Inspector reports **counts only** (`ownActiveConstraints`, `ownTotalConstraints`) through the existing schema v2 `attributes`. No constraint text, mutation or view-owned identity leaves the phone. | Advisory `mixedLayoutModes` hint; suppresses intentionally hidden zero-size warnings. Not an unsatisfiable-constraint detector. |
| PR53 | Privacy/redaction and the sampler remain the same owner; do not share mutable per-session state between phones. | In-memory search across workspaces, same-session-only diagnostic snapshot shortcuts. |
| PR54 | New static architecture gate `Scripts/validate_debug_studio_pr54.py` runs in the existing Quality/debug-core-manifest job. One Agent, one privacy module, one Inspector fingerprint owner; Foundation-only protocol, opt-in and read-only boundaries. | Existing `verify-pr50-boundaries.py` now guards single correlation owner and the session binding. |
| PR55 | Release checklist, source-of-truth report regeneration and explicit evidence blockers. | Release evidence template/validator plus Linux/macOS schema checks. |

## Required checks — NOT automatically satisfied by merged code

On Linux:
```sh
python3 Scripts/validate_debug_studio_pr54.py
bash Scripts/Governance/generate_all_current_reports.sh --check
swift package dump-package >/dev/null
```

On Mac/Xcode:
- Swift 6 strict concurrency Debug and public umbrella; iOS 17+ Inspector/Console/Metrics and CocoaPods compatibility
- iOS 13 deployment compatibility for compatible modules, and iOS 26/27 plus Duo folding/multi-window where relevant
- Two authorized iPhones and stable peer identities; trusted CA/pin and explicit opt-in; revoke, reconnect, pending command, wrong-session and replay
- Inspector screenshot, highlight, layout counts, edit/undo, privacy redaction; Console/Storage/Metrics read-only snapshots
- 100/500/1000 flows and views, live scope/search churn, 30-minute host idle + heavy CPU/memory using Instruments; compare against pre-patch baseline

The Mac companion provides `Docs/Studio_PR55_Release_Evidence.template.json`
and `Scripts/verify-pr55-release-evidence.py`. The template intentionally
starts with **not_run** for every required gate. An approval claim requires
replacing the template with actual evidence and running the verifier **without**
`--validate-template`. Never assert physical 7/7 pass or performance
percentages from synthetic Python/Swift benchmarks.

## Governance repair

`report/current` is exclusively generator-owned. Run:
```sh
bash Scripts/Governance/generate_all_current_reports.sh --write
bash Scripts/Governance/generate_all_current_reports.sh --check
```
The automated generator workflow on the PR feature branch writes only
`report/current`, not altered source, and does not disable required CI.
Review bot regeneration commits before merging; independent `Quality`,
`PTools Governance`, `iOS Inspector` and `cocoapods` checks must pass.

No 6.0 release authorization is implied by this documentation.
