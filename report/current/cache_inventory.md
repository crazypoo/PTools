<!--
Current report metadata.
AUTO-GENERATED FILE.
Repository: crazypoo/PTools
Branch: feature/pr46-pr50-inspector-layout-governance-20261030
Source revision: 0deb064cea510c896e78b35fab0997808e796173
Source version: 5.69.0
Source inputs digest: 8c745967288dcd0493111e7ec716d9f601938762a8f52bae2525c7d3591bb455
Generator version: 1
Generator: Scripts/report_cache_inventory.rb
Generated at: 2026-10-30T03:42:31Z
-->

# PTools 当前缓存盘点

本报告标出缓存实现位置，后续优化必须同时记录所有者、线程边界、容量和清理策略。

| 位置 | 类型 | 代码行 |
| --- | --- | --- |
| PooToolsSource/Base/PTAudioCache.swift:141 | disk or custom cache | // English: Derived durations use an explicit bounded cache policy. |
| PooToolsSource/Base/PTAudioCache.swift:147 | NSCache | private let durationCache: NSCache<NSString, NSNumber> = { |
| PooToolsSource/Base/PTAudioCache.swift:148 | NSCache | let cache = NSCache<NSString, NSNumber>() |
| PooToolsSource/Base/PTAudioCache.swift:149 | disk or custom cache | cache.countLimit = 256 |
| PooToolsSource/Base/PTAudioCache.swift:150 | disk or custom cache | cache.totalCostLimit = 256 * MemoryLayout<Float>.size |
| PooToolsSource/Base/PTAudioCache.swift:151 | disk or custom cache | return cache |
| PooToolsSource/Base/PTAudioCache.swift:165 | disk or custom cache | /// 获取音频时长（一定基于 cache 文件） |
| PooToolsSource/Base/PTAudioCache.swift:205 | disk or custom cache | /// 创建播放用 PlayerItem（只用 cache 文件） |
| PooToolsSource/Base/PTBaseDecorationFunction.swift:16 | disk or custom cache | // English: Cache the shadow geometry to avoid rebuilding the path on every layout pass. |
| PooToolsSource/Base/PTBaseViewController+Navigation.swift:79 | disk or custom cache | // English: Cache only the value signature and weak view identity used by the title adapters. |
| PooToolsSource/Base/PTBaseViewController+Navigation.swift:292 | disk or custom cache | // English: Cache only an expanded large-title compact row that satisfies the current content requirement. |
| PooToolsSource/Base/PTCollectionView.swift:131 | disk or custom cache | // English: Invalidate every geometry cache when a runtime layout contract changes. |
| PooToolsSource/Base/PTCollectionView.swift:844 | disk or custom cache | if let cache = heightCache.get(forKey: key) { |
| PooToolsSource/Base/PTCollectionView.swift:845 | disk or custom cache | return cache.doubleValue |
| PooToolsSource/Base/PTCollectionView.swift:1598 | disk or custom cache | if let cache = layoutCache.get(forKey: key) { |
| PooToolsSource/Base/PTCollectionView.swift:1599 | disk or custom cache | return cache |
| PooToolsSource/Base/PTCollectionView.swift:1709 | disk or custom cache | if let cache = waterfallCache[key] { |
| PooToolsSource/Base/PTCollectionView.swift:1710 | disk or custom cache | return (cache.items, cache.contentHeight) |
| PooToolsSource/Base/PTCollectionView.swift:2436 | disk or custom cache | // English: Invalidate only the geometry cache for the requested rows. |
| PooToolsSource/Base/PTCollectionViewLayoutSupport.swift:5 | disk or custom cache | //  English: Keep pure layout cache keys outside the collection-view facade. |
| PooToolsSource/Base/PTCollectionViewTypes.swift:10 | disk or custom cache | // English: Keep the reusable cache type separate from PTCollectionView's facade and layout code. |
| PooToolsSource/Base/PTCollectionViewTypes.swift:15 | NSCache | private let cache = NSCache<WrappedKey, Value>() |
| PooToolsSource/Base/PTCollectionViewTypes.swift:18 | disk or custom cache | cache.countLimit = max(0, countLimit) |
| PooToolsSource/Base/PTCollectionViewTypes.swift:22 | disk or custom cache | cache.setObject(value, forKey: WrappedKey(key)) |
| PooToolsSource/Base/PTCollectionViewTypes.swift:26 | disk or custom cache | cache.object(forKey: WrappedKey(key)) |
| PooToolsSource/Base/PTCollectionViewTypes.swift:30 | disk or custom cache | cache.removeObject(forKey: WrappedKey(key)) |
| PooToolsSource/Base/PTCollectionViewTypes.swift:34 | disk or custom cache | cache.removeAllObjects() |
| PooToolsSource/Base/PTCollectionViewTypes.swift:414 | disk or custom cache | // English: Own list layout caches outside PTCollectionView so cache policy can evolve independently. |
| PooToolsSource/Base/PTNavigationBarManager.swift:552 | disk or custom cache | // English: Do not cache a zero frame while UIKit is between layout states. |
| PooToolsSource/Base/PTNavigationBarManager.swift:888 | disk or custom cache | // English: Use only a geometry-validated compact row, then test measured fallbacks before caching. |
| PooToolsSource/Base/PTNavigationContentRowResolver.swift:99 | disk or custom cache | // English: Reject a thin or out-of-host row before it can become a cache entry. |
| PooToolsSource/Base/PTVideoCoverCache.swift:154 | disk or custom cache | /// Video file cache manager. |
| PooToolsSource/Base/PTVideoCoverCache.swift:249 | disk or custom cache | /// Video cover cache and thumbnail request coordinator. |
| PooToolsSource/Base/PTVideoCoverCache.swift:351 | disk or custom cache | // English: Keep thumbnail limits aligned with the shared cache contract. |
| PooToolsSource/Base/PTVideoCoverCache.swift:358 | NSCache | @MainActor private static let memoryCache: NSCache<NSString, UIImage> = { |
| PooToolsSource/Base/PTVideoCoverCache.swift:359 | NSCache | let cache = NSCache<NSString, UIImage>() |
| PooToolsSource/Base/PTVideoCoverCache.swift:360 | disk or custom cache | cache.countLimit = cachePolicy.countLimit |
| PooToolsSource/Base/PTVideoCoverCache.swift:361 | disk or custom cache | cache.totalCostLimit = cachePolicy.costLimit |
| PooToolsSource/Base/PTVideoCoverCache.swift:362 | disk or custom cache | return cache |
| PooToolsSource/Base/PTVideoCoverCache.swift:471 | disk or custom cache | /// Preserves the URL-only key used by the video file cache. |
| PooToolsSource/Base/PTVideoCoverCache.swift:480 | disk or custom cache | /// Writes a JPEG cache entry atomically on a utility task. |
| PooToolsSource/Base/PTVideoCoverCache.swift:502 | disk or custom cache | // English: Encode generated thumbnails away from UI work before writing the disk cache. |
| PooToolsSource/Base/PTVideoCoverCache.swift:517 | disk or custom cache | // Keep invalid dimensions out of integer conversion and make the cache key deterministic. |
| PooToolsSource/Base/PTVideoCoverCache.swift:531 | disk or custom cache | // English: Version the key because this cache now stores pixel-bounded covers. |
| PooToolsSource/Button/PTActionLayoutButton.swift:103 | disk or custom cache | // English: Cache the last layout size to avoid rebuilding identical constraints. |
| PooToolsSource/C7Collector/C7Collector.swift:77 | disk or custom cache | // English: Harbeth owns the shared texture cache and supplies it at conversion time. |
| PooToolsSource/C7Collector/C7Collector.swift:90 | disk or custom cache | // English: Let each Harbeth distribution provide its own shared texture cache. |
| PooToolsSource/Category/FileManager+PTEX.swift:24 | disk or custom cache | - 3.1、Library/Cache |
| PooToolsSource/Category/FileManager+PTEX.swift:27 | disk or custom cache | - 系统不会清理 cache 目录中的文件 |
| PooToolsSource/Category/FileManager+PTEX.swift:28 | disk or custom cache | - 就要求程序开发时, "必须提供 cache 目录的清理解决方案" |
| PooToolsSource/Category/NSImageView+PTEX.swift:74 | NSCache | cache = NSCache() |
| PooToolsSource/Category/NSImageView+PTEX.swift:243 | disk or custom cache | /// Update cache for the current imageView. |
| PooToolsSource/Category/NSImageView+PTEX.swift:251 | disk or custom cache | cache?.removeAllObjects() |
| PooToolsSource/Category/NSImageView+PTEX.swift:278 | disk or custom cache | if haveCache, let image = cache?.object(forKey: displayOrderIndex as AnyObject) as? NSImage { |
| PooToolsSource/Category/NSImageView+PTEX.swift:338 | disk or custom cache | cache?.removeAllObjects() |
| PooToolsSource/Category/NSImageView+PTEX.swift:370 | NSCache | /// Prepare the cache by adding every images of the gif to an NSCache object. |
| PooToolsSource/Category/NSImageView+PTEX.swift:372 | disk or custom cache | guard let cache = self.cache else { return } |
| PooToolsSource/Category/NSImageView+PTEX.swift:374 | disk or custom cache | cache.removeAllObjects() |
| PooToolsSource/Category/NSImageView+PTEX.swift:383 | disk or custom cache | cache.setObject(NSImage(cgImage: cgImage, size: .zero), forKey: i as AnyObject) |
| PooToolsSource/Category/NSImageView+PTEX.swift:489 | NSCache | private var cache: NSCache<AnyObject, AnyObject>? { |
| PooToolsSource/Category/NSImageView+PTEX.swift:490 | NSCache | get { return (objc_getAssociatedObject(self, AssociatedKeys.NSImageViewGIFCacheKey!) as? NSCache) } |
| PooToolsSource/Category/UIApplication+PTEX.swift:27 | disk or custom cache | PTNSLogConsole("Failed to delete launch screen cache: \(result.error)",levelType: .error,loggerType: .uiApplication) |
| PooToolsSource/Category/UIImageView+PTEX.swift:198 | NSCache | cache = NSCache() |
| PooToolsSource/Category/UIImageView+PTEX.swift:354 | disk or custom cache | /// Update cache for the current imageView. |
| PooToolsSource/Category/UIImageView+PTEX.swift:362 | disk or custom cache | cache?.removeAllObjects() |
| PooToolsSource/Category/UIImageView+PTEX.swift:389 | disk or custom cache | if haveCache, let image = cache?.object(forKey: displayOrderIndex as AnyObject) as? UIImage { |
| PooToolsSource/Category/UIImageView+PTEX.swift:453 | disk or custom cache | cache?.removeAllObjects() |
| PooToolsSource/Category/UIImageView+PTEX.swift:485 | NSCache | /// Prepare the cache by adding every images of the gif to an NSCache object. |
| PooToolsSource/Category/UIImageView+PTEX.swift:487 | disk or custom cache | guard let cache = self.cache else { return } |
| PooToolsSource/Category/UIImageView+PTEX.swift:488 | disk or custom cache | cache.removeAllObjects() |
| PooToolsSource/Category/UIImageView+PTEX.swift:496 | disk or custom cache | cache.setObject(UIImage(cgImage: cgImage), forKey: i as AnyObject) |
| PooToolsSource/Category/UIImageView+PTEX.swift:512 | disk or custom cache | static var cache: UInt8 = 0 |
| PooToolsSource/Category/UIImageView+PTEX.swift:598 | NSCache | private var cache: NSCache<AnyObject, AnyObject>? { |
| PooToolsSource/Category/UIImageView+PTEX.swift:599 | NSCache | get { objc_getAssociatedObject(self, &AssociatedKeys.cache) as? NSCache } |
| PooToolsSource/Category/UIImageView+PTEX.swift:600 | disk or custom cache | set { objc_setAssociatedObject(self, &AssociatedKeys.cache, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) } |
| PooToolsSource/Core/BorderManager.swift:23 | disk or custom cache | // English: Cache the previous layer configuration for restoration. |
| PooToolsSource/Core/PTCacheStore.swift:1 | disk or custom cache | // English: This bounded actor is the shared cache contract for resource and computation caches. |
| PooToolsSource/Core/PTGCDManager.swift:51 | NSCache | // 用于保存定时器的 Task 引用，替代原有的 NSCache 和 DispatchSourceTimer |
| PooToolsSource/Core/PTGifManager.swift:179 | disk or custom cache | /// Check if this manager has cache for an imageView |
| PooToolsSource/Core/PTGifManager.swift:180 | disk or custom cache | /// - Parameter imageView: The image view we're searching cache for |
| PooToolsSource/Core/PTGifManager.swift:181 | disk or custom cache | /// - Returns : a boolean for wether we have cache for the imageView |
| PooToolsSource/Core/PTLoadImageFunction.swift:648 | disk or custom cache | // Prefer Kingfisher's embedded original bytes before asking the cache serializer for data. |
| PooToolsSource/Core/PTMediaCache.swift:11 | disk or custom cache | // English: Cache variants are part of the key so originals, thumbnails, GIF frames, and Live Photo resources never collide. |
| PooToolsSource/Core/PTMediaCache.swift:24 | disk or custom cache | // English: A stable cache key is derived from media identity and rendering intent, not Swift's randomized hashValue. |
| PooToolsSource/Debug/CwlDemangle.swift:3484 | disk or custom cache | _ = printOptional(name.children.at(0), prefix: "lazy protocol witness table cache variable for type ") |
| PooToolsSource/Debug/CwlDemangle.swift:3551 | disk or custom cache | case .typeMetadataInstantiationCache: printFirstChild(name, prefix: "type metadata instantiation cache for ") |
| PooToolsSource/Debug/CwlDemangle.swift:3552 | disk or custom cache | case .typeMetadataInstantiationFunction: printFirstChild(name, prefix: "type metadata instantiation cache for ") |
| PooToolsSource/Debug/CwlDemangle.swift:3554 | disk or custom cache | case .typeMetadataLazyCache: printFirstChild(name, prefix: "lazy cache variable for type metadata for ") |
| PooToolsSource/DebugCategory/HTTPURLResponse+PTEX.swift:16 | disk or custom cache | if let cc = (allHeaderFields["Cache-Control"] as? String)?.lowercased(), |
| PooToolsSource/DebugCategory/URLCache+PTDebugEX.swift:2 | URLCache | //  URLCache+PTDebugEX.swift |
| PooToolsSource/DebugCategory/URLCache+PTDebugEX.swift:14 | URLCache | extension URLCache { |
| PooToolsSource/DebugCategory/URLCache+PTDebugEX.swift:16 | URLCache | static let customHttp: URLCache = { |
| PooToolsSource/DebugCategory/URLCache+PTDebugEX.swift:26 | URLCache | return URLCache( |
| PooToolsSource/DebugCategory/URLCache+PTDebugEX.swift:45 | URLCache | URLCache.cachedExtensions.contains(ext), |
| PooToolsSource/DebugCategory/URLCache+PTDebugEX.swift:60 | URLCache | URLCache.cacheIOQueue.async { |
| PooToolsSource/DebugCategory/URLCache+PTDebugEX.swift:68 | URLCache | return URLCache.cacheIOQueue.sync { |
| PooToolsSource/DebugCategory/URLCache+PTDebugEX.swift:69 | disk or custom cache | guard let cache = self.cachedResponse(for: request), |
| PooToolsSource/DebugCategory/URLCache+PTDebugEX.swift:70 | disk or custom cache | let info = cache.userInfo, |
| PooToolsSource/DebugCategory/URLCache+PTDebugEX.swift:77 | disk or custom cache | return cache |
| PooToolsSource/DebugLibs/PTLoadedImageTypes.swift:32 | disk or custom cache | return "Shared Cache / System Image" |
| PooToolsSource/DebugLibs/PTLoadedLibrariesViewModel.swift:120 | disk or custom cache | report += "- Shared Cache Candidates: \(diagnostics.sharedCacheCandidateCount)\n" |
| PooToolsSource/DebugNetwork/PTNetworkExporters.swift:92 | disk or custom cache | "cache": [:], |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1417 | disk or custom cache | // English: Filter previews use an explicit bounded cache policy. |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1423 | NSCache | private lazy var filterCache: NSCache<NSString, UIImage> = { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1424 | NSCache | let cache = NSCache<NSString, UIImage>() |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1425 | disk or custom cache | cache.countLimit = filterCachePolicy.countLimit |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1426 | disk or custom cache | cache.totalCostLimit = filterCachePolicy.costLimit |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1427 | disk or custom cache | return cache |
| PooToolsSource/KingfisherSVG/Kingfisher+SVG.swift:24 | disk or custom cache | // It will be used when storing and retrieving the image to/from cache. |
| PooToolsSource/NetWork/Network.swift:65 | disk or custom cache | case cache(String) |
| PooToolsSource/NetWork/Network.swift:93 | disk or custom cache | case .cache(let message): return "PT Network cache failed: \(message)" |
| PooToolsSource/NetWork/Network.swift:120 | disk or custom cache | case .cache: return 9999999912 |
| PooToolsSource/NetWork/Network.swift:283 | URLCache | urlConfiguration.urlCache = URLCache(memoryCapacity: configurationSnapshot.memoryCapacity, |
| PooToolsSource/NetWork/Network.swift:508 | disk or custom cache | throw PTNetworkError.cache("cacheOnly 没有可用缓存 / cacheOnly has no usable entry / cacheOnly no tiene una entrada utilizable") |
| PooToolsSource/NetWork/NetworkSupport.swift:1 | disk or custom cache | // English: Keep retry, cache, reachability, and upload support outside the Network facade. |
| PooToolsSource/NetWork/NetworkSupport.swift:240 | disk or custom cache | // English: A cache entry carries validators and freshness without exposing URLSession objects. |
| PooToolsSource/NetWork/NetworkSupport.swift:260 | NSCache | private let memoryCache = NSCache<NSString, NSData>() |
| PooToolsSource/NetWork/NetworkSupport.swift:269 | disk or custom cache | // English: Bound the in-memory cache so a large response cannot grow without limit. |
| PooToolsSource/NetWork/NetworkSupport.swift:289 | disk or custom cache | "pt-cache-miss", |
| PooToolsSource/NetWork/NetworkSupport.swift:299 | disk or custom cache | // English: Cache-control and revalidation headers must not change the resource identity. |
| PooToolsSource/NetWork/NetworkSupport.swift:392 | disk or custom cache | // English: Accept a caller-owned configuration so cache maintenance does not read Network.share. |
| PooToolsSource/NetWork/NetworkSupport.swift:439 | disk or custom cache | // English: Keep JSON and file operations off the cache actor while the actor owns only cache state. |
| PooToolsSource/NetWork/NetworkSupport.swift:448 | disk or custom cache | // English: Decode cache metadata on a utility executor before updating actor-owned memory state. |
| PooToolsSource/NetWork/NetworkSupport.swift:457 | disk or custom cache | // English: Read cache files without occupying the actor executor with synchronous file I/O. |
| PooToolsSource/NetWork/NetworkSupport.swift:466 | disk or custom cache | // English: Persist cache data on a background executor and keep the actor responsive. |
| PooToolsSource/NetWork/NetworkSupport.swift:501 | disk or custom cache | get { value(forHTTPHeaderField: "PT-Cache-Miss") == "true" } |
| PooToolsSource/NetWork/NetworkSupport.swift:502 | disk or custom cache | set { setValue(newValue ? "true" : "false", forHTTPHeaderField: "PT-Cache-Miss") } |
| PooToolsSource/NetWork/NetworkSupport.swift:523 | disk or custom cache | // English: Expose the default cache adapter so the public Network initializer can use it safely. |
| PooToolsSource/NetWork/NetworkSupport.swift:549 | disk or custom cache | if request.cachePolicyType == .networkElseCache, let cache = await NetworkCache.shared.read(request: request) { |
| PooToolsSource/NetWork/NetworkSupport.swift:550 | disk or custom cache | NotificationCenter.default.post(name: NSNotification.Name("PTNetworkCacheFallback"), object: cache) |
| PooToolsSource/NetWork/NetworkSupport.swift:556 | disk or custom cache | if response?.value(forHTTPHeaderField: "Cache-Control")?.lowercased().contains("no-store") == true { return } |
| PooToolsSource/NetWork/NetworkSupport.swift:582 | disk or custom cache | guard let cacheControl = response?.value(forHTTPHeaderField: "Cache-Control") else { return fallback } |
| PooToolsSource/PDF/UIImage+PTpdfEX.swift:158 | disk or custom cache | // MARK: - Cache Public |
| PooToolsSource/PDF/UIImage+PTpdfEX.swift:164 | disk or custom cache | // English: PDF rendering cache limits follow the repository cache contract. |
| PooToolsSource/PDF/UIImage+PTpdfEX.swift:216 | disk or custom cache | // MARK: - Cache Private |
| PooToolsSource/PDF/UIImage+PTpdfEX.swift:219 | disk or custom cache | // MARK: - Memory Cache |
| PooToolsSource/PDF/UIImage+PTpdfEX.swift:220 | NSCache | @MainActor private static let imageCache: NSCache<NSString, UIImage> = { |
| PooToolsSource/PDF/UIImage+PTpdfEX.swift:221 | NSCache | let cache = NSCache<NSString, UIImage>() |
| PooToolsSource/PDF/UIImage+PTpdfEX.swift:222 | disk or custom cache | cache.countLimit = pdfCachePolicy.countLimit |
| PooToolsSource/PDF/UIImage+PTpdfEX.swift:223 | disk or custom cache | cache.totalCostLimit = pdfCachePolicy.costLimit |
| PooToolsSource/PDF/UIImage+PTpdfEX.swift:224 | disk or custom cache | return cache |
| PooToolsSource/PDF/UIImage+PTpdfEX.swift:237 | disk or custom cache | // MARK: - Disk Cache |
| PooToolsSource/PToolsConfiguration/PTRemoteConfigurationProviders.swift:177 | disk or custom cache | public let cache: any PTConfigurationProvider |
| PooToolsSource/PToolsConfiguration/PTRemoteConfigurationProviders.swift:178 | disk or custom cache | public init(remote: any PTConfigurationProvider, cache: any PTConfigurationProvider) { |
| PooToolsSource/PToolsConfiguration/PTRemoteConfigurationProviders.swift:179 | disk or custom cache | self.remote = remote; self.cache = cache |
| PooToolsSource/PToolsConfiguration/PTRemoteConfigurationProviders.swift:183 | disk or custom cache | catch { return try await cache.values(for: context) } |
| PooToolsSource/PToolsCore/PTCoreContracts.swift:5 | disk or custom cache | // English: Foundation-only contracts shared by logging, cache, and error adapters. |
| PooToolsSource/PToolsCore/PTCoreContracts.swift:40 | disk or custom cache | // English: Use a small typed cache contract instead of exposing a third-party cache type. |
| PooToolsSource/PToolsCore/PTCoreContracts.swift:53 | disk or custom cache | // English: The default memory cache is actor-isolated, bounded by ownership, and dependency-free. |
| PooToolsSource/PToolsCore/PTCoreValueTypes.swift:49 | disk or custom cache | // English: Shared cache values stay in the Foundation-only Core product so every target uses one contract. |
| PooToolsSource/PToolsDebugMetricsUI/PTDebugMetricsTrackRenderer.swift:13 | disk or custom cache | // not once per visible track. Do not cache across trait changes. |
| PooToolsSource/PToolsHTTPServer/PTHTTPTypes.swift:267 | disk or custom cache | .setting("no-cache", for: "Cache-Control") |
| PooToolsSource/PToolsLogging/Destinations/PTOSLogDestination.swift:39 | disk or custom cache | // English: Cache OSLog Logger instances so high-frequency logging does not recreate them. |
| PooToolsSource/PToolsLogging/Destinations/PTOSLogDestination.swift:44 | disk or custom cache | return loggerCache.withLock { cache in |
| PooToolsSource/PToolsLogging/Destinations/PTOSLogDestination.swift:45 | disk or custom cache | if let logger = cache[key] { |
| PooToolsSource/PToolsLogging/Destinations/PTOSLogDestination.swift:49 | disk or custom cache | cache[key] = logger |
| PooToolsSource/PToolsMediaCore/PTMediaCoreContracts.swift:187 | disk or custom cache | // English: Cache access is asynchronous and value-based, preventing feature modules from sharing mutable caches. |
| PooToolsSource/PToolsUIFoundation/PTRichTextBuilder.swift:21 | disk or custom cache | // English: This compatibility boundary is only for immutable matcher reuse; every cache access is serialized by the lock. |
| PooToolsSource/PToolsUIFoundation/PTRichTextCache.swift:1 | disk or custom cache | // English: Lock-protected Foundation matcher cache shared by rich-text value operations. |
| PooToolsSource/PToolsUIFoundation/PTRichTextCache.swift:9 | NSCache | private let regexCache = NSCache<NSString, NSRegularExpression>() |
| PooToolsSource/PToolsUIFoundation/PTRichTextCache.swift:10 | NSCache | private let detectorCache = NSCache<NSNumber, NSDataDetector>() |
| PooToolsSource/PToolsUIFoundation/PTRichTextMatcher.swift:1 | disk or custom cache | // English: Rich-text match rules and conflict policies remain value-only and independent from caching. |
| PooToolsSource/PToolsUIFoundation/PTRichTextMedia.swift:751 | NSCache | private let imageCache = NSCache<NSString, UIImage>() |
| PooToolsSource/PToolsUIFoundation/PTRichTextMedia.swift:752 | NSCache | private let posterCache = NSCache<NSString, UIImage>() |
| PooToolsSource/PToolsUIFoundation/PTRichTextMedia.swift:929 | disk or custom cache | // English: The poster renderer uses the bounded rich-text cache contract. |
| PooToolsSource/PToolsUIFoundation/PTRichTextMedia.swift:935 | NSCache | private static let cache: NSCache<NSString, UIImage> = { |
| PooToolsSource/PToolsUIFoundation/PTRichTextMedia.swift:936 | NSCache | let cache = NSCache<NSString, UIImage>() |
| PooToolsSource/PToolsUIFoundation/PTRichTextMedia.swift:937 | disk or custom cache | cache.countLimit = cachePolicy.countLimit |
| PooToolsSource/PToolsUIFoundation/PTRichTextMedia.swift:938 | disk or custom cache | cache.totalCostLimit = cachePolicy.costLimit |
| PooToolsSource/PToolsUIFoundation/PTRichTextMedia.swift:939 | disk or custom cache | return cache |
| PooToolsSource/PToolsUIFoundation/PTRichTextMedia.swift:952 | disk or custom cache | cache.removeAllObjects() |
| PooToolsSource/PToolsUIFoundation/PTRichTextMedia.swift:961 | disk or custom cache | if let cached = cache.object(forKey: key as NSString) { |
| PooToolsSource/PToolsUIFoundation/PTRichTextMedia.swift:1021 | disk or custom cache | cache.setObject(rendered, forKey: key as NSString) |
| PooToolsSource/PhotoPicker/PTMediaLibListModel.swift:449 | disk or custom cache | // English: Cache the result of the asynchronous public PhotoKit size request for final selection validation. |
| PooToolsSource/PhotoPicker/PTMediaLibView.swift:1209 | disk or custom cache | message: "Save to cache failed", |
| PooToolsSource/PhotoPicker/PTMediaLibView.swift:1212 | disk or custom cache | PTAlertTipsViewController.tipsAlertShow(title: "Error", subtitle: "Save to cache failed", icon: .Error) |
| PooToolsSource/PhotoPicker/PTMediaLibView.swift:1220 | disk or custom cache | // English: Remove the exported cache file after PhotoKit has finished reading it. |
| PooToolsSource/PhotoPicker/PTMediaLibView.swift:1260 | disk or custom cache | // MARK: - Cache Helper |
| PooToolsSource/PhotoPicker/PTMediaLibView.swift:1274 | disk or custom cache | PTNSLogConsole("Video cache export failed: \(String(describing: error))") |
| PooToolsSource/Router/PTRouterServiceManager.swift:159 | disk or custom cache | // MARK: - Service Clean Cache |
| PooToolsSource/SegmentControl/PTMainSegmentDataSource.swift:66 | disk or custom cache | /// English: Refreshes the native item cache; old callers can then call apply(to:). |
| PooToolsSource/SegmentControl/PTPageContainer.swift:1 | disk or custom cache | // English: Owns loaded page views, lifecycle callbacks and stable-ID cache policy. |
| PooToolsSource/SegmentControl/PTPageContainer.swift:19 | disk or custom cache | /// English: A lazy, stable-ID horizontal page container that owns page lifecycle and cache policy. |
| PooToolsSource/SegmentControl/PTPageContainer.swift:219 | disk or custom cache | /// English: Returns whether a page is currently held by the container cache. |
| PooToolsSource/SegmentControl/PTSegmentedTypes.swift:606 | disk or custom cache | /// English: Cache policy for lazy pages. |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:758 | disk or custom cache | open func cache(viewControllerGenerator: @escaping () -> UIViewController?, with identifier: String) { |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:762 | disk or custom cache | open func cache(viewController: UIViewController, with identifier: String) { |
