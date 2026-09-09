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
}
