# PTPingSession 指南

`PTPingSession` 使用 actor 管理状态和 `AsyncThrowingStream` 输出，状态包括 resolving、ready、
sending、waiting、success、failed 和 stopped。它替代旧的 Timer/RunLoop 轮询入口，新代码无需
自行管理计时器。

```swift
let session = PTPingSession()
let stream = await session.start(host: "example.com", interval: .seconds(1))

do {
    for try await response in stream {
        print(response.responseTime)
    }
} catch {
    print(error.localizedDescription)
}

await session.stop()
```

旧 `PTPingTool` 和 callback 入口继续兼容。主机解析失败、地址族不支持、发送失败和停止都会
进入明确的错误/终态，不再从公共路径触发 `fatalError`。
