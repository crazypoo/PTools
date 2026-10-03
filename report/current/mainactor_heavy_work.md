<!--
Current report metadata.
AUTO-GENERATED FILE.
Repository: crazypoo/PTools
Branch: master
Source revision: b6875bfcbb5b503f145e05d8bcc101c196cc316e
Source version: 5.60.0
Source inputs digest: eb66b030720b0fd30eb573eff88c7601464f448a455eafda9e1630c8be0309e3
Generator version: 1
Generator: Scripts/report_mainactor_heavy_work.rb
Generated at: 2026-10-03T05:18:13Z
-->

# MainActor 重活盘点

静态报告只用于定位和复核；运行时调度仍需通过 Xcode/Instruments 和真实宿主验证。

- 已识别并有边界：11
- 有意保留：26
- 需要人工复核：0

| 文件 | 行号 | 操作 | 分类 | 代码 |
| --- | ---: | --- | --- | --- |
| `PooToolsSource/Base/PTVideoCoverCache.swift` | 152 | `FileManager.default` | INTENTIONAL | `guard let files = try? FileManager.default.contentsOfDirectory(at: directory,` |
| `PooToolsSource/Base/PTVideoCoverCache.swift` | 170 | `FileManager.default` | INTENTIONAL | `try? FileManager.default.removeItem(at: entry.url)` |
| `PooToolsSource/Base/PTVideoCoverCache.swift` | 197 | `FileManager.default` | MIGRATED | `let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first` |
| `PooToolsSource/Base/PTVideoCoverCache.swift` | 200 | `FileManager.default` | INTENTIONAL | `if !FileManager.default.fileExists(atPath: dir.path) {` |
| `PooToolsSource/Base/PTVideoCoverCache.swift` | 201 | `FileManager.default` | INTENTIONAL | `try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)` |
| `PooToolsSource/Base/PTVideoCoverCache.swift` | 217 | `FileManager.default` | INTENTIONAL | `return FileManager.default.fileExists(atPath: url.path) ? url : nil` |
| `PooToolsSource/Base/PTVideoCoverCache.swift` | 222 | `FileManager.default` | INTENTIONAL | `guard FileManager.default.fileExists(atPath: localURL.path) else {` |
| `PooToolsSource/Base/PTVideoCoverCache.swift` | 227 | `FileManager.default` | INTENTIONAL | `if let attr = try? FileManager.default.attributesOfItem(atPath: localURL.path),` |
| `PooToolsSource/Base/PTVideoCoverCache.swift` | 520 | `jpegData\(` | MIGRATED | `image.jpegData(compressionQuality: 0.8)` |
| `PooToolsSource/Base/PTVideoCoverCache.swift` | 534 | `FileManager.default` | INTENTIONAL | `let attributes = try? FileManager.default.attributesOfItem(atPath: url.path) {` |
| `PooToolsSource/Category/PTVideoThumbnailService.swift` | 172 | `AVAssetImageGenerator` | INTENTIONAL | `let generator = AVAssetImageGenerator(asset: AVURLAsset(url: url))` |
| `PooToolsSource/Category/PTVideoThumbnailService.swift` | 239 | `loadTracks\(` | MIGRATED | `guard let track = try await asset.loadTracks(withMediaType: .video).first else {` |
| `PooToolsSource/Category/PTVideoThumbnailService.swift` | 294 | `AVAssetImageGenerator` | INTENTIONAL | `let generator = AVAssetImageGenerator(asset: asset)` |
| `PooToolsSource/Category/PTVideoThumbnailService.swift` | 309 | `generator.image` | INTENTIONAL | `let result = try await generator.image(at: time)` |
| `PooToolsSource/Category/PTVideoThumbnailService.swift` | 320 | `AVAssetImageGenerator` | INTENTIONAL | `let generator = AVAssetImageGenerator(asset: asset)` |
| `PooToolsSource/Core/PTLoadImageFunction.swift` | 96 | `Data\(contentsOf:` | MIGRATED | `return try Data(contentsOf: url, options: .mappedIfSafe)` |
| `PooToolsSource/Core/PTLoadImageFunction.swift` | 626 | `CGImageSourceCreate` | INTENTIONAL | `guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {` |
| `PooToolsSource/Core/PTLoadImageFunction.swift` | 638 | `CGImageSourceCreate` | INTENTIONAL | `guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, options) else {` |
| `PooToolsSource/Core/PTLoadImageFunction.swift` | 657 | `CGImageSourceCreate` | INTENTIONAL | `kCGImageSourceCreateThumbnailFromImageAlways as String: true,` |
| `PooToolsSource/Core/PTLoadImageFunction.swift` | 658 | `CGImageSourceCreate` | INTENTIONAL | `kCGImageSourceCreateThumbnailWithTransform as String: true,` |
| `PooToolsSource/Core/PTLoadImageFunction.swift` | 677 | `CGImageSourceCreate` | INTENTIONAL | `guard let source = CGImageSourceCreateWithData(data as CFData, nil),` |
| `PooToolsSource/Core/PTLoadImageFunction.swift` | 678 | `CGImageSourceCreate` | INTENTIONAL | `let cgImage = CGImageSourceCreateImageAtIndex(source, 0, [` |
| `PooToolsSource/Core/PTLoadImageFunction.swift` | 682 | `UIImage\(data:` | INTENTIONAL | `return UIImage(data: data)` |
| `PooToolsSource/NetWork/Network.swift` | 448 | `JSONDecoder` | INTENTIONAL | `if let statusModel = try? JSONDecoder().decode(PTNetworkStatusModel.self, from: data) {` |
| `PooToolsSource/NetWork/Network.swift` | 707 | `JSONDecoder` | INTENTIONAL | `let status = try? JSONDecoder().decode(PTNetworkStatusModel.self, from: data) else {` |
| `PooToolsSource/NetWork/Network.swift` | 810 | `JSONSerialization` | INTENTIONAL | `if let jsonObject = try? JSONSerialization.jsonObject(with: body, options: []), let dictionary = jsonObject as? [String: any Any & Sendable] { dic = dictionary }` |
| `PooToolsSource/NetWork/Network.swift` | 856 | `JSONSerialization` | INTENTIONAL | `if let jsonObject = try? JSONSerialization.jsonObject(with: body, options: []), let dictionary = jsonObject as? [String: any Any & Sendable] { dic = dictionary }` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 268 | `FileManager.default` | MIGRATED | `?? FileManager.default.temporaryDirectory.path` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 270 | `FileManager.default` | MIGRATED | `try? FileManager.default.createDirectory(atPath: diskPath, withIntermediateDirectories: true)` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 376 | `FileManager.default` | INTENTIONAL | `try? FileManager.default.removeItem(atPath: path)` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 383 | `FileManager.default` | INTENTIONAL | `try? FileManager.default.removeItem(atPath: diskPath)` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 384 | `FileManager.default` | INTENTIONAL | `try? FileManager.default.createDirectory(atPath: diskPath, withIntermediateDirectories: true)` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 414 | `FileManager.default` | MIGRATED | `let fm = FileManager.default` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 446 | `JSONEncoder` | MIGRATED | `try? JSONEncoder().encode(object)` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 455 | `JSONDecoder` | MIGRATED | `try? JSONDecoder().decode(CacheObject.self, from: data)` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 464 | `Data\(contentsOf:` | MIGRATED | `try? Data(contentsOf: URL(fileURLWithPath: path))` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 474 | `FileManager.default` | MIGRATED | `try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)` |
