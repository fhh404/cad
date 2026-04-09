//
//  ContentView.swift
//  CADFP
//
//  Created by huaheng feng on 4/9/26.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house")
                    Text("首页")
                }
                .tag(0)
            
            MyView()
                .tabItem {
                    Image(systemName: "person")
                    Text("我的")
                }
                .tag(1)
        }
    }
}

struct MyView: View {
    var body: some View {
        VStack {
            Text("我的")
                .font(.largeTitle)
                .fontWeight(.bold)
        }
        .padding()
    }
}

struct HomeView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 标题
                Text("AR室内扫描建模")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                
                // 主要功能按钮
                HStack(spacing: 15) {
                    FunctionButton(
                        title: "导入图纸",
                        description: "支持微信、本地文件",
                        icon: "folder.badge.plus",
                        color: .blue
                    )
                    
                    FunctionButton(
                        title: "扫描图纸",
                        description: "生成可编辑文件",
                        icon: "camera",
                        color: .cyan
                    )
                }
                .padding(.horizontal, 20)
                
                // 工具按钮
                HStack(spacing: 20) {
                    ToolButton(title: "水印相机", icon: "camera.badge.clock")
                    ToolButton(title: "计算器", icon: "calculator")
                    ToolButton(title: "测量工具", icon: "ruler")
                }
                .padding(.horizontal, 20)
                
                // 热门推荐
                SectionHeader(title: "热门推荐")
                
                VStack(spacing: 15) {
                    HStack(spacing: 15) {
                        ConvertToolButton(title: "DWG转PDF", icon: "doc.fill")
                        ConvertToolButton(title: "3D转STP", icon: "cube.fill")
                        ConvertToolButton(title: "PDF转DWG", icon: "doc.fill")
                        ConvertToolButton(title: "PDF转Word", icon: "doc.text.fill")
                    }
                    
                    HStack(spacing: 15) {
                        ConvertToolButton(title: "PDF转图片", icon: "photo.fill")
                        ConvertToolButton(title: "DWG转图片", icon: "photo.fill")
                        ConvertToolButton(title: "DWG转DXF", icon: "doc.fill")
                    }
                }
                .padding(.horizontal, 20)
                
                // 最近文件
                SectionHeader(title: "最近文件")
                
                RecentFileItem(
                    fileName: "DWG 示例 - 1.dwg",
                    fileType: "DWG",
                    date: "2026-03-21 16:05"
                )
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.top, 20)
        }
    }
}

struct FunctionButton: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color)
                    .frame(width: 160, height: 100)
                
                VStack {
                    Image(systemName: icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.white)
                    
                    Text(title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.white)
                        .opacity(0.8)
                }
            }
        }
    }
}

struct ToolButton: View {
    let title: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 5) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.blue)
            }
            
            Text(title)
                .font(.caption)
        }
    }
}

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
}

struct ConvertToolButton: View {
    let title: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 5) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 70, height: 70)
                
                Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.blue)
            }
            
            Text(title)
                .font(.caption2)
                .multilineTextAlignment(.center)
        }
    }
}

struct RecentFileItem: View {
    let fileName: String
    let fileType: String
    let date: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 50, height: 60)
                
                VStack {
                    Image(systemName: "doc.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 25, height: 25)
                        .foregroundColor(.red)
                    
                    Text(fileType)
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text(fileName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(date)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.05)))
    }
}

#Preview {
    ContentView()
}
