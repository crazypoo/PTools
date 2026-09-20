# Public API Baseline

`api-baseline/` 保存发布版本的公开 Swift API 快照。5.19.0 使用 `5.18.2` 作为基线：

- 新增 API 必须出现在 CHANGELOG 或迁移文档中。
- 删除 API 和 breaking signature 默认让门禁失败。
- deprecated API 必须注明兼容入口、canonical 入口和 6.0 删除条件。
- 报告来自 `Scripts/report_public_api_5_9.rb`；比较由 `Scripts/compare_public_api.rb` 完成。

## 目录约定

```text
api-baseline/
└── 5.18.2/
    └── public_api.json
```

更新 API 快照时必须同时运行：

```bash
bash Scripts/validate_api_baseline.sh
```

当前快照不是 ABI 保证，也不替代 iOS Simulator、真实宿主或真机编译验证。

