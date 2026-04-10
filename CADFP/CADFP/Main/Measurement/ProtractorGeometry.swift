//
//  ProtractorGeometry.swift
//  CADFP
//
//  Created by Codex on 2026/4/10.
//

import CoreGraphics
import Foundation

enum ProtractorHandle: Hashable {
    case leading
    case trailing
}

struct ProtractorMeasurementState: Equatable {
    var leadingRayAngleDegrees: Double
    var trailingRayAngleDegrees: Double

    static let initial = ProtractorMeasurementState(
        leadingRayAngleDegrees: -12.3,
        trailingRayAngleDegrees: 58.4
    )
}

enum ProtractorGeometry {
    static let minimumRayAngleDegrees: Double = -90
    static let maximumRayAngleDegrees: Double = 90
    static let majorStepCount = 18
    static let innerLabelInset: CGFloat = 48

    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        formatter.roundingMode = .halfUp
        return formatter
    }()

    static func measurementDegrees(for state: ProtractorMeasurementState) -> Double {
        abs(state.trailingRayAngleDegrees - state.leadingRayAngleDegrees)
    }

    static func formattedMeasurement(_ degrees: Double) -> String {
        let number = NSNumber(value: degrees)
        return "\(formatter.string(from: number) ?? "0")°"
    }

    static func majorLabelValue(for step: Int, reversed: Bool) -> Int {
        let clampedStep = min(max(step, 0), majorStepCount)
        let value = clampedStep * 10
        return reversed ? 180 - value : value
    }

    static func innerTickLength(for degree: Int) -> CGFloat {
        if degree.isMultiple(of: 10) {
            return 38
        }

        if degree.isMultiple(of: 5) {
            return 22
        }

        return 8
    }

    static func endpoint(
        for angleDegrees: Double,
        center: CGPoint,
        radius: CGFloat
    ) -> CGPoint {
        let radians = angleDegrees * .pi / 180
        return CGPoint(
            x: center.x + radius * cos(radians),
            y: center.y + radius * sin(radians)
        )
    }

    static func updating(
        _ state: ProtractorMeasurementState,
        handle: ProtractorHandle,
        location: CGPoint,
        center: CGPoint
    ) -> ProtractorMeasurementState {
        let nextAngle = clampedRayAngle(angleDegrees(for: location, center: center))
        var nextState = state

        switch handle {
        case .leading:
            nextState.leadingRayAngleDegrees = nextAngle
        case .trailing:
            nextState.trailingRayAngleDegrees = nextAngle
        }

        return nextState
    }

    static func clampedRayAngle(_ angleDegrees: Double) -> Double {
        min(max(angleDegrees, minimumRayAngleDegrees), maximumRayAngleDegrees)
    }

    static func angleDegrees(for location: CGPoint, center: CGPoint) -> Double {
        let dx = location.x - center.x
        let dy = location.y - center.y
        return atan2(dy, dx) * 180 / .pi
    }
}
