//
//  BarLevelScreen.swift
//  CADFP
//
//  Created by Codex on 2026/4/11.
//

import SwiftUI

struct BarLevelScreen: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var motionEngine = LevelMotionEngine()

    private let referenceHeight: CGFloat = 852
    private let readoutCenterY: CGFloat = 346
    private let closeButtonCenterY: CGFloat = 70

    var body: some View {
        GeometryReader { proxy in
            let angle = LevelGeometry.barAngleDegrees(
                for: motionEngine.sample,
                orientation: motionEngine.orientation
            )
            let measurementLineRotation = LevelGeometry.barMeasurementLineRotationDegrees(
                for: motionEngine.sample,
                orientation: motionEngine.orientation
            )

            ZStack(alignment: .topTrailing) {
                Color.white
                    .ignoresSafeArea()

                BarLevelGuides(
                    width: proxy.size.width,
                    height: proxy.size.height,
                    measurementLineRotation: measurementLineRotation
                )

                Text(LevelGeometry.formattedAngle(angle))
                    .font(.system(size: 28, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(.black)
                    .position(
                        x: proxy.size.width / 2,
                        y: proxy.size.height * readoutCenterY / referenceHeight
                    )

                if !motionEngine.isMotionAvailable {
                    LevelUnavailableCard(message: "当前设备不支持运动传感器，请在真机上使用水平仪。")
                        .padding(.top, proxy.safeAreaInsets.top + 58)
                        .padding(.horizontal, 22)
                }

                closeButton
                    .position(
                        x: proxy.size.width - 35,
                        y: 15
                    )
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
                .fill(Color(red: 191 / 255, green: 191 / 255, blue: 191 / 255))
                .frame(width: 30, height: 30)
                .overlay {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                }
        }
        .buttonStyle(.plain)
    }
}

private struct BarLevelGuides: View {
    let width: CGFloat
    let height: CGFloat
    let measurementLineRotation: Double

    private let baselineColor = Color(red: 62 / 255, green: 129 / 255, blue: 255 / 255)
    private let measurementColor = Color(red: 178 / 255, green: 184 / 255, blue: 194 / 255)

    var body: some View {
        let measurementLineLength = hypot(width, height) + 48

        ZStack {
            GuideLine()
                .stroke(
                    baselineColor,
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )
                .frame(width: width, height: 10)

            GuideLine()
                .stroke(
                    measurementColor,
                    style: StrokeStyle(
                        lineWidth: 1.5,
                        lineCap: .round,
                        dash: [8, 7]
                    )
                )
                .frame(width: measurementLineLength, height: 10)
                .rotationEffect(.degrees(measurementLineRotation))
        }
        .frame(width: width, height: 44)
        .position(x: width / 2, y: height / 2)
    }
}

private struct GuideLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

#Preview {
    NavigationStack {
        BarLevelScreen()
    }
}
