//
//  CalculatorDetailScreen.swift
//  CADFP
//
//  Created by Codex on 2026/4/10.
//

import SwiftUI

struct CalculatorDetailScreen: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: CalculatorFieldKey?

    let kind: CalculatorKind

    @State private var inputTexts: [CalculatorFieldKey: String]
    @State private var resultValues: [CalculatorFieldKey: Double] = [:]
    @State private var alertMessage: String?

    init(kind: CalculatorKind) {
        self.kind = kind
        _inputTexts = State(initialValue: Dictionary(uniqueKeysWithValues: kind.inputFields.map { ($0.key, "") }))
    }

    var body: some View {
        ZStack {
            CalculatorTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                calculatorHeader(title: kind.title, onBack: { dismiss() })

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                    detailCard

                    Text("计算结果")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(CalculatorTheme.body)
                        .padding(.top, CalculatorTheme.resultSectionTopSpacing)
                        .padding(.leading, 6)

                    resultCard
                        .padding(.top, 18)
                    }
                    .padding(.horizontal, CalculatorTheme.screenHorizontalPadding)
                    .padding(.bottom, 32)
                }
                .scrollIndicators(.hidden)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .alert(
            "提示",
            isPresented: Binding(
                get: { alertMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        alertMessage = nil
                    }
                }
            ),
            actions: {
                Button("知道了") {
                    alertMessage = nil
                }
            },
            message: {
                Text(alertMessage ?? "")
            }
        )
    }

    private var detailCard: some View {
        VStack(spacing: 0) {
            Image(kind.iconAssetName)
                .resizable()
                .scaledToFit()
                .frame(width: CalculatorTheme.iconSize, height: CalculatorTheme.iconSize)
                .padding(.top, CalculatorTheme.topCardTopPadding)

            VStack(spacing: CalculatorTheme.inputRowSpacing) {
                ForEach(kind.inputFields) { field in
                    inputRow(for: field)
                }
            }
            .padding(.top, CalculatorTheme.iconToInputsSpacing)

            Button(action: calculate) {
                Text("开始计算")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: CalculatorTheme.buttonHeight)
                    .background(CalculatorTheme.primary, in: RoundedRectangle(cornerRadius: CalculatorTheme.buttonCornerRadius, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, CalculatorTheme.cardInnerHorizontalPadding)
            .padding(.top, CalculatorTheme.inputsToButtonSpacing)
            .padding(.bottom, CalculatorTheme.topCardBottomPadding)
        }
        .frame(maxWidth: .infinity)
        .frame(height: CalculatorTheme.contentCardHeight(inputCount: kind.inputFields.count))
        .background(CalculatorTheme.cardBackground, in: RoundedRectangle(cornerRadius: CalculatorTheme.cardCornerRadius, style: .continuous))
    }

    private var resultCard: some View {
        VStack(spacing: CalculatorTheme.resultRowSpacing) {
            ForEach(kind.resultFields) { field in
                HStack(spacing: 8) {
                    Text(field.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(CalculatorTheme.body)

                    Spacer(minLength: 12)

                    Text(displayValue(for: field.key))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(CalculatorTheme.body)

                    Text(field.unit)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(CalculatorTheme.body)
                }
                .frame(height: 22)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, CalculatorTheme.resultCardVerticalPadding)
        .frame(maxWidth: .infinity)
        .frame(height: CalculatorTheme.resultCardHeight(resultCount: kind.resultFields.count))
        .background(CalculatorTheme.cardBackground, in: RoundedRectangle(cornerRadius: CalculatorTheme.cardCornerRadius, style: .continuous))
    }

    private func inputRow(for field: CalculatorInputFieldDefinition) -> some View {
        HStack(spacing: 10) {
            Text(field.title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(CalculatorTheme.body)
                .frame(width: 48, alignment: .leading)

            TextField(
                "",
                text: Binding(
                    get: { inputTexts[field.key, default: ""] },
                    set: { inputTexts[field.key] = $0 }
                ),
                prompt: Text(field.placeholder).foregroundColor(CalculatorTheme.placeholder)
            )
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(CalculatorTheme.body)
            .padding(.horizontal, 14)
            .frame(height: CalculatorTheme.inputHeight)
            .background(CalculatorTheme.cardBackground, in: RoundedRectangle(cornerRadius: CalculatorTheme.inputCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: CalculatorTheme.inputCornerRadius, style: .continuous)
                    .stroke(CalculatorTheme.inputBorder, lineWidth: 1)
            )
            .keyboardType(.decimalPad)
            .focused($focusedField, equals: field.key)

            Text(field.unit)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(CalculatorTheme.body)
                .frame(width: 15, alignment: .center)
        }
        .padding(.horizontal, CalculatorTheme.cardInnerHorizontalPadding)
    }

    private func displayValue(for key: CalculatorFieldKey) -> String {
        guard let value = resultValues[key] else {
            return "--"
        }
        return CalculatorFormatting.string(from: value)
    }

    private func calculate() {
        focusedField = nil

        do {
            var numericInputs: [CalculatorFieldKey: Double] = [:]
            for field in kind.inputFields {
                guard let value = CalculatorFormatting.parse(inputTexts[field.key, default: ""]) else {
                    throw CalculatorComputationError.missingValue(field.key)
                }
                numericInputs[field.key] = value
            }

            resultValues = try CalculatorEngine.compute(kind: kind, inputs: numericInputs)
        } catch let error as CalculatorComputationError {
            alertMessage = error.errorDescription
        } catch {
            alertMessage = "计算失败，请稍后重试。"
        }
    }
}

#Preview {
    NavigationStack {
        CalculatorDetailScreen(kind: .cone)
    }
}
