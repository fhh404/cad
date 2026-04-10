//
//  RulerGeometry.swift
//  CADFP
//
//  Created by Codex on 2026/4/10.
//

import Foundation

enum RulerGeometry {
    static let edgeTrackingMarginPoints: Double = 96
    static let initialMeasurementCentimeters: Double = 4.7
    static let initialTopHandleCentimeters: Double = 5.0
    static let minimumMeasurementCentimeters: Double = 0.2

    private static let measurementFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.roundingMode = .halfUp
        return formatter
    }()

    static func points(fromCentimeters centimeters: Double, profile: RulerDisplayProfile) -> Double {
        centimeters * profile.pointsPerCentimeter
    }

    static func centimeters(fromPoints points: Double, profile: RulerDisplayProfile) -> Double {
        points / profile.pointsPerCentimeter
    }

    static func measurementCentimeters(for state: RulerViewportState, profile: RulerDisplayProfile) -> Double {
        centimeters(fromPoints: state.bottomHandlePoints - state.topHandlePoints, profile: profile)
    }

    static func formattedMeasurement(_ centimeters: Double) -> String {
        let number = NSNumber(value: centimeters)
        return "\(measurementFormatter.string(from: number) ?? "0")CM"
    }

    static func initialState(
        profile: RulerDisplayProfile,
        viewportHeight: Double
    ) -> RulerViewportState {
        let topHandlePoints = points(fromCentimeters: initialTopHandleCentimeters, profile: profile)
        let bottomHandlePoints = topHandlePoints + points(fromCentimeters: initialMeasurementCentimeters, profile: profile)
        let visibleStartPoints = max(0, bottomHandlePoints - (viewportHeight - edgeTrackingMarginPoints))

        return RulerViewportState(
            visibleStartPoints: visibleStartPoints,
            topHandlePoints: topHandlePoints,
            bottomHandlePoints: bottomHandlePoints
        )
    }

    static func applyingDrag(
        to state: RulerViewportState,
        handle: RulerHandle,
        deltaPoints: Double,
        viewportHeight: Double,
        profile: RulerDisplayProfile,
        edgeTrackingMarginPoints: Double = RulerGeometry.edgeTrackingMarginPoints,
        minimumMeasurementCentimeters: Double = RulerGeometry.minimumMeasurementCentimeters
    ) -> RulerViewportState {
        var nextState = state
        let minimumMeasurementPoints = points(fromCentimeters: minimumMeasurementCentimeters, profile: profile)

        switch handle {
        case .top:
            nextState.topHandlePoints = max(
                0,
                min(state.topHandlePoints + deltaPoints, state.bottomHandlePoints - minimumMeasurementPoints)
            )
        case .bottom:
            nextState.bottomHandlePoints = max(
                state.topHandlePoints + minimumMeasurementPoints,
                state.bottomHandlePoints + deltaPoints
            )
        }

        let visibleLowerBound = nextState.visibleStartPoints + viewportHeight - edgeTrackingMarginPoints
        let visibleUpperBound = nextState.visibleStartPoints + edgeTrackingMarginPoints

        switch handle {
        case .top:
            if nextState.topHandlePoints < visibleUpperBound {
                nextState.visibleStartPoints = max(0, nextState.topHandlePoints - edgeTrackingMarginPoints)
            } else if nextState.topHandlePoints > visibleLowerBound {
                nextState.visibleStartPoints = max(
                    0,
                    nextState.topHandlePoints - (viewportHeight - edgeTrackingMarginPoints)
                )
            }
        case .bottom:
            if nextState.bottomHandlePoints > visibleLowerBound {
                nextState.visibleStartPoints = max(
                    0,
                    nextState.bottomHandlePoints - (viewportHeight - edgeTrackingMarginPoints)
                )
            } else if nextState.bottomHandlePoints < visibleUpperBound {
                nextState.visibleStartPoints = max(0, nextState.bottomHandlePoints - edgeTrackingMarginPoints)
            }
        }

        return nextState
    }

    static func applyingViewportPan(
        to state: RulerViewportState,
        translationPoints: Double
    ) -> RulerViewportState {
        var nextState = state
        nextState.visibleStartPoints = max(0, state.visibleStartPoints - translationPoints)
        return nextState
    }
}
