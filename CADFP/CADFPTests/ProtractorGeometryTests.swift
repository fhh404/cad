import CoreGraphics
import XCTest
@testable import CADFP

final class ProtractorGeometryTests: XCTestCase {
    func testMeasurementDegreesReturnsAbsoluteAngleDifference() {
        let state = ProtractorMeasurementState(
            leadingRayAngleDegrees: -12.3,
            trailingRayAngleDegrees: 58.4
        )

        XCTAssertEqual(ProtractorGeometry.measurementDegrees(for: state), 70.7, accuracy: 0.000001)
    }

    func testMeasurementDegreesSupportsWideAnglesAcrossSemicircle() {
        let state = ProtractorMeasurementState(
            leadingRayAngleDegrees: -85,
            trailingRayAngleDegrees: 85
        )

        XCTAssertEqual(ProtractorGeometry.measurementDegrees(for: state), 170, accuracy: 0.000001)
    }

    func testFormatsMeasurementWithTrimmedFractionDigits() {
        XCTAssertEqual(ProtractorGeometry.formattedMeasurement(70.7), "70.7°")
        XCTAssertEqual(ProtractorGeometry.formattedMeasurement(45), "45°")
    }

    func testDraggingHandleClampsAngleIntoSupportedSemicircle() {
        let state = ProtractorMeasurementState(
            leadingRayAngleDegrees: -15,
            trailingRayAngleDegrees: 48
        )

        let updated = ProtractorGeometry.updating(
            state,
            handle: .trailing,
            location: CGPoint(x: -40, y: 60),
            center: .zero
        )

        XCTAssertEqual(updated.leadingRayAngleDegrees, state.leadingRayAngleDegrees, accuracy: 0.000001)
        XCTAssertEqual(updated.trailingRayAngleDegrees, 90, accuracy: 0.000001)
    }

    func testDraggingHandleAcrossHorizontalAxisProducesStableAngle() {
        let state = ProtractorMeasurementState(
            leadingRayAngleDegrees: -5,
            trailingRayAngleDegrees: 5
        )

        let updated = ProtractorGeometry.updating(
            state,
            handle: .leading,
            location: CGPoint(x: 120, y: -120),
            center: .zero
        )

        XCTAssertEqual(updated.leadingRayAngleDegrees, -45, accuracy: 0.000001)
        XCTAssertEqual(ProtractorGeometry.measurementDegrees(for: updated), 50, accuracy: 0.000001)
    }

    func testMajorLabelValueSupportsOuterAndInnerScaleRings() {
        XCTAssertEqual(ProtractorGeometry.majorLabelValue(for: 0, reversed: false), 0)
        XCTAssertEqual(ProtractorGeometry.majorLabelValue(for: 7, reversed: false), 70)
        XCTAssertEqual(ProtractorGeometry.majorLabelValue(for: 18, reversed: false), 180)

        XCTAssertEqual(ProtractorGeometry.majorLabelValue(for: 0, reversed: true), 180)
        XCTAssertEqual(ProtractorGeometry.majorLabelValue(for: 7, reversed: true), 110)
        XCTAssertEqual(ProtractorGeometry.majorLabelValue(for: 18, reversed: true), 0)
    }

    func testInnerScaleUsesOneDegreeTicksWithFiveAndTenDegreeEmphasis() {
        XCTAssertEqual(ProtractorGeometry.innerTickLength(for: 1), 8, accuracy: 0.000001)
        XCTAssertEqual(ProtractorGeometry.innerTickLength(for: 5), 22, accuracy: 0.000001)
        XCTAssertEqual(ProtractorGeometry.innerTickLength(for: 10), 38, accuracy: 0.000001)
    }

    func testInnerScaleLabelInsetKeepsLabelsInsideMajorTicks() {
        XCTAssertGreaterThanOrEqual(
            ProtractorGeometry.innerLabelInset,
            ProtractorGeometry.innerTickLength(for: 10) + 10
        )
    }

    @MainActor
    func testProtractorCaptureServiceProviderReusesPreviewSession() {
        XCTAssertTrue(ProtractorCaptureServiceProvider.shared === ProtractorCaptureServiceProvider.shared)
    }
}
