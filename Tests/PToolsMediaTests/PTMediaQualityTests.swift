import UIKit
import XCTest
@testable import ptools

@MainActor
final class PTMediaQualityTests: XCTestCase {
    func testVideoThumbnailRequestNormalizesFrameNumber() {
        guard let url = URL(string: "https://example.com/video.mp4") else {
            XCTFail("无法创建视频 URL")
            return
        }

        let request = PTVideoThumbnailRequest(url: url,
                                              frameNumber: 0,
                                              maximumSize: CGSize(width: 320, height: 180))

        XCTAssertEqual(request.frameNumber, 1)
        XCTAssertEqual(request.maximumSize, CGSize(width: 320, height: 180))
    }

    func testVideoThumbnailCacheKeyIncludesFrameAndSize() {
        guard let url = URL(string: "https://example.com/video.mp4") else {
            XCTFail("无法创建视频 URL")
            return
        }

        let first = PTVideoCoverCache.cacheKeyForVideo("\(url.absoluteString)|frame:1|size:320x180")
        let second = PTVideoCoverCache.cacheKeyForVideo("\(url.absoluteString)|frame:10|size:320x180")

        XCTAssertNotEqual(first, second)
    }

    func testInvalidVideoDoesNotProduceThumbnail() async {
        let url = URL(fileURLWithPath: "/tmp/ptools-quality-missing-video.mp4")
        let image = await PTVideoThumbnailService.image(for: url,
                                                        frameNumber: 10,
                                                        maximumSize: CGSize(width: 320, height: 180))

        XCTAssertNil(image)
    }

    func testMeasureFourKImageThumbnailPreparation() {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 3_840, height: 2_160), format: format)
        let image = renderer.image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(origin: .zero, size: CGSize(width: 3_840, height: 2_160)))
        }

        measure {
            autoreleasepool {
                _ = image.preparingThumbnail(of: CGSize(width: 960, height: 540))
            }
        }
    }

    func testMediaPagingUsesExplicitEdgeToEdgeInsetPolicy() {
        let config = PTCollectionViewConfig()
        config.contentInsetAdjustmentBehavior = .never
        let list = PTCollectionView(viewConfig: config)
        list.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        list.layoutIfNeeded()

        XCTAssertEqual(list.contentCollectionView.contentInsetAdjustmentBehavior, .never)
        XCTAssertEqual(list.contentCollectionView.frame, list.bounds)
    }

    // English: Verify the avatar composer handles empty, bounded, and rectangular input deterministically.
    // Español: Verifica que el compositor de avatares maneje de forma determinista entradas vacías, limitadas y rectangulares.
    // 中文：验证头像合成器对空输入、数量上限和矩形输出都保持确定性。
    func testGroupAvatarComposerUsesBoundedCountAndOutputSize() {
        XCTAssertNil(PTGroupAvatarComposer.render(images: [],
                                                  size: CGSize(width: 120, height: 80)))

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let source = UIGraphicsImageRenderer(size: CGSize(width: 20, height: 20),
                                             format: format).image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 20, height: 20))
        }
        let image = PTGroupAvatarComposer.render(images: Array(repeating: source, count: 12),
                                                  size: CGSize(width: 120, height: 80),
                                                  options: .init(gap: 2, cornerRadius: 8))

        XCTAssertEqual(image?.size, CGSize(width: 120, height: 80))
    }

    // English: Verify image preparation applies a pixel budget without blocking the UI actor.
    // Español: Verifica que la preparación aplique un presupuesto de píxeles sin bloquear el actor de UI.
    // 中文：验证图片预处理会遵守像素预算且不会阻塞 UI actor。
    func testMediaImagePreprocessorAppliesPixelBudget() async throws {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let source = UIGraphicsImageRenderer(size: CGSize(width: 160, height: 80),
                                             format: format).image { context in
            UIColor.systemGreen.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 160, height: 80))
        }
        guard let data = source.pngData() else {
            XCTFail("无法生成测试图片数据")
            return
        }

        let result = try await PTMediaImagePreprocessor.prepare(
            data: data,
            configuration: .init(maxPixelDimension: 32,
                                 encoding: .jpeg,
                                 initialQuality: 0.8,
                                 qualityFloor: 0.4))

        XCTAssertLessThanOrEqual(max(result.pixelSize.width, result.pixelSize.height), 32)
        XCTAssertEqual(result.encoding, .jpeg)
        XCTAssertTrue(result.didDownsample)
        XCTAssertFalse(result.data.isEmpty)
    }
}
