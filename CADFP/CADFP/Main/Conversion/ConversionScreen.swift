import SwiftUI

struct ConversionScreen: View {
    @Environment(\.dismiss) private var dismiss

    let kind: ConversionKind
    let onConverted: (ConversionKind) -> Void

    @State private var documents: [ConversionDocument] = []
    @State private var alertMessage: ConversionAlert?

    private let store = ConversionDocumentStore()

    var body: some View {
        ZStack(alignment: .top) {
            ConversionBackdrop()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.top, 118)

                    importCards
                        .padding(.top, 26)

                    documentsPanel
                        .padding(.top, 24)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 48)
            }
            .scrollIndicators(.hidden)

            ConversionNavigationBar(title: kind.title, onBack: { dismiss() })
        }
        .toolbar(.hidden, for: .navigationBar)
        .background(Color.white)
        .task {
            reloadDocuments()
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
            } label: {
                VStack(spacing: 20) {
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
                }
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
                    action: runMockConversion
                )

                ConversionImportOptionCard(
                    title: "微信导入",
                    background: Color(red: 230 / 255, green: 1, blue: 246 / 255),
                    imageName: nil,
                    iconColor: Color(red: 38 / 255, green: 214 / 255, blue: 134 / 255),
                    action: runMockConversion
                )
            }
        }
    }

    private var documentsPanel: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("我的文档")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.black)

            if documents.isEmpty {
                ConversionEmptyDocumentView(kind: kind)
                    .padding(.top, 22)
            } else {
                VStack(spacing: 22) {
                    ForEach(documents) { document in
                        ConversionDocumentRow(document: document)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 4)
        .padding(.top, 24)
        .frame(maxWidth: .infinity, minHeight: 420, alignment: .topLeading)
        .background(.white, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .padding(.horizontal, -20)
    }

    private func runMockConversion() {
        do {
            _ = try store.saveConvertedPlaceholder(kind: kind)
            reloadDocuments()
            onConverted(kind)
        } catch {
            alertMessage = ConversionAlert(
                title: "保存失败",
                message: "占位转换文件没有保存成功，请稍后再试。"
            )
        }
    }

    private func reloadDocuments() {
        documents = store.documents(for: kind)
    }
}

struct ConversionCompleteScreen: View {
    @Environment(\.dismiss) private var dismiss

    let kind: ConversionKind
    let onReturnHome: () -> Void

    @State private var alertMessage: ConversionAlert?

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
                        alertMessage = ConversionAlert(title: "下载", message: "真实下载功能会在转换引擎接入后补上。")
                    } label: {
                        Text("下载")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(Color(red: 35 / 255, green: 99 / 255, blue: 254 / 255), in: Capsule())
                    }
                    .buttonStyle(.plain)

                    Button {
                        alertMessage = ConversionAlert(title: "分享至", message: "真实分享功能会在转换文件可用后补上。")
                    } label: {
                        Text("分享至")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color(red: 22 / 255, green: 22 / 255, blue: 22 / 255))
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(Color(red: 243 / 255, green: 246 / 255, blue: 250 / 255), in: Capsule())
                    }
                    .buttonStyle(.plain)
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

            ConversionNavigationBar(title: "转换完成", onBack: { dismiss() })
        }
        .toolbar(.hidden, for: .navigationBar)
        .alert(item: $alertMessage) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("知道了"))
            )
        }
    }
}

private struct ConversionNavigationBar: View {
    let title: String
    let onBack: () -> Void

    var body: some View {
        ZStack {
            Button(action: onBack) {
                Image("Group 189")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .frame(width: 44, height: 44, alignment: .leading)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 16)

            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color(red: 22 / 255, green: 22 / 255, blue: 22 / 255))
        }
        .frame(height: 52)
        .padding(.top, 44)
        .background(Color.white.opacity(0.001))
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
        ConversionScreen(kind: .pdfToDwg, onConverted: { _ in })
    }
}
