<!--
AUTO-GENERATED FILE.
DO NOT EDIT MANUALLY.

Generator: Scripts/report_mainactor_heavy_work.rb
Source revision: fb33a71e17c7112c3bf511e03440cbc6acbb4bd1
Generated at: 2026-09-26T14:07:57Z
-->

# MainActor 重活盘点

静态报告只用于定位和复核；运行时调度仍需通过 Xcode/Instruments 和真实宿主验证。

- 已识别并有边界：11
- 需要人工复核：26

| 文件 | 行号 | 操作 | 分类 | 代码 |
| --- | ---: | --- | --- | --- |
| `PooToolsSource/Base/PTVideoCoverCache.swift` | 147 | `FileManager.default` | explicit-background-or-actor-boundary | `guard let files = try? FileManager.default.contentsOfDirectory(at: directory,` |
| `PooToolsSource/Base/PTVideoCoverCache.swift` | 165 | `FileManager.default` | review-required | `try? FileManager.default.removeItem(at: entry.url)` |
| `PooToolsSource/Base/PTVideoCoverCache.swift` | 186 | `FileManager.default` | review-required | `let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first` |
| `PooToolsSource/Base/PTVideoCoverCache.swift` | 189 | `FileManager.default` | review-required | `if !FileManager.default.fileExists(atPath: dir.path) {` |
| `PooToolsSource/Base/PTVideoCoverCache.swift` | 190 | `FileManager.default` | review-required | `try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)` |
| `PooToolsSource/Base/PTVideoCoverCache.swift` | 206 | `FileManager.default` | review-required | `return FileManager.default.fileExists(atPath: url.path) ? url : nil` |
| `PooToolsSource/Base/PTVideoCoverCache.swift` | 211 | `FileManager.default` | review-required | `guard FileManager.default.fileExists(atPath: localURL.path) else {` |
| `PooToolsSource/Base/PTVideoCoverCache.swift` | 216 | `FileManager.default` | review-required | `if let attr = try? FileManager.default.attributesOfItem(atPath: localURL.path),` |
| `PooToolsSource/Base/PTVideoCoverCache.swift` | 502 | `jpegData\(` | explicit-background-or-actor-boundary | `image.jpegData(compressionQuality: 0.8)` |
| `PooToolsSource/Base/PTVideoCoverCache.swift` | 516 | `FileManager.default` | review-required | `let attributes = try? FileManager.default.attributesOfItem(atPath: url.path) {` |
| `PooToolsSource/Category/PTVideoThumbnailService.swift` | 172 | `AVAssetImageGenerator` | review-required | `let generator = AVAssetImageGenerator(asset: AVURLAsset(url: url))` |
| `PooToolsSource/Category/PTVideoThumbnailService.swift` | 239 | `loadTracks\(` | explicit-background-or-actor-boundary | `guard let track = try await asset.loadTracks(withMediaType: .video).first else {` |
| `PooToolsSource/Category/PTVideoThumbnailService.swift` | 294 | `AVAssetImageGenerator` | review-required | `let generator = AVAssetImageGenerator(asset: asset)` |
| `PooToolsSource/Category/PTVideoThumbnailService.swift` | 309 | `generator.image` | review-required | `let result = try await generator.image(at: time)` |
| `PooToolsSource/Category/PTVideoThumbnailService.swift` | 320 | `AVAssetImageGenerator` | review-required | `let generator = AVAssetImageGenerator(asset: asset)` |
| `PooToolsSource/Core/PTLoadImageFunction.swift` | 96 | `Data\(contentsOf:` | dedicated-system-or-disk-boundary | `return try Data(contentsOf: url, options: .mappedIfSafe)` |
| `PooToolsSource/Core/PTLoadImageFunction.swift` | 626 | `CGImageSourceCreate` | review-required | `guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {` |
| `PooToolsSource/Core/PTLoadImageFunction.swift` | 638 | `CGImageSourceCreate` | review-required | `guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, options) else {` |
| `PooToolsSource/Core/PTLoadImageFunction.swift` | 657 | `CGImageSourceCreate` | review-required | `kCGImageSourceCreateThumbnailFromImageAlways as String: true,` |
| `PooToolsSource/Core/PTLoadImageFunction.swift` | 658 | `CGImageSourceCreate` | review-required | `kCGImageSourceCreateThumbnailWithTransform as String: true,` |
| `PooToolsSource/Core/PTLoadImageFunction.swift` | 677 | `CGImageSourceCreate` | review-required | `guard let source = CGImageSourceCreateWithData(data as CFData, nil),` |
| `PooToolsSource/Core/PTLoadImageFunction.swift` | 678 | `CGImageSourceCreate` | review-required | `let cgImage = CGImageSourceCreateImageAtIndex(source, 0, [` |
| `PooToolsSource/Core/PTLoadImageFunction.swift` | 682 | `UIImage\(data:` | review-required | `return UIImage(data: data)` |
| `PooToolsSource/NetWork/Network.swift` | 437 | `JSONDecoder` | review-required | `if let statusModel = try? JSONDecoder().decode(PTNetworkStatusModel.self, from: data) {` |
| `PooToolsSource/NetWork/Network.swift` | 693 | `JSONDecoder` | review-required | `let status = try? JSONDecoder().decode(PTNetworkStatusModel.self, from: data) else {` |
| `PooToolsSource/NetWork/Network.swift` | 793 | `JSONSerialization` | review-required | `if let jsonObject = try? JSONSerialization.jsonObject(with: body, options: []), let dictionary = jsonObject as? [String: any Any & Sendable] { dic = dictionary }` |
| `PooToolsSource/NetWork/Network.swift` | 839 | `JSONSerialization` | review-required | `if let jsonObject = try? JSONSerialization.jsonObject(with: body, options: []), let dictionary = jsonObject as? [String: any Any & Sendable] { dic = dictionary }` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 262 | `FileManager.default` | explicit-background-or-actor-boundary | `?? FileManager.default.temporaryDirectory.path` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 264 | `FileManager.default` | explicit-background-or-actor-boundary | `try? FileManager.default.createDirectory(atPath: diskPath, withIntermediateDirectories: true)` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 370 | `FileManager.default` | review-required | `try? FileManager.default.removeItem(atPath: path)` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 377 | `FileManager.default` | review-required | `try? FileManager.default.removeItem(atPath: diskPath)` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 378 | `FileManager.default` | review-required | `try? FileManager.default.createDirectory(atPath: diskPath, withIntermediateDirectories: true)` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 408 | `FileManager.default` | explicit-background-or-actor-boundary | `let fm = FileManager.default` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 440 | `JSONEncoder` | explicit-background-or-actor-boundary | `try? JSONEncoder().encode(object)` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 449 | `JSONDecoder` | explicit-background-or-actor-boundary | `try? JSONDecoder().decode(CacheObject.self, from: data)` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 458 | `Data\(contentsOf:` | explicit-background-or-actor-boundary | `try? Data(contentsOf: URL(fileURLWithPath: path))` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 468 | `FileManager.default` | explicit-background-or-actor-boundary | `try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)` |
