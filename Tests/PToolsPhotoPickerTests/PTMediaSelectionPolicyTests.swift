import XCTest
@testable import PooToolsPhotoPicker

@MainActor
private final class PTMediaCancellationCounter {
    var value = 0
}

@MainActor
final class PTMediaSelectionPolicyTests: XCTestCase {
    func testImageThenVideoIsRejectedWhenMixingIsDisabled() {
        let options = PTMediaLibSelectionOptions(allowMixSelect: false)
        let context = PTMediaSelectionContext(selectedCount: 1,
                                               selectedFamilies: [.image],
                                               candidateType: .video,
                                               candidateDuration: 1,
                                               candidateDataSize: nil,
                                               options: options)

        XCTAssertEqual(PTMediaSelectionPolicy.violation(for: context), .mixedMediaNotAllowed)
    }

    func testVideoThenImageIsRejectedWhenMixingIsDisabled() {
        let options = PTMediaLibSelectionOptions(allowMixSelect: false)
        let context = PTMediaSelectionContext(selectedCount: 1,
                                               selectedFamilies: [.video],
                                               candidateType: .image,
                                               candidateDuration: 0,
                                               candidateDataSize: nil,
                                               options: options)

        XCTAssertEqual(PTMediaSelectionPolicy.violation(for: context), .mixedMediaNotAllowed)
    }

    func testReservedSelectionCountsAgainstMaximum() {
        let options = PTMediaLibSelectionOptions(maxSelectCount: 1)
        let context = PTMediaSelectionContext(selectedCount: 1,
                                               selectedFamilies: [.image],
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
                                                selectedFamilies: [],
                                                candidateType: .video,
                                                candidateDuration: 1,
                                                candidateDataSize: nil,
                                                options: options)
        let tooLong = PTMediaSelectionContext(selectedCount: 0,
                                               selectedFamilies: [],
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
                                               selectedFamilies: [],
                                               candidateType: .gif,
                                               candidateDuration: 0,
                                               candidateDataSize: nil,
                                               options: options)

        XCTAssertEqual(PTMediaSelectionPolicy.violation(for: context), .mediaTypeNotAllowed)
    }

    func testImageFamilyAllowsGifWhenGifIsEnabled() {
        let options = PTMediaLibSelectionOptions(allowMixSelect: false,
                                                 allowSelectGif: true)
        let context = PTMediaSelectionContext(selectedCount: 1,
                                               selectedFamilies: [.image],
                                               candidateType: .gif,
                                               candidateDuration: 0,
                                               candidateDataSize: nil,
                                               options: options)

        XCTAssertNil(PTMediaSelectionPolicy.violation(for: context))
    }

    func testImageFamilyAllowsLivePhotoWhenMixingIsDisabled() {
        let options = PTMediaLibSelectionOptions(allowMixSelect: false)
        let context = PTMediaSelectionContext(selectedCount: 1,
                                               selectedFamilies: [.image],
                                               candidateType: .livePhoto,
                                               candidateDuration: 0,
                                               candidateDataSize: nil,
                                               options: options)

        XCTAssertNil(PTMediaSelectionPolicy.violation(for: context))
    }

    func testRegularImageFilterRejectsGif() {
        let options = PTMediaLibSelectionOptions(imageFilter: .regularImageOnly)
        let context = PTMediaSelectionContext(selectedCount: 0,
                                               selectedFamilies: [],
                                               candidateType: .gif,
                                               candidateDuration: 0,
                                               candidateDataSize: nil,
                                               options: options)

        XCTAssertEqual(PTMediaSelectionPolicy.violation(for: context), .imageFilterNotAllowed)
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
        XCTAssertFalse(session.beginSubmitting())
    }

    func testPickerSessionCancellationIsTerminal() {
        let session = PTMediaPickerSession(options: .singleImage)
        session.beginLoading()
        session.markReady()
        session.markCancelled()

        XCTAssertEqual(session.state, .cancelled)
        XCTAssertFalse(session.beginSubmitting())
        session.markCompleted()
        XCTAssertEqual(session.state, .cancelled)
    }

    func testMediaRequestCancellationIsIdempotentAndHandlesLateRegistration() {
        let cancellation = PTMediaRequestCancellation()
        let counter = PTMediaCancellationCounter()

        cancellation.setCancelAction {
            counter.value += 1
        }
        cancellation.cancel()
        cancellation.cancel()

        XCTAssertTrue(cancellation.isCancelled)
        XCTAssertEqual(counter.value, 1)

        cancellation.setCancelAction {
            counter.value += 1
        }
        XCTAssertEqual(counter.value, 2)
    }
}
