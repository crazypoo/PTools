# PTools Test Governance

## English

`docs/_meta/tests.yml` is the canonical test-target registry generated from `Package.swift`; `report/tests/TEST_INVENTORY.json` records the current files. Test levels are `UNIT`, `CONTRACT`, `INTEGRATION`, `PERFORMANCE`, and `DEVICE_ONLY`.

Do not create a new test target for every feature. Extend the existing domain target when the dependency boundary and execution lane are the same. Create a target only when isolation, platform availability, extension safety, or build-time ownership requires it. Never make a test target depend on `PooToolsAll` by default.

Execution lanes:

- PR fast: affected contract/unit targets and governance checks.
- PR full: all SwiftPM test targets plus the iOS workspace build.
- Nightly: performance, device-only, extension and host integration scenarios.
- Release: full matrix, CocoaPods, Simulator, Generic Device and documented real-device gates.

## 简体中文

`docs/_meta/tests.yml` 是从 `Package.swift` 生成的测试 target registry，`report/tests/TEST_INVENTORY.json` 记录当前文件。测试分为 `UNIT`、`CONTRACT`、`INTEGRATION`、`PERFORMANCE` 和 `DEVICE_ONLY` 五层。

不要为每个功能机械新增 test target。只要依赖边界和执行 lane 相同，就扩展已有领域 target；只有平台隔离、扩展安全、依赖所有权或构建时间确实需要时才创建新 target。默认禁止测试 target 依赖 `PooToolsAll`。

## Español

`docs/_meta/tests.yml` es el registro canónico de targets generado desde `Package.swift`; `report/tests/TEST_INVENTORY.json` contiene los archivos actuales. Las capas son `UNIT`, `CONTRACT`, `INTEGRATION`, `PERFORMANCE` y `DEVICE_ONLY`.

No se crea un target por cada funcionalidad. Se amplía el target de dominio existente cuando coinciden los límites de dependencia y la lane de ejecución; se crea uno nuevo solo cuando se necesita aislamiento, disponibilidad de plataforma, seguridad de extensión o propiedad de build.

## Canonical commands

```bash
python3 Scripts/Docs/audit_docs.py --write-all
python3 Scripts/Docs/audit_docs.py --check
bash Scripts/CI/check_5_56_1_governance.sh
```

Generated inventories are not hand-edited. Fixtures, mocks, golden files, timing baselines and quarantine entries must have an owner and an expiry in the registry or the corresponding test documentation.
