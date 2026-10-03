<!--
AUTO-GENERATED FILE.
DO NOT EDIT MANUALLY.

Generator: Scripts/report_mainactor_heavy_work.rb
Source revision: e9ae991e3411ea728be377c2e82b1635af069c05
Generated at: 2026-10-03T13:42:43Z
-->

# MainActor 重活盘点

静态报告只用于定位和复核；运行时调度仍需通过 Xcode/Instruments 和真实宿主验证。

- 已识别并有边界：11
- 有意保留：24
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
| `PooToolsSource/NetWork/Network.swift` | 451 | `JSONDecoder` | INTENTIONAL | `if let statusModel = try? JSONDecoder().decode(PTNetworkStatusModel.self, from: data) {` |
| `PooToolsSource/NetWork/Network.swift` | 626 | `JSONDecoder` | INTENTIONAL | `let status = try? JSONDecoder().decode(PTNetworkStatusModel.self, from: data) else {` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 271 | `FileManager.default` | MIGRATED | `?? FileManager.default.temporaryDirectory.path` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 273 | `FileManager.default` | MIGRATED | `try? FileManager.default.createDirectory(atPath: diskPath, withIntermediateDirectories: true)` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 379 | `FileManager.default` | INTENTIONAL | `try? FileManager.default.removeItem(atPath: path)` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 386 | `FileManager.default` | INTENTIONAL | `try? FileManager.default.removeItem(atPath: diskPath)` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 387 | `FileManager.default` | INTENTIONAL | `try? FileManager.default.createDirectory(atPath: diskPath, withIntermediateDirectories: true)` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 417 | `FileManager.default` | MIGRATED | `let fm = FileManager.default` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 449 | `JSONEncoder` | MIGRATED | `try? JSONEncoder().encode(object)` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 458 | `JSONDecoder` | MIGRATED | `try? JSONDecoder().decode(CacheObject.self, from: data)` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 467 | `Data\(contentsOf:` | MIGRATED | `try? Data(contentsOf: URL(fileURLWithPath: path))` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 477 | `FileManager.default` | MIGRATED | `try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)` |
