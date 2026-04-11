//
//  CircularLevelScreen.swift
//  CADFP
//
//  Created by Codex on 2026/4/11.
//

import SwiftUI

struct CircularLevelScreen: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var motionEngine = LevelMotionEngine()

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width - 72, 292)
            let bubbleTravel = max(0, size / 2 - 28)
            let bubbleOffset = LevelGeometry.circularBubbleOffset(
                for: motionEngine.sample,
                travelRadius: bubbleTravel
            )

            ZStack(alignment: .topTrailing) {
                Color.white
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer(minLength: 168)

                    CircularLevelInstrument(
                        size: size,
                        bubbleOffset: bubbleOffset
                    )

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if !motionEngine.isMotionAvailable {
                    LevelUnavailableCard(message: "当前设备不支持运动传感器，请在真机上使用水平仪。")
                        .padding(.top, proxy.safeAreaInsets.top + 58)
                        .padding(.horizontal, 22)
                }

                closeButton
//                    .padding(.top, proxy.safeAreaInsets.top + 10)
                    .padding(.trailing, 20)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            motionEngine.start()
        }
        .onDisappear {
            motionEngine.stop()
        }
    }

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Circle()
                .fill(Color(red: 244 / 255, green: 246 / 255, blue: 250 / 255).opacity(0.94))
                .frame(width: 30, height: 30)
                .overlay {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(red: 168 / 255, green: 175 / 255, blue: 184 / 255))
                }
        }
        .buttonStyle(.plain)
    }
}

private struct CircularLevelInstrument: View {
    let size: CGFloat
    let bubbleOffset: CGSize

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(red: 229 / 255, green: 239 / 255, blue: 255 / 255))

            Circle()
                .stroke(Color(red: 76 / 255, green: 132 / 255, blue: 255 / 255), lineWidth: 2)

            Circle()
                .stroke(Color(red: 76 / 255, green: 132 / 255, blue: 255 / 255).opacity(0.34), lineWidth: 1)
                .frame(width: size * 0.48, height: size * 0.48)

            Rectangle()
                .fill(Color(red: 76 / 255, green: 132 / 255, blue: 255 / 255).opacity(0.42))
                .frame(width: 1.2, height: size)

            Rectangle()
                .fill(Color(red: 76 / 255, green: 132 / 255, blue: 255 / 255).opacity(0.42))
                .frame(width: size, height: 1.2)

            Circle()
                .fill(Color(red: 46 / 255, green: 103 / 255, blue: 246 / 255))
                .frame(width: 28, height: 28)
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.82), lineWidth: 4)
                }
                .shadow(color: Color(red: 46 / 255, green: 103 / 255, blue: 246 / 255).opacity(0.24), radius: 12, y: 5)
                .offset(bubbleOffset)
        }
        .frame(width: size, height: size)
    }
}

struct LevelUnavailableCard: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(Color(red: 84 / 255, green: 92 / 255, blue: 109 / 255))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(Color(red: 243 / 255, green: 246 / 255, blue: 250 / 255), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        CircularLevelScreen()
    }
}
