<!--
AUTO-GENERATED FILE.
DO NOT EDIT MANUALLY.

Generator: Scripts/report_cache_inventory_5_9.rb
Source revision: 84f512673b489f53d4eac962bef71e5903208ac1
Generated at: 2026-09-23T07:31:34Z
-->

# PTools 当前缓存盘点

本报告标出缓存实现位置，后续优化必须同时记录所有者、线程边界、容量和清理策略。

| 位置 | 类型 | 代码行 |
| --- | --- | --- |
| PooToolsSource/Base/PTAudioCache.swift:199 | NSCache | private let durationCache: NSCache<NSString, NSNumber> = { |
| PooToolsSource/Base/PTAudioCache.swift:200 | NSCache | let cache = NSCache<NSString, NSNumber>() |
| PooToolsSource/Base/PTAudioCache.swift:201 | disk or custom cache | cache.countLimit = 256 |
| PooToolsSource/Base/PTAudioCache.swift:202 | disk or custom cache | cache.totalCostLimit = 256 * MemoryLayout<Float>.size |
| PooToolsSource/Base/PTAudioCache.swift:203 | disk or custom cache | return cache |
| PooToolsSource/Base/PTAudioCache.swift:215 | disk or custom cache | /// 获取音频时长（一定基于 cache 文件） |
| PooToolsSource/Base/PTAudioCache.swift:255 | disk or custom cache | /// 创建播放用 PlayerItem（只用 cache 文件） |
| PooToolsSource/Base/PTBaseDecorationFunction.swift:16 | disk or custom cache | // English: Cache the shadow geometry to avoid rebuilding the path on every layout pass. |
| PooToolsSource/Base/PTCollectionView.swift:1213 | disk or custom cache | if let cache = heightCache.get(forKey: key) { |
| PooToolsSource/Base/PTCollectionView.swift:1214 | disk or custom cache | return cache.doubleValue |
| PooToolsSource/Base/PTCollectionView.swift:1765 | disk or custom cache | if let cache = layoutCache.get(forKey: key) { |
| PooToolsSource/Base/PTCollectionView.swift:1766 | disk or custom cache | return cache |
| PooToolsSource/Base/PTCollectionView.swift:1856 | disk or custom cache | if let cache = waterfallCache[key] { |
| PooToolsSource/Base/PTCollectionView.swift:1857 | disk or custom cache | return (cache.items, cache.contentHeight) |
| PooToolsSource/Base/PTCollectionViewTypes.swift:11 | disk or custom cache | // English: Keep the reusable cache type separate from PTCollectionView's facade and layout code. |
| PooToolsSource/Base/PTCollectionViewTypes.swift:16 | NSCache | private let cache = NSCache<WrappedKey, Value>() |
| PooToolsSource/Base/PTCollectionViewTypes.swift:19 | disk or custom cache | cache.countLimit = max(0, countLimit) |
| PooToolsSource/Base/PTCollectionViewTypes.swift:23 | disk or custom cache | cache.setObject(value, forKey: WrappedKey(key)) |
| PooToolsSource/Base/PTCollectionViewTypes.swift:27 | disk or custom cache | cache.object(forKey: WrappedKey(key)) |
| PooToolsSource/Base/PTCollectionViewTypes.swift:31 | disk or custom cache | cache.removeObject(forKey: WrappedKey(key)) |
| PooToolsSource/Base/PTCollectionViewTypes.swift:35 | disk or custom cache | cache.removeAllObjects() |
| PooToolsSource/Base/PTCollectionViewTypes.swift:485 | disk or custom cache | // English: Own list layout caches outside PTCollectionView so cache policy can evolve independently. |
| PooToolsSource/Base/PTVideoCoverCache.swift:108 | disk or custom cache | // English: A shared actor prevents concurrent callers from writing the same video cache file. |
| PooToolsSource/Base/PTVideoCoverCache.swift:172 | disk or custom cache | /// Video file cache manager. |
| PooToolsSource/Base/PTVideoCoverCache.swift:249 | disk or custom cache | /// Video cover cache and thumbnail request coordinator. |
| PooToolsSource/Base/PTVideoCoverCache.swift:351 | NSCache | @MainActor private static let memoryCache: NSCache<NSString, UIImage> = { |
| PooToolsSource/Base/PTVideoCoverCache.swift:352 | NSCache | let cache = NSCache<NSString, UIImage>() |
| PooToolsSource/Base/PTVideoCoverCache.swift:353 | disk or custom cache | cache.countLimit = 100 |
| PooToolsSource/Base/PTVideoCoverCache.swift:354 | disk or custom cache | cache.totalCostLimit = 50 * 1024 * 1024 |
| PooToolsSource/Base/PTVideoCoverCache.swift:355 | disk or custom cache | return cache |
| PooToolsSource/Base/PTVideoCoverCache.swift:464 | disk or custom cache | /// Preserves the URL-only key used by the video file cache. |
| PooToolsSource/Base/PTVideoCoverCache.swift:473 | disk or custom cache | /// Writes a JPEG cache entry atomically on a utility task. |
| PooToolsSource/Base/PTVideoCoverCache.swift:495 | disk or custom cache | // English: Encode generated thumbnails away from UI work before writing the disk cache. |
| PooToolsSource/Base/PTVideoCoverCache.swift:510 | disk or custom cache | // Keep invalid dimensions out of integer conversion and make the cache key deterministic. |
| PooToolsSource/Button/PTActionLayoutButton.swift:100 | disk or custom cache | // English: Cache the last layout size to avoid rebuilding identical constraints. |
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
| PooToolsSource/Core/PTGCDManager.swift:51 | NSCache | // 用于保存定时器的 Task 引用，替代原有的 NSCache 和 DispatchSourceTimer |
| PooToolsSource/Core/PTGifManager.swift:185 | disk or custom cache | /// Check if this manager has cache for an imageView |
| PooToolsSource/Core/PTGifManager.swift:186 | disk or custom cache | /// - Parameter imageView: The image view we're searching cache for |
| PooToolsSource/Core/PTGifManager.swift:187 | disk or custom cache | /// - Returns : a boolean for wether we have cache for the imageView |
| PooToolsSource/Core/PTLoadImageFunction.swift:547 | disk or custom cache | // Prefer Kingfisher's embedded original bytes before asking the cache serializer for data. |
| PooToolsSource/Core/PTMediaCache.swift:8 | disk or custom cache | // English: Cache variants are part of the key so originals, thumbnails, GIF frames, and Live Photo resources never collide. |
| PooToolsSource/Core/PTMediaCache.swift:21 | disk or custom cache | // English: A stable cache key is derived from media identity and rendering intent, not Swift's randomized hashValue. |
| PooToolsSource/Debug/CwlDemangle.swift:3481 | disk or custom cache | _ = printOptional(name.children.at(0), prefix: "lazy protocol witness table cache variable for type ") |
| PooToolsSource/Debug/CwlDemangle.swift:3548 | disk or custom cache | case .typeMetadataInstantiationCache: printFirstChild(name, prefix: "type metadata instantiation cache for ") |
| PooToolsSource/Debug/CwlDemangle.swift:3549 | disk or custom cache | case .typeMetadataInstantiationFunction: printFirstChild(name, prefix: "type metadata instantiation cache for ") |
| PooToolsSource/Debug/CwlDemangle.swift:3551 | disk or custom cache | case .typeMetadataLazyCache: printFirstChild(name, prefix: "lazy cache variable for type metadata for ") |
| PooToolsSource/DebugCategory/HTTPURLResponse+PTEX.swift:14 | disk or custom cache | if let cc = (allHeaderFields["Cache-Control"] as? String)?.lowercased(), |
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
| PooToolsSource/DebugNetwork/PTCacheStoragePolicy.swift:17 | URLCache | /// - Returns: 合适的 URLCache.StoragePolicy |
| PooToolsSource/DebugNetwork/PTCacheStoragePolicy.swift:18 | URLCache | static func cacheStoragePolicy(for request: URLRequest, and response: HTTPURLResponse) -> URLCache.StoragePolicy { |
| PooToolsSource/DebugNetwork/PTCacheStoragePolicy.swift:39 | disk or custom cache | if let respCC = (response.allHeaderFields["Cache-Control"] as? String)?.lowercased(), respCC.contains("no-store") { |
| PooToolsSource/DebugNetwork/PTCacheStoragePolicy.swift:45 | disk or custom cache | if let reqCC = request.allHTTPHeaderFields?["Cache-Control"]?.lowercased(), (reqCC.contains("no-store") \|\| reqCC.contains("no-cache")) { |
| PooToolsSource/DebugNetwork/PTCustomHTTPProtocol.swift:34 | URLCache | URLCache.customHttp.removeAllCachedResponses() |
| PooToolsSource/DebugNetwork/PTCustomHTTPProtocol.swift:78 | URLCache | private var cachePolicy: URLCache.StoragePolicy = .notAllowed |
| PooToolsSource/DebugNetwork/PTCustomHTTPProtocol.swift:110 | disk or custom cache | private func use(_ cache: CachedURLResponse) { |
| PooToolsSource/DebugNetwork/PTCustomHTTPProtocol.swift:112 | disk or custom cache | client?.urlProtocol(self, didReceive: cache.response, cacheStoragePolicy: .allowed) |
| PooToolsSource/DebugNetwork/PTCustomHTTPProtocol.swift:113 | disk or custom cache | client?.urlProtocol(self, didLoad: cache.data) |
| PooToolsSource/DebugNetwork/PTCustomHTTPProtocol.swift:131 | URLCache | if let cache = URLCache.customHttp.validCache(for: request) { |
| PooToolsSource/DebugNetwork/PTCustomHTTPProtocol.swift:132 | disk or custom cache | use(cache) |
| PooToolsSource/DebugNetwork/PTCustomHTTPProtocol.swift:133 | disk or custom cache | PTNSLogConsole("Use disk cache for \(request.url?.lastPathComponent ?? "")") |
| PooToolsSource/DebugNetwork/PTCustomHTTPProtocol.swift:163 | disk or custom cache | PTNSLogConsole("Use Business API Cache for \(originalRequest.url?.path ?? "")") |
| PooToolsSource/DebugNetwork/PTCustomHTTPProtocol.swift:232 | disk or custom cache | model.responseHeaderFields?.updateValue(getCachePolicy(value: request.cachePolicy.rawValue), forKey: "Cache-Policy") |
| PooToolsSource/DebugNetwork/PTCustomHTTPProtocol.swift:410 | URLCache | URLCache.customHttp.storeIfNeeded(for: task, data: self.data) |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1420 | NSCache | private lazy var filterCache: NSCache<NSString, UIImage> = { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1421 | NSCache | let cache = NSCache<NSString, UIImage>() |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1422 | disk or custom cache | cache.countLimit = 6 |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1423 | disk or custom cache | cache.totalCostLimit = 96 * 1024 * 1024 |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1424 | disk or custom cache | return cache |
| PooToolsSource/KingfisherSVG/Kingfisher+SVG.swift:17 | disk or custom cache | // It will be used when storing and retrieving the image to/from cache. |
| PooToolsSource/NetWork/Network.swift:54 | disk or custom cache | case cache(String) |
| PooToolsSource/NetWork/Network.swift:82 | disk or custom cache | case .cache(let message): return "PT Network cache failed: \(message)" |
| PooToolsSource/NetWork/Network.swift:109 | disk or custom cache | case .cache: return 9999999912 |
| PooToolsSource/NetWork/Network.swift:274 | URLCache | urlConfiguration.urlCache = URLCache(memoryCapacity: configurationSnapshot.memoryCapacity, |
| PooToolsSource/NetWork/Network.swift:590 | disk or custom cache | throw PTNetworkError.cache("cacheOnly 没有可用缓存 / cacheOnly has no usable entry / cacheOnly no tiene una entrada utilizable") |
| PooToolsSource/NetWork/NetworkSupport.swift:1 | disk or custom cache | // English: Keep retry, cache, reachability, and upload support outside the Network facade. |
| PooToolsSource/NetWork/NetworkSupport.swift:236 | disk or custom cache | // English: A cache entry carries validators and freshness without exposing URLSession objects. |
| PooToolsSource/NetWork/NetworkSupport.swift:256 | NSCache | private let memoryCache = NSCache<NSString, NSData>() |
| PooToolsSource/NetWork/NetworkSupport.swift:265 | disk or custom cache | // English: Bound the in-memory cache so a large response cannot grow without limit. |
| PooToolsSource/NetWork/NetworkSupport.swift:285 | disk or custom cache | "pt-cache-miss", |
| PooToolsSource/NetWork/NetworkSupport.swift:295 | disk or custom cache | // English: Cache-control and revalidation headers must not change the resource identity. |
| PooToolsSource/NetWork/NetworkSupport.swift:388 | disk or custom cache | // English: Accept a caller-owned configuration so cache maintenance does not read Network.share. |
| PooToolsSource/NetWork/NetworkSupport.swift:435 | disk or custom cache | // English: Keep JSON and file operations off the cache actor while the actor owns only cache state. |
| PooToolsSource/NetWork/NetworkSupport.swift:444 | disk or custom cache | // English: Decode cache metadata on a utility executor before updating actor-owned memory state. |
| PooToolsSource/NetWork/NetworkSupport.swift:453 | disk or custom cache | // English: Read cache files without occupying the actor executor with synchronous file I/O. |
| PooToolsSource/NetWork/NetworkSupport.swift:462 | disk or custom cache | // English: Persist cache data on a background executor and keep the actor responsive. |
| PooToolsSource/NetWork/NetworkSupport.swift:497 | disk or custom cache | get { value(forHTTPHeaderField: "PT-Cache-Miss") == "true" } |
| PooToolsSource/NetWork/NetworkSupport.swift:498 | disk or custom cache | set { setValue(newValue ? "true" : "false", forHTTPHeaderField: "PT-Cache-Miss") } |
| PooToolsSource/NetWork/NetworkSupport.swift:519 | disk or custom cache | // English: Expose the default cache adapter so the public Network initializer can use it safely. |
| PooToolsSource/NetWork/NetworkSupport.swift:545 | disk or custom cache | if request.cachePolicyType == .networkElseCache, let cache = await NetworkCache.shared.read(request: request) { |
| PooToolsSource/NetWork/NetworkSupport.swift:546 | disk or custom cache | NotificationCenter.default.post(name: NSNotification.Name("PTNetworkCacheFallback"), object: cache) |
| PooToolsSource/NetWork/NetworkSupport.swift:552 | disk or custom cache | if response?.value(forHTTPHeaderField: "Cache-Control")?.lowercased().contains("no-store") == true { return } |
| PooToolsSource/NetWork/NetworkSupport.swift:578 | disk or custom cache | guard let cacheControl = response?.value(forHTTPHeaderField: "Cache-Control") else { return fallback } |
| PooToolsSource/PDF/UIImage+PTpdfEX.swift:155 | disk or custom cache | // MARK: - Cache Public |
| PooToolsSource/PDF/UIImage+PTpdfEX.swift:203 | disk or custom cache | // MARK: - Cache Private |
| PooToolsSource/PDF/UIImage+PTpdfEX.swift:206 | disk or custom cache | // MARK: - Memory Cache |
| PooToolsSource/PDF/UIImage+PTpdfEX.swift:207 | NSCache | @MainActor private static let imageCache = NSCache<NSString, UIImage>() |
| PooToolsSource/PDF/UIImage+PTpdfEX.swift:219 | disk or custom cache | // MARK: - Disk Cache |
| PooToolsSource/PToolsCore/PTCoreContracts.swift:5 | disk or custom cache | // English: Foundation-only contracts shared by logging, cache, and error adapters. |
| PooToolsSource/PToolsCore/PTCoreContracts.swift:40 | disk or custom cache | // English: Use a small typed cache contract instead of exposing a third-party cache type. |
| PooToolsSource/PToolsCore/PTCoreContracts.swift:53 | disk or custom cache | // English: The default memory cache is actor-isolated, bounded by ownership, and dependency-free. |
| PooToolsSource/PToolsLogging/Destinations/PTOSLogDestination.swift:39 | disk or custom cache | // English: Cache OSLog Logger instances so high-frequency logging does not recreate them. |
| PooToolsSource/PToolsLogging/Destinations/PTOSLogDestination.swift:44 | disk or custom cache | return loggerCache.withLock { cache in |
| PooToolsSource/PToolsLogging/Destinations/PTOSLogDestination.swift:45 | disk or custom cache | if let logger = cache[key] { |
| PooToolsSource/PToolsLogging/Destinations/PTOSLogDestination.swift:49 | disk or custom cache | cache[key] = logger |
| PooToolsSource/PToolsMediaCore/PTMediaCoreContracts.swift:187 | disk or custom cache | // English: Cache access is asynchronous and value-based, preventing feature modules from sharing mutable caches. |
| PooToolsSource/PhotoPicker/PTMediaLibViewController.swift:628 | disk or custom cache | PTAlertTipsViewController.tipsAlertShow(title: "Error",subtitle: "Save to cache failed", icon: .Error) |
| PooToolsSource/PhotoPicker/PTMediaLibViewController.swift:666 | disk or custom cache | // MARK: - Cache Helper |
| PooToolsSource/PhotoPicker/PTMediaLibViewController.swift:680 | disk or custom cache | PTNSLogConsole("Video cache export failed: \(String(describing: error))") |
| PooToolsSource/Router/PTRouterServiceManager.swift:157 | disk or custom cache | // MARK: - Service Clean Cache |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:758 | disk or custom cache | open func cache(viewControllerGenerator: @escaping () -> UIViewController?, with identifier: String) { |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:762 | disk or custom cache | open func cache(viewController: UIViewController, with identifier: String) { |
