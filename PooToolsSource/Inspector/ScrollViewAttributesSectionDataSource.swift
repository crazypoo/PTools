//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension DefaultElementAttributesLibrary {
    final class ScrollViewAttributesSectionDataSource: InspectorElementSectionDataSource {
        var state: InspectorElementSectionState = .collapsed

        let title = "Scroll View"

        private weak var scrollView: UIScrollView?

        init?(with object: NSObject) {
            guard let scrollView = object as? UIScrollView else { return nil }

            self.scrollView = scrollView
        }

        private enum Property: String, Swift.CaseIterable {
            case groupIndicators = "Indicators"
            case indicatorStyle = "Indicator Style"
            case showsHorizontalScrollIndicator = "Show Horizontal Indicator"
            case showsVerticalScrollIndicator = "Show Vertical Indicator"
            case groupScrolling = "Scrolling"
            case isScrollEnabled = "Scroll Enabled"
            case pagingEnabled = "Paging Enabled"
            case isDirectionalLockEnabled = "Direction Lock Enabled"
            case groupBounce = "Bounce"
            case bounces = "Bounce On Scroll"
            case bouncesZoom = "Bounce On Zoom"
            case alwaysBounceHorizontal = "Bounce Horizontally"
            case bounceVertically = "Bounce Vertically"
            case groupZoom = "Zoom Separator"
            case zoomScale = "Zoom"
            case minimumZoomScale = "Minimum Scale"
            case maximumZoomScale = "Maximum Scale"
            case groupContentTouch = "Content Touch"
            case delaysContentTouches = "Delay Touch Down"
            case canCancelContentTouches = "Can Cancel On Scroll"
            case keyboardDismissMode = "Keyboard"
        }

        var properties: [InspectorElementProperty] {
            guard let scrollView = scrollView else { return [] }

            return Property.allCases.compactMap { property in
                switch property {
                case .groupIndicators:
                    return .group(title: property.rawValue)

                case .indicatorStyle:
                    return .optionsList(
                        title: property.rawValue,
                        options: UIScrollView.IndicatorStyle.allCases.map(\.description),
                        selectedIndex: { UIScrollView.IndicatorStyle.allCases.firstIndex(of: scrollView.indicatorStyle) }
                    ) {
                        guard let newIndex = $0 else { return }

                        let indicatorStyle = UIScrollView.IndicatorStyle.allCases[newIndex]

                        scrollView.indicatorStyle = indicatorStyle
                    }
                case .showsHorizontalScrollIndicator:
                    return .switch(
                        title: property.rawValue,
                        isOn: { scrollView.showsHorizontalScrollIndicator }
                    ) { showsHorizontalScrollIndicator in
                        scrollView.showsHorizontalScrollIndicator = showsHorizontalScrollIndicator
                    }
                case .showsVerticalScrollIndicator:
                    return .switch(
                        title: property.rawValue,
                        isOn: { scrollView.showsVerticalScrollIndicator }
                    ) { showsVerticalScrollIndicator in
                        scrollView.showsVerticalScrollIndicator = showsVerticalScrollIndicator
                    }
                case .groupScrolling:
                    return .group(title: property.rawValue)

                case .isScrollEnabled:
                    return .switch(
                        title: property.rawValue,
                        isOn: { scrollView.isScrollEnabled }
                    ) { isScrollEnabled in
                        scrollView.isScrollEnabled = isScrollEnabled
                    }
                case .pagingEnabled:
                    return .switch(
                        title: property.rawValue,
                        isOn: { scrollView.isPagingEnabled }
                    ) { isPagingEnabled in
                        scrollView.isPagingEnabled = isPagingEnabled
                    }
                case .isDirectionalLockEnabled:
                    return .switch(
                        title: property.rawValue,
                        isOn: { scrollView.isDirectionalLockEnabled }
                    ) { isDirectionalLockEnabled in
                        scrollView.isDirectionalLockEnabled = isDirectionalLockEnabled
                    }
                case .groupBounce:
                    return .group(title: property.rawValue)

                case .bounces:
                    return .switch(
                        title: property.rawValue,
                        isOn: { scrollView.bounces }
                    ) { bounces in
                        scrollView.bounces = bounces
                    }
                case .bouncesZoom:
                    return .switch(
                        title: property.rawValue,
                        isOn: { scrollView.bouncesZoom }
                    ) { bouncesZoom in
                        scrollView.bouncesZoom = bouncesZoom
                    }
                case .alwaysBounceHorizontal:
                    return .switch(
                        title: property.rawValue,
                        isOn: { scrollView.alwaysBounceHorizontal }
                    ) { alwaysBounceHorizontal in
                        scrollView.alwaysBounceHorizontal = alwaysBounceHorizontal
                    }
                case .bounceVertically:
                    return .switch(
                        title: property.rawValue,
                        isOn: { scrollView.alwaysBounceVertical }
                    ) { alwaysBounceVertical in
                        scrollView.alwaysBounceVertical = alwaysBounceVertical
                    }
                case .groupZoom:
                    return .separator

                case .zoomScale:
                    return .cgFloatStepper(
                        title: property.rawValue,
                        value: { scrollView.zoomScale },
                        range: { min(scrollView.minimumZoomScale, scrollView.maximumZoomScale)...max(scrollView.minimumZoomScale, scrollView.maximumZoomScale) },
                        stepValue: { 0.1 }
                    ) { zoomScale in
                        scrollView.zoomScale = zoomScale
                    }
                case .minimumZoomScale:
                    return .cgFloatStepper(
                        title: property.rawValue,
                        value: { scrollView.minimumZoomScale },
                        range: { 0...max(0, scrollView.maximumZoomScale) },
                        stepValue: { 0.1 }
                    ) { minimumZoomScale in
                        scrollView.minimumZoomScale = minimumZoomScale
                    }
                case .maximumZoomScale:
                    return .cgFloatStepper(
                        title: property.rawValue,
                        value: { scrollView.maximumZoomScale },
                        range: { scrollView.minimumZoomScale...CGFloat.infinity },
                        stepValue: { 0.1 }
                    ) { maximumZoomScale in
                        scrollView.maximumZoomScale = maximumZoomScale
                    }
                case .groupContentTouch:
                    return .group(title: property.rawValue)

                case .delaysContentTouches:
                    return .switch(
                        title: property.rawValue,
                        isOn: { scrollView.delaysContentTouches }
                    ) { delaysContentTouches in
                        scrollView.delaysContentTouches = delaysContentTouches
                    }
                case .canCancelContentTouches:
                    return .switch(
                        title: property.rawValue,
                        isOn: { scrollView.canCancelContentTouches }
                    ) { canCancelContentTouches in
                        scrollView.canCancelContentTouches = canCancelContentTouches
                    }
                case .keyboardDismissMode:
                    return .optionsList(
                        title: property.rawValue,
                        options: UIScrollView.KeyboardDismissMode.allCases.map(\.description),
                        selectedIndex: { UIScrollView.KeyboardDismissMode.allCases.firstIndex(of: scrollView.keyboardDismissMode) }
                    ) {
                        guard let newIndex = $0 else { return }

                        let keyboardDismissMode = UIScrollView.KeyboardDismissMode.allCases[newIndex]

                        scrollView.keyboardDismissMode = keyboardDismissMode
                    }
                }
            }
        }
    }
}
