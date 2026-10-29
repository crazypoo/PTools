import XCTest
@testable import PooToolsDEBUG

final class PTInstrumentLatestSampleTests: XCTestCase {
    func testLastSampleSurvivesRingWrapWithoutFullTimeline() async {
        let metadata = PTInstrumentSessionMetadata(
            bundleIdentifier: "tests", appVersion: "1",
            operatingSystem: "iOS", deviceModel: "Simulator", screenRefreshRate: 60)
        let policy = PTInstrumentSamplingPolicy(maxSampleCount: 8)
        let session = PTInstrumentSession(selectedInstruments: [.fps],
                                          metadata: metadata, policy: policy)
        for index in 0..<1_000 {
            await session.recordSample(PTInstrumentSample(kind: .fps, value: Double(index), unit: "fps"))
        }
        let latest = await session.latestSamples(for: [.fps, .cpu])
        XCTAssertEqual(latest[.fps]?.value, 999)
        XCTAssertNil(latest[.cpu])
    }

    func testLatestReadDoesNotStopOrModifyRecording() async {
        let metadata = PTInstrumentSessionMetadata(
            bundleIdentifier: "tests", appVersion: "1",
            operatingSystem: "iOS", deviceModel: "Simulator", screenRefreshRate: 60)
        let session = PTInstrumentSession(selectedInstruments: [.memory], metadata: metadata)
        await session.recordSample(PTInstrumentSample(kind: .memory, value: 32, unit: "MB"))
        let first = await session.latestSamples(for: [.memory])
        let second = await session.latestSamples(for: [.memory])
        XCTAssertEqual(first[.memory], second[.memory])
        let state = await session.currentState()
        XCTAssertEqual(state, .recording)
    }

    @MainActor
    func testStudioOwnedRecorderStopsButLocalTakeoverSurvivesDisconnect() async {
        let studioOnly = PTInstrumentRecorder()
        studioOnly.startStudioSamplerIfNeeded()
        XCTAssertTrue(studioOnly.isRecording)
        await studioOnly.releaseStudioSamplerIfOwned()
        XCTAssertFalse(studioOnly.isRecording)

        let sharedWithLocalUI = PTInstrumentRecorder()
        sharedWithLocalUI.startStudioSamplerIfNeeded()
        let localSession = sharedWithLocalUI.start(instruments: [.fps])
        await sharedWithLocalUI.releaseStudioSamplerIfOwned()
        XCTAssertTrue(sharedWithLocalUI.isRecording)
        XCTAssertTrue(sharedWithLocalUI.session === localSession)
        _ = await sharedWithLocalUI.stop()
    }
}
