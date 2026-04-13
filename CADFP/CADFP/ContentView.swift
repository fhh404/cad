//
//  ContentView.swift
//  CADFP
//
//  Created by huaheng feng on 4/9/26.
//

import SwiftUI

private enum AppTab: Hashable {
    case home
    case profile
}

enum HomeRoute: Hashable {
    case cadViewer
    case calculatorCatalog
    case calculatorDetail(CalculatorKind)
    case measurementCatalog
    case measurementCircularLevel
    case measurementBarLevel
    case measurementRuler
    case measurementProtractor
    case conversion(ConversionKind)
    case importedConversion(ConversionKind, URL)
    case conversionComplete(ConversionDocument)
    case conversionDocumentPreview(ConversionDocument)
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .home
    @State private var homePath: [HomeRoute] = []
    @State private var pendingAction: HomeAction?
    @State private var externalImportAlert: ConversionAlert?
    @State private var showsWatermarkCamera = false

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack(path: $homePath) {
                HomeView { action in
                    switch action {
                    case .openRecentFile:
                        homePath.append(.cadViewer)
                    case .calculator:
                        homePath.append(.calculatorCatalog)
                    case .measurementTools:
                        homePath.append(.measurementCatalog)
                    case .watermarkCamera:
                        showsWatermarkCamera = true
                    default:
                        if let conversionKind = action.conversionKind {
                            homePath.append(.conversion(conversionKind))
                        } else {
                            pendingAction = action
                        }
                    }
                }
                .navigationDestination(for: HomeRoute.self) { route in
                    switch route {
                    case .cadViewer:
                        CADViewerScreen(
                            title: "DWG 示例 -1",
                            filePath: Bundle.main.path(forResource: "Sample", ofType: "dwg") ?? ""
                        )
                    case .calculatorCatalog:
                        CalculatorCatalogScreen()
                    case let .calculatorDetail(kind):
                        CalculatorDetailScreen(kind: kind)
                    case .measurementCatalog:
                        MeasurementCatalogScreen()
                    case .measurementCircularLevel:
                        CircularLevelScreen()
                    case .measurementBarLevel:
                        BarLevelScreen()
                    case .measurementRuler:
                        RulerScreen()
                    case .measurementProtractor:
                        ProtractorScreen()
                    case let .conversion(kind):
                        ConversionScreen(
                            kind: kind,
                            onConverted: { document in
                                homePath.append(.conversionComplete(document))
                            },
                            onOpenDocument: { document in
                                homePath.append(.conversionDocumentPreview(document))
                            }
                        )
                    case let .importedConversion(kind, url):
                        ConversionScreen(
                            kind: kind,
                            incomingFileURL: url,
                            onConverted: { document in
                                homePath.append(.conversionComplete(document))
                            },
                            onOpenDocument: { document in
                                homePath.append(.conversionDocumentPreview(document))
                            }
                        )
                    case let .conversionComplete(document):
                        ConversionCompleteScreen(document: document) {
                            homePath.removeAll()
                        }
                    case let .conversionDocumentPreview(document):
                        switch document.previewDestination {
                        case .cadViewer:
                            CADViewerScreen(title: document.fileName, filePath: document.fileURL.path)
                        case .systemPreview:
                            ConversionFilePreviewScreen(document: document)
                        }
                    }
                }
            }
            .tabItem {
                Label("首页", systemImage: "house.fill")
            }
            .tag(AppTab.home)

            MyView()
                .tabItem {
                Label("我的", systemImage: "person.fill")
            }
            .tag(AppTab.profile)
        }
        .fullScreenCover(isPresented: $showsWatermarkCamera) {
            WatermarkCameraScreen()
        }
        .onOpenURL(perform: handleIncomingFile)
        .alert(item: $pendingAction) { action in
            Alert(
                title: Text(action.title),
                message: Text(action.implementationHint),
                dismissButton: .default(Text("知道了"))
            )
        }
        .alert(item: $externalImportAlert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("知道了"))
            )
        }
    }

    private func handleIncomingFile(_ url: URL) {
        guard let kind = ConversionKind.preferredImportKind(for: url) else {
            externalImportAlert = ConversionAlert(
                title: "暂不支持",
                message: "当前文件格式还不能导入，请选择 PDF、DWG 或 DXF 文件。"
            )
            return
        }

        selectedTab = .home
        homePath.append(.importedConversion(kind, url))
    }
}

private struct MyView: View {
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Spacer(minLength: 80)

                Image("默认头像 (4) 1")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 96, height: 96)

                Text("我的")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(red: 36 / 255, green: 58 / 255, blue: 96 / 255))

                Text("这里后续可以承接账号信息、最近项目和配置中心。")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(red: 140 / 255, green: 149 / 255, blue: 166 / 255))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)

                Spacer()
            }
        }
    }
}

#Preview {
    ContentView()
}
