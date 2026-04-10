//
//  CalculatorModels.swift
//  CADFP
//
//  Created by Codex on 2026/4/10.
//

import Foundation

enum CalculatorFieldKey: String, Hashable {
    case radius
    case height
    case diameter
    case sideLength
    case base
    case length
    case width
    case topBase
    case bottomBase
    case area
    case totalArea
    case surfaceArea
    case lateralSurfaceArea
    case slantHeight
    case volume
    case perimeter

    var title: String {
        switch self {
        case .radius:
            return "半径："
        case .height:
            return "高度："
        case .diameter:
            return "直径："
        case .sideLength:
            return "边长："
        case .base:
            return "下底："
        case .length:
            return "长度："
        case .width:
            return "宽度："
        case .topBase:
            return "上底："
        case .bottomBase:
            return "下底："
        case .area:
            return "面积："
        case .totalArea:
            return "总面积："
        case .surfaceArea:
            return "表面积："
        case .lateralSurfaceArea:
            return "曲面表面积："
        case .slantHeight:
            return "斜面高："
        case .volume:
            return "体积："
        case .perimeter:
            return "周长："
        }
    }

    var plainTitle: String {
        title.replacingOccurrences(of: "：", with: "")
    }
}

struct CalculatorInputFieldDefinition: Identifiable, Hashable {
    let key: CalculatorFieldKey
    let title: String
    let placeholder: String
    let unit: String

    var id: CalculatorFieldKey { key }
}

struct CalculatorResultDefinition: Identifiable, Hashable {
    let key: CalculatorFieldKey
    let title: String
    let unit: String

    var id: CalculatorFieldKey { key }
}

enum CalculatorKind: String, CaseIterable, Identifiable, Hashable {
    case cylinder
    case sphere
    case cube
    case cone
    case triangleArea
    case rectangle
    case circle
    case trapezoid

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cylinder:
            return "圆柱体"
        case .sphere:
            return "球体"
        case .cube:
            return "立方体"
        case .cone:
            return "圆锥"
        case .triangleArea:
            return "三角形面积"
        case .rectangle:
            return "矩形"
        case .circle:
            return "圆形"
        case .trapezoid:
            return "梯形"
        }
    }

    var iconAssetName: String {
        switch self {
        case .cylinder:
            return "Group 353"
        case .sphere:
            return "Group 352"
        case .cube:
            return "Group 351"
        case .cone:
            return "Group 349"
        case .triangleArea:
            return "Group 350"
        case .rectangle:
            return "Group 344"
        case .circle:
            return "Group 347"
        case .trapezoid:
            return "Group 345"
        }
    }

    var inputFields: [CalculatorInputFieldDefinition] {
        switch self {
        case .cylinder:
            return [
                .init(key: .radius, title: "半径：", placeholder: "输入半径", unit: "m"),
                .init(key: .height, title: "高度：", placeholder: "输入高度", unit: "m")
            ]
        case .sphere:
            return [
                .init(key: .diameter, title: "直径：", placeholder: "输入直径", unit: "m")
            ]
        case .cube:
            return [
                .init(key: .sideLength, title: "边长：", placeholder: "输入边长", unit: "m")
            ]
        case .cone:
            return [
                .init(key: .radius, title: "半径：", placeholder: "输入半径", unit: "m"),
                .init(key: .height, title: "高度：", placeholder: "输入高度", unit: "m")
            ]
        case .triangleArea:
            return [
                .init(key: .height, title: "高度：", placeholder: "输入高度", unit: "m"),
                .init(key: .base, title: "下底：", placeholder: "输入下底", unit: "m")
            ]
        case .rectangle:
            return [
                .init(key: .length, title: "长度：", placeholder: "输入长度", unit: "m"),
                .init(key: .width, title: "宽度：", placeholder: "输入宽度", unit: "m")
            ]
        case .circle:
            return [
                .init(key: .radius, title: "半径：", placeholder: "输入半径", unit: "m")
            ]
        case .trapezoid:
            return [
                .init(key: .topBase, title: "上底：", placeholder: "输入上底", unit: "m"),
                .init(key: .bottomBase, title: "下底：", placeholder: "输入下底", unit: "m"),
                .init(key: .height, title: "高：", placeholder: "输入高", unit: "m")
            ]
        }
    }

    var resultFields: [CalculatorResultDefinition] {
        switch self {
        case .cylinder:
            return [
                .init(key: .totalArea, title: "总面积：", unit: "㎡"),
                .init(key: .volume, title: "体积：", unit: "m³")
            ]
        case .sphere:
            return [
                .init(key: .surfaceArea, title: "球体表面积：", unit: "㎡"),
                .init(key: .volume, title: "球体体积：", unit: "m³")
            ]
        case .cube:
            return [
                .init(key: .surfaceArea, title: "面积：", unit: "㎡"),
                .init(key: .volume, title: "体积：", unit: "m³")
            ]
        case .cone:
            return [
                .init(key: .slantHeight, title: "斜面高：", unit: "m"),
                .init(key: .lateralSurfaceArea, title: "曲面表面积：", unit: "㎡"),
                .init(key: .surfaceArea, title: "圆锥表面积：", unit: "㎡"),
                .init(key: .volume, title: "圆锥体积：", unit: "m³")
            ]
        case .triangleArea:
            return [
                .init(key: .area, title: "三角形面积：", unit: "㎡")
            ]
        case .rectangle:
            return [
                .init(key: .area, title: "面积：", unit: "㎡"),
                .init(key: .perimeter, title: "周长：", unit: "m")
            ]
        case .circle:
            return [
                .init(key: .area, title: "面积：", unit: "㎡"),
                .init(key: .perimeter, title: "周长：", unit: "m")
            ]
        case .trapezoid:
            return [
                .init(key: .area, title: "面积：", unit: "㎡")
            ]
        }
    }
}

enum CalculatorComputationError: LocalizedError, Equatable {
    case missingValue(CalculatorFieldKey)
    case nonPositiveValue(CalculatorFieldKey)

    var errorDescription: String? {
        switch self {
        case let .missingValue(key), let .nonPositiveValue(key):
            return "请输入有效的\(key.plainTitle)"
        }
    }
}
