//
//  CalculatorEngine.swift
//  CADFP
//
//  Created by Codex on 2026/4/10.
//

import Foundation

enum CalculatorEngine {
    static func compute(
        kind: CalculatorKind,
        inputs: [CalculatorFieldKey: Double]
    ) throws -> [CalculatorFieldKey: Double] {
        switch kind {
        case .cylinder:
            let radius = try requiredValue(.radius, in: inputs)
            let height = try requiredValue(.height, in: inputs)
            return [
                .totalArea: 2 * .pi * radius * (radius + height),
                .volume: .pi * radius * radius * height
            ]
        case .sphere:
            let diameter = try requiredValue(.diameter, in: inputs)
            let radius = diameter / 2
            return [
                .surfaceArea: 4 * .pi * radius * radius,
                .volume: (4.0 / 3.0) * .pi * pow(radius, 3)
            ]
        case .cube:
            let sideLength = try requiredValue(.sideLength, in: inputs)
            return [
                .surfaceArea: 6 * sideLength * sideLength,
                .volume: pow(sideLength, 3)
            ]
        case .cone:
            let radius = try requiredValue(.radius, in: inputs)
            let height = try requiredValue(.height, in: inputs)
            let slantHeight = hypot(radius, height)
            return [
                .slantHeight: slantHeight,
                .lateralSurfaceArea: .pi * radius * slantHeight,
                .surfaceArea: .pi * radius * (radius + slantHeight),
                .volume: .pi * radius * radius * height / 3
            ]
        case .triangleArea:
            let height = try requiredValue(.height, in: inputs)
            let base = try requiredValue(.base, in: inputs)
            return [
                .area: base * height / 2
            ]
        case .rectangle:
            let length = try requiredValue(.length, in: inputs)
            let width = try requiredValue(.width, in: inputs)
            return [
                .area: length * width,
                .perimeter: 2 * (length + width)
            ]
        case .circle:
            let radius = try requiredValue(.radius, in: inputs)
            return [
                .area: .pi * radius * radius,
                .perimeter: 2 * .pi * radius
            ]
        case .trapezoid:
            let topBase = try requiredValue(.topBase, in: inputs)
            let bottomBase = try requiredValue(.bottomBase, in: inputs)
            let height = try requiredValue(.height, in: inputs)
            return [
                .area: (topBase + bottomBase) * height / 2
            ]
        }
    }

    private static func requiredValue(
        _ key: CalculatorFieldKey,
        in inputs: [CalculatorFieldKey: Double]
    ) throws -> Double {
        guard let value = inputs[key] else {
            throw CalculatorComputationError.missingValue(key)
        }
        guard value.isFinite, value > 0 else {
            throw CalculatorComputationError.nonPositiveValue(key)
        }
        return value
    }
}
