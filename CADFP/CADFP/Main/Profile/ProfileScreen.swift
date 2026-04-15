//
//  ProfileScreen.swift
//  CADFP
//
//  Created by Codex on 4/15/26.
//

import SwiftUI

struct ProfileMenuItem: Equatable, Identifiable {
    let title: String

    var id: String { title }

    static let defaultItems: [ProfileMenuItem] = [
        .init(title: "常见问题"),
        .init(title: "去App Store给我们好评！"),
        .init(title: "分享给朋友！"),
        .init(title: "服务条款"),
        .init(title: "联系我们")
    ]
}

struct ProfileScreen: View {
    private let menuItems: [ProfileMenuItem]

    init(menuItems: [ProfileMenuItem] = ProfileMenuItem.defaultItems) {
        self.menuItems = menuItems
    }

    var body: some View {
        GeometryReader { proxy in
            let pageWidth = proxy.size.width
            let cardWidth = min(53, max(0, pageWidth - 40))

            ZStack(alignment: .top) {
                ProfileBackground()

                Text("我的")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(.top, 68)

                ProfileMenuCard(items: menuItems)
                    .frame(width: cardWidth, height: 295)
                    .padding(.top, 213)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(.container, edges: .top)
        }
        .background(ProfilePalette.pageBottom)
    }
}

private struct ProfileBackground: View {
    var body: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(
                colors: [
                    ProfilePalette.pageTop,
                    ProfilePalette.pageMid,
                    ProfilePalette.pageBottom
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            Image("Intersect")
                .resizable()
                .scaledToFit()
                .frame(width: 360, height: 174)
                .offset(x: 28, y: 0)
                .opacity(0.55)
        }
    }
}

private struct ProfileMenuCard: View {
    let items: [ProfileMenuItem]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(items) { item in
                Button {
                } label: {
                    HStack(spacing: 12) {
                        Text(item.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.black)

                        Spacer(minLength: 12)

                        Image("返回 (11) 3")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                    }
                    .frame(height: 54)
                    .padding(.leading, 26)
                    .padding(.trailing, 24)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.title)
            }
        }
        .padding(.vertical, 12)
        .background(.white)
        .clipShape(.rect(cornerRadius: 28, style: .continuous))
    }
}

private enum ProfilePalette {
    static let pageTop = Color(red: 218 / 255, green: 240 / 255, blue: 255 / 255)
    static let pageMid = Color(red: 239 / 255, green: 247 / 255, blue: 255 / 255)
    static let pageBottom = Color(red: 244 / 255, green: 248 / 255, blue: 253 / 255)
}

#Preview {
    ProfileScreen()
}
