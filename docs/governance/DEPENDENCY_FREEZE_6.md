# Dependency Freeze 6.0

第三方依赖决策冻结在 `Scripts/dependency_freeze.json`，每项必须是 `KEEP`、`OPTIONAL_PRODUCT` 或 `REMOVE_IN_6`，并记录用途、原生替代、公开 API 暴露和删除前置条件。

DebugNetwork 不新增网络业务依赖，也不把 cache、retry、auth 或 dedup 复制到观测模块。
