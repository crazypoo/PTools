# Public API Baseline

`api-baseline/` 保存发布版本的公开 Swift API 快照。5.19.0、5.19.2 和 5.23.0 在缺少新的冻结快照时，
继续使用最近可用的 `5.18.2` 作为比较基线；门禁会明确打印这个回退，而不会伪造版本快照：

- 新增 API 必须出现在 CHANGELOG 或迁移文档中。
- 删除 API 和 breaking signature 默认让门禁失败。
- deprecated API 必须注明兼容入口、canonical 入口和 6.0 删除条件。
- 5.23.0 的 `removals_5.23.0.txt` 延续登记 5.22 日志兼容层已经审阅的删除项，避免旧迁移在新版本中被重复判定为未审阅。
- 报告来自 `Scripts/report_public_api_5_9.rb`；比较由 `Scripts/compare_public_api.rb` 完成。

## 目录约定

```text
api-baseline/
├── 5.18.2/
│   └── public_api.json
└── removals_<version>.txt
```

更新 API 快照时必须同时运行：

```bash
bash Scripts/validate_api_baseline.sh
```

当前快照不是 ABI 保证，也不替代 iOS Simulator、真实宿主或真机编译验证。
