<!--
Current report metadata.
AUTO-GENERATED FILE.
Repository: crazypoo/PTools
Branch: master
Source revision: 3f9f7d5b604877bdb4a48d32a53944734c9c5072
Source version: 5.69.0
Source inputs digest: ed60290a1fc9bcf9c6196aef2f4a5f386a8a93a84f766fa6d58cfb4cb854f084
Generator version: 1
Generator: Scripts/report_mainactor_heavy_work.rb
Generated at: 2026-11-12T02:17:28Z
-->

# MainActor 重活盘点

静态报告只用于定位和复核；运行时调度仍需通过 Xcode/Instruments 和真实宿主验证。

- 已识别并有边界：11
- 有意保留：24
- 需要人工复核：0

| 文件 | 行号 | 操作 | 分类 | 代码 |
| --- | ---: | --- | --- | --- |
| `PooToolsSource/Base/PTVideoCoverCache.swift` | 129 | `FileManager.default` | INTENTIONAL | `guard let files = try? FileManager.default.contentsOfDirectory(at: directory,` |
| `PooToolsSource/Base/PTVideoCoverCache.swift` | 147 | `FileManager.default` | INTENTIONAL | `try? FileManager.default.removeItem(at: entry.url)` |
| `PooToolsSource/Base/PTVideoCoverCache.swift` | 174 | `FileManager.default` | MIGRATED | `let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first` |
| `PooToolsSource/Base/PTVideoCoverCache.swift` | 177 | `FileManager.default` | INTENTIONAL | `if !FileManager.default.fileExists(atPath: dir.path) {` |
| `PooToolsSource/Base/PTVideoCoverCache.swift` | 178 | `FileManager.default` | INTENTIONAL | `try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)` |
| `PooToolsSource/Base/PTVideoCoverCache.swift` | 194 | `FileManager.default` | INTENTIONAL | `return FileManager.default.fileExists(atPath: url.path) ? url : nil` |
| `PooToolsSource/Base/PTVideoCoverCache.swift` | 199 | `FileManager.default` | INTENTIONAL | `guard FileManager.default.fileExists(atPath: localURL.path) else {` |
| `PooToolsSource/Base/PTVideoCoverCache.swift` | 204 | `FileManager.default` | INTENTIONAL | `if let attr = try? FileManager.default.attributesOfItem(atPath: localURL.path),` |
| `PooToolsSource/Base/PTVideoCoverCache.swift` | 509 | `jpegData\(` | MIGRATED | `image.jpegData(compressionQuality: 0.8)` |
| `PooToolsSource/Base/PTVideoCoverCache.swift` | 523 | `FileManager.default` | INTENTIONAL | `let attributes = try? FileManager.default.attributesOfItem(atPath: url.path) {` |
| `PooToolsSource/Category/PTVideoThumbnailService.swift` | 172 | `AVAssetImageGenerator` | INTENTIONAL | `let generator = AVAssetImageGenerator(asset: AVURLAsset(url: url))` |
| `PooToolsSource/Category/PTVideoThumbnailService.swift` | 239 | `loadTracks\(` | MIGRATED | `guard let track = try await asset.loadTracks(withMediaType: .video).first else {` |
| `PooToolsSource/Category/PTVideoThumbnailService.swift` | 294 | `AVAssetImageGenerator` | INTENTIONAL | `let generator = AVAssetImageGenerator(asset: asset)` |
| `PooToolsSource/Category/PTVideoThumbnailService.swift` | 309 | `generator.image` | INTENTIONAL | `let result = try await generator.image(at: time)` |
| `PooToolsSource/Category/PTVideoThumbnailService.swift` | 320 | `AVAssetImageGenerator` | INTENTIONAL | `let generator = AVAssetImageGenerator(asset: asset)` |
| `PooToolsSource/Core/PTLoadImageFunction.swift` | 96 | `Data\(contentsOf:` | MIGRATED | `return try Data(contentsOf: url, options: .mappedIfSafe)` |
| `PooToolsSource/Core/PTLoadImageFunction.swift` | 730 | `CGImageSourceCreate` | INTENTIONAL | `guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {` |
| `PooToolsSource/Core/PTLoadImageFunction.swift` | 742 | `CGImageSourceCreate` | INTENTIONAL | `guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, options) else {` |
| `PooToolsSource/Core/PTLoadImageFunction.swift` | 763 | `CGImageSourceCreate` | INTENTIONAL | `kCGImageSourceCreateThumbnailFromImageAlways as String: true,` |
| `PooToolsSource/Core/PTLoadImageFunction.swift` | 764 | `CGImageSourceCreate` | INTENTIONAL | `kCGImageSourceCreateThumbnailWithTransform as String: true,` |
| `PooToolsSource/Core/PTLoadImageFunction.swift` | 784 | `CGImageSourceCreate` | INTENTIONAL | `guard let source = CGImageSourceCreateWithData(data as CFData, nil),` |
| `PooToolsSource/Core/PTLoadImageFunction.swift` | 785 | `CGImageSourceCreate` | INTENTIONAL | `let cgImage = CGImageSourceCreateImageAtIndex(source, 0, [` |
| `PooToolsSource/Core/PTLoadImageFunction.swift` | 789 | `UIImage\(data:` | INTENTIONAL | `return UIImage(data: data)` |
| `PooToolsSource/NetWork/Network.swift` | 448 | `JSONDecoder` | INTENTIONAL | `if let statusModel = try? JSONDecoder().decode(PTNetworkStatusModel.self, from: data) {` |
| `PooToolsSource/NetWork/Network.swift` | 635 | `JSONDecoder` | INTENTIONAL | `let status = try? JSONDecoder().decode(PTNetworkStatusModel.self, from: data) else {` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 266 | `FileManager.default` | MIGRATED | `?? FileManager.default.temporaryDirectory.path` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 268 | `FileManager.default` | MIGRATED | `try? FileManager.default.createDirectory(atPath: diskPath, withIntermediateDirectories: true)` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 370 | `FileManager.default` | INTENTIONAL | `try? FileManager.default.removeItem(atPath: path)` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 377 | `FileManager.default` | INTENTIONAL | `try? FileManager.default.removeItem(atPath: diskPath)` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 378 | `FileManager.default` | INTENTIONAL | `try? FileManager.default.createDirectory(atPath: diskPath, withIntermediateDirectories: true)` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 408 | `FileManager.default` | MIGRATED | `let fm = FileManager.default` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 440 | `JSONEncoder` | MIGRATED | `try? JSONEncoder().encode(object)` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 449 | `JSONDecoder` | MIGRATED | `try? JSONDecoder().decode(CacheObject.self, from: data)` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 458 | `Data\(contentsOf:` | MIGRATED | `try? Data(contentsOf: URL(fileURLWithPath: path))` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 468 | `FileManager.default` | MIGRATED | `try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)` |
