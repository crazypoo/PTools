# Scripts Governance

The canonical documentation and repository-asset command is:

```bash
python3 Scripts/Docs/audit_docs.py --write-all
python3 Scripts/Docs/audit_docs.py --check
```

Use existing domain validators for domain-specific contracts. Do not create a new version-named validator when the canonical domain validator can evolve. Version-specific migration scripts are exceptions and must be recorded in `docs/_meta/scripts.yml`.

新增脚本前先检查 `docs/_meta/scripts.yml`，优先扩展现有 canonical 入口。新脚本必须说明输入、输出、破坏性行为和迁移期限。

Antes de crear un script, revisa `docs/_meta/scripts.yml` y amplía la entrada canónica existente cuando sea posible.
# PTAcknowledgements

`pt_acknowledgements_build.sh` 在构建期收集 `Package.resolved`、`Podfile.lock` 和本地覆盖文件，生成离线 `PTAcknowledgements.json` 与 CI 报告；`validate_acknowledgements.sh` 以 strict 模式校验生成结果。两个脚本只依赖 Bash、Swift 和仓库内的生成器，不要求安装 `rg`。

```sh
bash Scripts/pt_acknowledgements_build.sh
bash Scripts/validate_acknowledgements.sh .build/acknowledgements/PTAcknowledgements.json
```

For English and Español usage details, see `docs/guides/PTACKNOWLEDGEMENTS_GUIDE.md` and the module README translations.
