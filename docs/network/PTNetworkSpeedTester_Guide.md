# PTNetworkSpeedTester 指南

`PTNetworkSpeedTester` 是 5.61.0 的 actor 实现。它不内置生产公共测速服务器，调用方必须显式
提供下载和上传 endpoint，避免把测试流量误发到未知服务。

```swift
let configuration = PTNetworkSpeedTestConfiguration(
    downloadURL: URL(string: "https://example.com/test.bin"),
    uploadURL: URL(string: "https://example.com/upload"),
    uploadPayloadSize: 2 * 1024 * 1024
)

let stream = await PTNetworkSpeedTester.shared.start(configuration: configuration)
do {
    for try await snapshot in stream {
        print(snapshot.phase, snapshot.megabitsPerSecond)
    }
} catch {
    print(error.localizedDescription)
}
```

重复开始会取消上一轮会话。离开页面时调用 `await PTNetworkSpeedTester.shared.cancel()`，
并取消消费 Task。旧 `PTNetworkSpeedTestFunction` 仍保留，但空 endpoint 会返回明确错误。
