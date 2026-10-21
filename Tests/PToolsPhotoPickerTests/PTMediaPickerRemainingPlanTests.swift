import XCTest
@testable import PooToolsPhotoPicker

@MainActor
private final class PTMediaFeedbackTestRecorder {
    var events: [PTMediaPickerFeedbackKind] = []
    var fallbackCount = 0
}

@MainActor
final class PTMediaGridNoopInFlightCommitTests: XCTestCase {
    func testLatestDesiredRowsWaitForThePreviousCommit() {
        var state = PTMediaGridCommitState()
        state.enqueue(rowIDs: ["a"])
        XCTAssertTrue(state.begin(transactionID: "first"))
        state.enqueue(rowIDs: ["a", "b"])
        XCTAssertFalse(state.commit(transactionID: "noop", rowIDs: ["a", "b"]))
        XCTAssertTrue(state.commit(transactionID: "first", rowIDs: ["a"]))
        XCTAssertTrue(state.begin(transactionID: "second"))
        XCTAssertTrue(state.commit(transactionID: "second", rowIDs: ["a", "b"]))
        XCTAssertEqual(state.committedRowIDs, ["a", "b"])
        XCTAssertFalse(state.hasInFlightTransaction)
    }
}

@MainActor
final class PTMediaPhotoKitDeltaIncrementalTests: XCTestCase {
    func testProjectionMetricsDescribeReuseAndCreationSeparately() {
        let metrics = PTMediaModelProjectionMetrics(reusedCount: 999,
                                                     createdCount: 1,
                                                     removedCount: 2)
        XCTAssertEqual(metrics.reusedCount, 999)
        XCTAssertEqual(metrics.createdCount, 1)
        XCTAssertEqual(metrics.removedCount, 2)
    }

    func testTransactionKeepsStableOrderAndAffectedIDs() {
        let transaction = PTMediaAlbumChangeTransaction(albumIdentifier: "album",
                                                         generation: 1,
                                                         oldRevision: 2,
                                                         newRevision: 3,
                                                         oldCount: 2,
                                                         newCount: 3,
                                                         insertedIDs: ["new"],
                                                         removedIDs: [],
                                                         changedIDs: ["changed"],
                                                         movedIDs: ["moved"],
                                                         orderedIDs: ["new", "changed", "moved"],
                                                         oldModeledResultOffset: 96,
                                                         oldWasFullyModeled: false)
        XCTAssertEqual(transaction.orderedIDs.first, "new")
        XCTAssertEqual(transaction.insertedIDs, ["new"])
        XCTAssertEqual(transaction.changedIDs, ["changed"])
    }
}

@MainActor
final class PTMediaThumbnailNilAndReuseTests: XCTestCase {
    func testNilImageResultDoesNotPretendToBeAResolvedImage() {
        let result = PTMediaImageRequestResult(image: nil,
                                                isDegraded: false,
                                                isCancelled: false,
                                                error: .failed("temporary"))
        XCTAssertNil(result.image)
        XCTAssertFalse(result.isCancelled)
        XCTAssertNotNil(result.error)
    }
}

@MainActor
final class PTMediaPendingCaptureTerminalTests: XCTestCase {
    func testCaptureOperationHasOneTerminalState() {
        let operation = PTMediaPickerFeedbackOperation()
        XCTAssertTrue(operation.canEmitTerminal())
        XCTAssertFalse(operation.canEmitTerminal())
    }
}

@MainActor
final class PTMediaPickerFeedbackRoutingTests: XCTestCase {
    func testDefaultAndCustomFeedbackAreMutuallyExclusive() {
        let recorder = PTMediaFeedbackTestRecorder()
        let feedback = PTMediaPickerFeedback(kind: .selectionLimitReached,
                                              title: "title",
                                              message: "message")
        PTMediaPickerFeedbackRouter.route(feedback, handler: nil) {
            recorder.fallbackCount += 1
        }
        PTMediaPickerFeedbackRouter.route(feedback, handler: { [recorder] event in
            recorder.events.append(event.kind)
        })
        XCTAssertEqual(recorder.fallbackCount, 1)
        XCTAssertEqual(recorder.events, [.selectionLimitReached])
    }
}

@MainActor
final class PTMediaCollectionV2ConfigurationTests: XCTestCase {
    func testV2ContextCarriesTheStableRowIdentity() {
        let row = PTRows(ID: "media", diffId: "asset:1")
        let section = PTSection(rows: [row])
        let context = PTCollectionCellContext(section: section,
                                               row: row,
                                               indexPath: IndexPath(item: 0, section: 0))
        XCTAssertEqual(context.row.diffId, "asset:1")
        XCTAssertEqual(context.logicalRowID.rawValue, "asset:1")
    }
}
