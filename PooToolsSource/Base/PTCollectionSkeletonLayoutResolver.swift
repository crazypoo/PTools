//
//  PTCollectionSkeletonLayoutResolver.swift
//  PooTools
//
// English: Resolve skeleton geometry from values only; never touch business cells or snapshots.
// Español: Resuelve la geometría usando solo valores; nunca toca celdas ni snapshots de negocio.
// 中文：只根据值计算骨架几何，绝不触碰业务 Cell 或 Snapshot。
//

import UIKit

@MainActor
struct PTSkeletonRenderedItem {
    let frame: CGRect
    let descriptor: PTSkeletonItemDescriptor
}

@MainActor
enum PTCollectionSkeletonLayoutResolver {
    private static let maximumViewportItemCount = 200

    static func resolve(bounds: CGRect,
                        viewConfig: PTCollectionViewConfig,
                        configuration: PTCollectionSkeletonConfiguration,
                        explicitItemCount: Int?,
                        adjustedContentInset: UIEdgeInsets,
                        layoutDirection: UIUserInterfaceLayoutDirection) -> [PTSkeletonRenderedItem] {
        guard bounds.width.isFinite, bounds.height.isFinite, bounds.width > 0, bounds.height > 0 else { return [] }

        let layout = configuration.layout
        let contentInsets = resolvedInsets(layout.contentInsets,
                                            viewConfig: viewConfig,
                                            adjusted: adjustedContentInset)
        let contentRect = directionalRect(bounds: bounds,
                                          insets: contentInsets,
                                          direction: layoutDirection)
        guard contentRect.width > 0, contentRect.height > 0 else { return [] }

        if let sections = configuration.sections, !sections.isEmpty {
            return resolveSections(sections,
                                   bounds: bounds,
                                   contentRect: contentRect,
                                   viewConfig: viewConfig,
                                   configuration: configuration,
                                   adjustedContentInset: adjustedContentInset,
                                   layoutDirection: layoutDirection)
        }

        let count = resolvedCount(mode: explicitItemCount.map { .fixed($0) } ?? configuration.itemCountMode,
                                   fallback: viewConfig.skeletonItemCount,
                                   type: viewConfig.viewType,
                                   contentRect: contentRect,
                                   layout: layout,
                                   viewConfig: viewConfig)
        let frames = resolveFrames(count: count,
                                   type: viewConfig.viewType,
                                   contentRect: contentRect,
                                   layout: layout,
                                   viewConfig: viewConfig,
                                   layoutDirection: layoutDirection,
                                   adjustedContentInset: adjustedContentInset)
        return frames.enumerated().map { index, frame in
            let descriptor = configurationDescriptor(configuration.content,
                                                     frame: frame,
                                                     fallbackCornerRadius: layout.cornerRadius ?? viewConfig.skeletonCornerRadius)
            return PTSkeletonRenderedItem(frame: frame,
                                          descriptor: descriptorForTemplate(descriptor,
                                                                            index: index,
                                                                            frame: frame))
        }
    }

    private static func resolveSections(_ sections: [PTSkeletonSectionDescriptor],
                                        bounds: CGRect,
                                        contentRect: CGRect,
                                        viewConfig: PTCollectionViewConfig,
                                        configuration: PTCollectionSkeletonConfiguration,
                                        adjustedContentInset: UIEdgeInsets,
                                        layoutDirection: UIUserInterfaceLayoutDirection) -> [PTSkeletonRenderedItem] {
        var output: [PTSkeletonRenderedItem] = []
        var cursor = contentRect.minY
        let sectionSpacing: CGFloat = 8

        for (sectionIndex, section) in sections.prefix(20).enumerated() {
            let sectionLayout = section.layoutOverride ?? configuration.layout
            let sectionRect = CGRect(x: contentRect.minX,
                                     y: cursor,
                                     width: contentRect.width,
                                     height: max(0, contentRect.maxY - cursor))
            guard sectionRect.width > 0, sectionRect.height > 0 else { break }

            if let header = section.header {
                let headerFrame = CGRect(x: sectionRect.minX,
                                         y: cursor,
                                         width: sectionRect.width,
                                         height: min(header.height, max(1, bounds.height)))
                let descriptor = section.supplementaryProvider?(sectionIndex, UICollectionView.elementKindSectionHeader, headerFrame) ?? header.content
                output.append(PTSkeletonRenderedItem(frame: headerFrame, descriptor: descriptor))
                cursor = headerFrame.maxY + sectionSpacing
            }

            let sectionContentRect = CGRect(x: contentRect.minX,
                                            y: cursor,
                                            width: contentRect.width,
                                            height: max(0, contentRect.maxY - cursor))
            let count = resolvedCount(mode: section.itemCountMode,
                                      fallback: viewConfig.skeletonItemCount,
                                      type: viewConfig.viewType,
                                      contentRect: sectionContentRect,
                                      layout: sectionLayout,
                                      viewConfig: viewConfig)
            let frames = resolveFrames(count: count,
                                       type: viewConfig.viewType,
                                       contentRect: sectionContentRect,
                                       layout: sectionLayout,
                                       viewConfig: viewConfig,
                                       layoutDirection: layoutDirection,
                                       adjustedContentInset: adjustedContentInset)
            for (itemIndex, frame) in frames.enumerated() {
                let context = PTSkeletonItemContext(skeletonSectionIndex: sectionIndex,
                                                    itemIndex: itemIndex,
                                                    itemFrame: frame,
                                                    layoutDirection: layoutDirection)
                let templateContext = PTSkeletonTemplateContext(reuseIdentifier: section.id,
                                                                sectionIndex: sectionIndex,
                                                                itemIndex: itemIndex,
                                                                itemFrame: frame)
                let descriptor = section.itemProvider?(context)
                    ?? PTCollectionSkeletonTemplateRegistry.shared.descriptor(forReuseIdentifier: section.id,
                                                                               context: templateContext)
                    ?? section.defaultItem
                output.append(PTSkeletonRenderedItem(frame: frame, descriptor: descriptor))
            }

            if let last = frames.last {
                cursor = last.maxY + sectionSpacing
            }
            if let footer = section.footer {
                let footerFrame = CGRect(x: sectionContentRect.minX,
                                         y: cursor,
                                         width: sectionContentRect.width,
                                         height: min(footer.height, max(1, bounds.height)))
                let descriptor = section.supplementaryProvider?(sectionIndex, UICollectionView.elementKindSectionFooter, footerFrame) ?? footer.content
                output.append(PTSkeletonRenderedItem(frame: footerFrame, descriptor: descriptor))
                cursor = footerFrame.maxY + sectionSpacing
            }
        }
        return output
    }

    private static func resolvedInsets(_ explicit: NSDirectionalEdgeInsets?,
                                      viewConfig: PTCollectionViewConfig,
                                      adjusted: UIEdgeInsets) -> NSDirectionalEdgeInsets {
        let base = explicit ?? NSDirectionalEdgeInsets(top: viewConfig.contentTopSpace,
                                                        leading: viewConfig.itemOriginalX,
                                                        bottom: viewConfig.contentBottomSpace,
                                                        trailing: viewConfig.itemOriginalX)
        return NSDirectionalEdgeInsets(top: safe(base.top) + safe(adjusted.top),
                                       leading: safe(base.leading) + safe(adjusted.left),
                                       bottom: safe(base.bottom) + safe(adjusted.bottom),
                                       trailing: safe(base.trailing) + safe(adjusted.right))
    }

    private static func directionalRect(bounds: CGRect,
                                        insets: NSDirectionalEdgeInsets,
                                        direction: UIUserInterfaceLayoutDirection) -> CGRect {
        let leading = direction == .rightToLeft ? insets.trailing : insets.leading
        let trailing = direction == .rightToLeft ? insets.leading : insets.trailing
        return CGRect(x: bounds.minX + leading,
                      y: bounds.minY + insets.top,
                      width: max(0, bounds.width - leading - trailing),
                      height: max(0, bounds.height - insets.top - insets.bottom))
    }

    private static func resolvedCount(mode: PTCollectionSkeletonItemCountMode,
                                      fallback: Int,
                                      type: PTCollectionViewType,
                                      contentRect: CGRect,
                                      layout: PTCollectionSkeletonLayout,
                                      viewConfig: PTCollectionViewConfig) -> Int {
        switch mode {
        case .configured:
            return min(max(fallback, 1), 50)
        case .fixed(let value):
            return min(max(value, 1), maximumViewportItemCount)
        case .fillViewport(let extraRows):
            let safeExtraRows = min(max(extraRows, 0), 50)
            let columns = max(1, layout.columnCount ?? viewConfig.rowCount)
            switch type {
            case .Horizontal, .HorizontalLayoutSystem:
                let width = max(1, safe(layout.itemWidth ?? viewConfig.itemWidth))
                let spacing = safe(layout.horizontalSpacing ?? viewConfig.cellLeadingSpace)
                return min(max(1, Int(ceil((contentRect.width + spacing) / max(1, width + spacing))) + safeExtraRows), maximumViewportItemCount)
            default:
                let height = max(1, safe(layout.itemHeight ?? viewConfig.itemHeight))
                let spacing = safe(layout.verticalSpacing ?? viewConfig.cellTrailingSpace)
                let rows = max(1, Int(ceil((contentRect.height + spacing) / max(1, height + spacing))) + safeExtraRows)
                return min(max(1, rows * columns), maximumViewportItemCount)
            }
        }
    }

    private static func resolveFrames(count: Int,
                                     type: PTCollectionViewType,
                                     contentRect: CGRect,
                                     layout: PTCollectionSkeletonLayout,
                                     viewConfig: PTCollectionViewConfig,
                                     layoutDirection: UIUserInterfaceLayoutDirection,
                                     adjustedContentInset: UIEdgeInsets) -> [CGRect] {
        guard count > 0, contentRect.width > 0, contentRect.height > 0 else { return [] }
        let horizontalSpacing = safe(layout.horizontalSpacing ?? viewConfig.cellLeadingSpace)
        let verticalSpacing = safe(layout.verticalSpacing ?? viewConfig.cellTrailingSpace)
        let columns = max(1, min(layout.columnCount ?? viewConfig.rowCount, 50))
        let width = max(1, (contentRect.width - CGFloat(columns - 1) * horizontalSpacing) / CGFloat(columns))
        let defaultHeight = max(1, safe(layout.itemHeight ?? viewConfig.itemHeight))
        var frames: [CGRect] = []
        frames.reserveCapacity(min(count, maximumViewportItemCount))

        switch type {
        case .Normal, .Custom:
            for index in 0..<count {
                let frame = CGRect(x: contentRect.minX,
                                   y: contentRect.minY + CGFloat(index) * (defaultHeight + verticalSpacing),
                                   width: contentRect.width,
                                   height: defaultHeight)
                frames.append(clamped(frame, to: contentRect.insetBy(dx: 0, dy: -contentRect.height)))
            }
        case .Gird, .Tag:
            for index in 0..<count {
                let row = index / columns
                let column = index % columns
                let frame = CGRect(x: contentRect.minX + CGFloat(column) * (width + horizontalSpacing),
                                   y: contentRect.minY + CGFloat(row) * (defaultHeight + verticalSpacing),
                                   width: width,
                                   height: defaultHeight)
                frames.append(clamped(frame, to: contentRect.insetBy(dx: 0, dy: -contentRect.height)))
            }
        case .WaterFall:
            var columnHeights = Array(repeating: contentRect.minY, count: columns)
            let multipliers = (layout.itemHeightMultipliers ?? [0.82, 1, 1.18]).filter { $0.isFinite && $0 > 0 }.prefix(8)
            let safeMultipliers = multipliers.isEmpty ? [CGFloat(1)] : Array(multipliers)
            for index in 0..<count {
                let column = columnHeights.enumerated().min(by: { $0.element < $1.element })?.offset ?? (index % columns)
                let height = max(1, defaultHeight * safeMultipliers[index % safeMultipliers.count])
                let frame = CGRect(x: contentRect.minX + CGFloat(column) * (width + horizontalSpacing),
                                   y: columnHeights[column],
                                   width: width,
                                   height: height)
                columnHeights[column] = frame.maxY + verticalSpacing
                frames.append(clamped(frame, to: contentRect.insetBy(dx: 0, dy: -contentRect.height)))
            }
        case .Horizontal, .HorizontalLayoutSystem:
            let itemWidth = max(1, safe(layout.itemWidth ?? viewConfig.itemWidth))
            let itemHeight = min(defaultHeight, contentRect.height)
            let y = contentRect.minY + max(0, (contentRect.height - itemHeight) / 2)
            for index in 0..<count {
                let frame = CGRect(x: contentRect.minX + CGFloat(index) * (itemWidth + horizontalSpacing),
                                   y: y,
                                   width: itemWidth,
                                   height: itemHeight)
                frames.append(frame)
            }
        }

        let provider = layout.geometryProvider
        return frames.enumerated().compactMap { index, frame in
            let safeFrame = clamped(frame, to: contentRect.insetBy(dx: 0, dy: -contentRect.height))
            guard isFinite(safeFrame) else { return nil }
            let context = PTSkeletonItemContext(skeletonSectionIndex: 0,
                                                itemIndex: index,
                                                itemFrame: safeFrame,
                                                layoutDirection: layoutDirection)
            let provided = provider?(0, index, contentRect, context) ?? safeFrame
            return mirrored(clamped(provided, to: contentRect.insetBy(dx: 0, dy: -contentRect.height)),
                            in: contentRect,
                            direction: layoutDirection)
        }
    }

    private static func configurationDescriptor(_ content: PTCollectionSkeletonContent,
                                                frame: CGRect,
                                                fallbackCornerRadius: CGFloat) -> PTSkeletonItemDescriptor {
        switch content {
        case .block:
            return PTSkeletonItemDescriptor(shapes: [.roundedRect(CGRect(x: 0, y: 0, width: 1, height: 1), cornerRadius: fallbackCornerRadius)])
        case .text(let text):
            return PTSkeletonItemDescriptor(content: .text(text))
        case .avatarText:
            return PTSkeletonItemDescriptor(content: .avatarText)
        case .imageText:
            return PTSkeletonItemDescriptor(content: .imageText)
        case .card:
            return PTSkeletonItemDescriptor(content: .card)
        case .custom(let shapes):
            return PTSkeletonItemDescriptor(content: .custom(shapes: shapes), shapes: shapes)
        }
    }

    private static func descriptorForTemplate(_ descriptor: PTSkeletonItemDescriptor,
                                              index: Int,
                                              frame: CGRect) -> PTSkeletonItemDescriptor {
        guard descriptor.shapes.isEmpty else { return descriptor }
        switch descriptor.content {
        case .block:
            return PTSkeletonItemDescriptor(shapes: [.roundedRect(CGRect(x: 0, y: 0, width: 1, height: 1))])
        case .text(let text):
            let font = text.preferredFont ?? .preferredFont(forTextStyle: .body)
            let lineHeight: CGFloat
            switch text.lineHeight {
            case .fixed(let value): lineHeight = max(1, value)
            case .relativeToFont(let value): lineHeight = max(1, value.lineHeight)
            case .relativeToAvailableHeight: lineHeight = max(1, (frame.height - text.padding.top - text.padding.bottom) / 2)
            }
            let availableHeight = max(1, frame.height - text.padding.top - text.padding.bottom)
            let lineCount: Int
            switch text.lineCount {
            case .fixed(let value): lineCount = min(max(value, 0), 20)
            case .inherited(let value): lineCount = min(max(value ?? 2, 0), 20)
            case .automaticFill:
                lineCount = min(max(Int(floor((availableHeight + text.lineSpacing) / (lineHeight + text.lineSpacing))), 1), 20)
            }
            let contentWidth = max(1, 1 - text.padding.leading - text.padding.trailing)
            let x: CGFloat = text.alignment == .right ? 1 - text.padding.trailing - contentWidth : text.padding.leading
            let lines = (0..<lineCount).map { line -> PTSkeletonShape in
                let ratio: CGFloat = line == lineCount - 1 ? text.lastLineFillRatio : 1
                let lineWidth = max(0.02, contentWidth * ratio)
                let y = text.padding.top + CGFloat(line) * ((lineHeight + text.lineSpacing) / max(frame.height, 1))
                let lineX = text.alignment == .right ? 1 - text.padding.trailing - lineWidth : x
                return .line(CGRect(x: lineX, y: y, width: lineWidth, height: lineHeight / max(frame.height, 1)), cornerRadius: text.lineCornerRadius)
            }
            _ = font
            return PTSkeletonItemDescriptor(content: .text(text), shapes: lines)
        case .avatarText:
            return PTSkeletonItemDescriptor(content: .avatarText, shapes: [
                .circle(CGRect(x: 0, y: 0.08, width: 0.28, height: 0.84)),
                .line(CGRect(x: 0.36, y: 0.25, width: 0.48, height: 0.14)),
                .line(CGRect(x: 0.36, y: 0.55, width: 0.36, height: 0.12))
            ])
        case .imageText:
            return PTSkeletonItemDescriptor(content: .imageText, shapes: [
                .roundedRect(CGRect(x: 0, y: 0, width: 0.32, height: 1), cornerRadius: 8),
                .line(CGRect(x: 0.4, y: 0.25, width: 0.48, height: 0.14)),
                .line(CGRect(x: 0.4, y: 0.55, width: 0.36, height: 0.12))
            ])
        case .card:
            return PTSkeletonItemDescriptor(content: .card, shapes: [
                .roundedRect(CGRect(x: 0, y: 0, width: 1, height: 0.54), cornerRadius: 8),
                .line(CGRect(x: 0.06, y: 0.66, width: 0.72, height: 0.1)),
                .line(CGRect(x: 0.06, y: 0.84, width: 0.38, height: 0.1))
            ])
        case .custom(let shapes):
            return PTSkeletonItemDescriptor(content: .custom(shapes: shapes), shapes: shapes)
        }
    }

    private static func safe(_ value: CGFloat) -> CGFloat {
        value.isFinite ? max(0, min(value, 10_000)) : 0
    }

    private static func isFinite(_ rect: CGRect) -> Bool {
        rect.origin.x.isFinite && rect.origin.y.isFinite && rect.size.width.isFinite && rect.size.height.isFinite
    }

    private static func clamped(_ rect: CGRect, to bounds: CGRect) -> CGRect {
        guard isFinite(rect), rect.width > 0, rect.height > 0 else { return .zero }
        let width = min(rect.width, max(0, bounds.width))
        let height = min(rect.height, max(0, bounds.height))
        let x = max(bounds.minX, min(rect.minX, bounds.maxX - width))
        let y = max(bounds.minY, min(rect.minY, bounds.maxY - height))
        return CGRect(x: x, y: y, width: width, height: height)
    }

    private static func mirrored(_ rect: CGRect,
                                 in bounds: CGRect,
                                 direction: UIUserInterfaceLayoutDirection) -> CGRect {
        guard direction == .rightToLeft else { return rect }
        return CGRect(x: bounds.maxX - (rect.minX - bounds.minX) - rect.width,
                      y: rect.minY,
                      width: rect.width,
                      height: rect.height)
    }
}
