# PTools 5.9.x 缓存盘点

本报告标出缓存实现位置，后续优化必须同时记录所有者、线程边界、容量和清理策略。

| 位置 | 类型 | 代码行 |
| --- | --- | --- |
| PooToolsSource/ActionsheetAndAlert/PTCustomerAlertController.swift:48 | disk or custom cache | // English: Cache only geometry inputs so repeated layout passes do not recreate constraints or controls. |
| PooToolsSource/Base/PTAudioCache.swift:166 | NSCache | private let durationCache = NSCache<NSString, NSNumber>() |
| PooToolsSource/Base/PTAudioCache.swift:170 | disk or custom cache | /// 获取音频时长（一定基于 cache 文件） |
| PooToolsSource/Base/PTAudioCache.swift:208 | disk or custom cache | /// 创建播放用 PlayerItem（只用 cache 文件） |
| PooToolsSource/Base/PTBaseDecorationFunction.swift:16 | disk or custom cache | // English: Cache the shadow geometry to avoid rebuilding the path on every layout pass. |
| PooToolsSource/Base/PTCollectionView.swift:1278 | disk or custom cache | if let cache = heightCache.get(forKey: key) { |
| PooToolsSource/Base/PTCollectionView.swift:1279 | disk or custom cache | return cache.doubleValue |
| PooToolsSource/Base/PTCollectionView.swift:1828 | disk or custom cache | if let cache = layoutCache.get(forKey: key) { |
| PooToolsSource/Base/PTCollectionView.swift:1829 | disk or custom cache | return cache |
| PooToolsSource/Base/PTCollectionView.swift:1919 | disk or custom cache | if let cache = waterfallCache[key] { |
| PooToolsSource/Base/PTCollectionView.swift:1920 | disk or custom cache | return (cache.items, cache.contentHeight) |
| PooToolsSource/Base/PTCollectionViewTypes.swift:10 | disk or custom cache | // English: Keep the reusable cache type separate from PTCollectionView's facade and layout code. |
| PooToolsSource/Base/PTCollectionViewTypes.swift:15 | NSCache | private let cache = NSCache<WrappedKey, Value>() |
| PooToolsSource/Base/PTCollectionViewTypes.swift:18 | disk or custom cache | cache.countLimit = max(0, countLimit) |
| PooToolsSource/Base/PTCollectionViewTypes.swift:22 | disk or custom cache | cache.setObject(value, forKey: WrappedKey(key)) |
| PooToolsSource/Base/PTCollectionViewTypes.swift:26 | disk or custom cache | cache.object(forKey: WrappedKey(key)) |
| PooToolsSource/Base/PTCollectionViewTypes.swift:30 | disk or custom cache | cache.removeObject(forKey: WrappedKey(key)) |
| PooToolsSource/Base/PTCollectionViewTypes.swift:34 | disk or custom cache | cache.removeAllObjects() |
| PooToolsSource/Base/PTVideoCoverCache.swift:192 | disk or custom cache | /// Video cover cache and thumbnail request coordinator. |
| PooToolsSource/Base/PTVideoCoverCache.swift:287 | NSCache | @MainActor private static let memoryCache: NSCache<NSString, UIImage> = { |
| PooToolsSource/Base/PTVideoCoverCache.swift:288 | NSCache | let cache = NSCache<NSString, UIImage>() |
| PooToolsSource/Base/PTVideoCoverCache.swift:289 | disk or custom cache | cache.countLimit = 100 |
| PooToolsSource/Base/PTVideoCoverCache.swift:290 | disk or custom cache | cache.totalCostLimit = 50 * 1024 * 1024 |
| PooToolsSource/Base/PTVideoCoverCache.swift:291 | disk or custom cache | return cache |
| PooToolsSource/Base/PTVideoCoverCache.swift:393 | disk or custom cache | /// Preserves the URL-only key used by the video file cache. |
| PooToolsSource/Base/PTVideoCoverCache.swift:402 | disk or custom cache | /// Writes a JPEG cache entry atomically on a utility task. |
| PooToolsSource/Base/PTVideoCoverCache.swift:420 | disk or custom cache | // Keep invalid dimensions out of integer conversion and make the cache key deterministic. |
| PooToolsSource/Button/PTActionLayoutButton.swift:100 | disk or custom cache | // English: Cache the last layout size to avoid rebuilding identical constraints. |
| PooToolsSource/Category/FileManager+PTEX.swift:25 | disk or custom cache | - 3.1、Library/Cache |
| PooToolsSource/Category/FileManager+PTEX.swift:28 | disk or custom cache | - 系统不会清理 cache 目录中的文件 |
| PooToolsSource/Category/FileManager+PTEX.swift:29 | disk or custom cache | - 就要求程序开发时, "必须提供 cache 目录的清理解决方案" |
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
| PooToolsSource/Category/UIApplication+PTEX.swift:19 | disk or custom cache | PTNSLogConsole("Failed to delete launch screen cache: \(result.error)",levelType: .error,loggerType: .uiApplication) |
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
| PooToolsSource/Core/PTGCDManager.swift:41 | NSCache | // 用于保存定时器的 Task 引用，替代原有的 NSCache 和 DispatchSourceTimer |
| PooToolsSource/Core/PTGifManager.swift:185 | disk or custom cache | /// Check if this manager has cache for an imageView |
| PooToolsSource/Core/PTGifManager.swift:186 | disk or custom cache | /// - Parameter imageView: The image view we're searching cache for |
| PooToolsSource/Core/PTGifManager.swift:187 | disk or custom cache | /// - Returns : a boolean for wether we have cache for the imageView |
| PooToolsSource/Core/PTLoadImageFunction.swift:550 | disk or custom cache | // Prefer Kingfisher's embedded original bytes before asking the cache serializer for data. |
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
| PooToolsSource/DebugNetwork/PTCustomHTTPProtocol.swift:391 | URLCache | URLCache.customHttp.storeIfNeeded(for: task, data: self.data) |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1421 | NSCache | private lazy var filterCache: NSCache<NSString, UIImage> = { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1422 | NSCache | let cache = NSCache<NSString, UIImage>() |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1423 | disk or custom cache | cache.countLimit = 6 |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1424 | disk or custom cache | cache.totalCostLimit = 96 * 1024 * 1024 |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1425 | disk or custom cache | return cache |
| PooToolsSource/KingfisherSVG/Kingfisher+SVG.swift:17 | disk or custom cache | // It will be used when storing and retrieving the image to/from cache. |
| PooToolsSource/NetWork/Network.swift:318 | NSCache | private let memoryCache = NSCache<NSString, NSData>() |
| PooToolsSource/NetWork/Network.swift:327 | disk or custom cache | // English: Bound the in-memory cache so a large response cannot grow without limit. |
| PooToolsSource/NetWork/Network.swift:392 | disk or custom cache | // English: Accept a caller-owned configuration so cache maintenance does not read Network.share. |
| PooToolsSource/NetWork/Network.swift:483 | disk or custom cache | // English: Expose the default cache adapter so the public Network initializer can use it safely. |
| PooToolsSource/NetWork/Network.swift:501 | disk or custom cache | if request.cachePolicyType == .networkElseCache, let cache = await NetworkCache.shared.read(request: request) { |
| PooToolsSource/NetWork/Network.swift:502 | disk or custom cache | NotificationCenter.default.post(name: NSNotification.Name("PTNetworkCacheFallback"), object: cache) |
| PooToolsSource/NetWork/Network.swift:727 | URLCache | urlConfiguration.urlCache = URLCache(memoryCapacity: 20 * 1024 * 1024, diskCapacity: 100 * 1024 * 1024) |
| PooToolsSource/PDF/UIImage+PTpdfEX.swift:155 | disk or custom cache | // MARK: - Cache Public |
| PooToolsSource/PDF/UIImage+PTpdfEX.swift:203 | disk or custom cache | // MARK: - Cache Private |
| PooToolsSource/PDF/UIImage+PTpdfEX.swift:206 | disk or custom cache | // MARK: - Memory Cache |
| PooToolsSource/PDF/UIImage+PTpdfEX.swift:207 | NSCache | @MainActor private static let imageCache = NSCache<NSString, UIImage>() |
| PooToolsSource/PDF/UIImage+PTpdfEX.swift:219 | disk or custom cache | // MARK: - Disk Cache |
| PooToolsSource/PhotoPicker/PTMediaLibViewController.swift:627 | disk or custom cache | PTAlertTipsViewController.tipsAlertShow(title: "Error",subtitle: "Save to cache failed", icon: .Error) |
| PooToolsSource/PhotoPicker/PTMediaLibViewController.swift:665 | disk or custom cache | // MARK: - Cache Helper |
| PooToolsSource/PhotoPicker/PTMediaLibViewController.swift:679 | disk or custom cache | PTNSLogConsole("Video cache export failed: \(String(describing: error))") |
| PooToolsSource/Router/PTRouterServiceManager.swift:157 | disk or custom cache | // MARK: - Service Clean Cache |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:758 | disk or custom cache | open func cache(viewControllerGenerator: @escaping () -> UIViewController?, with identifier: String) { |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:762 | disk or custom cache | open func cache(viewController: UIViewController, with identifier: String) { |
