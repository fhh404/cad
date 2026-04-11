import CoreGraphics
import UIKit
import XCTest
@testable import CADFP

final class LevelGeometryTests: XCTestCase {
    func testCircularBubbleOffsetClampsToTravelRadius() {
        let sample = LevelMotionSample(
            gravityX: 0.70710678118,
            gravityY: 0.70710678118,
            gravityZ: -0.05
        )

        let offset = LevelGeometry.circularBubbleOffset(
            for: sample,
            travelRadius: 64
        )

        XCTAssertLessThanOrEqual(hypot(offset.width, offset.height), 64.000001)
    }

    func testBarAngleUsesXAxisInPortrait() {
        let sample = LevelMotionSample(
            gravityX: 0.5,
            gravityY: 0,
            gravityZ: -0.86602540378
        )

        XCTAssertEqual(
            LevelGeometry.barAngleDegrees(for: sample, orientation: .portrait),
            30,
            accuracy: 0.0001
        )
    }

    func testBarAngleUsesYAxisInLandscape() {
        let sample = LevelMotionSample(
            gravityX: 0,
            gravityY: 0.5,
            gravityZ: -0.86602540378
        )

        XCTAssertEqual(
            LevelGeometry.barAngleDegrees(for: sample, orientation: .landscapeLeft),
            30,
            accuracy: 0.0001
        )
    }

    func testBarBubbleOffsetClampsToVisibleTravel() {
        let sample = LevelMotionSample(
            gravityX: 0.70710678118,
            gravityY: 0,
            gravityZ: -0.70710678118
        )

        XCTAssertEqual(
            LevelGeometry.barBubbleOffset(for: sample, orientation: .portrait, travel: 72),
            72,
            accuracy: 0.0001
        )
    }

    func testBarMeasurementLineRotationMatchesMeasuredAngle() {
        let sample = LevelMotionSample(
            gravityX: -0.156434465,
            gravityY: 0,
            gravityZ: -0.987688341
        )

        XCTAssertEqual(
            LevelGeometry.barMeasurementLineRotationDegrees(for: sample, orientation: .portrait),
            -9,
            accuracy: 0.0001
        )
    }

    func testFormatsAnglesWithTrimmedFractionDigits() {
        XCTAssertEqual(LevelGeometry.formattedAngle(9), "9°")
        XCTAssertEqual(LevelGeometry.formattedAngle(-9.4), "-9.4°")
    }
}
