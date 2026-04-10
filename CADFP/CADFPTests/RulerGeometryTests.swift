import XCTest
@testable import CADFP

final class RulerGeometryTests: XCTestCase {
    private let profile = RulerDisplayProfile(
        hardwareIdentifier: "iPhone15,4",
        ppi: 460,
        nativeScale: 3
    )

    func testPointsPerCentimeterDerivedFromPPIAndNativeScale() {
        XCTAssertEqual(profile.pointsPerCentimeter, 60.36745406824147, accuracy: 0.000001)
    }

    func testConvertsPointsToCentimetersAndBack() {
        let points = RulerGeometry.points(fromCentimeters: 4.7, profile: profile)

        XCTAssertEqual(points, 283.7270341207349, accuracy: 0.000001)
        XCTAssertEqual(RulerGeometry.centimeters(fromPoints: points, profile: profile), 4.7, accuracy: 0.000001)
    }

    func testFormatsMeasurementWithTrimmedFractionDigits() {
        XCTAssertEqual(RulerGeometry.formattedMeasurement(4.7), "4.7CM")
        XCTAssertEqual(RulerGeometry.formattedMeasurement(4.75), "4.75CM")
        XCTAssertEqual(RulerGeometry.formattedMeasurement(5), "5CM")
    }

    func testRegistryResolvesCurrentIPhone15PPI() throws {
        let resolvedProfile = try XCTUnwrap(RulerDeviceRegistry.profile(for: "iPhone15,4", nativeScale: 3))

        XCTAssertEqual(resolvedProfile.ppi, 460)
        XCTAssertEqual(resolvedProfile.pointsPerCentimeter, profile.pointsPerCentimeter, accuracy: 0.000001)
    }

    func testDraggingBottomHandlePastTrackingMarginShiftsViewport() {
        let state = RulerViewportState(
            visibleStartPoints: 0,
            topHandlePoints: RulerGeometry.points(fromCentimeters: 2.0, profile: profile),
            bottomHandlePoints: RulerGeometry.points(fromCentimeters: 6.0, profile: profile)
        )

        let next = RulerGeometry.applyingDrag(
            to: state,
            handle: .bottom,
            deltaPoints: 250,
            viewportHeight: 500,
            profile: profile
        )

        XCTAssertEqual(next.bottomHandlePoints, state.bottomHandlePoints + 250, accuracy: 0.000001)
        XCTAssertEqual(next.visibleStartPoints, 208.2047244094488, accuracy: 0.000001)
    }

    func testDraggingTopHandleRespectsMinimumSeparation() {
        let state = RulerViewportState(
            visibleStartPoints: 60,
            topHandlePoints: 200,
            bottomHandlePoints: 220
        )

        let next = RulerGeometry.applyingDrag(
            to: state,
            handle: .top,
            deltaPoints: 100,
            viewportHeight: 500,
            profile: profile
        )

        XCTAssertEqual(
            next.topHandlePoints,
            state.bottomHandlePoints - RulerGeometry.points(fromCentimeters: RulerGeometry.minimumMeasurementCentimeters, profile: profile),
            accuracy: 0.000001
        )
        XCTAssertEqual(next.bottomHandlePoints, state.bottomHandlePoints, accuracy: 0.000001)
    }

    func testViewportPanMovesVisibleWindowWithoutChangingMeasurement() {
        let state = RulerViewportState(
            visibleStartPoints: 180,
            topHandlePoints: 300,
            bottomHandlePoints: 420
        )

        let next = RulerGeometry.applyingViewportPan(
            to: state,
            translationPoints: -80
        )

        XCTAssertEqual(next.visibleStartPoints, 260, accuracy: 0.000001)
        XCTAssertEqual(next.topHandlePoints, state.topHandlePoints, accuracy: 0.000001)
        XCTAssertEqual(next.bottomHandlePoints, state.bottomHandlePoints, accuracy: 0.000001)
    }

    func testViewportPanClampsToZeroWhenDraggingDownPastOrigin() {
        let state = RulerViewportState(
            visibleStartPoints: 40,
            topHandlePoints: 150,
            bottomHandlePoints: 310
        )

        let next = RulerGeometry.applyingViewportPan(
            to: state,
            translationPoints: 120
        )

        XCTAssertEqual(next.visibleStartPoints, 0, accuracy: 0.000001)
    }
}
