# Scripts Governance

The canonical documentation and repository-asset command is:

```bash
python3 Scripts/Docs/audit_docs.py --write-all
python3 Scripts/Docs/audit_docs.py --check
```

Use existing domain validators for domain-specific contracts. Do not create a new version-named validator when the canonical domain validator can evolve. Version-specific migration scripts are exceptions and must be recorded in `docs/_meta/scripts.yml`.

新增脚本前先检查 `docs/_meta/scripts.yml`，优先扩展现有 canonical 入口。新脚本必须说明输入、输出、破坏性行为和迁移期限。

Antes de crear un script, revisa `docs/_meta/scripts.yml` y amplía la entrada canónica existente cuando sea posible.
