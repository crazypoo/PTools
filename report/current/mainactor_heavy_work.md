<!--
AUTO-GENERATED FILE.
DO NOT EDIT MANUALLY.

Generator: Scripts/report_mainactor_heavy_work.rb
Source revision: 5276a8381a0e5044f28fcf62920c9ef8e22c83dc
Generated at: 2026-09-20T14:21:09Z
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
| `PooToolsSource/Base/PTVideoCoverCache.swift` | 500 | `jpegData\(` | explicit-background-or-actor-boundary | `image.jpegData(compressionQuality: 0.8)` |
| `PooToolsSource/Base/PTVideoCoverCache.swift` | 515 | `FileManager.default` | review-required | `let attributes = try? FileManager.default.attributesOfItem(atPath: url.path) {` |
| `PooToolsSource/Category/PTVideoThumbnailService.swift` | 150 | `AVAssetImageGenerator` | review-required | `let generator = AVAssetImageGenerator(asset: AVURLAsset(url: url))` |
| `PooToolsSource/Category/PTVideoThumbnailService.swift` | 217 | `loadTracks\(` | explicit-background-or-actor-boundary | `guard let track = try await asset.loadTracks(withMediaType: .video).first else {` |
| `PooToolsSource/Category/PTVideoThumbnailService.swift` | 272 | `AVAssetImageGenerator` | review-required | `let generator = AVAssetImageGenerator(asset: asset)` |
| `PooToolsSource/Category/PTVideoThumbnailService.swift` | 287 | `generator.image` | review-required | `let result = try await generator.image(at: time)` |
| `PooToolsSource/Category/PTVideoThumbnailService.swift` | 298 | `AVAssetImageGenerator` | review-required | `let generator = AVAssetImageGenerator(asset: asset)` |
| `PooToolsSource/Core/PTLoadImageFunction.swift` | 96 | `Data\(contentsOf:` | dedicated-system-or-disk-boundary | `return try Data(contentsOf: url, options: .mappedIfSafe)` |
| `PooToolsSource/Core/PTLoadImageFunction.swift` | 623 | `CGImageSourceCreate` | review-required | `guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {` |
| `PooToolsSource/Core/PTLoadImageFunction.swift` | 635 | `CGImageSourceCreate` | review-required | `guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, options) else {` |
| `PooToolsSource/Core/PTLoadImageFunction.swift` | 654 | `CGImageSourceCreate` | review-required | `kCGImageSourceCreateThumbnailFromImageAlways as String: true,` |
| `PooToolsSource/Core/PTLoadImageFunction.swift` | 655 | `CGImageSourceCreate` | review-required | `kCGImageSourceCreateThumbnailWithTransform as String: true,` |
| `PooToolsSource/Core/PTLoadImageFunction.swift` | 674 | `CGImageSourceCreate` | review-required | `guard let source = CGImageSourceCreateWithData(data as CFData, nil),` |
| `PooToolsSource/Core/PTLoadImageFunction.swift` | 675 | `CGImageSourceCreate` | review-required | `let cgImage = CGImageSourceCreateImageAtIndex(source, 0, [` |
| `PooToolsSource/Core/PTLoadImageFunction.swift` | 679 | `UIImage\(data:` | review-required | `return UIImage(data: data)` |
| `PooToolsSource/NetWork/Network.swift` | 438 | `JSONDecoder` | review-required | `if let statusModel = try? JSONDecoder().decode(PTNetworkStatusModel.self, from: data) {` |
| `PooToolsSource/NetWork/Network.swift` | 694 | `JSONDecoder` | review-required | `let status = try? JSONDecoder().decode(PTNetworkStatusModel.self, from: data) else {` |
| `PooToolsSource/NetWork/Network.swift` | 794 | `JSONSerialization` | review-required | `if let jsonObject = try? JSONSerialization.jsonObject(with: body, options: []), let dictionary = jsonObject as? [String: any Any & Sendable] { dic = dictionary }` |
| `PooToolsSource/NetWork/Network.swift` | 840 | `JSONSerialization` | review-required | `if let jsonObject = try? JSONSerialization.jsonObject(with: body, options: []), let dictionary = jsonObject as? [String: any Any & Sendable] { dic = dictionary }` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 263 | `FileManager.default` | explicit-background-or-actor-boundary | `?? FileManager.default.temporaryDirectory.path` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 265 | `FileManager.default` | explicit-background-or-actor-boundary | `try? FileManager.default.createDirectory(atPath: diskPath, withIntermediateDirectories: true)` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 371 | `FileManager.default` | review-required | `try? FileManager.default.removeItem(atPath: path)` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 378 | `FileManager.default` | review-required | `try? FileManager.default.removeItem(atPath: diskPath)` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 379 | `FileManager.default` | review-required | `try? FileManager.default.createDirectory(atPath: diskPath, withIntermediateDirectories: true)` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 409 | `FileManager.default` | explicit-background-or-actor-boundary | `let fm = FileManager.default` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 441 | `JSONEncoder` | explicit-background-or-actor-boundary | `try? JSONEncoder().encode(object)` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 450 | `JSONDecoder` | explicit-background-or-actor-boundary | `try? JSONDecoder().decode(CacheObject.self, from: data)` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 459 | `Data\(contentsOf:` | explicit-background-or-actor-boundary | `try? Data(contentsOf: URL(fileURLWithPath: path))` |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 469 | `FileManager.default` | explicit-background-or-actor-boundary | `try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)` |
