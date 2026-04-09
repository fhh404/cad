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

struct ContentView: View {
    @State private var selectedTab: AppTab = .home
    @State private var pendingAction: HomeAction?

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView { action in
                pendingAction = action
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
