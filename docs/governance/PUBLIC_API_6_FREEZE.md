# Public API 6.0 Freeze

公开符号分为 `canonical`、`compatibility`、`internal`、`experimental`。只有 canonical 入口获得 6.0 稳定承诺；5.x 兼容入口必须是转发层，不在兼容层复制业务实现。

当前机器事实来自 `report/current/public_api.json`，历史事实放在 `report/baselines/<version>`。新增公开 API 必须说明模块、并发隔离、替代入口和 6.0 归属。
