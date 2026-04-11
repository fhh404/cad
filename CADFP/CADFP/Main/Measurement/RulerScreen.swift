//
//  RulerScreen.swift
//  CADFP
//
//  Created by Codex on 2026/4/10.
//

import SwiftUI

struct RulerScreen: View {
    @Environment(\.dismiss) private var dismiss

    @State private var profile: RulerDisplayProfile?
    @State private var viewportState: RulerViewportState?
    @State private var unsupportedMessage: String?
    @State private var activeDragSession: RulerDragSession?
    @State private var activePanStartingState: RulerViewportState?
    @State private var lastViewportHeight: Double = 0

    private let rulerStripWidth: CGFloat = 68
    private let handleSize: CGFloat = 32
    private let dragCoordinateSpaceName = "ruler-screen-space"

    var body: some View {
        GeometryReader { proxy in
            let viewportSize = proxy.size
            let viewportHeight = proxy.size.height

            ZStack(alignment: .topLeading) {
                Color.white
                    .ignoresSafeArea()

                Rectangle()
                    .fill(Color.black.opacity(0.08))
                    .frame(width: rulerStripWidth)
                    .ignoresSafeArea()

                if let profile, let viewportState {
                    rulerContent(
                        profile: profile,
                        state: viewportState,
                        viewportSize: viewportSize
                    )
                } else {
                    unsupportedState
                }

                closeButton(topInset: 0)
            }
            .coordinateSpace(name: dragCoordinateSpaceName)
            .onAppear {
                configureProfileIfNeeded(viewportHeight: viewportHeight)
            }
            .onChange(of: viewportHeight) { newValue in
                configureProfileIfNeeded(viewportHeight: newValue)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
    }

    @ViewBuilder
    private func rulerContent(
        profile: RulerDisplayProfile,
        state: RulerViewportState,
        viewportSize: CGSize
    ) -> some View {
        let viewportHeight = viewportSize.height
        let viewportWidth = viewportSize.width
        let topDisplayY = CGFloat(state.topHandlePoints - state.visibleStartPoints)
        let bottomDisplayY = CGFloat(state.bottomHandlePoints - state.visibleStartPoints)
        let measurementHeight = max(0, bottomDisplayY - topDisplayY)
        let measurementCenterY = topDisplayY + measurementHeight / 2

        Rectangle()
            .fill(Color(red: 217 / 255, green: 228 / 255, blue: 255 / 255).opacity(0.82))
            .frame(maxWidth: .infinity)
            .frame(height: measurementHeight)
            .offset(y: topDisplayY)

        RulerStripOverlay(
            profile: profile,
            visibleStartPoints: state.visibleStartPoints,
            viewportHeight: viewportHeight
        )
        .frame(width: rulerStripWidth)

        Text(RulerGeometry.formattedMeasurement(RulerGeometry.measurementCentimeters(for: state, profile: profile)))
            .font(.system(size: 32, weight: .semibold))
            .foregroundStyle(.black)
            .position(x: viewportWidth / 2, y: measurementCenterY)

        dragSurface(viewportSize: viewportSize)

        rulerHandle(.top, viewportHeight: viewportHeight)
            .position(x: viewportWidth / 2, y: topDisplayY)
        rulerHandle(.bottom, viewportHeight: viewportHeight)
            .position(x: viewportWidth / 2, y: bottomDisplayY)

        if let unsupportedMessage {
            Text(unsupportedMessage)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color(red: 84 / 255, green: 92 / 255, blue: 109 / 255))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.96), in: Capsule())
                .position(x: viewportWidth / 2, y: viewportHeight - 52)
        }
    }

    private func dragSurface(viewportSize: CGSize) -> some View {
        Color.clear
            .contentShape(Rectangle())
            .frame(width: viewportSize.width, height: viewportSize.height)
            .gesture(viewportDragGesture())
    }

    private var unsupportedState: some View {
        VStack(spacing: 12) {
            Spacer()

            Text("当前设备暂未完成真尺标定")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.black)

            Text("无法保证厘米刻度的真实物理尺寸，请在已支持的 iPhone 上使用。")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(red: 84 / 255, green: 92 / 255, blue: 109 / 255))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func closeButton(topInset: CGFloat) -> some View {
        Button {
            dismiss()
        } label: {
            Circle()
                .fill(Color.black.opacity(0.2))
                .frame(width: 30, height: 30)
                .overlay {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                }
        }
        .buttonStyle(.plain)
        .padding(.top, topInset + 10)
        .padding(.trailing, 20)
        .frame(maxWidth: .infinity, alignment: .topTrailing)
    }

    private func rulerHandle(_ handle: RulerHandle, viewportHeight: CGFloat) -> some View {
        let symbolName = handle == .top ? "chevron.up" : "chevron.down"

        return Circle()
            .fill(Color(red: 46 / 255, green: 103 / 255, blue: 246 / 255))
            .frame(width: handleSize, height: handleSize)
            .overlay {
                Image(systemName: symbolName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
            }
            .gesture(dragGesture(for: handle, viewportHeight: viewportHeight))
    }

    private func dragGesture(for handle: RulerHandle, viewportHeight: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named(dragCoordinateSpaceName))
            .onChanged { value in
                applyDrag(
                    for: handle,
                    translation: value.location.y - value.startLocation.y,
                    viewportHeight: viewportHeight
                )
            }
            .onEnded { _ in
                if activeDragSession?.handle == handle {
                    activeDragSession = nil
                }
            }
    }

    private func viewportDragGesture() -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named(dragCoordinateSpaceName))
            .onChanged { value in
                applyViewportPan(translation: value.location.y - value.startLocation.y)
            }
            .onEnded { _ in
                activePanStartingState = nil
            }
    }

    private func applyDrag(for handle: RulerHandle, translation: CGFloat, viewportHeight: CGFloat) {
        guard let profile, let viewportState else {
            return
        }

        if activeDragSession?.handle != handle {
            activeDragSession = RulerDragSession(handle: handle, startingState: viewportState)
        }

        guard let startingState = activeDragSession?.startingState else {
            return
        }

        self.viewportState = RulerGeometry.applyingDrag(
            to: startingState,
            handle: handle,
            deltaPoints: Double(translation),
            viewportHeight: viewportHeight,
            profile: profile
        )
    }

    private func applyViewportPan(translation: CGFloat) {
        guard let viewportState else {
            return
        }

        if activePanStartingState == nil {
            activePanStartingState = viewportState
        }

        guard let startingState = activePanStartingState else {
            return
        }

        self.viewportState = RulerGeometry.applyingViewportPan(
            to: startingState,
            translationPoints: Double(translation)
        )
    }

    private func configureProfileIfNeeded(viewportHeight: CGFloat) {
        guard viewportHeight > 0 else {
            return
        }

        if profile == nil {
            profile = RulerDeviceRegistry.currentProfile()
            if profile != nil {
                unsupportedMessage = nil
            } else {
                unsupportedMessage = "当前设备机型未录入真尺标定，无法保证真实厘米精度。"
            }
        }

        guard let profile else {
            return
        }

        let viewportHeight = Double(viewportHeight)
        let needsInitialization = viewportState == nil
        let heightChanged = abs(lastViewportHeight - viewportHeight) > 0.5

        guard needsInitialization || heightChanged else {
            return
        }

        if needsInitialization {
            viewportState = RulerGeometry.initialState(profile: profile, viewportHeight: viewportHeight)
        } else if var viewportState {
            let visibleLowerBound = viewportState.visibleStartPoints + viewportHeight - RulerGeometry.edgeTrackingMarginPoints
            let visibleUpperBound = viewportState.visibleStartPoints + RulerGeometry.edgeTrackingMarginPoints

            if viewportState.topHandlePoints < visibleUpperBound {
                viewportState.visibleStartPoints = max(0, viewportState.topHandlePoints - RulerGeometry.edgeTrackingMarginPoints)
            }

            if viewportState.bottomHandlePoints > visibleLowerBound {
                viewportState.visibleStartPoints = max(
                    0,
                    viewportState.bottomHandlePoints - (viewportHeight - RulerGeometry.edgeTrackingMarginPoints)
                )
            }

            self.viewportState = viewportState
        }

        lastViewportHeight = viewportHeight
    }
}

private struct RulerDragSession {
    let handle: RulerHandle
    let startingState: RulerViewportState
}

private struct RulerStripOverlay: View {
    let profile: RulerDisplayProfile
    let visibleStartPoints: Double
    let viewportHeight: CGFloat

    private let stripWidth: CGFloat = 68

    var body: some View {
        ZStack(alignment: .leading) {
            Canvas { context, size in
                let millimeterSpacing = profile.pointsPerCentimeter / 10
                let startMillimeter = max(0, Int(floor(visibleStartPoints / millimeterSpacing)))
                let endMillimeter = Int(ceil((visibleStartPoints + Double(size.height)) / millimeterSpacing))

                for millimeter in startMillimeter...endMillimeter {
                    let absolutePoints = Double(millimeter) * millimeterSpacing
                    let y = absolutePoints - visibleStartPoints
                    let tickLength: CGFloat
                    let strokeColor: Color

                    if millimeter.isMultiple(of: 10) {
                        tickLength = 19
                        strokeColor = .black.opacity(0.8)
                    } else if millimeter.isMultiple(of: 5) {
                        tickLength = 14
                        strokeColor = .black.opacity(0.65)
                    } else {
                        tickLength = 10
                        strokeColor = .black.opacity(0.45)
                    }

                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: tickLength, y: y))
                    context.stroke(path, with: .color(strokeColor), lineWidth: 1)
                }
            }

            ForEach(visibleCentimeterMarks, id: \.self) { centimeter in
                let y = CGFloat(Double(centimeter) * profile.pointsPerCentimeter - visibleStartPoints)

                if isLabelFullyVisible(centimeter: centimeter, y: y) {
                    Text("\(centimeter)")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.black)
                        .rotationEffect(.degrees(-90))
                        .position(x: 28, y: y)
                }
            }
        }
        .frame(width: stripWidth, height: viewportHeight, alignment: .topLeading)
        .clipped()
    }

    private var visibleCentimeterMarks: [Int] {
        let startCentimeter = max(1, Int(floor(visibleStartPoints / profile.pointsPerCentimeter)))
        let endCentimeter = Int(ceil((visibleStartPoints + Double(viewportHeight)) / profile.pointsPerCentimeter))
        return Array(startCentimeter...max(startCentimeter, endCentimeter))
    }

    private func isLabelFullyVisible(centimeter: Int, y: CGFloat) -> Bool {
        let halfHeight = estimatedLabelHalfHeight(for: centimeter)
        return y >= halfHeight && y <= viewportHeight - halfHeight
    }

    private func estimatedLabelHalfHeight(for centimeter: Int) -> CGFloat {
        let digits = String(centimeter).count
        return CGFloat(10 + digits * 5)
    }
}

#Preview {
    NavigationStack {
        RulerScreen()
    }
}
