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

            VStack(spacing: 0) {
                headerBar
                Spacer()
                bottomChrome
            }

            if viewModel.isMarkupPanelPresented {
                markupPanel
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $viewModel.isLayerSheetPresented) {
            layerSheet
        }
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
        .animation(.easeInOut(duration: 0.2), value: viewModel.isMarkupPanelPresented)
    }

    private var headerBar: some View {
        VStack(spacing: 0) {
            Color.black
                .frame(height: 0)
                .safeAreaInset(edge: .top) {
                    ZStack {
                        HStack {
                            Button(action: { dismiss() }) {
                                Image("返回 (11) 3")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 22, height: 22)
                                    .padding(10)
                                    .background(Color.white.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(.plain)

                            Spacer()
                        }

                        Text(viewModel.title)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                    .background(Color.black.opacity(0.92))
                }
        }
    }

    private var bottomChrome: some View {
        VStack(spacing: 18) {
            HStack(spacing: 22) {
                statusIcon(title: "图层", symbol: "square.3.layers.3d.top.filled", isActive: viewModel.isLayerSheetPresented)
                statusIcon(title: "批注", symbol: "pencil.tip.crop.circle", isActive: viewModel.activeMarkup != nil)
                statusIcon(title: "测量", symbol: "ruler", isActive: false)
                statusIcon(title: "隐藏", symbol: viewModel.isMarkupHidden ? "eye.slash.fill" : "eye.fill", isActive: viewModel.isMarkupHidden)
                statusIcon(title: "文字", symbol: "text.magnifyingglass", isActive: viewModel.isTextSheetPresented)
            }

            HStack(spacing: 0) {
                toolbarButton(title: "图层") {
                    viewModel.showLayers()
                }
                toolbarButton(title: "批注") {
                    viewModel.showMarkupPanel()
                }
                toolbarButton(title: "测量") {
                    viewModel.showMeasurementPlaceholder()
                }
                toolbarButton(title: viewModel.isMarkupHidden ? "显示批注" : "隐藏批注") {
                    viewModel.toggleMarkupsHidden()
                }
                toolbarButton(title: "文字提取") {
                    viewModel.showExtractedTexts()
                }
            }
            .frame(maxWidth: 360)
            .frame(height: 66)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Color(red: 31 / 255, green: 33 / 255, blue: 37 / 255).opacity(0.96))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 18)
        .background(
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.68)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
        )
    }

    private var markupPanel: some View {
        VStack {
            Spacer()

            VStack(alignment: .leading, spacing: 16) {
                Text("选择批注工具")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(red: 26 / 255, green: 31 / 255, blue: 43 / 255))

                HStack(spacing: 12) {
                    ForEach(CADViewerViewModel.MarkupOption.allCases) { option in
                        Button {
                            viewModel.selectMarkup(option)
                        } label: {
                            VStack(spacing: 10) {
                                Image(systemName: option.symbolName)
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(Color(red: 46 / 255, green: 112 / 255, blue: 255 / 255))
                                    .frame(width: 44, height: 44)
                                    .background(Color(red: 237 / 255, green: 244 / 255, blue: 255 / 255))
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                                Text(option.rawValue)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color(red: 70 / 255, green: 78 / 255, blue: 92 / 255))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.white)
            )
            .padding(.horizontal, 18)
            .padding(.bottom, 136)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.18).ignoresSafeArea())
        .onTapGesture {
            viewModel.isMarkupPanelPresented = false
        }
    }

    private var layerSheet: some View {
        NavigationStack {
            List {
                ForEach(viewModel.layers, id: \.index) { layer in
                    Button {
                        viewModel.toggleLayer(layer)
                    } label: {
                        HStack(spacing: 14) {
                            Circle()
                                .fill(Color(uiColor: layer.color))
                                .frame(width: 14, height: 14)

                            Text(layer.name)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color(red: 32 / 255, green: 39 / 255, blue: 51 / 255))

                            Spacer()

                            Image(systemName: layer.isHidden ? "eye.slash" : "eye")
                                .foregroundColor(layer.isHidden ? .secondary : Color(red: 46 / 255, green: 112 / 255, blue: 255 / 255))
                        }
                    }
                    .buttonStyle(.plain)
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .navigationTitle("图层")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.fraction(0.42), .large])
        .presentationDragIndicator(.visible)
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

    private func statusIcon(title: String, symbol: String, isActive: Bool) -> some View {
        VStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(isActive ? .white : Color.white.opacity(0.7))
                .frame(width: 34, height: 34)
                .background(
                    Circle()
                        .fill(isActive ? Color(red: 46 / 255, green: 112 / 255, blue: 255 / 255) : Color.white.opacity(0.08))
                )

            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color.white.opacity(isActive ? 0.92 : 0.58))
        }
    }

    private func toolbarButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.plain)
    }
}
