//
//  MeasurementModels.swift
//  CADFP
//
//  Created by Codex on 2026/4/10.
//

import Foundation

enum MeasurementToolKind: String, CaseIterable, Identifiable, Hashable {
    case circularLevel
    case barLevel
    case ruler
    case protractor

    var id: String { rawValue }

    var title: String {
        switch self {
        case .circularLevel:
            return "圆形水平仪"
        case .barLevel:
            return "条形水平仪"
        case .ruler:
            return "直尺"
        case .protractor:
            return "量角器"
        }
    }

    var iconAssetName: String {
        switch self {
        case .circularLevel:
            return "水平仪 1"
        case .barLevel:
            return "Group 355"
        case .ruler:
            return "直尺 1"
        case .protractor:
            return "测量角度 1"
        }
    }

    var isImplemented: Bool {
        true
    }
}

enum RulerHandle: Hashable {
    case top
    case bottom
}

struct RulerDisplayProfile: Equatable {
    let hardwareIdentifier: String
    let ppi: Double
    let nativeScale: Double

    var pixelsPerCentimeter: Double {
        ppi / 2.54
    }

    var pointsPerCentimeter: Double {
        pixelsPerCentimeter / nativeScale
    }
}

struct RulerViewportState: Equatable {
    var visibleStartPoints: Double
    var topHandlePoints: Double
    var bottomHandlePoints: Double
}
