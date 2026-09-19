<!--
AUTO-GENERATED FILE.
DO NOT EDIT MANUALLY.

Generator: Scripts/report_mainactor_heavy_work.rb
Source revision: bb9fa317fb1609afeb3774eb589eea2140d51e82
Generated at: 2026-09-19T18:12:00Z
-->

# MainActor 重活盘点

静态报告只用于定位和复核；运行时调度仍需通过 Xcode/Instruments 和真实宿主验证。

- 已识别并有边界：13
- 需要人工复核：27

| 文件 | 行号 | 操作 | 分类 | 代码 |
| --- | ---: | --- | --- | --- |
| `PooToolsSource/Base/PTVideoCoverCache.swift` | 24 | `FileManager.default` | explicit-background-or-actor-boundary | `let baseURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first` |
| `PooToolsSource/Base/PTVideoCoverCache.swift` | 27 | `FileManager.default` | review-required | `try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)` |
| `PooToolsSource/Base/PTVideoCoverCache.swift` | 36 | `FileManager.default` | review-required | `try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)` |
| `PooToolsSource/Base/PTVideoCoverCache.swift` | 53 | `FileManager.default` | review-required | `guard let files = try? FileManager.default.contentsOfDirectory(` |
| `PooToolsSource/Base/PTVideoCoverCache.swift` | 83 | `FileManager.default` | review-required | `try? FileManager.default.removeItem(at: entry.url)` |
| `PooToolsSource/Base/PTVideoCoverCache.swift` | 181 | `FileManager.default` | review-required | `let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first` |
| `PooToolsSource/Base/PTVideoCoverCache.swift` | 184 | `FileManager.default` | review-required | `if !FileManager.default.fileExists(atPath: dir.path) {` |
| `PooToolsSource/Base/PTVideoCoverCache.swift` | 185 | `FileManager.default` | review-required | `try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)` |
| `PooToolsSource/Base/PTVideoCoverCache.swift` | 200 | `FileManager.default` | review-required | `return FileManager.default.fileExists(atPath: url.path) ? url : nil` |
| `PooToolsSource/Base/PTVideoCoverCache.swift` | 205 | `FileManager.default` | review-required | `guard FileManager.default.fileExists(atPath: localURL.path) else {` |
| `PooToolsSource/Base/PTVideoCoverCache.swift` | 210 | `FileManager.default` | review-required | `if let attr = try? FileManager.default.attributesOfItem(atPath: localURL.path),` |
| `PooToolsSource/Base/PTVideoCoverCache.swift` | 484 | `UIImage\(data:` | explicit-background-or-actor-boundary | `UIImage(data: data)` |
| `PooToolsSource/Base/PTVideoCoverCache.swift` | 493 | `jpegData\(` | explicit-background-or-actor-boundary | `image.jpegData(compressionQuality: 0.8)` |
| `PooToolsSource/Base/PTVideoCoverCache.swift` | 508 | `FileManager.default` | review-required | `let attributes = try? FileManager.default.attributesOfItem(atPath: url.path) {` |
| `PooToolsSource/Category/PTVideoThumbnailService.swift` | 150 | `AVAssetImageGenerator` | review-required | `let generator = AVAssetImageGenerator(asset: AVURLAsset(url: url))` |
| `PooToolsSource/Category/PTVideoThumbnailService.swift` | 217 | `loadTracks\(` | explicit-background-or-actor-boundary | `guard let track = try await asset.loadTracks(withMediaType: .video).first else {` |
| `PooToolsSource/Category/PTVideoThumbnailService.swift` | 272 | `AVAssetImageGenerator` | review-required | `let generator = AVAssetImageGenerator(asset: asset)` |
| `PooToolsSource/Category/PTVideoThumbnailService.swift` | 287 | `generator.image` | review-required | `let result = try await generator.image(at: time)` |
| `PooToolsSource/Category/PTVideoThumbnailService.swift` | 298 | `AVAssetImageGenerator` | review-required | `let generator = AVAssetImageGenerator(asset: asset)` |
| `PooToolsSource/Core/PTLoadImageFunction.swift` | 96 | `Data\(contentsOf:` | dedicated-system-or-disk-boundary | `return try Data(contentsOf: url, options: .mappedIfSafe)` |
| `PooToolsSource/Core/PTLoadImageFunction.swift` | 415 | `Data\(contentsOf:` | explicit-background-or-actor-boundary | `guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {` |
| `PooToolsSource/Core/PTLoadImageFunction.swift` | 625 | `CGImageSourceCreate` | review-required | `guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {` |
| `PooToolsSource/Core/PTLoadImageFunction.swift` | 637 | `CGImageSourceCreate` | review-required | `guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, options) else {` |
| `PooToolsSource/Core/PTLoadImageFunction.swift` | 656 | `CGImageSourceCreate` | review-required | `kCGImageSourceCreateThumbnailFromImageAlways as String: true,` |
| `PooToolsSource/Core/PTLoadImageFunction.swift` | 657 | `CGImageSourceCreate` | review-required | `kCGImageSourceCreateThumbnailWithTransform as String: true,` |
| `PooToolsSource/Core/PTLoadImageFunction.swift` | 670 | `CGImageSourceCreate` | review-required | `let source = CGImageSourceCreateWithData(data as CFData, nil),` |
| `PooToolsSource/Core/PTLoadImageFunction.swift` | 671 | `CGImageSourceCreate` | review-required | `let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else {` |
| `PooToolsSource/Core/PTLoadImageFunction.swift` | 672 | `UIImage\(data:` | review-required | `return UIImage(data: data)` |
| `PooToolsSource/NetWork/Network.swift` | 383 | `JSONDecoder` | review-required | `if let statusModel = try? JSONDecoder().decode(PTNetworkStatusModel.self, from: data) {` |
| `PooToolsSource/NetWork/Network.swift` | 663 | `JSONSerialization` | review-required | `if let jsonObject = try? JSONSerialization.jsonObject(with: body, options: []), let dictionary = jsonObject as? [String: any Any & Sendable] { dic = dictionary }` |
| `PooToolsSource/NetWork/Network.swift` | 709 | `JSONSerialization` | review-required | `if let jsonObject = try? JSONSerialization.jsonObject(with: body, options: []), let dictionary = jsonObject as? [String: any Any & Sendable] { dic = dictionary }` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 246 | `FileManager.default` | explicit-background-or-actor-boundary | `?? FileManager.default.temporaryDirectory.path` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 248 | `FileManager.default` | explicit-background-or-actor-boundary | `try? FileManager.default.createDirectory(atPath: diskPath, withIntermediateDirectories: true)` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 311 | `FileManager.default` | review-required | `try? FileManager.default.removeItem(atPath: diskPath)` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 312 | `FileManager.default` | review-required | `try? FileManager.default.createDirectory(atPath: diskPath, withIntermediateDirectories: true)` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 342 | `FileManager.default` | explicit-background-or-actor-boundary | `let fm = FileManager.default` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 374 | `JSONEncoder` | explicit-background-or-actor-boundary | `try? JSONEncoder().encode(object)` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 383 | `JSONDecoder` | explicit-background-or-actor-boundary | `try? JSONDecoder().decode(CacheObject.self, from: data)` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 392 | `Data\(contentsOf:` | explicit-background-or-actor-boundary | `try? Data(contentsOf: URL(fileURLWithPath: path))` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 402 | `FileManager.default` | explicit-background-or-actor-boundary | `try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)` |
