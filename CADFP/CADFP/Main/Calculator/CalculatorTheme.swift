//
//  CalculatorTheme.swift
//  CADFP
//
//  Created by Codex on 2026/4/10.
//

import SwiftUI

enum CalculatorTheme {
    static let background = Color(red: 243 / 255, green: 246 / 255, blue: 250 / 255)
    static let cardBackground = Color.white
    static let inputBorder = Color(red: 235 / 255, green: 235 / 255, blue: 235 / 255)
    static let primary = Color(red: 35 / 255, green: 99 / 255, blue: 254 / 255)
    static let title = Color(red: 22 / 255, green: 22 / 255, blue: 22 / 255)
    static let body = Color.black
    static let placeholder = Color(red: 184 / 255, green: 184 / 255, blue: 184 / 255)

    static let screenHorizontalPadding: CGFloat = 16
    static let gridSpacing: CGFloat = 13
    static let cardCornerRadius: CGFloat = 20
    static let inputCornerRadius: CGFloat = 8
    static let buttonCornerRadius: CGFloat = 10
    static let cardInnerHorizontalPadding: CGFloat = 20.5
    static let topCardTopPadding: CGFloat = 36
    static let iconSize: CGFloat = 88
    static let iconToInputsSpacing: CGFloat = 36
    static let inputRowSpacing: CGFloat = 16
    static let inputsToButtonSpacing: CGFloat = 28
    static let buttonHeight: CGFloat = 46
    static let topCardBottomPadding: CGFloat = 28
    static let resultSectionTopSpacing: CGFloat = 28
    static let resultCardVerticalPadding: CGFloat = 28
    static let resultRowSpacing: CGFloat = 38
    static let inputHeight: CGFloat = 44

    static func contentCardHeight(inputCount: Int) -> CGFloat {
        246 + CGFloat(inputCount) * 60
    }

    static func resultCardHeight(resultCount: Int) -> CGFloat {
        78 + CGFloat(max(resultCount - 1, 0)) * 60
    }
}
