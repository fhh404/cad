//
//  WatermarkCameraScreen.swift
//  CADFP
//
//  Created by Codex on 2026/4/10.
//

import SwiftUI

struct WatermarkCameraScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel = WatermarkCameraViewModel()
    @GestureState private var overlayDragTranslation: CGSize = .zero

    var body: some View {
        GeometryReader { proxy in
            let safeTop = max(proxy.safeAreaInsets.top, 16)
            let safeBottom = max(proxy.safeAreaInsets.bottom, 12)

            ZStack {
                VStack(spacing: 0) {
                    previewArea
                        .overlay(alignment: .topLeading) {
                            closeButton
                                .padding(.top, safeTop + 12)
                                .padding(.leading, 20)
                        }

                    WatermarkControlBar(
                        showsEditControl: viewModel.selectedStyle == .classic,
                        isCapturing: viewModel.isCapturing,
                        onEdit: viewModel.beginEditing,
                        onCapture: { Task { await viewModel.capture() } },
                        onSelectStyle: viewModel.beginStyleSelection
                    )
                    .padding(.bottom, safeBottom)
                    .background(Color(red: 17 / 255, green: 14 / 255, blue: 25 / 255))
                }
                .ignoresSafeArea()

                if viewModel.isEditingText {
                    dimmedOverlay {
                        WatermarkEditorDialog(
                            draft: $viewModel.editorDraft,
                            onCancel: viewModel.cancelEditing,
                            onConfirm: viewModel.confirmEditing
                        )
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await viewModel.handleAppear()
        }
        .onDisappear {
            viewModel.handleDisappear()
        }
        .onChange(of: scenePhase) { newPhase in
            guard newPhase == .active else { return }
            Task {
                await viewModel.handleSceneActive()
            }
        }
        .sheet(isPresented: $viewModel.isShowingStylePicker) {
            WatermarkStyleSheet(
                selectedStyle: viewModel.selectedStyle,
                draft: viewModel.draft,
                onSelect: viewModel.selectStyle
            )
            .presentationDetents([.height(216)])
            .presentationDragIndicator(.hidden)
            .presentationBackground(.ultraThinMaterial)
        }
        .alert(item: $viewModel.alert) { alert in
            if alert.opensSettings {
                return Alert(
                    title: Text(alert.title),
                    message: Text(alert.message),
                    primaryButton: .default(Text("打开设置"), action: viewModel.openSettings),
                    secondaryButton: .cancel(Text("取消"))
                )
            }

            return Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("知道了"))
            )
        }
    }

    private var previewArea: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                previewBackground

                let interactiveOffsetRatio = viewModel.interactiveOverlayOffsetRatio(
                    for: overlayDragTranslation,
                    in: proxy.size
                )
                let overlayFrame = viewModel.selectedStyle.previewFrame(
                    in: proxy.size,
                    content: viewModel.overlayContent,
                    offsetRatio: interactiveOffsetRatio
                )
                WatermarkTemplateCard(
                    style: viewModel.selectedStyle,
                    content: viewModel.overlayContent,
                    cardSize: overlayFrame.size,
                    context: .preview
                )
                .frame(width: overlayFrame.width, height: overlayFrame.height)
                .position(
                    x: overlayFrame.midX,
                    y: overlayFrame.midY
                )
                .gesture(
                    DragGesture()
                        .updating($overlayDragTranslation) { value, state, _ in
                            state = value.translation
                        }
                        .onEnded { value in
                            viewModel.commitOverlayTranslation(value.translation, in: proxy.size)
                        }
                )
                .animation(.spring(response: 0.28, dampingFraction: 0.86), value: viewModel.selectedStyle)
                .animation(.easeInOut(duration: 0.2), value: viewModel.overlayContent)
                .animation(.spring(response: 0.28, dampingFraction: 0.86), value: viewModel.overlayOffsetRatio)

                if let notice = viewModel.cameraNotice {
                    CameraStatusNotice(message: notice)
                        .padding(.horizontal, 20)
                        .padding(.top, 72)
                }
            }
        }
    }

    @ViewBuilder
    private var previewBackground: some View {
        switch viewModel.captureService.authorizationState {
        case .authorized where viewModel.captureService.isSessionConfigured:
            CameraPreviewView(session: viewModel.captureService.session)
                .ignoresSafeArea()
        default:
            LinearGradient(
                colors: [
                    Color(red: 84 / 255, green: 84 / 255, blue: 86 / 255),
                    Color(red: 66 / 255, green: 66 / 255, blue: 66 / 255),
                    Color(red: 48 / 255, green: 48 / 255, blue: 51 / 255)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
    }

    private func dimmedOverlay<Content: View>(
        alignment: Alignment = .center,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            Color.black.opacity(0.34)
                .ignoresSafeArea()
                .onTapGesture {
                    viewModel.dismissOverlays()
                }

            content()
                .padding(.horizontal, 20)
                .padding(.bottom, 18)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.98)))
    }
}

struct WatermarkTemplateCard: View {
    let style: WatermarkTemplateStyle
    let content: WatermarkOverlayContent
    let cardSize: CGSize
    let context: WatermarkCardContext

    var body: some View {
        switch style {
        case .classic:
            ClassicWatermarkCard(content: content, context: context)
        case .punchCard:
            PunchCardWatermarkCard(content: content, context: context)
        }
    }
}

private struct ClassicWatermarkCard: View {
    let content: WatermarkOverlayContent
    let context: WatermarkCardContext

    var body: some View {
        GeometryReader { proxy in
            let metrics = WatermarkTemplateStyle.classic.classicLayoutMetrics(
                for: content,
                width: proxy.size.width,
                minimumHeight: proxy.size.height,
                context: context
            )
            let shadowRadius = context == .preview ? 8.0 : 0.0
            let shadowYOffset = context == .preview ? 6.0 : 0.0

            VStack(spacing: 0) {
                ZStack(alignment: .top) {
                    Color(red: 47 / 255, green: 116 / 255, blue: 255 / 255)

                    Text(content.title ?? "")
                        .font(.system(size: metrics.titleFont.pointSize, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(metrics.lineLimit)
                        .fixedSize(horizontal: false, vertical: metrics.lineLimit == nil)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, metrics.horizontalPadding)
                        .padding(.top, metrics.titleTopInset)
                        .padding(.bottom, metrics.titleBottomInset)
                }
                .frame(height: metrics.topBandHeight)

                ZStack(alignment: .topLeading) {
                    Color.white

                    VStack(alignment: .leading, spacing: metrics.bodyLineSpacing) {
                        ForEach(Array(content.primaryLines.enumerated()), id: \.offset) { index, line in
                            Text(line)
                                .font(.system(size: metrics.bodyFont.pointSize, weight: index == 0 ? .semibold : .medium))
                                .foregroundStyle(.black)
                                .lineLimit(metrics.lineLimit)
                                .fixedSize(horizontal: false, vertical: metrics.lineLimit == nil)
                        }
                    }
                    .padding(.horizontal, metrics.horizontalPadding)
                    .padding(.top, metrics.bodyTopInset)
                    .padding(.bottom, metrics.bodyBottomInset)
                }
                .frame(height: metrics.middleHeight)

                ZStack(alignment: .bottomLeading) {
                    Color(red: 47 / 255, green: 116 / 255, blue: 255 / 255)

                    Text(content.footerLine ?? "")
                        .font(.system(size: metrics.footerFont.pointSize, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(metrics.lineLimit)
                        .fixedSize(horizontal: false, vertical: metrics.lineLimit == nil)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, metrics.horizontalPadding)
                        .padding(.top, metrics.footerTopInset)
                        .padding(.bottom, metrics.footerBottomInset)
                }
                .frame(height: metrics.bottomBandHeight)
            }
            .clipShape(RoundedRectangle(cornerRadius: metrics.cornerRadius, style: .continuous))
            .shadow(
                color: context == .preview ? .black.opacity(0.14) : .clear,
                radius: shadowRadius,
                x: 0,
                y: shadowYOffset
            )
        }
    }
}

private struct PunchCardWatermarkCard: View {
    let content: WatermarkOverlayContent
    let context: WatermarkCardContext

    private var textColor: Color {
        switch context {
        case .preview, .export:
            return .white
        case .thumbnail:
            return .black
        }
    }

    var body: some View {
        GeometryReader { proxy in
            let metrics = WatermarkTemplateStyle.punchCard.punchLayoutMetrics(
                for: content,
                width: proxy.size.width,
                minimumHeight: proxy.size.height,
                context: context
            )

            VStack(alignment: .leading, spacing: metrics.bodySpacing) {
                HStack(spacing: 0) {
                    ZStack {
                        RoundedRectangle(cornerRadius: metrics.badgeHeight * 0.16, style: .continuous)
                            .fill(.white)
                            .frame(width: metrics.badgeWidth, height: metrics.badgeHeight)

                        RoundedRectangle(cornerRadius: metrics.badgeHeight * 0.14, style: .continuous)
                            .fill(Color(red: 236 / 255, green: 201 / 255, blue: 82 / 255))
                            .frame(width: metrics.badgeLabelWidth, height: metrics.badgeHeight * 0.82)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, metrics.badgeInnerPadding * 0.45)

                        HStack(spacing: 0) {
                            Text(content.badgeText ?? "打卡")
                                .font(.system(size: metrics.badgeFont.pointSize, weight: .bold))
                                .foregroundStyle(.black)
                                .frame(width: metrics.badgeLabelWidth, alignment: .center)
                                .offset(x:2)

                            Text(content.timeText ?? "")
                                .font(.system(size: metrics.timeFont.pointSize, weight: .bold, design: .rounded))
                                .foregroundStyle(.black)
                                .lineLimit(1)
                                .minimumScaleFactor(0.88)
                                .allowsTightening(true)
                                .frame(width: metrics.badgeWidth - metrics.badgeLabelWidth, alignment: .center)
                        }
                        .frame(width: metrics.badgeWidth, height: metrics.badgeHeight)
                    }
                    .frame(width: metrics.badgeWidth, height: metrics.badgeHeight, alignment: .leading)
                }

                VStack(alignment: .leading, spacing: metrics.bodyLineSpacing) {
                    ForEach(Array(content.primaryLines.enumerated()), id: \.offset) { index, line in
                        Text(line)
                            .font(.system(size: metrics.bodyFont.pointSize, weight: index == 0 ? .semibold : .medium))
                            .foregroundStyle(textColor)
                            .lineLimit(metrics.lineLimit)
                            .fixedSize(horizontal: false, vertical: metrics.lineLimit == nil)
                    }
                }
                .frame(width: metrics.bodyWidth, alignment: .leading)
            }
            .padding(.top, metrics.topPadding)
            .padding(.leading, metrics.leadingPadding)
            .padding(.bottom, metrics.bottomPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

private struct WatermarkControlBar: View {
    let showsEditControl: Bool
    let isCapturing: Bool
    let onEdit: () -> Void
    let onCapture: () -> Void
    let onSelectStyle: () -> Void

    var body: some View {
        ZStack {
            captureButton

            HStack {
                if showsEditControl {
                    toolButton(
                        systemImage: "character.textbox",
                        title: "编辑文字",
                        action: onEdit
                    )
                } else {
                    Color.clear
                        .frame(width: 72, height: 48)
                }

                Spacer()

                toolButton(
                    systemImage: "rectangle.stack.badge.person.crop",
                    title: "水印样式",
                    action: onSelectStyle
                )

            }
            .padding(.horizontal, 28)
        }
        .padding(.top, 14)
        .padding(.bottom, 6)
        .frame(maxWidth: .infinity)
    }

    private var captureButton: some View {
        Button(action: onCapture) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.35), lineWidth: 5)
                    .frame(width: 68, height: 68)

                Circle()
                    .fill(.white)
                    .frame(width: 50, height: 50)

                if isCapturing {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.black)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isCapturing)
    }

    private func toolButton(systemImage: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)

                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 72)
        }
        .buttonStyle(.plain)
    }
}

private struct WatermarkEditorDialog: View {
    @Binding var draft: WatermarkDraft
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("编辑文字")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.black)
                .padding(.top, 18)
                .padding(.horizontal, 24)

            VStack(spacing: 18) {
                WatermarkInputRow(title: "标题", text: $draft.title, placeholder: "工程记录")
                WatermarkInputRow(title: "施工区域", text: $draft.area, placeholder: "外立面")
                WatermarkInputRow(title: "施工内容", text: $draft.content, placeholder: "变电施工")
                WatermarkInputRow(title: "施工单位", text: $draft.company, placeholder: "中铁集团")
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)

            HStack(spacing: 12) {
                dialogButton(title: "取消", foreground: Color(red: 102 / 255, green: 102 / 255, blue: 102 / 255), background: Color(red: 245 / 255, green: 245 / 255, blue: 245 / 255), action: onCancel)
                dialogButton(title: "确定", foreground: .white, background: Color(red: 47 / 255, green: 116 / 255, blue: 255 / 255), action: onConfirm)
            }
            .padding(.horizontal, 22)
            .padding(.top, 28)
            .padding(.bottom, 18)
        }
        .frame(maxWidth: 312)
        .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func dialogButton(title: String, foreground: Color, background: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(foreground)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(background, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct WatermarkInputRow: View {
    let title: String
    @Binding var text: String
    let placeholder: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.black)
                .padding(.top, 6)

            Spacer(minLength: 8)

            TextField(
                "",
                text: $text,
                prompt: Text(placeholder)
                    .foregroundColor(Color(red: 170 / 255, green: 170 / 255, blue: 170 / 255)),
                axis: .vertical
            )
                .font(.system(size: 14, weight: .medium))
                .multilineTextAlignment(.trailing)
                .foregroundStyle(.black)
                .textInputAutocapitalization(.never)
                .lineLimit(1 ... 4)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 190, alignment: .trailing)
        }
        .padding(.vertical, 2)
    }
}

private struct WatermarkStyleSheet: View {
    let selectedStyle: WatermarkTemplateStyle
    let draft: WatermarkDraft
    let onSelect: (WatermarkTemplateStyle) -> Void

    var body: some View {
        VStack(spacing: 18) {
            Text("水印样式")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.black)
                .padding(.top, 8)

            HStack(spacing: 14) {
                ForEach(WatermarkTemplateStyle.allCases) { style in
                    WatermarkStyleOptionCard(
                        style: style,
                        draft: draft,
                        isSelected: style == selectedStyle,
                        onTap: { onSelect(style) }
                    )
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 10)
        .padding(.bottom, 18)
    }
}

private struct WatermarkStyleOptionCard: View {
    let style: WatermarkTemplateStyle
    let draft: WatermarkDraft
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(red: 178 / 255, green: 182 / 255, blue: 190 / 255))

                WatermarkTemplateCard(
                    style: style,
                    content: style.makeOverlayContent(from: draft),
                    cardSize: style.previewSelectionSize,
                    context: .thumbnail
                )
                .frame(width: style.previewSelectionSize.width, height: style.previewSelectionSize.height)
            }
            .frame(width: 172, height: 90)
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(
                        isSelected ? Color(red: 35 / 255, green: 99 / 255, blue: 254 / 255) : .clear,
                        lineWidth: 2
                    )
            }
        }
        .buttonStyle(.plain)
    }
}

private struct CameraStatusNotice: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.black.opacity(0.28), in: Capsule())
    }
}
