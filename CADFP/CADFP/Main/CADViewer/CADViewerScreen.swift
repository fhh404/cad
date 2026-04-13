import SwiftUI

struct CADViewerScreen: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: CADViewerViewModel

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

            VStack(spacing: 0) {
                headerBar
                Spacer()
                bottomChrome
            }
            .zIndex(3)
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $viewModel.isTextSheetPresented) {
            textSheet
        }
        .alert(item: $viewModel.alertMessage) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("知道了"))
            )
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.isMarkupToolbarPresented)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isMarkupTextInputPresented)
        .animation(.easeInOut(duration: 0.2), value: viewModel.activeMarkupStylePanel)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isHotspotInputPresented)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isLayerSheetPresented)
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
        if viewModel.isMarkupToolbarPresented {
            markupBottomChrome
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
            return false
        case .hideMarkup:
            return viewModel.isMarkupHidden
        case .textExtraction:
            return viewModel.isTextSheetPresented
        case .reset, .settings:
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
            viewModel.showMeasurementPlaceholder()
        case .hideMarkup:
            viewModel.toggleMarkupsHidden()
        case .textExtraction:
            viewModel.showExtractedTexts()
        case .reset:
            viewModel.resetView()
        case .settings:
            viewModel.showSettingsPlaceholder()
        }
    }
}

private extension Color {
    static let cadToolbarBackground = Color(red: 70 / 255, green: 70 / 255, blue: 78 / 255)
    static let cadFieldBackground = Color(red: 86 / 255, green: 86 / 255, blue: 96 / 255)
    static let cadActiveBlue = Color(red: 35 / 255, green: 99 / 255, blue: 254 / 255)
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
