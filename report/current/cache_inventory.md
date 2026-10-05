<!--
AUTO-GENERATED FILE.
DO NOT EDIT MANUALLY.

Generator: Scripts/report_cache_inventory.rb
Source revision: ce2216ac80d2a749565c5cf8a603b1407e82382e
Generated at: 2026-10-05T10:58:05Z
-->

# PTools 当前缓存盘点

本报告标出缓存实现位置，后续优化必须同时记录所有者、线程边界、容量和清理策略。

| 位置 | 类型 | 代码行 |
| --- | --- | --- |
| PooToolsSource/Base/PTAudioCache.swift:236 | disk or custom cache | // English: Derived durations use an explicit bounded cache policy. |
| PooToolsSource/Base/PTAudioCache.swift:242 | NSCache | private let durationCache: NSCache<NSString, NSNumber> = { |
| PooToolsSource/Base/PTAudioCache.swift:243 | NSCache | let cache = NSCache<NSString, NSNumber>() |
| PooToolsSource/Base/PTAudioCache.swift:244 | disk or custom cache | cache.countLimit = 256 |
| PooToolsSource/Base/PTAudioCache.swift:245 | disk or custom cache | cache.totalCostLimit = 256 * MemoryLayout<Float>.size |
| PooToolsSource/Base/PTAudioCache.swift:246 | disk or custom cache | return cache |
| PooToolsSource/Base/PTAudioCache.swift:260 | disk or custom cache | /// 获取音频时长（一定基于 cache 文件） |
| PooToolsSource/Base/PTAudioCache.swift:300 | disk or custom cache | /// 创建播放用 PlayerItem（只用 cache 文件） |
| PooToolsSource/Base/PTBaseDecorationFunction.swift:16 | disk or custom cache | // English: Cache the shadow geometry to avoid rebuilding the path on every layout pass. |
| PooToolsSource/Base/PTCollectionView.swift:547 | disk or custom cache | if let cache = heightCache.get(forKey: key) { |
| PooToolsSource/Base/PTCollectionView.swift:548 | disk or custom cache | return cache.doubleValue |
| PooToolsSource/Base/PTCollectionView.swift:1097 | disk or custom cache | if let cache = layoutCache.get(forKey: key) { |
| PooToolsSource/Base/PTCollectionView.swift:1098 | disk or custom cache | return cache |
| PooToolsSource/Base/PTCollectionView.swift:1191 | disk or custom cache | if let cache = waterfallCache[key] { |
| PooToolsSource/Base/PTCollectionView.swift:1192 | disk or custom cache | return (cache.items, cache.contentHeight) |
| PooToolsSource/Base/PTCollectionViewLayoutSupport.swift:5 | disk or custom cache | //  English: Keep pure layout cache keys outside the collection-view facade. |
| PooToolsSource/Base/PTCollectionViewTypes.swift:10 | disk or custom cache | // English: Keep the reusable cache type separate from PTCollectionView's facade and layout code. |
| PooToolsSource/Base/PTCollectionViewTypes.swift:15 | NSCache | private let cache = NSCache<WrappedKey, Value>() |
| PooToolsSource/Base/PTCollectionViewTypes.swift:18 | disk or custom cache | cache.countLimit = max(0, countLimit) |
| PooToolsSource/Base/PTCollectionViewTypes.swift:22 | disk or custom cache | cache.setObject(value, forKey: WrappedKey(key)) |
| PooToolsSource/Base/PTCollectionViewTypes.swift:26 | disk or custom cache | cache.object(forKey: WrappedKey(key)) |
| PooToolsSource/Base/PTCollectionViewTypes.swift:30 | disk or custom cache | cache.removeObject(forKey: WrappedKey(key)) |
| PooToolsSource/Base/PTCollectionViewTypes.swift:34 | disk or custom cache | cache.removeAllObjects() |
| PooToolsSource/Base/PTCollectionViewTypes.swift:308 | disk or custom cache | // English: Own list layout caches outside PTCollectionView so cache policy can evolve independently. |
| PooToolsSource/Base/PTVideoCoverCache.swift:111 | disk or custom cache | // English: A shared actor prevents concurrent callers from writing the same video cache file. |
| PooToolsSource/Base/PTVideoCoverCache.swift:177 | disk or custom cache | /// Video file cache manager. |
| PooToolsSource/Base/PTVideoCoverCache.swift:260 | disk or custom cache | /// Video cover cache and thumbnail request coordinator. |
| PooToolsSource/Base/PTVideoCoverCache.swift:362 | disk or custom cache | // English: Keep thumbnail limits aligned with the shared cache contract. |
| PooToolsSource/Base/PTVideoCoverCache.swift:369 | NSCache | @MainActor private static let memoryCache: NSCache<NSString, UIImage> = { |
| PooToolsSource/Base/PTVideoCoverCache.swift:370 | NSCache | let cache = NSCache<NSString, UIImage>() |
| PooToolsSource/Base/PTVideoCoverCache.swift:371 | disk or custom cache | cache.countLimit = cachePolicy.countLimit |
| PooToolsSource/Base/PTVideoCoverCache.swift:372 | disk or custom cache | cache.totalCostLimit = cachePolicy.costLimit |
| PooToolsSource/Base/PTVideoCoverCache.swift:373 | disk or custom cache | return cache |
| PooToolsSource/Base/PTVideoCoverCache.swift:482 | disk or custom cache | /// Preserves the URL-only key used by the video file cache. |
| PooToolsSource/Base/PTVideoCoverCache.swift:491 | disk or custom cache | /// Writes a JPEG cache entry atomically on a utility task. |
| PooToolsSource/Base/PTVideoCoverCache.swift:513 | disk or custom cache | // English: Encode generated thumbnails away from UI work before writing the disk cache. |
| PooToolsSource/Base/PTVideoCoverCache.swift:528 | disk or custom cache | // Keep invalid dimensions out of integer conversion and make the cache key deterministic. |
| PooToolsSource/Button/PTActionLayoutButton.swift:103 | disk or custom cache | // English: Cache the last layout size to avoid rebuilding identical constraints. |
| PooToolsSource/Category/FileManager+PTEX.swift:24 | disk or custom cache | - 3.1、Library/Cache |
| PooToolsSource/Category/FileManager+PTEX.swift:27 | disk or custom cache | - 系统不会清理 cache 目录中的文件 |
| PooToolsSource/Category/FileManager+PTEX.swift:28 | disk or custom cache | - 就要求程序开发时, "必须提供 cache 目录的清理解决方案" |
| PooToolsSource/Category/NSImageView+PTEX.swift:73 | NSCache | cache = NSCache() |
| PooToolsSource/Category/NSImageView+PTEX.swift:258 | disk or custom cache | /// Update cache for the current imageView. |
| PooToolsSource/Category/NSImageView+PTEX.swift:266 | disk or custom cache | cache?.removeAllObjects() |
| PooToolsSource/Category/NSImageView+PTEX.swift:293 | disk or custom cache | if haveCache, let image = cache?.object(forKey: displayOrderIndex as AnyObject) as? NSImage { |
| PooToolsSource/Category/NSImageView+PTEX.swift:353 | disk or custom cache | cache?.removeAllObjects() |
| PooToolsSource/Category/NSImageView+PTEX.swift:385 | NSCache | /// Prepare the cache by adding every images of the gif to an NSCache object. |
| PooToolsSource/Category/NSImageView+PTEX.swift:387 | disk or custom cache | guard let cache = self.cache else { return } |
| PooToolsSource/Category/NSImageView+PTEX.swift:389 | disk or custom cache | cache.removeAllObjects() |
| PooToolsSource/Category/NSImageView+PTEX.swift:398 | disk or custom cache | cache.setObject(NSImage(cgImage: cgImage, size: .zero), forKey: i as AnyObject) |
| PooToolsSource/Category/NSImageView+PTEX.swift:504 | NSCache | private var cache: NSCache<AnyObject, AnyObject>? { |
| PooToolsSource/Category/NSImageView+PTEX.swift:505 | NSCache | get { return (objc_getAssociatedObject(self, AssociatedKeys.NSImageViewGIFCacheKey!) as? NSCache) } |
| PooToolsSource/Category/UIApplication+PTEX.swift:27 | disk or custom cache | PTNSLogConsole("Failed to delete launch screen cache: \(result.error)",levelType: .error,loggerType: .uiApplication) |
| PooToolsSource/Category/UIImageView+PTEX.swift:192 | NSCache | cache = NSCache() |
| PooToolsSource/Category/UIImageView+PTEX.swift:349 | disk or custom cache | /// Update cache for the current imageView. |
| PooToolsSource/Category/UIImageView+PTEX.swift:357 | disk or custom cache | cache?.removeAllObjects() |
| PooToolsSource/Category/UIImageView+PTEX.swift:384 | disk or custom cache | if haveCache, let image = cache?.object(forKey: displayOrderIndex as AnyObject) as? UIImage { |
| PooToolsSource/Category/UIImageView+PTEX.swift:432 | disk or custom cache | cache?.removeAllObjects() |
| PooToolsSource/Category/UIImageView+PTEX.swift:464 | NSCache | /// Prepare the cache by adding every images of the gif to an NSCache object. |
| PooToolsSource/Category/UIImageView+PTEX.swift:466 | disk or custom cache | guard let cache = self.cache else { return } |
| PooToolsSource/Category/UIImageView+PTEX.swift:467 | disk or custom cache | cache.removeAllObjects() |
| PooToolsSource/Category/UIImageView+PTEX.swift:475 | disk or custom cache | cache.setObject(UIImage(cgImage: cgImage), forKey: i as AnyObject) |
| PooToolsSource/Category/UIImageView+PTEX.swift:491 | disk or custom cache | static var cache: UInt8 = 0 |
| PooToolsSource/Category/UIImageView+PTEX.swift:577 | NSCache | private var cache: NSCache<AnyObject, AnyObject>? { |
| PooToolsSource/Category/UIImageView+PTEX.swift:578 | NSCache | get { objc_getAssociatedObject(self, &AssociatedKeys.cache) as? NSCache } |
| PooToolsSource/Category/UIImageView+PTEX.swift:579 | disk or custom cache | set { objc_setAssociatedObject(self, &AssociatedKeys.cache, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) } |
| PooToolsSource/Core/BorderManager.swift:19 | disk or custom cache | // Previous configuration cache. |
| PooToolsSource/Core/PTCacheStore.swift:1 | disk or custom cache | // English: This bounded actor is the shared cache contract for resource and computation caches. |
| PooToolsSource/Core/PTGCDManager.swift:51 | NSCache | // 用于保存定时器的 Task 引用，替代原有的 NSCache 和 DispatchSourceTimer |
| PooToolsSource/Core/PTGifManager.swift:179 | disk or custom cache | /// Check if this manager has cache for an imageView |
| PooToolsSource/Core/PTGifManager.swift:180 | disk or custom cache | /// - Parameter imageView: The image view we're searching cache for |
| PooToolsSource/Core/PTGifManager.swift:181 | disk or custom cache | /// - Returns : a boolean for wether we have cache for the imageView |
| PooToolsSource/Core/PTLoadImageFunction.swift:550 | disk or custom cache | // Prefer Kingfisher's embedded original bytes before asking the cache serializer for data. |
| PooToolsSource/Core/PTMediaCache.swift:11 | disk or custom cache | // English: Cache variants are part of the key so originals, thumbnails, GIF frames, and Live Photo resources never collide. |
| PooToolsSource/Core/PTMediaCache.swift:24 | disk or custom cache | // English: A stable cache key is derived from media identity and rendering intent, not Swift's randomized hashValue. |
| PooToolsSource/Debug/CwlDemangle.swift:3481 | disk or custom cache | _ = printOptional(name.children.at(0), prefix: "lazy protocol witness table cache variable for type ") |
| PooToolsSource/Debug/CwlDemangle.swift:3548 | disk or custom cache | case .typeMetadataInstantiationCache: printFirstChild(name, prefix: "type metadata instantiation cache for ") |
| PooToolsSource/Debug/CwlDemangle.swift:3549 | disk or custom cache | case .typeMetadataInstantiationFunction: printFirstChild(name, prefix: "type metadata instantiation cache for ") |
| PooToolsSource/Debug/CwlDemangle.swift:3551 | disk or custom cache | case .typeMetadataLazyCache: printFirstChild(name, prefix: "lazy cache variable for type metadata for ") |
| PooToolsSource/DebugCategory/HTTPURLResponse+PTEX.swift:13 | disk or custom cache | if let cc = (allHeaderFields["Cache-Control"] as? String)?.lowercased(), |
| PooToolsSource/DebugCategory/URLCache+PTDebugEX.swift:2 | URLCache | //  URLCache+PTDebugEX.swift |
| PooToolsSource/DebugCategory/URLCache+PTDebugEX.swift:11 | URLCache | extension URLCache { |
| PooToolsSource/DebugCategory/URLCache+PTDebugEX.swift:13 | URLCache | static let customHttp: URLCache = { |
| PooToolsSource/DebugCategory/URLCache+PTDebugEX.swift:23 | URLCache | return URLCache( |
| PooToolsSource/DebugCategory/URLCache+PTDebugEX.swift:42 | URLCache | URLCache.cachedExtensions.contains(ext), |
| PooToolsSource/DebugCategory/URLCache+PTDebugEX.swift:57 | URLCache | URLCache.cacheIOQueue.async { |
| PooToolsSource/DebugCategory/URLCache+PTDebugEX.swift:65 | URLCache | return URLCache.cacheIOQueue.sync { |
| PooToolsSource/DebugCategory/URLCache+PTDebugEX.swift:66 | disk or custom cache | guard let cache = self.cachedResponse(for: request), |
| PooToolsSource/DebugCategory/URLCache+PTDebugEX.swift:67 | disk or custom cache | let info = cache.userInfo, |
| PooToolsSource/DebugCategory/URLCache+PTDebugEX.swift:74 | disk or custom cache | return cache |
| PooToolsSource/DebugLibs/PTLoadedImageTypes.swift:29 | disk or custom cache | return "Shared Cache / System Image" |
| PooToolsSource/DebugLibs/PTLoadedLibrariesViewModel.swift:117 | disk or custom cache | report += "- Shared Cache Candidates: \(diagnostics.sharedCacheCandidateCount)\n" |
| PooToolsSource/DebugNetwork/PTNetworkExporters.swift:88 | disk or custom cache | "cache": [:], |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1417 | disk or custom cache | // English: Filter previews use an explicit bounded cache policy. |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1423 | NSCache | private lazy var filterCache: NSCache<NSString, UIImage> = { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1424 | NSCache | let cache = NSCache<NSString, UIImage>() |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1425 | disk or custom cache | cache.countLimit = filterCachePolicy.countLimit |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1426 | disk or custom cache | cache.totalCostLimit = filterCachePolicy.costLimit |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1427 | disk or custom cache | return cache |
| PooToolsSource/KingfisherSVG/Kingfisher+SVG.swift:17 | disk or custom cache | // It will be used when storing and retrieving the image to/from cache. |
| PooToolsSource/NetWork/Network.swift:65 | disk or custom cache | case cache(String) |
| PooToolsSource/NetWork/Network.swift:93 | disk or custom cache | case .cache(let message): return "PT Network cache failed: \(message)" |
| PooToolsSource/NetWork/Network.swift:120 | disk or custom cache | case .cache: return 9999999912 |
| PooToolsSource/NetWork/Network.swift:285 | URLCache | urlConfiguration.urlCache = URLCache(memoryCapacity: configurationSnapshot.memoryCapacity, |
| PooToolsSource/NetWork/Network.swift:523 | disk or custom cache | throw PTNetworkError.cache("cacheOnly 没有可用缓存 / cacheOnly has no usable entry / cacheOnly no tiene una entrada utilizable") |
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
| PooToolsSource/PToolsUIFoundation/PTRichTextMedia.swift:691 | NSCache | private let imageCache = NSCache<NSString, UIImage>() |
| PooToolsSource/PToolsUIFoundation/PTRichTextMedia.swift:692 | NSCache | private let posterCache = NSCache<NSString, UIImage>() |
| PooToolsSource/PToolsUIFoundation/PTRichTextMedia.swift:869 | disk or custom cache | // English: The poster renderer uses the bounded rich-text cache contract. |
| PooToolsSource/PToolsUIFoundation/PTRichTextMedia.swift:875 | NSCache | private static let cache: NSCache<NSString, UIImage> = { |
| PooToolsSource/PToolsUIFoundation/PTRichTextMedia.swift:876 | NSCache | let cache = NSCache<NSString, UIImage>() |
| PooToolsSource/PToolsUIFoundation/PTRichTextMedia.swift:877 | disk or custom cache | cache.countLimit = cachePolicy.countLimit |
| PooToolsSource/PToolsUIFoundation/PTRichTextMedia.swift:878 | disk or custom cache | cache.totalCostLimit = cachePolicy.costLimit |
| PooToolsSource/PToolsUIFoundation/PTRichTextMedia.swift:879 | disk or custom cache | return cache |
| PooToolsSource/PToolsUIFoundation/PTRichTextMedia.swift:892 | disk or custom cache | cache.removeAllObjects() |
| PooToolsSource/PToolsUIFoundation/PTRichTextMedia.swift:901 | disk or custom cache | if let cached = cache.object(forKey: key as NSString) { |
| PooToolsSource/PToolsUIFoundation/PTRichTextMedia.swift:961 | disk or custom cache | cache.setObject(rendered, forKey: key as NSString) |
| PooToolsSource/PhotoPicker/PTMediaLibViewController.swift:630 | disk or custom cache | PTAlertTipsViewController.tipsAlertShow(title: "Error",subtitle: "Save to cache failed", icon: .Error) |
| PooToolsSource/PhotoPicker/PTMediaLibViewController.swift:668 | disk or custom cache | // MARK: - Cache Helper |
| PooToolsSource/PhotoPicker/PTMediaLibViewController.swift:682 | disk or custom cache | PTNSLogConsole("Video cache export failed: \(String(describing: error))") |
| PooToolsSource/Router/PTRouterServiceManager.swift:159 | disk or custom cache | // MARK: - Service Clean Cache |
| PooToolsSource/SegmentControl/PTMainSegmentDataSource.swift:63 | disk or custom cache | /// English: Refreshes the native item cache; old callers can then call apply(to:). |
| PooToolsSource/SegmentControl/PTPageContainer.swift:1 | disk or custom cache | // English: Owns loaded page views, lifecycle callbacks and stable-ID cache policy. |
| PooToolsSource/SegmentControl/PTPageContainer.swift:19 | disk or custom cache | /// English: A lazy, stable-ID horizontal page container that owns page lifecycle and cache policy. |
| PooToolsSource/SegmentControl/PTPageContainer.swift:219 | disk or custom cache | /// English: Returns whether a page is currently held by the container cache. |
| PooToolsSource/SegmentControl/PTSegmentedTypes.swift:606 | disk or custom cache | /// English: Cache policy for lazy pages. |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:758 | disk or custom cache | open func cache(viewControllerGenerator: @escaping () -> UIViewController?, with identifier: String) { |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:762 | disk or custom cache | open func cache(viewController: UIViewController, with identifier: String) { |
