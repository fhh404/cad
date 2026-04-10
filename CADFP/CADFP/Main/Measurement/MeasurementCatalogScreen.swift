//
//  MeasurementCatalogScreen.swift
//  CADFP
//
//  Created by Codex on 2026/4/10.
//

import SwiftUI

struct MeasurementCatalogScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var pendingTool: MeasurementToolKind?

    private let columns = [
        GridItem(.flexible(), spacing: 13),
        GridItem(.flexible(), spacing: 13)
    ]

    var body: some View {
        ZStack {
            Color(red: 243 / 255, green: 246 / 255, blue: 250 / 255)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                measurementHeader(title: "测量工具", onBack: { dismiss() })

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(MeasurementToolKind.allCases) { tool in
                            card(for: tool)
                        }
                    }
                    .padding(.top, 28)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
                .scrollIndicators(.hidden)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .task {
            await ProtractorCaptureServiceProvider.prewarmIfAuthorized()
        }
        .alert(item: $pendingTool) { tool in
            Alert(
                title: Text(tool.title),
                message: Text("功能开发中，后续会补上真实测量能力。"),
                dismissButton: .default(Text("知道了"))
            )
        }
    }

    @ViewBuilder
    private func card(for tool: MeasurementToolKind) -> some View {
        switch tool {
        case .ruler:
            NavigationLink(value: HomeRoute.measurementRuler) {
                MeasurementCatalogCard(tool: tool)
            }
            .buttonStyle(.plain)
        case .protractor:
            NavigationLink(value: HomeRoute.measurementProtractor) {
                MeasurementCatalogCard(tool: tool)
            }
            .buttonStyle(.plain)
        default:
            Button {
                pendingTool = tool
            } label: {
                MeasurementCatalogCard(tool: tool)
            }
            .buttonStyle(.plain)
        }
    }
}

private struct MeasurementCatalogCard: View {
    let tool: MeasurementToolKind

    var body: some View {
        VStack(spacing: 20) {
            Image(tool.iconAssetName)
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)

            Text(tool.title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.black)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 144)
        .background(.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

@ViewBuilder
private func measurementHeader(title: String, onBack: @escaping () -> Void) -> some View {
    ZStack {
        Text(title)
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(Color(red: 22 / 255, green: 22 / 255, blue: 22 / 255))

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
    .padding(.horizontal, 16)
}

#Preview {
    NavigationStack {
        MeasurementCatalogScreen()
    }
}
