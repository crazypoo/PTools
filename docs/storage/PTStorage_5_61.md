# PTStorage 5.61.0

`PTStorage` 是类型化 actor 存储入口；`PTMemoryStorage`、`PTUserDefaultsStorage`、
`PTFileStorage`、`PTKeychainStorage` 和 `PTCompositeStorage` 只是后端实现，不再新增平行的
typed UserDefaults 包装器。

```swift
struct Preferences: Codable, Sendable {
    let launchCount: Int
}

let storage = PTStorage(
    namespace: PTStorageNamespace(module: "PooTools", feature: "demo"),
    backend: PTUserDefaultsStorage()
)
let key = PTStorageKey<Preferences>("preferences")
try await storage.set(Preferences(launchCount: 1), for: key)
let value = try await storage.value(for: key)
```

`PTFileStorage` 会把读取、写入和删除放到 utility I/O 队列，并保留 atomic write。旧的
`UserDefaults+PTEX` 只做兼容转发，新的功能不要调用 `synchronize()` 或无范围清空。
