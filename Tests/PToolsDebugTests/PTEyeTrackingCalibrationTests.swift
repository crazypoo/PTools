// English: Verify that eye-tracking calibration failures never become a fake center-point callback.
// Español: Verifica que los fallos de calibración ocular nunca se conviertan en un punto central falso.
// 中文：验证眼动标定失败时不会伪装成屏幕中心坐标回调。

import XCTest
@testable import PooToolsDEBUGTrackingEyes

@MainActor
final class PTEyeTrackingCalibrationTests: XCTestCase {
    func testEmptyViewportDoesNotEmitOrigin() {
        let manager = PTEyeTrackingDataManager()

        XCTAssertEqual(manager.calibrationState.rawValue,
                       PTEyeTrackingCalibrationState.unsupported.rawValue)
        XCTAssertNil(manager.validatedLookAtPoint(.zero))
    }

    func testInvalidationRejectsOriginUntilCalibrationIsValid() {
        let manager = PTEyeTrackingDataManager(screenBounds: CGRect(x: 0, y: 0, width: 390, height: 844))
        let display = NSObject()

        manager.update(screenBounds: CGRect(x: 0, y: 0, width: 390, height: 844),
                       displayBounds: CGSize(width: 1170, height: 2532),
                       displayIdentifier: ObjectIdentifier(display),
                       sceneIdentifier: "scene-1")
        manager.updateCalibration(screenSizeMeters: CGSize(width: 0.0774, height: 0.1575))
        XCTAssertNotNil(manager.validatedLookAtPoint(.zero))

        manager.invalidateCalibration()
        XCTAssertNil(manager.validatedLookAtPoint(.zero))

        manager.updateCalibration(screenSizeMeters: CGSize(width: 0.0774, height: 0.1575))
        XCTAssertNotNil(manager.validatedLookAtPoint(.zero))
    }

    func testDisplayOrSceneChangeRequiresRecalibration() {
        let manager = PTEyeTrackingDataManager(screenBounds: CGRect(x: 0, y: 0, width: 390, height: 844))
        let firstDisplay = NSObject()
        let secondDisplay = NSObject()

        manager.update(screenBounds: CGRect(x: 0, y: 0, width: 390, height: 844),
                       displayBounds: CGSize(width: 1170, height: 2532),
                       displayIdentifier: ObjectIdentifier(firstDisplay),
                       sceneIdentifier: "scene-1")
        manager.updateCalibration(screenSizeMeters: CGSize(width: 0.0774, height: 0.1575))
        manager.update(screenBounds: CGRect(x: 0, y: 0, width: 390, height: 844),
                       displayBounds: CGSize(width: 1170, height: 2532),
                       displayIdentifier: ObjectIdentifier(secondDisplay),
                       sceneIdentifier: "scene-1")

        XCTAssertEqual(manager.calibrationState.rawValue,
                       PTEyeTrackingCalibrationState.needsRecalibration.rawValue)
    }

    func testRotationOnlyUpdatesLocalViewportAndKeepsPhysicalCalibration() {
        let manager = PTEyeTrackingDataManager(screenBounds: CGRect(x: 0, y: 0, width: 390, height: 844))
        let display = NSObject()

        manager.update(screenBounds: CGRect(x: 0, y: 0, width: 390, height: 844),
                       displayBounds: CGSize(width: 1170, height: 2532),
                       displayIdentifier: ObjectIdentifier(display),
                       sceneIdentifier: "scene-1")
        manager.updateCalibration(screenSizeMeters: CGSize(width: 0.0774, height: 0.1575))
        manager.update(screenBounds: CGRect(x: 0, y: 0, width: 844, height: 390),
                       displayBounds: CGSize(width: 1170, height: 2532),
                       displayIdentifier: ObjectIdentifier(display),
                       sceneIdentifier: "scene-1")

        XCTAssertEqual(manager.calibrationState.rawValue,
                       PTEyeTrackingCalibrationState.valid.rawValue)
        XCTAssertNotNil(manager.validatedLookAtPoint(.zero))
    }

    func testTrackingSessionResetClearsSamplesAndMarksPreciseCalibrationStale() {
        let manager = PTEyeTrackingDataManager(screenBounds: CGRect(x: 0, y: 0, width: 390, height: 844))
        manager.updateCalibration(screenSizeMeters: CGSize(width: 0.0774, height: 0.1575))

        manager.trackingSessionDidReset()

        XCTAssertEqual(manager.calibrationState.rawValue,
                       PTEyeTrackingCalibrationState.needsRecalibration.rawValue)
        XCTAssertNil(manager.validatedLookAtPoint(.zero))
    }

    func testTrackingSessionResetDoesNotRestoreInvalidCalibration() {
        let manager = PTEyeTrackingDataManager(screenBounds: CGRect(x: 0, y: 0, width: 390, height: 844))
        manager.invalidateCalibration()

        manager.trackingSessionDidReset()

        XCTAssertEqual(manager.calibrationState.rawValue,
                       PTEyeTrackingCalibrationState.needsRecalibration.rawValue)
        XCTAssertNil(manager.validatedLookAtPoint(.zero))
    }
}
