//
//  PTCycleScrollView.swift
//  PooTools
//
//  English: Compatibility facade for the canonical PTBannerView implementation.
//  Español: Fachada de compatibilidad para la implementación canónica PTBannerView.
//  中文：PTBannerView 统一实现的兼容门面。
//

import UIKit
import AVFoundation
import AttributedString
import SwifterSwift

/// English: Page-control styles kept for source compatibility with the legacy banner API.
/// Español: Estilos de control de páginas conservados para compatibilidad con la API heredada.
/// 中文：为兼容旧版 Banner API 保留的页面指示器样式。
@objc public enum PageControlStyle: Int {
    case none, system, fill, pill, snake, image, scrolling
}

/// English: Page-control positions kept for source compatibility with the legacy banner API.
/// Español: Posiciones del control de páginas conservadas para compatibilidad con la API heredada.
/// 中文：为兼容旧版 Banner API 保留的页面指示器位置。
@objc public enum PageControlPosition: Int {
    case center, left, right
}

public typealias PTCycleIndexClosure = (_ index: NSInteger) -> Void
public typealias PTScrollViewDidScrollClosure = (_ index: NSInteger, _ offSet: CGFloat) -> Void

/// English: Use PTBannerView for new code; this type forwards legacy calls to the same implementation.
/// Español: Usa PTBannerView en código nuevo; este tipo reenvía las llamadas heredadas a la misma implementación.
/// 中文：新代码请使用 PTBannerView；此类型将旧调用转发到同一套实现。
@available(*, deprecated, message: "Use PTBannerView for new code.")
@MainActor
@objcMembers
public class PTCycleScrollView: PTBannerView {

    public static var playButtonImage: UIImage = "▶️".emojiToImage(emojiFont: .appfont(size: 44))

    private var legacyImagePaths: [Any] = []
    private var legacyTitles: [Any] = []
    private var legacyOnlyTitle = false
    private var legacyArrowFrames: [CGRect]?
    private var isSynchronizing = false

    // MARK: - Legacy data

    public var imagePaths: [Any] = [] {
        didSet {
            legacyImagePaths = imagePaths
            synchronizeLegacyState()
        }
    }

    public var titles: [Any] = [] {
        didSet {
            legacyTitles = titles
            synchronizeLegacyState()
        }
    }

    // MARK: - Legacy callbacks

    public var didSelectItemAtIndexClosure: PTCycleIndexClosure? {
        didSet { didSelectIndex = didSelectItemAtIndexClosure }
    }

    // MARK: - Legacy configuration

    public var autoScroll: Bool = true { didSet { synchronizeLegacyState() } }
    public var infiniteLoop: Bool = true { didSet { synchronizeLegacyState() } }
    public var scrollDirection: UICollectionView.ScrollDirection? = .horizontal { didSet { synchronizeLegacyState() } }
    public var autoScrollTimeInterval: Double = 2 { didSet { synchronizeLegacyState() } }
    public var collectionViewBackgroundColor: UIColor = .clear { didSet { synchronizeLegacyState() } }
    public var imageViewContentMode: UIView.ContentMode? { didSet { synchronizeLegacyState() } }
    public var textColor: UIColor = .white { didSet { synchronizeLegacyState() } }
    public var numberOfLines: NSInteger = 2 { didSet { synchronizeLegacyState() } }
    public var titleLeading: CGFloat = 15 { didSet { synchronizeLegacyState() } }
    public var font: UIFont = .systemFont(ofSize: 15) { didSet { synchronizeLegacyState() } }
    public var titleBackgroundColor: UIColor = UIColor.black.withAlphaComponent(0.3) { didSet { synchronizeLegacyState() } }
    public var arrowLRIcon: [Any]? { didSet { synchronizeLegacyState() } }
    public var arrowLRFrame: [CGRect]? {
        get { legacyArrowFrames }
        set {
            legacyArrowFrames = newValue
            synchronizeLegacyState()
        }
    }

    public var pageControlTintColor: UIColor = .lightGray { didSet { synchronizeLegacyState() } }
    public var pageControlCurrentPageColor: UIColor = .white { didSet { synchronizeLegacyState() } }
    public var fillPageControlIndicatorRadius: CGFloat = 4 { didSet { synchronizeLegacyState() } }
    public var customPageControlInActiveTintColor: UIColor = UIColor(white: 1, alpha: 0.3) { didSet { synchronizeLegacyState() } }
    public var pageControlActiveImage: UIImage? { didSet { synchronizeLegacyState() } }
    public var pageControlInActiveImage: UIImage? { didSet { synchronizeLegacyState() } }
    public var dotSpacing: CGFloat = 8 { didSet { synchronizeLegacyState() } }
    public var customPageControlStyle: PageControlStyle = .system { didSet { synchronizeLegacyState() } }
    public var customPageControlTintColor: UIColor = .white { didSet { synchronizeLegacyState() } }
    public var customPageControlIndicatorPadding: CGFloat = 8 { didSet { synchronizeLegacyState() } }
    public var pageControlPosition: PageControlPosition = .center { didSet { synchronizeLegacyState() } }
    public var pageControlLeadingOrTrialingContact: CGFloat = 28 { didSet { synchronizeLegacyState() } }
    public var pageControlBottom: CGFloat = 5 { didSet { synchronizeLegacyState() } }

    public var iCloudDocument: String = ""
    public var defaultPlaceholderImage: UIImage = PTAppBaseConfig.share.defaultPlaceholderImage { didSet { synchronizeLegacyState() } }
    public var loadingProgressWidth: CGFloat = 1.5
    public var loadingProgressColor: DynamicColor = .purple
    public var autoPlayVideo: Bool = false { didSet { synchronizeLegacyState() } }
    public var showPlayButton: Bool = true { didSet { synchronizeLegacyState() } }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        synchronizeLegacyState()
    }

    public convenience init() {
        self.init(frame: .zero)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        synchronizeLegacyState()
    }

    public override func willMove(toSuperview newSuperview: UIView?) {
        if newSuperview == nil {
            invalidateTimer()
        }
        super.willMove(toSuperview: newSuperview)
    }

    // MARK: - Legacy factories

    public class func cycleScrollViewCreate(imageURLPaths: [Any]? = [],
                                             titles: [String]? = [],
                                             didSelectItemAtIndex: PTCycleIndexClosure? = nil) -> PTCycleScrollView {
        let banner = PTCycleScrollView()
        banner.didSelectItemAtIndexClosure = didSelectItemAtIndex
        banner.imagePaths = imageURLPaths ?? []
        banner.titles = titles ?? []
        return banner
    }

    public class func cycleScrollViewWithTitles(backImage: UIImage? = nil,
                                                titles: [String]? = [],
                                                didSelectItemAtIndex: PTCycleIndexClosure? = nil) -> PTCycleScrollView {
        let banner = PTCycleScrollView()
        banner.legacyOnlyTitle = true
        banner.bannerConfiguration.backgroundImage = backImage
        banner.didSelectItemAtIndexClosure = didSelectItemAtIndex
        banner.titles = titles ?? []
        banner.reloadData()
        return banner
    }

    public class func cycleScrollViewWithArrow(arrowLRImages: [Any],
                                               arrowLRFrame: [CGRect]? = nil,
                                               imageURLPaths: [Any]? = [],
                                               titles: [String]? = [],
                                               didSelectItemAtIndex: PTCycleIndexClosure? = nil) -> PTCycleScrollView {
        let banner = PTCycleScrollView()
        banner.arrowLRIcon = arrowLRImages
        banner.arrowLRFrame = arrowLRFrame
        banner.didSelectItemAtIndexClosure = didSelectItemAtIndex
        banner.imagePaths = imageURLPaths ?? []
        banner.titles = titles ?? []
        return banner
    }

    // MARK: - Legacy helpers

    public func setupArrowIcon() {
        synchronizeLegacyState()
    }

    public func automaticScroll() {
        guard !bannerModel.isEmpty else { return }
        let next = Int(currentIndex()) + 1
        if next < bannerModel.count {
            scrollToPage(index: next)
        } else if infiniteLoop {
            scrollToPage(index: 0)
        } else {
            stopAutoScroll()
        }
    }

    public func scollToIndex(targetIndex: Int) {
        guard !bannerModel.isEmpty else { return }
        let index = infiniteLoop ? targetIndex % bannerModel.count : targetIndex
        guard bannerModel.indices.contains(index) else { return }
        scrollToPage(index: index)
    }

    public func pageControlIndexWithCurrentCellIndex(index: NSInteger) -> Int {
        guard !bannerModel.isEmpty else { return 0 }
        return Int(index) % bannerModel.count
    }

    private func synchronizeLegacyState() {
        guard !isSynchronizing else { return }
        isSynchronizing = true
        defer { isSynchronizing = false }

        let configuration = bannerConfiguration
        configuration.playButtonImage = Self.playButtonImage
        configuration.autoScroll = autoScroll
        configuration.infiniteLoop = infiniteLoop
        configuration.scrollDirection = scrollDirection
        configuration.autoScrollInterval = autoScrollTimeInterval
        configuration.collectionViewBackgroundColor = collectionViewBackgroundColor
        configuration.numberOfLines = numberOfLines
        configuration.titleLeading = titleLeading
        configuration.titleBackgroundColor = titleBackgroundColor
        configuration.pageControlTintColor = pageControlTintColor
        configuration.pageControlCurrentPageColor = pageControlCurrentPageColor
        configuration.fillPageControlIndicatorRadius = fillPageControlIndicatorRadius
        configuration.customPageControlInActiveTintColor = customPageControlInActiveTintColor
        configuration.pageControlActiveImage = pageControlActiveImage
        configuration.pageControlInActiveImage = pageControlInActiveImage
        configuration.dotSpacing = dotSpacing
        configuration.customPageControlStyle = customPageControlStyle
        configuration.customPageControlTintColor = customPageControlTintColor
        configuration.customPageControlIndicatorPadding = customPageControlIndicatorPadding
        configuration.pageControlPosition = pageControlPosition
        configuration.pageControlLeadingOrTrialingContact = pageControlLeadingOrTrialingContact
        configuration.pageControlBottom = pageControlBottom
        configuration.placeholderImage = defaultPlaceholderImage
        configuration.iCloudDocumentName = iCloudDocument
        configuration.loadingProgressWidth = loadingProgressWidth
        configuration.loadingProgressColor = loadingProgressColor
        configuration.autoPlayMedia = autoPlayVideo
        configuration.showPlayButton = showPlayButton
        configuration.showsNavigationButtons = (arrowLRIcon?.count ?? 0) >= 2
        configuration.previousButtonImage = image(from: arrowLRIcon?.first)
        configuration.nextButtonImage = image(from: arrowLRIcon?.dropFirst().first)

        refreshBannerConfiguration()
        setNavigationButtonSources(previous: arrowLRIcon?.first,
                                   next: arrowLRIcon?.dropFirst().first)
        setNavigationButtonFrames(legacyArrowFrames)
        bannerModel = makeBannerModels()
        if autoScroll {
            startAutoScroll()
        } else {
            stopAutoScroll()
        }
    }

    private func makeBannerModels() -> [PTBannerModel] {
        let count = max(legacyImagePaths.count, legacyTitles.count)
        guard count > 0 else { return [] }

        return (0..<count).map { index in
            let model = PTBannerModel()
            if legacyImagePaths.indices.contains(index), !legacyOnlyTitle {
                model.media = legacyImagePaths[index]
            }
            if legacyTitles.indices.contains(index) {
                let value = legacyTitles[index]
                if let attributed = value as? ASAttributedString {
                    model.att = attributed
                } else if let text = value as? String {
                    model.title = text
                } else {
                    model.title = String(describing: value)
                }
            }
            model.titleColor = textColor
            model.descColor = textColor
            model.titleFont = font
            model.descFont = font
            model.imageViewContentMode = imageViewContentMode ?? .scaleAspectFit
            return model
        }
    }

    private func image(from value: Any?) -> UIImage? {
        if let image = value as? UIImage {
            return image
        }
        return nil
    }
}
