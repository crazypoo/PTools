<!--
Current report metadata.
AUTO-GENERATED FILE.
Repository: crazypoo/PTools
Branch: feature/pr56-pr60-rc-ci-security-20261030
Source revision: 1fb15b13c3f41fcaabd7a2ad5f537deb0a599df1
Source version: 5.69.0
Source inputs digest: d55d40519638e28785124558612fcb09551665299151a4effe0a7b983163cfcb
Generator version: 1
Generator: current-report-normalizer
Generated at: 2026-10-30T04:32:51Z
-->
<!-- Manual evidence is kept separate from generated scanner output. / La evidencia manual se mantiene separada del escáner generado. / 人工证据与扫描器生成结果分开保存。 -->
Source revision: be6cf4b34b62ce2c36f7639993c3eac176fd9ecb
Source manifest hash: 94c1e59b766ece9262682fde24122d12c890cba2c87e2cf367c113fc1db6bb39
Xcode: 27.2 (build 17C5046f)
iOS Simulator SDK: 27.2
Verification timestamp: 2026-10-24T19:13:14+08:00

# iPhone Duo Test Matrix / Matriz / 测试矩阵

| Case | Static evidence | Build | Runtime/visual | Device |
| --- | --- | --- | --- | --- |
| `DUO-T01` | pass_static: inventory and strict audit | pass_build: PooTools-Example Debug/Release app build | pending_runtime | pending_device |
| `DUO-T02` | pass_static: PhotoPicker paths inventoried | pass_build: PooTools-Example Debug/Release app build | pending_runtime | pending_device |
| `DUO-T03` | pass_static: navigation/WebView paths inventoried | pass_build: PooTools-Example Debug/Release app build | pending_runtime | pending_device |
| `DUO-T04` | pass_static: MediaViewer paths inventoried | pass_build: PooTools-Example Debug/Release app build | pending_runtime | pending_device |
| `DUO-T05` | pass_static: multi-scene LocalConsole paths inventoried | pass_build: PooTools-Example Debug/Release app build | pending_runtime | pending_device |
| `DUO-T06` | pass_static: Inspector paths inventoried | pass_build: PooTools-Example Debug/Release app build | pending_runtime | pending_device |
| `DUO-T07` | pass_static: QR/PhotoKit/DebugNetwork paths inventoried | pass_build: PooTools-Example Debug/Release app build | pending_runtime | pending_device |
| `DUO-T08` | pass_static: scanner self-test and strict-policy fixture pass | pass_build: scanner scripts | not_applicable | not_applicable |
| `DUO-T09` | pass_static: current checkout report freshness and strict check pass | pass_build: audit scripts | not_applicable | not_applicable |
| `DUO-T10` | pass_static: iPhone/iPad catalog entries available | pass_build: PooTools-Example Debug/Release app build | pending_runtime | pending_device |

## Current verification note

- `python3 Scripts/audit_duo_uikit_coverage.py --self-test` passed.
- `DUO_RELEASE_POLICY=strict python3 Scripts/audit_duo_uikit_coverage.py . --strict` passed, and `--check --strict` passed. This is a static audit result, not a runtime or visual pass.
- `bash Scripts/validate_duo_adaptive_bars.sh` passed its self-test, strict check, and source contract. The report keeps historical review decisions source-pinned; new or moved hits require re-review.
- `swift package dump-package` and `pod ipc spec PooTools.podspec` completed successfully.
- `PooTools-Example` iOS Simulator Debug and Release builds completed successfully with Xcode 27.2 and iOS Simulator SDK 27.2. The build was generic Simulator arm64/x86_64 and did not prove Duo behavior.
- The iPhone Duo simulator `839697B5-EE5E-44F5-A53C-C9F9964124BE` reached `Data Migration Failed` during boot. No erase or destructive recovery was performed, so all Duo runtime, visual, accessibility, and performance cases remain `pending_device`.
- The workspace has no Xcode test scheme/testable target for the `Tests/` tree. The tests were not reported as passed through a macOS `swift test`; an iOS XCTest target/runner is still required for T01–T07 and the specified behavior tests.

English: Static, build, runtime, visual, and device evidence are intentionally reported in separate layers.

Español: La evidencia estática, de compilación, ejecución, visual y dispositivo se informa por capas separadas.

中文：静态、构建、运行、视觉和设备证据按层级分别记录，避免把静态通过误报为 Duo 真机通过。
