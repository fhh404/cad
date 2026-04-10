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
    case measurementRuler
    case measurementProtractor
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .home
    @State private var homePath: [HomeRoute] = []
    @State private var pendingAction: HomeAction?
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
                        pendingAction = action
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
                    case .measurementRuler:
                        RulerScreen()
                    case .measurementProtractor:
                        ProtractorScreen()
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
        .alert(item: $pendingAction) { action in
            Alert(
                title: Text(action.title),
                message: Text(action.implementationHint),
                dismissButton: .default(Text("知道了"))
            )
        }
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
