import SwiftUI

struct CADViewerScreen: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: CADViewerViewModel
    @State private var textExtractionSelectionDragStartRect: CGRect?
    @State private var textExtractionSelectionResizeStartRect: CGRect?

    private let filePath: String

    init(title: String, filePath: String) {
        self.filePath = filePath
        _viewModel = StateObject(wrappedValue: CADViewerViewModel(title: title))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            CADViewerBridgeView(viewModel: viewModel, filePath: filePath)
                .ignoresSafeArea()

            if !viewModel.hotspotAnnotations.isEmpty {
                hotspotAnnotationsOverlay
                    .zIndex(0.5)
            }

            if viewModel.isMeasurementToolbarPresented {
                measurementOverlay
                    .zIndex(0.75)
            }

            if viewModel.isMarkupSubpanelPresented {
                markupSubpanelDismissOverlay
                    .zIndex(1)
            }

            if viewModel.isHotspotInputPresented {
                hotspotInputOverlay
                    .transition(.opacity)
                    .zIndex(1.5)
            }

            if viewModel.isLayerSheetPresented {
                layerPanelOverlay
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(2)
            }

            if viewModel.isTextExtractionOverlayPresented {
                textExtractionOverlay
                    .transition(.opacity)
                    .zIndex(2.5)
            }

            VStack(spacing: 0) {
                headerBar
                Spacer()
                bottomChrome
            }
            .zIndex(3)
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .alert(item: $viewModel.alertMessage) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("知道了"))
            )
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.isMarkupToolbarPresented)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isMeasurementToolbarPresented)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isMarkupTextInputPresented)
        .animation(.easeInOut(duration: 0.2), value: viewModel.activeMarkupStylePanel)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isHotspotInputPresented)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isLayerSheetPresented)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isTextExtractionOverlayPresented)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isSettingsPanelPresented)
    }

    private var headerBar: some View {
        VStack(spacing: 0) {
            Color.black
                .frame(height: 0)
                .safeAreaInset(edge: .top) {
                    ZStack {
                        HStack {
                            Button(action: { dismiss() }) {
                                Image("Group 189")
                                    .resizable()
                                    .renderingMode(.template)
                                    .scaledToFit()
                                    .foregroundStyle(.white)
                                    .frame(width: 20, height: 20)
                                    .frame(width: 28, height: 28, alignment: .leading)
                            }
                            .buttonStyle(.plain)

                            Spacer()
                        }

                        Text(viewModel.title)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                    .background(Color.black.opacity(0.92))
                }
        }
    }

    @ViewBuilder
    private var bottomChrome: some View {
        if viewModel.isTextExtractionOverlayPresented {
            EmptyView()
        } else if viewModel.isMeasurementToolbarPresented {
            measurementToolbar
        } else if viewModel.isMarkupToolbarPresented {
            markupBottomChrome
        } else if viewModel.isSettingsPanelPresented {
            settingsPanel
        } else {
            defaultBottomToolbar
        }
    }

    private var defaultBottomToolbar: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                ForEach(CADViewerToolbarItemKind.allCases) { item in
                    toolbarButton(item)
                }
            }
        }
        .scrollIndicators(.hidden)
        .frame(height: 66)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.cadToolbarBackground)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 31)
    }

    @ViewBuilder
    private var markupBottomChrome: some View {
        if let stylePanel = viewModel.activeMarkupStylePanel {
            markupStylePanel(stylePanel)
        } else if viewModel.isMarkupTextInputPresented {
            markupTextInputPanel
        } else {
            markupToolbar
        }
    }

    private var markupToolbar: some View {
        HStack(spacing: 0) {
            ForEach(CADMarkupToolbarItemKind.allCases) { item in
                markupToolbarButton(item)
            }
        }
        .frame(height: 66)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.cadToolbarBackground)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 31)
    }

    private var measurementToolbar: some View {
        HStack(spacing: 0) {
            ForEach(CADMeasurementToolbarItemKind.allCases) { item in
                measurementToolbarButton(item)
            }
        }
        .frame(height: 66)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.cadToolbarBackground)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 31)
    }

    private var settingsPanel: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Button {
                    viewModel.dismissSettingsPanel()
                } label: {
                    Image("返回 (2) 1")
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)

                Spacer()

                Text("设置")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                Color.clear
                    .frame(width: 44, height: 44)
            }
            .frame(height: 44)

            HStack(spacing: 0) {
                Text("旋转")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 84, alignment: .leading)

                Spacer()

                settingsRotationButton(systemName: "arrow.counterclockwise") {
                    viewModel.rotateSettingsViewCounterclockwise()
                }

                Text("\(viewModel.settingsRotationDegrees)°")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 64, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.cadFieldBackground)
                    )
                    .padding(.horizontal, 14)

                settingsRotationButton(systemName: "arrow.clockwise") {
                    viewModel.rotateSettingsViewClockwise()
                }
            }
            .frame(height: 56)
            .padding(.horizontal, 20)

            HStack(spacing: 0) {
                Text("背景")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 84, alignment: .leading)

                Spacer()

                HStack(spacing: 8) {
                    ForEach(CADViewerSettingsBackgroundOption.allCases) { option in
                        settingsBackgroundOptionButton(option)
                    }
                }
            }
            .frame(height: 65)
            .padding(.horizontal, 20)
        }
        .frame(height: 165)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.cadToolbarBackground)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 31)
    }

    private func settingsRotationButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 20, height: 28)
        }
        .buttonStyle(.plain)
    }

    private func settingsBackgroundOptionButton(_ option: CADViewerSettingsBackgroundOption) -> some View {
        let isSelected = viewModel.selectedSettingsBackground == option

        return Button {
            viewModel.selectSettingsBackground(option)
        } label: {
            ZStack {
                if isSelected {
                    Circle()
                        .stroke(.black, lineWidth: 2)
                        .frame(width: 34, height: 34)
                }

                Circle()
                    .fill(settingsBackgroundColor(option))
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .stroke(option == .black ? Color.white.opacity(0.35) : Color.clear, lineWidth: 1)
                    )
            }
            .frame(width: 34, height: 34)
        }
        .buttonStyle(.plain)
    }

    private var markupTextInputPanel: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.cadFieldBackground)

                if viewModel.markupTextDraft.isEmpty {
                    Text("输入文字")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(Color(red: 183 / 255, green: 183 / 255, blue: 183 / 255))
                        .padding(.leading, 12)
                        .padding(.top, 12)
                }

                TextEditor(text: $viewModel.markupTextDraft)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.white)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
            }
            .frame(height: 76)
            .padding(.top, 16)
            .padding(.horizontal, 16)

            HStack(spacing: 0) {
                Button {
                    viewModel.showMarkupTextStylePanel()
                } label: {
                    HStack(spacing: 8) {
                        Image("文字 (3) 1")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 14)

                        Text("文字样式")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    viewModel.confirmMarkupText()
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 15)
            .padding(.horizontal, 24)
        }
        .frame(height: 148)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.cadToolbarBackground)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 31)
    }

    private func markupStylePanel(_ stylePanel: CADViewerViewModel.MarkupStylePanel) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Button {
                    viewModel.dismissMarkupStylePanel()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)

                Spacer()

                Text(stylePanel == .text ? "文字样式" : "手绘样式")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                Color.clear
                    .frame(width: 44, height: 44)
            }
            .frame(height: 44)

            if stylePanel == .text {
                textSizeStyleRow
                    .frame(height: 56)
            } else {
                handDrawLineWidthStyleRow
                    .frame(height: 56)
            }

            markupColorStyleRow(stylePanel)
                .frame(height: 65)
        }
        .frame(height: 165)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.cadToolbarBackground)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 31)
    }

    private var textSizeStyleRow: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text("字号大小")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)

                Text("\(Int(viewModel.markupFontSize))号")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(Color(red: 153 / 255, green: 153 / 255, blue: 153 / 255))
            }
            .frame(width: 84, alignment: .leading)

            Slider(value: $viewModel.markupFontSize, in: 12...80, step: 1)
                .tint(Color.cadActiveBlue)
        }
        .padding(.horizontal, 20)
    }

    private var handDrawLineWidthStyleRow: some View {
        HStack(spacing: 0) {
            Text("线条粗细")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 84, alignment: .leading)

            HStack(spacing: 22) {
                ForEach(Array([2.0, 4.0, 6.0].enumerated()), id: \.offset) { index, width in
                    Button {
                        viewModel.selectHandDrawLineWeight(CADMarkupLineWeightOption(rawValue: index) ?? .thin)
                    } label: {
                        ZStack {
                            if viewModel.selectedLineWidthIndex == index {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(Color.cadFieldBackground)
                            }

                            Capsule()
                                .fill(markupColor(CADMarkupColorOption(rawValue: viewModel.selectedHandDrawColorIndex) ?? .cyan))
                                .frame(width: 36, height: width)
                        }
                        .frame(width: 64, height: 28)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private func markupColorStyleRow(_ stylePanel: CADViewerViewModel.MarkupStylePanel) -> some View {
        let selectedIndex = stylePanel == .text ? viewModel.selectedTextColorIndex : viewModel.selectedHandDrawColorIndex

        return HStack(spacing: 0) {
            Text(stylePanel == .text ? "文字颜色" : "线条颜色")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 84, alignment: .leading)

            HStack(spacing: 8) {
                ForEach(CADMarkupColorOption.allCases) { option in
                    Button {
                        viewModel.selectMarkupColor(option, for: stylePanel)
                    } label: {
                        ZStack {
                            if selectedIndex == option.rawValue {
                                Circle()
                                    .stroke(.white, lineWidth: 2)
                                    .frame(width: 34, height: 34)
                            }

                            Circle()
                                .fill(markupColor(option))
                                .frame(width: 24, height: 24)
                        }
                        .frame(width: 34, height: 34)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private var markupSubpanelDismissOverlay: some View {
        Color.clear
            .contentShape(Rectangle())
            .ignoresSafeArea()
            .onTapGesture {
                viewModel.dismissMarkupSubpanel()
            }
    }

    private func markupColor(_ option: CADMarkupColorOption) -> Color {
        let rgb = option.rgb
        return Color(
            red: Double(rgb.red) / 255,
            green: Double(rgb.green) / 255,
            blue: Double(rgb.blue) / 255
        )
    }

    private func settingsBackgroundColor(_ option: CADViewerSettingsBackgroundOption) -> Color {
        let rgb = option.rgb
        return Color(
            red: Double(rgb.red) / 255,
            green: Double(rgb.green) / 255,
            blue: Double(rgb.blue) / 255
        )
    }

    private var layerPanelOverlay: some View {
        VStack(spacing: 0) {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.isLayerSheetPresented = false
                }

            layerPanel
                .frame(height: 347)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }

    private var layerPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("选择图层")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)
                .padding(.top, 18)
                .padding(.leading, 16)

            if viewModel.layers.isEmpty {
                Text("暂无图层数据")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.72))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(viewModel.layers.enumerated()), id: \.element.index) { offset, layer in
                            layerRow(layer: layer, showsDisclosure: offset == 0)
                        }
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 16)
                }
                .scrollIndicators(.hidden)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.89))
        .clipShape(TopRoundedRectangle(radius: 24))
    }

    private var textSheet: some View {
        NavigationStack {
            Group {
                if viewModel.isExtractingTexts {
                    VStack(spacing: 18) {
                        ProgressView()
                        Text("正在提取图纸中的文字内容...")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.extractedTexts.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "text.badge.xmark")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary)
                        Text("当前图纸没有提取到可展示的文字。")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(Array(viewModel.extractedTexts.enumerated()), id: \.offset) { index, text in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("文字 \(index + 1)")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(red: 46 / 255, green: 112 / 255, blue: 255 / 255))
                            Text(text)
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(Color(red: 32 / 255, green: 39 / 255, blue: 51 / 255))
                        }
                        .padding(.vertical, 6)
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("文字提取")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var textExtractionOverlay: some View {
        GeometryReader { proxy in
            let canvasSize = proxy.size
            let selectionRect = CADTextExtractionSelectionGeometry.denormalized(
                viewModel.textExtractionSelectionRect,
                in: canvasSize
            )

            ZStack(alignment: .topLeading) {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()

                textExtractionSelectionBox(selectionRect, canvasSize: canvasSize)

                ForEach(CADTextExtractionSelectionHandle.allCases) { handle in
                    textExtractionResizeHandle(handle, selectionRect: selectionRect, canvasSize: canvasSize)
                        .position(textExtractionHandlePosition(handle, in: selectionRect))
                }

                textExtractionActionButtons(selectionRect: selectionRect, canvasSize: canvasSize)

                textExtractionResultPanel
                    .frame(width: max(canvasSize.width - 32, 0), height: 254)
                    .position(x: canvasSize.width / 2, y: canvasSize.height - 31 - 127)
            }
            .frame(width: canvasSize.width, height: canvasSize.height)
        }
        .ignoresSafeArea()
    }

    private func textExtractionSelectionBox(_ rect: CGRect, canvasSize: CGSize) -> some View {
        Rectangle()
            .fill(Color.cadTextExtractionSelectionFill)
            .overlay(
                Rectangle()
                    .stroke(Color.cadActiveBlue, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 4)
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if textExtractionSelectionDragStartRect == nil {
                            textExtractionSelectionDragStartRect = rect
                        }

                        let movedRect = CADTextExtractionSelectionGeometry.moved(
                            textExtractionSelectionDragStartRect ?? rect,
                            by: value.translation,
                            in: canvasSize
                        )
                        viewModel.updateTextExtractionSelection(movedRect, in: canvasSize)
                    }
                    .onEnded { _ in
                        textExtractionSelectionDragStartRect = nil
                    }
            )
    }

    private func textExtractionResizeHandle(
        _ handle: CADTextExtractionSelectionHandle,
        selectionRect: CGRect,
        canvasSize: CGSize
    ) -> some View {
        Circle()
            .fill(.white)
            .overlay(
                Circle()
                    .stroke(Color.cadActiveBlue, lineWidth: 2)
            )
            .frame(width: 8, height: 8)
            .frame(width: 32, height: 32)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if textExtractionSelectionResizeStartRect == nil {
                            textExtractionSelectionResizeStartRect = selectionRect
                        }

                        let resizedRect = CADTextExtractionSelectionGeometry.resized(
                            textExtractionSelectionResizeStartRect ?? selectionRect,
                            handle: handle,
                            by: value.translation,
                            in: canvasSize
                        )
                        viewModel.updateTextExtractionSelection(resizedRect, in: canvasSize)
                    }
                    .onEnded { _ in
                        textExtractionSelectionResizeStartRect = nil
                    }
            )
    }

    private func textExtractionHandlePosition(
        _ handle: CADTextExtractionSelectionHandle,
        in rect: CGRect
    ) -> CGPoint {
        switch handle {
        case .topLeading:
            return CGPoint(x: rect.minX, y: rect.minY)
        case .top:
            return CGPoint(x: rect.midX, y: rect.minY)
        case .topTrailing:
            return CGPoint(x: rect.maxX, y: rect.minY)
        case .leading:
            return CGPoint(x: rect.minX, y: rect.midY)
        case .trailing:
            return CGPoint(x: rect.maxX, y: rect.midY)
        case .bottomLeading:
            return CGPoint(x: rect.minX, y: rect.maxY)
        case .bottom:
            return CGPoint(x: rect.midX, y: rect.maxY)
        case .bottomTrailing:
            return CGPoint(x: rect.maxX, y: rect.maxY)
        }
    }

    private func textExtractionActionButtons(selectionRect: CGRect, canvasSize: CGSize) -> some View {
        let actionCenterX = min(max(selectionRect.maxX - 54, 54), max(canvasSize.width - 54, 54))
        let actionCenterY = min(max(selectionRect.maxY + 33, 44), max(canvasSize.height - 44, 44))

        return HStack(spacing: 8) {
            Button {
                viewModel.cancelTextExtraction()
            } label: {
                Text("取消")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(.black)
                    .frame(width: 50, height: 26)
                    .background(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Color.cadTextExtractionCancelBackground)
                    )
            }
            .buttonStyle(.plain)

            Button {
                viewModel.confirmTextExtraction(in: canvasSize)
            } label: {
                Text("确定")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 26)
                    .background(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Color.cadActiveBlue)
                    )
            }
            .buttonStyle(.plain)
        }
        .position(x: actionCenterX, y: actionCenterY)
    }

    private var textExtractionResultPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                Text("文字提取")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    viewModel.copyExtractedTexts()
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color.cadActiveBlue)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
            }
            .frame(height: 32)
            .padding(.top, 8)
            .padding(.horizontal, 18)

            textExtractionResultBox
                .frame(height: 194)
                .padding(.top, 4)
                .padding(.horizontal, 16)

            Spacer(minLength: 0)
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.cadToolbarBackground)
        )
    }

    @ViewBuilder
    private var textExtractionResultBox: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.cadFieldBackground)

            if viewModel.isExtractingTexts {
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(.white)

                    Text("正在提取图纸中的文字内容...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.cadTextExtractionSecondaryText)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.extractedTexts.isEmpty {
                Text(viewModel.hasTextExtractionAttempted ? "当前范围没有提取到文字" : "拖动蓝框选择文字范围后点击确定")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.cadTextExtractionSecondaryText)
                    .padding(.horizontal, 12)
                    .padding(.top, 12)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 9) {
                        ForEach(Array(viewModel.extractedTexts.enumerated()), id: \.offset) { _, text in
                            Text(text)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.cadTextExtractionSecondaryText)
                                .lineLimit(nil)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 11)
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    private func layerRow(layer: CADLayerItem, showsDisclosure: Bool) -> some View {
        Button {
            viewModel.toggleLayer(layer)
        } label: {
            HStack(spacing: 0) {
                if showsDisclosure {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 17, height: 10)
                        .padding(.leading, 20)
                        .padding(.trailing, 6)
                } else {
                    Color.clear
                        .frame(width: 64)
                }

                layerCheckbox(isSelected: !layer.isHidden)

                Text(layer.name.isEmpty ? "未命名图层" : layer.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .padding(.leading, showsDisclosure ? 11 : 6)

                Spacer(minLength: 16)
            }
            .frame(height: 34)
        }
        .buttonStyle(.plain)
    }

    private func layerCheckbox(isSelected: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(.white, lineWidth: 1)
                .frame(width: 18, height: 18)

            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
    }

    private func markupToolbarButton(_ item: CADMarkupToolbarItemKind) -> some View {
        let isActive = item != .back && viewModel.selectedMarkupToolbarItem == item

        return Button {
            viewModel.selectMarkupToolbarItem(item)
        } label: {
            VStack(spacing: item == .back ? 0 : 4) {
                Image(item.iconName(isActive: isActive))
                    .resizable()
                    .scaledToFit()
                    .frame(width: item == .back ? 24 : 22, height: item == .back ? 24 : 22)

                if !item.title.isEmpty {
                    Text(item.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(isActive ? Color.cadActiveBlue : .white)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: item == .back ? 64 : .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.plain)
    }

    private func measurementToolbarButton(_ item: CADMeasurementToolbarItemKind) -> some View {
        let isActive = item.mode == viewModel.selectedMeasurementMode

        return Button {
            if let mode = item.mode {
                viewModel.selectMeasurementMode(mode)
            } else {
                viewModel.dismissMeasurementPanel()
            }
        } label: {
            VStack(spacing: item == .back ? 0 : 4) {
                Image(item.iconName(isActive: isActive))
                    .resizable()
                    .scaledToFit()
                    .frame(width: item == .back ? 24 : 22, height: item == .back ? 24 : 22)

                if !item.title.isEmpty {
                    Text(item.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(isActive ? Color.cadActiveBlue : .white)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: item == .back ? 64 : .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.plain)
    }

    private var measurementOverlay: some View {
        GeometryReader { proxy in
            let samples = viewModel.measurementSamples

            ZStack(alignment: .topLeading) {
                measurementGeometryLayer(samples: samples, mode: viewModel.selectedMeasurementMode)

                if viewModel.selectedMeasurementMode == .coordinate, samples.last != nil {
                    coordinateMagnifier(in: proxy.size)
                }

                ForEach(samples) { sample in
                    measurementMarker(isCoordinate: viewModel.selectedMeasurementMode == .coordinate)
                        .position(sample.screenPoint)
                }

                measurementResultLayer(samples: samples, mode: viewModel.selectedMeasurementMode)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func measurementGeometryLayer(samples: [CADMeasurementSample], mode: CADMeasurementMode) -> some View {
        switch mode {
        case .length:
            if samples.count >= 2, let first = samples.first, let second = samples.dropFirst().first {
                Path { path in
                    path.move(to: first.screenPoint)
                    path.addLine(to: second.screenPoint)
                }
                .stroke(Color.cadMeasurementMagenta, lineWidth: 2)
            }
        case .area:
            if samples.count >= 2 {
                let areaPath = measurementPath(samples: samples, closePath: samples.count >= 3)
                if samples.count >= 3 {
                    areaPath
                        .fill(Color.cadMeasurementMagenta.opacity(0.3))
                }
                areaPath
                    .stroke(Color.cadMeasurementMagenta, lineWidth: 1.5)
            }
        case .coordinate:
            EmptyView()
        }
    }

    @ViewBuilder
    private func measurementResultLayer(samples: [CADMeasurementSample], mode: CADMeasurementMode) -> some View {
        switch mode {
        case .length:
            if let text = viewModel.measurementLengthText,
               let first = samples.first,
               let second = samples.dropFirst().first {
                let center = midpoint(first.screenPoint, second.screenPoint)
                Text(text)
                    .font(.system(size: 18, weight: .bold))
                    .italic()
                    .foregroundStyle(.white)
                    .position(x: center.x + 8, y: center.y + 28)
            }
        case .area:
            if let text = viewModel.measurementAreaText {
                let center = screenCentroid(samples)
                Text(text)
                    .font(.system(size: 18, weight: .bold))
                    .italic()
                    .foregroundStyle(.white)
                    .position(center)
            }
        case .coordinate:
            if let text = viewModel.measurementCoordinateText, let sample = samples.last {
                Text(text)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.cadMeasurementMagenta)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(2)
                    .fixedSize(horizontal: true, vertical: true)
                    .position(x: sample.screenPoint.x + 42, y: sample.screenPoint.y + 42)
            }
        }
    }

    private func measurementMarker(isCoordinate: Bool) -> some View {
        ZStack {
            if isCoordinate {
                Circle()
                    .stroke(Color.cadMeasurementMagenta, lineWidth: 2)
                    .frame(width: 24, height: 24)
            }

            measurementCross(size: 10, lineWidth: 2)
        }
        .frame(width: isCoordinate ? 24 : 10, height: isCoordinate ? 24 : 10)
    }

    private func measurementCross(size: CGFloat, lineWidth: CGFloat) -> some View {
        ZStack {
            Rectangle()
                .fill(Color.cadMeasurementMagenta)
                .frame(width: size, height: lineWidth)

            Rectangle()
                .fill(Color.cadMeasurementMagenta)
                .frame(width: lineWidth, height: size)
        }
        .frame(width: size, height: size)
    }

    private func coordinateMagnifier(in canvasSize: CGSize) -> some View {
        let xScale = canvasSize.width / 393
        let yScale = canvasSize.height / 852

        return ZStack {
            Rectangle()
                .stroke(Color.cadActiveBlue, lineWidth: 2)

            measurementMarker(isCoordinate: true)
                .scaleEffect(1.16)
        }
        .frame(width: 118 * xScale, height: 168 * yScale)
        .position(x: (26 + 59) * xScale, y: (100 + 84) * yScale)
    }

    private func measurementPath(samples: [CADMeasurementSample], closePath: Bool) -> Path {
        var path = Path()
        guard let first = samples.first else {
            return path
        }

        path.move(to: first.screenPoint)
        for sample in samples.dropFirst() {
            path.addLine(to: sample.screenPoint)
        }

        if closePath {
            path.closeSubpath()
        }

        return path
    }

    private func midpoint(_ first: CGPoint, _ second: CGPoint) -> CGPoint {
        CGPoint(x: (first.x + second.x) / 2, y: (first.y + second.y) / 2)
    }

    private func screenCentroid(_ samples: [CADMeasurementSample]) -> CGPoint {
        guard !samples.isEmpty else {
            return .zero
        }

        let count = CGFloat(samples.count)
        let sum = samples.reduce(CGPoint.zero) { partialResult, sample in
            CGPoint(
                x: partialResult.x + sample.screenPoint.x,
                y: partialResult.y + sample.screenPoint.y
            )
        }
        return CGPoint(x: sum.x / count, y: sum.y / count)
    }

    private var hotspotInputOverlay: some View {
        GeometryReader { proxy in
            let xScale = proxy.size.width / 393
            let yScale = proxy.size.height / 852

            ZStack(alignment: .topLeading) {
                Image("定位 (1) 1")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .offset(x: 140 * xScale, y: 350 * yScale)

                VStack(alignment: .leading, spacing: 12) {
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Color.white.opacity(0.8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .stroke(
                                        Color.cadActiveBlue,
                                        style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                                    )
                            )

                        if viewModel.hotspotTextDraft.isEmpty {
                            Text("请输入文本")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundStyle(Color(red: 153 / 255, green: 153 / 255, blue: 153 / 255))
                                .padding(.leading, 10)
                                .padding(.top, 8)
                        }

                        TextEditor(text: $viewModel.hotspotTextDraft)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(.black)
                            .scrollContentBackground(.hidden)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                    }
                    .frame(width: 128, height: 84)

                    HStack(spacing: 8) {
                        Button {
                            viewModel.cancelHotspotText()
                        } label: {
                            Text("取消")
                                .font(.system(size: 10, weight: .regular))
                                .foregroundStyle(.black)
                                .frame(width: 50, height: 26)
                                .background(
                                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                                        .fill(Color(red: 217 / 255, green: 217 / 255, blue: 217 / 255))
                                )
                        }
                        .buttonStyle(.plain)

                        Button {
                            viewModel.confirmHotspotText()
                        } label: {
                            Text("确定")
                                .font(.system(size: 10, weight: .regular))
                                .foregroundStyle(.white)
                                .frame(width: 50, height: 26)
                                .background(
                                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                                        .fill(Color.cadActiveBlue)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.leading, 10)
                }
                .offset(x: 88 * xScale, y: 388 * yScale)
            }
        }
    }

    private var hotspotAnnotationsOverlay: some View {
        GeometryReader { proxy in
            let xScale = proxy.size.width / 393
            let yScale = proxy.size.height / 852

            ZStack(alignment: .topLeading) {
                ForEach(Array(viewModel.hotspotAnnotations.enumerated()), id: \.element.id) { index, annotation in
                    hotspotAnnotationView(annotation)
                        .offset(x: (88 + CGFloat(index) * 8) * xScale, y: (350 + CGFloat(index) * 28) * yScale)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func hotspotAnnotationView(_ annotation: CADHotspotAnnotation) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image("定位 (1) 2")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .padding(.leading, 52)

            Text(annotation.text)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.black)
                .lineLimit(3)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(width: 128, alignment: .topLeading)
                .frame(minHeight: 42, alignment: .topLeading)
                .background(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.white.opacity(0.8))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(
                            Color.cadActiveBlue,
                            style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                        )
                )
        }
    }

    private func toolbarButton(_ item: CADViewerToolbarItemKind) -> some View {
        let isActive = isToolbarItemActive(item)

        return Button {
            handleToolbarItem(item)
        } label: {
            VStack(spacing: 4) {
                Image(item.iconName(isActive: isActive))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)

                Text(item.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(width: 72, height: 66)
        }
        .buttonStyle(.plain)
    }

    private func isToolbarItemActive(_ item: CADViewerToolbarItemKind) -> Bool {
        switch item {
        case .layers:
            return viewModel.isLayerSheetPresented
        case .markup:
            return viewModel.isMarkupToolbarPresented || viewModel.activeMarkup != nil
        case .measurement:
            return viewModel.isMeasurementToolbarPresented
        case .hideMarkup:
            return viewModel.isMarkupHidden
        case .textExtraction:
            return viewModel.isTextExtractionOverlayPresented || viewModel.isTextSheetPresented
        case .settings:
            return viewModel.isSettingsPanelPresented
        case .reset:
            return false
        }
    }

    private func handleToolbarItem(_ item: CADViewerToolbarItemKind) {
        switch item {
        case .layers:
            viewModel.showLayers()
        case .markup:
            viewModel.showMarkupPanel()
        case .measurement:
            viewModel.showMeasurementPanel()
        case .hideMarkup:
            viewModel.toggleMarkupsHidden()
        case .textExtraction:
            viewModel.showExtractedTexts()
        case .reset:
            viewModel.resetView()
        case .settings:
            viewModel.showSettingsPanel()
        }
    }
}

private extension Color {
    static let cadToolbarBackground = Color(red: 70 / 255, green: 70 / 255, blue: 78 / 255)
    static let cadFieldBackground = Color(red: 86 / 255, green: 86 / 255, blue: 96 / 255)
    static let cadActiveBlue = Color(red: 35 / 255, green: 99 / 255, blue: 254 / 255)
    static let cadMeasurementMagenta = Color(red: 228 / 255, green: 48 / 255, blue: 204 / 255)
    static let cadTextExtractionSelectionFill = Color(red: 35 / 255, green: 99 / 255, blue: 254 / 255).opacity(0.2)
    static let cadTextExtractionCancelBackground = Color(red: 207 / 255, green: 207 / 255, blue: 207 / 255)
    static let cadTextExtractionSecondaryText = Color(red: 183 / 255, green: 183 / 255, blue: 183 / 255)
}

private struct TopRoundedRectangle: Shape {
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        let radius = min(radius, min(rect.width, rect.height) / 2)
        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + radius, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + radius),
            control: CGPoint(x: rect.maxX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
