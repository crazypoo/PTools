//
//  PTGroupAvatarComposer.swift
//  PooTools
//
// English: Render a deterministic static group avatar without coupling callers to a view hierarchy.
// Español: Renderiza un avatar grupal estático y determinista sin acoplar a los llamadores a una jerarquía de vistas.
// 中文：提供确定性的静态群头像合成能力，不让调用方依赖具体视图层级。
//

#if canImport(UIKit)
import UIKit

// English: The renderer is UI-bound by design; callers can keep the resulting image as a value.
// Español: El renderer está ligado a UI por diseño; los llamadores pueden conservar la imagen como un valor.
// 中文：渲染器有意绑定 UIKit，调用方只需要持有最终图片值。
@MainActor
public enum PTGroupAvatarComposer {
    public struct Options {
        public var gap: CGFloat
        public var backgroundColor: UIColor
        public var cornerRadius: CGFloat
        public var scale: CGFloat?
        public var contentMode: UIView.ContentMode
        public var maximumAvatarCount: Int

        public init(gap: CGFloat = 2,
                    backgroundColor: UIColor = .clear,
                    cornerRadius: CGFloat = 0,
                    scale: CGFloat? = nil,
                    contentMode: UIView.ContentMode = .scaleAspectFill,
                    maximumAvatarCount: Int = 9) {
            self.gap = max(0, gap)
            self.backgroundColor = backgroundColor
            self.cornerRadius = max(0, cornerRadius)
            self.scale = scale
            self.contentMode = contentMode
            self.maximumAvatarCount = min(9, max(1, maximumAvatarCount))
        }
    }

    // English: Empty input is a valid no-op and returns nil instead of manufacturing a blank avatar.
    // Español: Una entrada vacía es un no-op válido y devuelve nil en vez de fabricar un avatar vacío.
    // 中文：空输入是明确的无结果情况，返回 nil，不伪造空白头像。
    public static func render(images: [UIImage],
                              size: CGSize,
                              options: Options = .init()) -> UIImage? {
        guard !images.isEmpty,
              size.width.isFinite,
              size.height.isFinite,
              size.width > 0,
              size.height > 0 else {
            return nil
        }

        let visibleImages = Array(images.prefix(options.maximumAvatarCount))
        guard !visibleImages.isEmpty else { return nil }

        let format = UIGraphicsImageRendererFormat()
        let requestedScale = options.scale ?? visibleImages.map(\.scale).max() ?? 1
        format.scale = requestedScale.isFinite && requestedScale > 0 ? requestedScale : 1
        format.opaque = options.backgroundColor.cgColor.alpha >= 1

        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            options.backgroundColor.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            for rect in layoutRects(count: visibleImages.count,
                                    in: size,
                                    gap: options.gap) {
                let image = visibleImages[rect.index]
                let cornerRadius = min(options.cornerRadius,
                                       min(rect.frame.width, rect.frame.height) / 2)
                context.cgContext.saveGState()
                UIBezierPath(roundedRect: rect.frame,
                             cornerRadius: max(0, cornerRadius)).addClip()
                draw(image: image,
                     in: rect.frame,
                     contentMode: options.contentMode)
                context.cgContext.restoreGState()
            }
        }
    }

    private struct IndexedRect {
        let index: Int
        let frame: CGRect
    }

    // English: Center the final partial row so one-to-nine layouts remain visually balanced.
    // Español: Centra la última fila incompleta para mantener equilibrados los diseños de uno a nueve elementos.
    // 中文：居中排列最后一行，保证 1 到 9 张头像的布局始终平衡。
    private static func layoutRects(count: Int,
                                    in size: CGSize,
                                    gap: CGFloat) -> [IndexedRect] {
        guard count > 0 else { return [] }
        if count == 1 {
            return [IndexedRect(index: 0, frame: CGRect(origin: .zero, size: size))]
        }

        let columns = count <= 4 ? 2 : 3
        let rows = Int(ceil(Double(count) / Double(columns)))
        let safeGap = max(0, gap)
        let cellWidth = max(1, (size.width - safeGap * CGFloat(columns - 1)) / CGFloat(columns))
        let cellHeight = max(1, (size.height - safeGap * CGFloat(rows - 1)) / CGFloat(rows))
        var result: [IndexedRect] = []
        result.reserveCapacity(count)

        for row in 0..<rows {
            let rowStart = row * columns
            let countInRow = min(columns, count - rowStart)
            let rowWidth = cellWidth * CGFloat(countInRow)
                + safeGap * CGFloat(max(0, countInRow - 1))
            let originX = (size.width - rowWidth) / 2
            let originY = CGFloat(row) * (cellHeight + safeGap)

            for column in 0..<countInRow {
                let origin = CGPoint(x: originX + CGFloat(column) * (cellWidth + safeGap),
                                     y: originY)
                result.append(IndexedRect(index: rowStart + column,
                                          frame: CGRect(origin: origin,
                                                        size: CGSize(width: cellWidth,
                                                                     height: cellHeight))))
            }
        }
        return result
    }

    private static func draw(image: UIImage,
                             in rect: CGRect,
                             contentMode: UIView.ContentMode) {
        guard rect.width > 0, rect.height > 0,
              image.size.width > 0, image.size.height > 0 else { return }

        switch contentMode {
        case .scaleAspectFit:
            let scale = min(rect.width / image.size.width,
                            rect.height / image.size.height)
            let size = CGSize(width: image.size.width * scale,
                              height: image.size.height * scale)
            image.draw(in: CGRect(x: rect.midX - size.width / 2,
                                  y: rect.midY - size.height / 2,
                                  width: size.width,
                                  height: size.height))
        case .center:
            let size = image.size
            image.draw(in: CGRect(x: rect.midX - size.width / 2,
                                  y: rect.midY - size.height / 2,
                                  width: size.width,
                                  height: size.height))
        default:
            let scale = max(rect.width / image.size.width,
                            rect.height / image.size.height)
            let size = CGSize(width: image.size.width * scale,
                              height: image.size.height * scale)
            image.draw(in: CGRect(x: rect.midX - size.width / 2,
                                  y: rect.midY - size.height / 2,
                                  width: size.width,
                                  height: size.height))
        }
    }
}
#endif
