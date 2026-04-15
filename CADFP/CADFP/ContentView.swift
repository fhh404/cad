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
                Label {
                    Text("首页")
                } icon: {
                    Image(selectedTab == .home ? "Group 245" : "Group 246")
                        .renderingMode(.original)
                }
            }
            .tag(AppTab.home)

//            ProfileScreen()
//                .tabItem {
//                    Label {
//                        Text("我的")
//                    } icon: {
//                        Image(selectedTab == .profile ? "Group 244" : "Group 243")
//                            .renderingMode(.original)
//                    }
//                }
//            .tag(AppTab.profile)
        }
        .tint(Color(red: 35 / 255, green: 99 / 255, blue: 254 / 255))
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

#Preview {
    ContentView()
}
