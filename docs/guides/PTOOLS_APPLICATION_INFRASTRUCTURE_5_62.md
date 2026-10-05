# PTools 5.62.0 Application Infrastructure

本指南记录 5.62.0 P0/P1 应用基础设施的公共边界。所有能力均为可选模块，不进入默认 `Core`；默认目标仍是 iOS 17+ / Swift 6+。

## 模块与最小入口

| 能力 | SwiftPM | CocoaPods | 主要边界 |
| --- | --- | --- | --- |
| SQLite 数据库 | `PToolsDatabase` | `PooTools/Database` | `PToolsDatabaseCore` + actor SQLite3 |
| 认证 | `PToolsAuth` | `PooTools/Auth` | `PToolsStorage` / Keychain + single-flight refresh |
| 离线同步 | `PToolsSync` | `PooTools/Sync` | 幂等 mutation、重试和远程 adapter |
| 传输 | `PToolsTransfer` | `PooTools/Transfer` | 下载、上传、取消、进度、校验和后台配置 |
| StoreKit 2 | `PToolsStoreKit` | `PooTools/StoreKit` | 商品、购买、权益和交易监听 |
| 可观测性 | `PToolsObservability` | `PooTools/Observability` | event、metric、span、breadcrumb、error、脱敏 |
| Web Bridge | `PToolsWeb` / `PToolsWebBridge` | `PooTools/Web` | WebKit reply、Content World、来源策略、超时 |
| MapKit | `PToolsMap` | `PooTools/Map` | 地理编码、搜索、路线、快照、Apple Maps |
| App Integrity | `PToolsAppIntegrity` | `PooTools/AppIntegrity` | App Attest / DeviceCheck，服务端 challenge 由宿主负责 |
| Remote Config | `PToolsConfiguration` | `PooTools/Configuration` | ETag、TTL、缓存、LKG、稳定 rollout |
| Realtime | `PToolsRealtime` | `PooTools/Realtime` | SSE parser、Last-Event-ID、重连和既有 WebSocket adapter |

## 安装

```ruby
pod 'PooTools/Database'
pod 'PooTools/Auth'
pod 'PooTools/Sync'
pod 'PooTools/Transfer'
```

```swift
import PToolsDatabase
import PToolsAuth
```

Core contract 可单独选择 `PToolsDatabaseCore`、`PToolsAuthCore` 等 `Core` product；实现层不应把裸
SQLite、Keychain、WebKit、MapKit 或 StoreKit 对象跨 actor 传递。

## Database 最小用法

```swift
let database = try await PTDatabase.open(url: databaseURL)
try await database.execute("CREATE TABLE IF NOT EXISTS user (id INTEGER PRIMARY KEY, name TEXT NOT NULL)")
_ = try await database.insert(PTDatabaseQuery(
    "INSERT INTO user (name) VALUES (?)",
    arguments: [.text("Jax")]
))
let rows = try await database.query("SELECT id, name FROM user")
```

事务使用 `database.transaction { ... }`，迁移使用 `PTDatabaseMigrationPlan`；原始 Row API 始终保留，
Codable 映射是可选能力。不要在业务层调用 `sqlite3_*`，也不要把 SQLite handle 带出 `PTDatabase` actor。

## Auth / Network 边界

`PTAuthRefreshCoordinator` 对并发 401 只创建一个 refresh Task；Network 只通过 credential provider 读取
授权信息，不把 refresh 逻辑塞回 `Network.swift`。Token 存储复用 `PToolsStorage` 和 `PTKeychainStorage`。
OAuth PKCE、Apple 和 Passkey 通过 `PTAuthProvider` 形状接入，真实登录 UI 和服务端校验仍由宿主负责。

## Sync / Transfer

Sync mutation 必须带稳定 `idempotencyKey`，远程 adapter 负责服务端幂等；失败任务留在 store 中并受 retry limit
约束。Transfer 的下载、上传、取消和 `AsyncStream` 事件均由 `PTTransferQueue` actor 管理；大文件校验使用
checksum，iOS 后台宿主使用显式 `PTBackgroundTransferCapability` 标识和 URLSession background 配置。

## StoreKit / Observability

新购买代码使用 `PTStore` 和 `PTTransactionMonitor`；旧 `PTIAPManager` 仅为 StoreKit 1 兼容入口，并已标记弃用。
Observability 默认只记录有界内存快照，敏感 key（Authorization、Cookie、Token、Password）会被脱敏；宿主可以
注入异步 sink，但不得把完整响应体或凭据写入日志。

## Web / Map / Integrity / Remote Config / Realtime

- Web Bridge 使用 reply handler、`WKContentWorld.page`、主 frame 与 origin allowlist，并对 handler 应用超时。
- Map 值类型在 `PToolsMapCore`，MapKit 和 UIKit 适配在 `PToolsMap`，地图权限和 API key 由宿主处理。
- App Integrity 只生成真实 App Attest / DeviceCheck 证明，不伪造服务端通过；真机和服务器 challenge 必须单独验证。
- Remote Config 支持 ETag、TTL、cached fallback、最后已验证值和稳定 rollout；kill switch 应由配置 key 明确定义。
- SSE 使用 `PTSSEParser` 和 `Last-Event-ID`，WebSocket 复用既有 `PTWebSocketClient`，不创建第二套 Socket 实现。

## Demo 与验证

`infrastructure.database`、`infrastructure.auth`、`infrastructure.sync`、`infrastructure.transfer`、
`infrastructure.storekit`、`infrastructure.observability`、`infrastructure.webbridge`、`infrastructure.map`、
`infrastructure.integrity`、`infrastructure.remote-config` 和 `infrastructure.realtime` 已注册到 Demo Catalog。
其中需要 Entitlement、真机、网络或服务端的 Demo 会在目录中显示限制，不把环境阻断伪装成源码通过。

```bash
python3 Scripts/Example/validate_demo_coverage.py --check
bash Scripts/validate_application_infrastructure.sh
```

## Español / English

The same contracts are documented in the generated module guides under `docs/modules/ptools-*/README.en.md`
and `README.es.md`. Use the smallest opt-in product, keep UI work on `@MainActor`, pass only `Sendable` snapshots
across actors, and treat device, entitlement, server, and long-running performance evidence as host-level validation.
