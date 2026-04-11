//
//  LevelGeometry.swift
//  CADFP
//
//  Created by Codex on 2026/4/11.
//

import CoreGraphics
import Foundation
import UIKit

struct LevelMotionSample: Equatable {
    let gravityX: Double
    let gravityY: Double
    let gravityZ: Double

    static let flat = LevelMotionSample(gravityX: 0, gravityY: 0, gravityZ: -1)
}

enum LevelGeometry {
    static let maximumVisibleAngleDegrees: Double = 30

    private static let minimumGravityZ: Double = 0.0001
    private static let angleFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        return formatter
    }()

    static func circularBubbleOffset(
        for sample: LevelMotionSample,
        travelRadius: CGFloat
    ) -> CGSize {
        let x = normalizedOffset(for: angleDegrees(forAxisGravity: sample.gravityX, gravityZ: sample.gravityZ))
        let y = normalizedOffset(for: angleDegrees(forAxisGravity: sample.gravityY, gravityZ: sample.gravityZ))
        let rawOffset = CGVector(dx: CGFloat(x) * travelRadius, dy: CGFloat(y) * travelRadius)
        let distance = hypot(rawOffset.dx, rawOffset.dy)

        guard distance > travelRadius, distance > 0 else {
            return CGSize(width: rawOffset.dx, height: rawOffset.dy)
        }

        let scale = travelRadius / distance
        return CGSize(width: rawOffset.dx * scale, height: rawOffset.dy * scale)
    }

    static func barAngleDegrees(
        for sample: LevelMotionSample,
        orientation: UIDeviceOrientation
    ) -> Double {
        angleDegrees(
            forAxisGravity: barAxisGravity(for: sample, orientation: orientation),
            gravityZ: sample.gravityZ
        )
    }

    static func barBubbleOffset(
        for sample: LevelMotionSample,
        orientation: UIDeviceOrientation,
        travel: CGFloat
    ) -> CGFloat {
        CGFloat(normalizedOffset(for: barAngleDegrees(for: sample, orientation: orientation))) * travel
    }

    static func barMeasurementLineRotationDegrees(
        for sample: LevelMotionSample,
        orientation: UIDeviceOrientation
    ) -> Double {
        barAngleDegrees(for: sample, orientation: orientation)
    }

    static func formattedAngle(_ angle: Double) -> String {
        let roundedAngle = (angle * 10).rounded() / 10
        let number = NSNumber(value: roundedAngle)
        return "\(angleFormatter.string(from: number) ?? "\(roundedAngle)")°"
    }

    static func displayOrientation(
        from orientation: UIDeviceOrientation,
        fallback: UIDeviceOrientation = .portrait
    ) -> UIDeviceOrientation {
        switch orientation {
        case .portrait, .portraitUpsideDown, .landscapeLeft, .landscapeRight:
            return orientation
        default:
            return fallback
        }
    }

    private static func barAxisGravity(
        for sample: LevelMotionSample,
        orientation: UIDeviceOrientation
    ) -> Double {
        switch displayOrientation(from: orientation) {
        case .landscapeLeft:
            return sample.gravityY
        case .landscapeRight:
            return -sample.gravityY
        case .portraitUpsideDown:
            return -sample.gravityX
        default:
            return sample.gravityX
        }
    }

    private static func angleDegrees(forAxisGravity axisGravity: Double, gravityZ: Double) -> Double {
        atan2(axisGravity, max(abs(gravityZ), minimumGravityZ)) * 180 / .pi
    }

    private static func normalizedOffset(for angleDegrees: Double) -> Double {
        min(max(angleDegrees / maximumVisibleAngleDegrees, -1), 1)
    }
}
