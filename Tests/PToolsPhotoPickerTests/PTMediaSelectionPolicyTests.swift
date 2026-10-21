import XCTest
@testable import PooToolsPhotoPicker

@MainActor
final class PTMediaSelectionPolicyTests: XCTestCase {
    func testImageThenVideoIsRejectedWhenMixingIsDisabled() {
        let options = PTMediaLibSelectionOptions(allowMixSelect: false)
        let context = PTMediaSelectionContext(selectedCount: 1,
                                               selectedTypes: [.image],
                                               candidateType: .video,
                                               candidateDuration: 1,
                                               candidateDataSize: nil,
                                               options: options)

        XCTAssertEqual(PTMediaSelectionPolicy.violation(for: context), .mixedMediaNotAllowed)
    }

    func testVideoThenImageIsRejectedWhenMixingIsDisabled() {
        let options = PTMediaLibSelectionOptions(allowMixSelect: false)
        let context = PTMediaSelectionContext(selectedCount: 1,
                                               selectedTypes: [.video],
                                               candidateType: .image,
                                               candidateDuration: 0,
                                               candidateDataSize: nil,
                                               options: options)

        XCTAssertEqual(PTMediaSelectionPolicy.violation(for: context), .mixedMediaNotAllowed)
    }

    func testReservedSelectionCountsAgainstMaximum() {
        let options = PTMediaLibSelectionOptions(maxSelectCount: 1)
        let context = PTMediaSelectionContext(selectedCount: 1,
                                               selectedTypes: [.image],
                                               candidateType: .image,
                                               candidateDuration: 0,
                                               candidateDataSize: nil,
                                               options: options)

        XCTAssertEqual(PTMediaSelectionPolicy.violation(for: context), .maximumSelectionReached)
    }

    func testVideoDurationBoundariesAreEnforced() {
        let options = PTMediaLibSelectionOptions(minSelectVideoDuration: 2,
                                                  maxSelectVideoDuration: 5)
        let tooShort = PTMediaSelectionContext(selectedCount: 0,
                                                selectedTypes: [],
                                                candidateType: .video,
                                                candidateDuration: 1,
                                                candidateDataSize: nil,
                                                options: options)
        let tooLong = PTMediaSelectionContext(selectedCount: 0,
                                               selectedTypes: [],
                                               candidateType: .video,
                                               candidateDuration: 6,
                                               candidateDataSize: nil,
                                               options: options)

        XCTAssertEqual(PTMediaSelectionPolicy.violation(for: tooShort), .videoDurationTooShort)
        XCTAssertEqual(PTMediaSelectionPolicy.violation(for: tooLong), .videoDurationTooLong)
    }

    func testGifCanBeDisabledWithoutDisablingRegularImages() {
        let options = PTMediaLibSelectionOptions(allowSelectGif: false)
        let context = PTMediaSelectionContext(selectedCount: 0,
                                               selectedTypes: [],
                                               candidateType: .gif,
                                               candidateDuration: 0,
                                               candidateDataSize: nil,
                                               options: options)

        XCTAssertEqual(PTMediaSelectionPolicy.violation(for: context), .mediaTypeNotAllowed)
    }

    func testPickerSessionLifecycleDoesNotNeedPhotoKitState() {
        let session = PTMediaPickerSession(options: .singleImage)
        XCTAssertEqual(session.state, .idle)

        session.beginLoading()
        XCTAssertEqual(session.state, .loading)
        session.markReady()
        XCTAssertEqual(session.state, .ready)
        XCTAssertTrue(session.beginSubmitting())
        XCTAssertFalse(session.beginSubmitting())
        session.markCompleted()
        XCTAssertEqual(session.state, .completed)
    }
}
