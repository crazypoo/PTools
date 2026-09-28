# PTools Documentation and Repository Governance

## English

`Scripts/Docs/audit_docs.py` is the canonical local entry point for documentation, module, script, data-asset, and test inventories.

```bash
python3 Scripts/Docs/audit_docs.py --write-all
python3 Scripts/Docs/audit_docs.py --check
bash Scripts/CI/check_5_56_1_governance.sh
```

English is the canonical technical source. Chinese and Spanish module guides share the same generated registry and section structure. Generated reports and module guides must not be hand-edited; change the registry or generator instead.

## 简体中文

`Scripts/Docs/audit_docs.py` 是文档、模块、脚本、数据资产和测试清单的唯一本地治理入口。

执行 `--write-all` 生成 registry、三语模块指南和报告，执行 `--check` 校验 manifest 漂移、三语文件完整性、链接和生成资产。历史计划只有在盘点和决策提炼后才进入 `docs/archive/`，禁止为了减少文件数量直接删除。

## Español

`Scripts/Docs/audit_docs.py` es la entrada canónica local para los inventarios de documentación, módulos, scripts, datos y tests.

English es la fuente técnica canónica; las guías en chino y español mantienen la misma estructura. Los informes y guías generados no se editan manualmente: se modifica el registro o el generador.

## Lifecycle

| Status | Meaning |
| --- | --- |
| ACTIVE | Current maintained guidance |
| ARCHIVED | Historical decision material |
| GENERATED | Reproducible script output |
| DELETED | Removed after consumer and history review |

## Version and review

The current documentation version comes from `VERSION`. The generator records the source revision and a deterministic commit timestamp. Formal module names come from `Package.swift` and `PooTools.podspec`; registry drift fails CI.
