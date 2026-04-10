//
//  CalculatorCatalogScreen.swift
//  CADFP
//
//  Created by Codex on 2026/4/10.
//

import SwiftUI

struct CalculatorCatalogScreen: View {
    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.flexible(), spacing: CalculatorTheme.gridSpacing),
        GridItem(.flexible(), spacing: CalculatorTheme.gridSpacing)
    ]

    var body: some View {
        ZStack {
            CalculatorTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                calculatorHeader(title: "计算器", onBack: { dismiss() })

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(CalculatorKind.allCases) { kind in
                            NavigationLink(value: HomeRoute.calculatorDetail(kind)) {
                                CalculatorCatalogCard(kind: kind)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 28)
                    .padding(.horizontal, CalculatorTheme.screenHorizontalPadding)
                    .padding(.bottom, 32)
                }
                .scrollIndicators(.hidden)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
    }
}

private struct CalculatorCatalogCard: View {
    let kind: CalculatorKind

    var body: some View {
        VStack(spacing: 20) {
            Image(kind.iconAssetName)
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)

            Text(kind.title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(CalculatorTheme.body)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 144)
        .background(CalculatorTheme.cardBackground, in: RoundedRectangle(cornerRadius: CalculatorTheme.cardCornerRadius, style: .continuous))
    }
}

@ViewBuilder
func calculatorHeader(title: String, onBack: @escaping () -> Void) -> some View {
    ZStack {
        Text(title)
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(CalculatorTheme.title)

        HStack {
            Button(action: onBack) {
                Image("Group 189")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .frame(width: 28, height: 28, alignment: .leading)
            }
            .buttonStyle(.plain)

            Spacer()
        }
    }
    .padding(.top, 16)
    .padding(.bottom, 24)
    .padding(.horizontal, CalculatorTheme.screenHorizontalPadding)
}

#Preview {
    NavigationStack {
        CalculatorCatalogScreen()
    }
}
