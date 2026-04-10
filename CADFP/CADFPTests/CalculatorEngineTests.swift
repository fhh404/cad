import XCTest
@testable import CADFP

final class CalculatorEngineTests: XCTestCase {
    func testCylinderComputesTotalAreaAndVolume() throws {
        let result = try CalculatorEngine.compute(
            kind: .cylinder,
            inputs: [
                .radius: 3,
                .height: 5
            ]
        )

        XCTAssertEqual(try XCTUnwrap(result[.totalArea]), 150.79644737231007, accuracy: 0.000001)
        XCTAssertEqual(try XCTUnwrap(result[.volume]), 141.3716694115407, accuracy: 0.000001)
    }

    func testSphereComputesSurfaceAreaAndVolumeFromDiameter() throws {
        let result = try CalculatorEngine.compute(
            kind: .sphere,
            inputs: [
                .diameter: 8
            ]
        )

        XCTAssertEqual(try XCTUnwrap(result[.surfaceArea]), 201.06192982974676, accuracy: 0.000001)
        XCTAssertEqual(try XCTUnwrap(result[.volume]), 268.082573106329, accuracy: 0.000001)
    }

    func testCubeComputesAreaAndVolume() throws {
        let result = try CalculatorEngine.compute(
            kind: .cube,
            inputs: [
                .sideLength: 4
            ]
        )

        XCTAssertEqual(try XCTUnwrap(result[.surfaceArea]), 96, accuracy: 0.000001)
        XCTAssertEqual(try XCTUnwrap(result[.volume]), 64, accuracy: 0.000001)
    }

    func testConeComputesSlantHeightAndAreas() throws {
        let result = try CalculatorEngine.compute(
            kind: .cone,
            inputs: [
                .radius: 3,
                .height: 4
            ]
        )

        XCTAssertEqual(try XCTUnwrap(result[.slantHeight]), 5, accuracy: 0.000001)
        XCTAssertEqual(try XCTUnwrap(result[.lateralSurfaceArea]), 47.12388980384689, accuracy: 0.000001)
        XCTAssertEqual(try XCTUnwrap(result[.surfaceArea]), 75.39822368615503, accuracy: 0.000001)
        XCTAssertEqual(try XCTUnwrap(result[.volume]), 37.69911184307752, accuracy: 0.000001)
    }

    func testTriangleComputesArea() throws {
        let result = try CalculatorEngine.compute(
            kind: .triangleArea,
            inputs: [
                .height: 6,
                .base: 8
            ]
        )

        XCTAssertEqual(try XCTUnwrap(result[.area]), 24, accuracy: 0.000001)
    }

    func testRectangleComputesAreaAndPerimeter() throws {
        let result = try CalculatorEngine.compute(
            kind: .rectangle,
            inputs: [
                .length: 8,
                .width: 3
            ]
        )

        XCTAssertEqual(try XCTUnwrap(result[.area]), 24, accuracy: 0.000001)
        XCTAssertEqual(try XCTUnwrap(result[.perimeter]), 22, accuracy: 0.000001)
    }

    func testCircleComputesAreaAndCircumferenceFromRadius() throws {
        let result = try CalculatorEngine.compute(
            kind: .circle,
            inputs: [
                .radius: 5
            ]
        )

        XCTAssertEqual(try XCTUnwrap(result[.area]), 78.53981633974483, accuracy: 0.000001)
        XCTAssertEqual(try XCTUnwrap(result[.perimeter]), 31.41592653589793, accuracy: 0.000001)
    }

    func testTrapezoidComputesArea() throws {
        let result = try CalculatorEngine.compute(
            kind: .trapezoid,
            inputs: [
                .topBase: 4,
                .bottomBase: 10,
                .height: 6
            ]
        )

        XCTAssertEqual(try XCTUnwrap(result[.area]), 42, accuracy: 0.000001)
    }

    func testComputeRejectsMissingInput() {
        XCTAssertThrowsError(
            try CalculatorEngine.compute(
                kind: .rectangle,
                inputs: [
                    .length: 10
                ]
            )
        ) { error in
            XCTAssertEqual(error as? CalculatorComputationError, .missingValue(.width))
        }
    }

    func testComputeRejectsNonPositiveInput() {
        XCTAssertThrowsError(
            try CalculatorEngine.compute(
                kind: .circle,
                inputs: [
                    .radius: 0
                ]
            )
        ) { error in
            XCTAssertEqual(error as? CalculatorComputationError, .nonPositiveValue(.radius))
        }
    }
}
