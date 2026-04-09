//
//  HomeView.swift
//  CADFP
//
//  Created by huaheng feng on 4/9/26.
//

import SwiftUI

enum HomeAction: String, Identifiable {
    case importDrawings
    case scanDrawings
    case watermarkCamera
    case calculator
    case measurementTools
    case dwgToPdf
    case modelToStp
    case pdfToDwg
    case pdfToWord
    case pdfToImage
    case dwgToImage
    case dwgToDxf
    case openRecentFile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .importDrawings:
            return "导入图纸"
        case .scanDrawings:
            return "扫描图纸"
        case .watermarkCamera:
            return "水印相机"
        case .calculator:
            return "计算器"
        case .measurementTools:
            return "测量工具"
        case .dwgToPdf:
            return "DWG转PDF"
        case .modelToStp:
            return "3D转STP"
        case .pdfToDwg:
            return "PDF转DWG"
        case .pdfToWord:
            return "PDF转Word"
        case .pdfToImage:
            return "PDF转图片"
        case .dwgToImage:
            return "DWG转图片"
        case .dwgToDxf:
            return "DWG转DXF"
        case .openRecentFile:
            return "最近文件"
        }
    }

    var implementationHint: String {
        switch self {
        case .importDrawings:
            return "建议优先接 fileImporter，先打通本地文件导入；微信导入放到第二阶段做分享扩展更稳。"
        case .scanDrawings:
            return "这类能力更适合做独立扫描页，先验证拍摄、识别和生成文件链路。"
        case .watermarkCamera:
            return "可以独立成相机流程，先做拍照、水印模板和导出。"
        case .calculator, .measurementTools:
            return "工具型入口适合走枚举路由，各自进入独立页面，首页只负责分发。"
        case .dwgToPdf, .modelToStp, .pdfToDwg, .pdfToWord, .pdfToImage, .dwgToImage, .dwgToDxf:
            return "文件转换建议统一走同一套任务页和转换引擎，首页只传入转换类型。"
        case .openRecentFile:
            return "最近文件可以先接本地缓存和最近访问记录，后续再接项目同步。"
        }
    }
}

private struct HomeToolShortcut: Identifiable {
    let title: String
    let iconAsset: String
    let action: HomeAction

    var id: HomeAction { action }
}

private struct RecommendItem: Identifiable {
    let title: String
    let action: HomeAction
    let badgeColor: Color
    let symbol: String
    let useTextBadge: Bool

    var id: HomeAction { action }
}

struct HomeView: View {
    let onAction: (HomeAction) -> Void

    private let tools: [HomeToolShortcut] = [
        .init(title: "水印相机", iconAsset: "Group 324", action: .watermarkCamera),
        .init(title: "计算器", iconAsset: "Group 326", action: .calculator),
        .init(title: "测量工具", iconAsset: "Group 328", action: .measurementTools)
    ]

    private let recommendRows: [[RecommendItem]] = [
        [
            .init(title: "DWG转PDF", action: .dwgToPdf, badgeColor: Color(red: 73 / 255, green: 206 / 255, blue: 224 / 255), symbol: "scissors", useTextBadge: false),
            .init(title: "3D转STP", action: .modelToStp, badgeColor: Color(red: 247 / 255, green: 169 / 255, blue: 56 / 255), symbol: "cube.fill", useTextBadge: false),
            .init(title: "PDF转DWG", action: .pdfToDwg, badgeColor: Color(red: 255 / 255, green: 108 / 255, blue: 133 / 255), symbol: "plus", useTextBadge: false),
            .init(title: "PDF转Word", action: .pdfToWord, badgeColor: Color(red: 64 / 255, green: 110 / 255, blue: 255 / 255), symbol: "W", useTextBadge: true)
        ],
        [
            .init(title: "PDF转图片", action: .pdfToImage, badgeColor: Color(red: 101 / 255, green: 91 / 255, blue: 250 / 255), symbol: "photo.fill", useTextBadge: false),
            .init(title: "DWG转图片", action: .dwgToImage, badgeColor: Color(red: 98 / 255, green: 89 / 255, blue: 247 / 255), symbol: "photo.fill", useTextBadge: false),
            .init(title: "DWG转DXF", action: .dwgToDxf, badgeColor: Color(red: 39 / 255, green: 204 / 255, blue: 122 / 255), symbol: "A", useTextBadge: true)
        ]
    ]

    init(onAction: @escaping (HomeAction) -> Void = { _ in }) {
        self.onAction = onAction
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            HomeBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("AR室内扫描建模")
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundColor(Color(red: 36 / 255, green: 58 / 255, blue: 96 / 255))
                        .padding(.top, 24)
                        .padding(.leading, 8)

                    PrimaryCardsSection(onAction: onAction)
                        .padding(.top, 32)

                    ToolShortcutRow(items: tools, onAction: onAction)
                        .padding(.top, 20)

                    RecommendSection(rows: recommendRows, onAction: onAction)
                        .padding(.top, 26)

                    RecentFilesSection(onAction: onAction)
                        .padding(.top, 22)
                }
                .padding(.horizontal, 18)
                .padding(.horizontal, 28)
                .padding(.bottom, 24)
            }
        }
        .background(Color(red: 236 / 255, green: 245 / 255, blue: 255 / 255))
    }
}

private struct HomeBackground: View {
    var body: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(
                colors: [
                    Color(red: 210 / 255, green: 232 / 255, blue: 255 / 255),
                    Color(red: 226 / 255, green: 240 / 255, blue: 255 / 255),
                    Color(red: 239 / 255, green: 247 / 255, blue: 255 / 255),
                    .white
                ],
                startPoint: .top,
                endPoint: .bottom
            )
                .ignoresSafeArea()

            Image("Intersect")
                .resizable()
                .scaledToFit()
                .frame(width: 462, height: 268)
                .offset(x: 92, y: -18)
                .opacity(1)
        }
        .ignoresSafeArea()
    }
}

private struct PrimaryCardsSection: View {
    let onAction: (HomeAction) -> Void

    var body: some View {
        HStack(spacing: 18) {
            PrimaryEntryCard(
                title: "导入图纸",
                subtitle: "支持微信、本地文件",
                colors: [
                    Color(red: 33 / 255, green: 101 / 255, blue: 255 / 255),
                    Color(red: 94 / 255, green: 157 / 255, blue: 255 / 255)
                ],
                subtitleColor: Color(red: 213 / 255, green: 228 / 255, blue: 255 / 255),
                action: { onAction(.importDrawings) }
            ) {
                ImportIllustration()
            }

            PrimaryEntryCard(
                title: "扫描图纸",
                subtitle: "生成可编辑文件",
                colors: [
                    Color(red: 4 / 255, green: 167 / 255, blue: 200 / 255),
                    Color(red: 77 / 255, green: 213 / 255, blue: 237 / 255)
                ],
                subtitleColor: Color(red: 212 / 255, green: 248 / 255, blue: 255 / 255),
                action: { onAction(.scanDrawings) }
            ) {
                ScanIllustration()
            }
        }
    }
}

private struct PrimaryEntryCard<Illustration: View>: View {
    let title: String
    let subtitle: String
    let colors: [Color]
    let subtitleColor: Color
    let action: () -> Void
    @ViewBuilder let illustration: Illustration

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(subtitleColor)
                }
                .padding(.top, 16)
                .padding(.leading, 18)

                illustration
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(.trailing, 7)
                    .padding(.bottom, 6)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
        }
        .buttonStyle(.plain)
    }
}

private struct ImportIllustration: View {
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.18))
                .frame(width: 54, height: 40)
                .offset(x: -18, y: -12)

            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(red: 199 / 255, green: 222 / 255, blue: 255 / 255).opacity(0.96))
                .frame(width: 66, height: 50)
                .offset(y: 2)

            Image("Vector5")
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 30)
                .offset(x: 0, y: -5)

            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(red: 125 / 255, green: 168 / 255, blue: 255 / 255))
                .frame(width: 26, height: 26)
                .overlay {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
                .offset(x: -10, y: -3)
        }
        .frame(width: 82, height: 64)
    }
}

private struct ScanIllustration: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.14))
                .frame(width: 62, height: 46)
                .offset(x: 4, y: -8)

            Image("Mask group")
                .resizable()
                .scaledToFit()
                .frame(width: 68, height: 58)

            Capsule()
                .fill(Color(red: 105 / 255, green: 233 / 255, blue: 255 / 255).opacity(0.95))
                .frame(width: 70, height: 8)
                .offset(y: 6)
        }
        .frame(width: 80, height: 62)
    }
}

private struct ToolShortcutRow: View {
    let items: [HomeToolShortcut]
    let onAction: (HomeAction) -> Void

    var body: some View {
        HStack(spacing: 14) {
            ForEach(items) { item in
                Button {
                    onAction(item.action)
                } label: {
                    HStack(spacing: 10) {
                        Image(item.iconAsset)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)

                        Text(item.title)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(red: 60 / 255, green: 76 / 255, blue: 117 / 255))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, minHeight: 64)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct RecommendSection: View {
    let rows: [[RecommendItem]]
    let onAction: (HomeAction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("热门推荐")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.black)

            VStack(spacing: 26) {
                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    HStack(alignment: .top, spacing: 14) {
                        ForEach(row) { item in
                            RecommendationButton(item: item, action: { onAction(item.action) })
                                .frame(maxWidth: .infinity)
                        }

                        if index == 1 {
                            Spacer(minLength: 0)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .frame(maxWidth: .infinity, minHeight: 224, alignment: .topLeading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct RecommendationButton: View {
    let item: RecommendItem
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ConversionBadgeIcon(
                    color: item.badgeColor,
                    symbol: item.symbol,
                    useTextBadge: item.useTextBadge
                )

                Text(item.title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(red: 60 / 255, green: 76 / 255, blue: 117 / 255))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct ConversionBadgeIcon: View {
    let color: Color
    let symbol: String
    let useTextBadge: Bool

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Image(systemName: "doc.text")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(Color(red: 72 / 255, green: 83 / 255, blue: 113 / 255))

            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(color)
                .frame(width: 16, height: 16)
                .overlay {
                    if useTextBadge {
                        Text(symbol)
                            .font(.system(size: 8, weight: .heavy))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: symbol)
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .offset(x: 4, y: 4)
        }
        .frame(width: 32, height: 32)
    }
}

private struct RecentFilesSection: View {
    let onAction: (HomeAction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("最近文件")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.black)

            Button {
                onAction(.openRecentFile)
            } label: {
                HStack(spacing: 14) {
                    DWGFileThumbnail()

                    VStack(alignment: .leading, spacing: 6) {
                        Text("DWG 示例 -1.dwg")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.black)

                        Text("2026-03-21 16:05")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(red: 153 / 255, green: 153 / 255, blue: 153 / 255))
                    }

                    Spacer()
                }
                .padding(.top, 2)
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .frame(maxWidth: .infinity, minHeight: 284, alignment: .topLeading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct DWGFileThumbnail: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 255 / 255, green: 206 / 255, blue: 215 / 255),
                            Color(red: 255 / 255, green: 119 / 255, blue: 140 / 255)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 52)

            VStack(spacing: 0) {
                Spacer()
                Rectangle()
                    .fill(Color(red: 255 / 255, green: 88 / 255, blue: 112 / 255))
                    .frame(height: 14)
                    .overlay {
                        Text("DWG")
                            .font(.system(size: 8, weight: .heavy))
                            .foregroundColor(.white)
                    }
            }
            .frame(width: 44, height: 52)

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 0))
                        path.addLine(to: CGPoint(x: 11, y: 0))
                        path.addLine(to: CGPoint(x: 11, y: 11))
                        path.closeSubpath()
                    }
                    .fill(Color.white.opacity(0.72))
                    .frame(width: 11, height: 11)
                }
                Spacer()
            }
            .frame(width: 44, height: 52)

            Image(systemName: "plus")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(red: 255 / 255, green: 118 / 255, blue: 145 / 255))
                .offset(y: -9)
        }
    }
}

#Preview {
    HomeView()
}
