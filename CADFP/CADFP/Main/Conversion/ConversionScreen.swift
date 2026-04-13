import QuickLook
import SwiftUI
import UIKit

enum ConversionScreenLayout {
    static let designWidth: CGFloat = 393
    static let designHeight: CGFloat = 852
    static let headerTop: CGFloat = 125
    static let importCardsTop: CGFloat = 233
    static let documentsPanelTop: CGFloat = 409
    static let documentsPanelHeight: CGFloat = 443
    static let horizontalMargin: CGFloat = 20
    static let documentTitleLeading: CGFloat = 24
}

struct ConversionScreen: View {
    let kind: ConversionKind
    let incomingFileURL: URL?
    let onConverted: (ConversionDocument) -> Void
    let onOpenDocument: (ConversionDocument) -> Void

    @State private var documents: [ConversionDocument] = []
    @State private var alertMessage: ConversionAlert?
    @State private var activeSheet: ConversionSheet?
    @State private var showsFileImporter = false
    @State private var handledIncomingFileURL: URL?

    private let store = ConversionDocumentStore()

    init(
        kind: ConversionKind,
        incomingFileURL: URL? = nil,
        onConverted: @escaping (ConversionDocument) -> Void,
        onOpenDocument: @escaping (ConversionDocument) -> Void
    ) {
        self.kind = kind
        self.incomingFileURL = incomingFileURL
        self.onConverted = onConverted
        self.onOpenDocument = onOpenDocument
    }

    var body: some View {
        GeometryReader { proxy in
            let pageWidth = min(proxy.size.width, ConversionScreenLayout.designWidth)
            let pageX = max((proxy.size.width - pageWidth) / 2, 0)
            let panelHeight = max(
                proxy.size.height - ConversionScreenLayout.documentsPanelTop,
                ConversionScreenLayout.documentsPanelHeight
            )

            ZStack(alignment: .topLeading) {
                ConversionBackdrop()

                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.white)
                    .frame(width: pageWidth, height: panelHeight)
                    .offset(x: pageX, y: ConversionScreenLayout.documentsPanelTop)

                header
                    .frame(
                        width: pageWidth - ConversionScreenLayout.horizontalMargin * 2,
                        alignment: .leading
                    )
                    .offset(
                        x: pageX + ConversionScreenLayout.horizontalMargin,
                        y: ConversionScreenLayout.headerTop
                    )

                importCards
                    .frame(width: 353, height: 152, alignment: .topLeading)
                    .offset(
                        x: pageX + ConversionScreenLayout.horizontalMargin,
                        y: ConversionScreenLayout.importCardsTop
                    )

                documentsPanel
                    .frame(width: pageWidth, height: panelHeight, alignment: .topLeading)
                    .offset(x: pageX, y: ConversionScreenLayout.documentsPanelTop)

            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
        }
        .ignoresSafeArea()
        .navigationTitle(kind.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .background(Color.white)
        .task {
            reloadDocuments()
        }
        .task(id: incomingFileURL) {
            importIncomingFileIfNeeded()
        }
        .fileImporter(
            isPresented: $showsFileImporter,
            allowedContentTypes: kind.importContentTypes,
            allowsMultipleSelection: false,
            onCompletion: handleFileImporterResult
        )
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .importedFiles:
                ConversionImportedFilesSheet(
                    kind: kind,
                    documents: documents,
                    onOpenDocument: onOpenDocument
                )
                    .presentationDetents([.medium, .large])
            case .weChatGuide:
                ConversionWeChatGuideSheet()
                    .presentationDetents([.medium])
            }
        }
        .alert(item: $alertMessage) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("知道了"))
            )
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(kind.title)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color(red: 22 / 255, green: 22 / 255, blue: 22 / 255))

            VStack(alignment: .leading, spacing: 2) {
                Text("1.支持选择微信聊天文件/本地文件")
                Text("2.转换完成后的文件，支持导出、分享")
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(Color(red: 102 / 255, green: 102 / 255, blue: 102 / 255))
            .lineSpacing(8)
        }
        .padding(.leading, 8)
    }

    private var importCards: some View {
        HStack(spacing: 12) {
            Button {
                reloadDocuments()
                activeSheet = .importedFiles
            } label: {
                VStack(spacing: 22) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 239 / 255, green: 244 / 255, blue: 1))
                            .frame(width: 56, height: 56)

                        Image("我的文件-face 1")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                    }

                    Text("我的文件")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.black)

                    Spacer(minLength: 0)
                }
                .padding(.top, 24)
                .frame(width: 157, height: 152)
                .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)

            VStack(spacing: 12) {
                ConversionImportOptionCard(
                    title: "本地导入",
                    background: Color(red: 230 / 255, green: 252 / 255, blue: 1),
                    imageName: "本地文件 (1) 1",
                    iconColor: nil,
                    action: { showsFileImporter = true }
                )

                ConversionImportOptionCard(
                    title: "微信导入",
                    background: Color(red: 230 / 255, green: 1, blue: 246 / 255),
                    imageName: nil,
                    iconColor: Color(red: 38 / 255, green: 214 / 255, blue: 134 / 255),
                    action: { activeSheet = .weChatGuide }
                )
            }
        }
    }

    private var documentsPanel: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("我的文档")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.black)
                .padding(.leading, ConversionScreenLayout.documentTitleLeading)

            if documents.isEmpty {
                ConversionEmptyDocumentView(kind: kind)
                    .padding(.top, 22)

                Spacer(minLength: 0)
            } else {
                ScrollView {
                    LazyVStack(spacing: 22) {
                        ForEach(documents) { document in
                            Button {
                                onOpenDocument(document)
                            } label: {
                                ConversionDocumentRow(document: document)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)
            }
        }
        .padding(.top, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func handleFileImporterResult(_ result: Result<[URL], Error>) {
        switch result {
        case let .success(urls):
            guard let url = urls.first else { return }
            importDocument(at: url)
        case let .failure(error):
            let nsError = error as NSError
            guard nsError.domain != NSCocoaErrorDomain || nsError.code != NSUserCancelledError else {
                return
            }

            alertMessage = ConversionAlert(
                title: "导入失败",
                message: "没有成功选择文件，请再试一次。"
            )
        }
    }

    private func importIncomingFileIfNeeded() {
        guard let incomingFileURL, handledIncomingFileURL != incomingFileURL else {
            return
        }

        handledIncomingFileURL = incomingFileURL
        importDocument(at: incomingFileURL)
    }

    private func importDocument(at url: URL) {
        do {
            let outputURL = try CADConversionEngine.convert(sourceURL: url, kind: kind)
            let document = try store.saveConvertedFile(
                at: outputURL,
                kind: kind,
                sourceName: url.lastPathComponent
            )
            reloadDocuments()
            onConverted(document)
        } catch CADConversionEngine.ConversionError.unsupported {
            alertMessage = ConversionAlert(
                title: "暂不支持",
                message: "\(kind.title) 本地转换还没有接入。"
            )
        } catch {
            alertMessage = ConversionAlert(
                title: "转换失败",
                message: error.localizedDescription
            )
        }
    }

    private func reloadDocuments() {
        documents = store.documents(for: kind)
    }
}

private enum ConversionSheet: Identifiable {
    case importedFiles
    case weChatGuide

    var id: String {
        switch self {
        case .importedFiles:
            return "importedFiles"
        case .weChatGuide:
            return "weChatGuide"
        }
    }
}

private struct ConversionImportedFilesSheet: View {
    @Environment(\.dismiss) private var dismiss

    let kind: ConversionKind
    let documents: [ConversionDocument]
    let onOpenDocument: (ConversionDocument) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if documents.isEmpty {
                    VStack(spacing: 14) {
                        ConversionFileIcon(extensionText: kind.outputExtension.uppercased())
                            .frame(width: 52, height: 52)
                            .opacity(0.72)

                        Text("暂无转换文件")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.black)

                        Text("转换完成后的文件会自动保存到这里。")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(red: 153 / 255, green: 153 / 255, blue: 153 / 255))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 24)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 22) {
                            ForEach(documents) { document in
                                Button {
                                    dismiss()
                                    onOpenDocument(document)
                                } label: {
                                    ConversionDocumentRow(document: document)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 20)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .navigationTitle("我的文件")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold))
                }
            }
        }
    }
}

private struct ConversionWeChatGuideSheet: View {
    @Environment(\.dismiss) private var dismiss

    private var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? "CADFP"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Capsule()
                .fill(Color(red: 219 / 255, green: 226 / 255, blue: 235 / 255))
                .frame(width: 40, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, 10)

            VStack(alignment: .leading, spacing: 10) {
                Text("微信导入")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.black)

                Text("请在微信聊天里打开要转换的文件，点右上角更多，选择“用其他应用打开”，再选择\(appName)。回到\(appName)后会自动进入转换页并保存到我的文件。")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color(red: 80 / 255, green: 88 / 255, blue: 102 / 255))
                    .lineSpacing(6)
            }

            VStack(alignment: .leading, spacing: 12) {
                ConversionGuideStep(number: "1", text: "微信聊天文件")
                ConversionGuideStep(number: "2", text: "用其他应用打开")
                ConversionGuideStep(number: "3", text: "选择\(appName)")
            }

            Spacer(minLength: 0)

            Button {
                dismiss()
            } label: {
                Text("知道了")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Color(red: 35 / 255, green: 99 / 255, blue: 254 / 255), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 22)
        .background(Color.white)
    }
}

private struct ConversionGuideStep: View {
    let number: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Text(number)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Color(red: 35 / 255, green: 99 / 255, blue: 254 / 255), in: Circle())

            Text(text)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(red: 22 / 255, green: 22 / 255, blue: 22 / 255))

            Spacer(minLength: 0)
        }
    }
}

struct ConversionCompleteScreen: View {
    let document: ConversionDocument
    let onReturnHome: () -> Void

    @State private var alertMessage: ConversionAlert?
    @State private var exportDocument: ConversionDocument?

    private var kind: ConversionKind {
        document.kind
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 174)

                Image("source_d276ccbaeeaceace5d3c28a71804c322d36e07feb1c-6RfEr0")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)

                Text("转换成功！")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(.top, 18)

                Text(kind.completionSubtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(red: 102 / 255, green: 102 / 255, blue: 102 / 255))
                    .padding(.top, 12)

                VStack(spacing: 20) {
                    Button {
                        guard FileManager.default.fileExists(atPath: document.fileURL.path) else {
                            alertMessage = ConversionAlert(title: "文件不存在", message: "没有找到转换后的文件，请重新转换一次。")
                            return
                        }

                        exportDocument = document
                    } label: {
                        Text("下载")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(Color(red: 35 / 255, green: 99 / 255, blue: 254 / 255), in: Capsule())
                    }
                    .buttonStyle(.plain)

                    ShareLink(item: document.fileURL) {
                        Text("分享至")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color(red: 22 / 255, green: 22 / 255, blue: 22 / 255))
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(Color(red: 243 / 255, green: 246 / 255, blue: 250 / 255), in: Capsule())
                    }
                }
                .padding(.horizontal, 44)
                .padding(.top, 48)

                Button(action: onReturnHome) {
                    Text("返回首页")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color(red: 102 / 255, green: 102 / 255, blue: 102 / 255))
                        .padding(.top, 28)
                }
                .buttonStyle(.plain)

                Spacer()
            }
        }
        .navigationTitle("转换完成")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .sheet(item: $exportDocument) { document in
            ConversionDocumentExporter(url: document.fileURL)
        }
        .alert(item: $alertMessage) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("知道了"))
            )
        }
    }
}

struct ConversionFilePreviewScreen: View {
    let document: ConversionDocument

    var body: some View {
        QuickLookPreview(url: document.fileURL)
            .ignoresSafeArea()
            .navigationTitle(document.fileName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .tabBar)
    }
}

private struct ConversionDocumentExporter: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        UIDocumentPickerViewController(forExporting: [url], asCopy: true)
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
}

private struct QuickLookPreview: UIViewControllerRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}

    final class Coordinator: NSObject, QLPreviewControllerDataSource {
        let url: URL

        init(url: URL) {
            self.url = url
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            FileManager.default.fileExists(atPath: url.path) ? 1 : 0
        }

        func previewController(
            _ controller: QLPreviewController,
            previewItemAt index: Int
        ) -> QLPreviewItem {
            url as NSURL
        }
    }
}

private struct ConversionBackdrop: View {
    var body: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(
                colors: [
                    Color(red: 224 / 255, green: 242 / 255, blue: 1),
                    Color(red: 238 / 255, green: 245 / 255, blue: 252 / 255),
                    Color(red: 246 / 255, green: 248 / 255, blue: 250 / 255)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            Image("Intersect")
                .resizable()
                .scaledToFit()
                .frame(width: 420)
                .offset(x: 80, y: -28)
                .opacity(0.35)
        }
    }
}

private struct ConversionImportOptionCard: View {
    let title: String
    let background: Color
    let imageName: String?
    let iconColor: Color?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(background)
                        .frame(width: 36, height: 36)

                    if let imageName {
                        Image(imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                    } else {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(iconColor ?? .green)
                    }
                }

                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.black)

                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(width: 184, height: 70)
            .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct ConversionDocumentRow: View {
    let document: ConversionDocument

    var body: some View {
        HStack(spacing: 12) {
            ConversionFileIcon(extensionText: document.fileName.pathExtensionLabel)
                .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 8) {
                Text(document.fileName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.black)
                    .lineLimit(1)

                Text(document.createdAt.conversionListDateText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(red: 153 / 255, green: 153 / 255, blue: 153 / 255))
            }

            Spacer()

            Image("更多 (5) 1")
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 8)
                .opacity(0.9)
        }
        .padding(.horizontal, 20)
    }
}

private struct ConversionEmptyDocumentView: View {
    let kind: ConversionKind

    var body: some View {
        VStack(spacing: 12) {
            ConversionFileIcon(extensionText: kind.outputExtension.uppercased())
                .frame(width: 52, height: 52)
                .opacity(0.72)

            Text("暂无转换后的\(kind.outputExtension.uppercased())文件")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(red: 153 / 255, green: 153 / 255, blue: 153 / 255))
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ConversionFileIcon: View {
    let extensionText: String

    private var colorPair: [Color] {
        switch extensionText.uppercased() {
        case "PDF":
            return [
                Color(red: 129 / 255, green: 229 / 255, blue: 241 / 255),
                Color(red: 0, green: 175 / 255, blue: 204 / 255)
            ]
        case "DWG":
            return [
                Color(red: 1, green: 207 / 255, blue: 216 / 255),
                Color(red: 1, green: 107 / 255, blue: 132 / 255)
            ]
        default:
            return [
                Color(red: 134 / 255, green: 166 / 255, blue: 1),
                Color(red: 35 / 255, green: 99 / 255, blue: 254 / 255)
            ]
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(colorPair[0].opacity(0.45))
                .frame(width: 38, height: 48)
                .overlay(alignment: .topTrailing) {
                    TriangleFold()
                        .fill(Color.white.opacity(0.76))
                        .frame(width: 10, height: 10)
                }

            VStack(spacing: 0) {
                Spacer()
                Rectangle()
                    .fill(colorPair[1])
                    .frame(height: 16)
                    .overlay {
                        Text(extensionText.uppercased())
                            .font(.system(size: 8, weight: .heavy))
                            .foregroundStyle(.white)
                    }
            }
            .frame(width: 38, height: 48)

            Image(systemName: "plus")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(colorPair[1])
                .offset(y: -16)
        }
    }
}

private struct TriangleFold: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct ConversionAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

private extension String {
    var pathExtensionLabel: String {
        let ext = (self as NSString).pathExtension
        return ext.isEmpty ? "FILE" : ext.uppercased()
    }
}

private extension Date {
    var conversionListDateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: self)
    }
}

#Preview {
    NavigationStack {
        ConversionScreen(
            kind: .pdfToDwg,
            onConverted: { _ in },
            onOpenDocument: { _ in }
        )
    }
}
