//
//  ProtractorScreen.swift
//  CADFP
//
//  Created by Codex on 2026/4/10.
//

import Combine
import SwiftUI
import UIKit

struct ProtractorScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var viewModel = ProtractorViewModel()

    private let coordinateSpaceName = "protractor-screen-space"

    var body: some View {
        GeometryReader { proxy in
            let safeTop = max(proxy.safeAreaInsets.top, 16)
            let safeBottom = max(proxy.safeAreaInsets.bottom, 16)
            let layout = ProtractorLayout(
                viewportSize: proxy.size,
                safeTopInset: safeTop,
                safeBottomInset: safeBottom
            )

            ZStack(alignment: .topLeading) {
                previewBackground
                    .ignoresSafeArea()

                ProtractorOverlay(
                    layout: layout,
                    measurementState: viewModel.measurementState
                )
                .allowsHitTesting(false)

                handle(
                    for: .leading,
                    angleDegrees: viewModel.measurementState.leadingRayAngleDegrees,
                    layout: layout
                )

                handle(
                    for: .trailing,
                    angleDegrees: viewModel.measurementState.trailingRayAngleDegrees,
                    layout: layout
                )

                Text(viewModel.formattedMeasurement)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.black)
                    .position(layout.readoutPosition)

                if let notice = viewModel.cameraNotice {
                    ProtractorNoticeCard(
                        message: notice,
                        showsSettingsAction: viewModel.showsSettingsAction
                    ) {
                        viewModel.openSettings()
                    }
                    .padding(.top, safeTop + 48)
                    .padding(.horizontal, 20)
                }

                closeButton(topInset: 0)
            }
            .coordinateSpace(name: coordinateSpaceName)
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .task {
            await viewModel.handleAppear()
        }
        .onDisappear {
            viewModel.handleDisappear()
        }
        .onChange(of: scenePhase) { newPhase in
            guard newPhase == .active else {
                return
            }

            Task {
                await viewModel.handleSceneActive()
            }
        }
    }

    @ViewBuilder
    private var previewBackground: some View {
        switch viewModel.captureService.authorizationState {
        case .authorized where viewModel.captureService.isSessionConfigured:
            CameraPreviewView(session: viewModel.captureService.session)
        default:
            LinearGradient(
                colors: [
                    Color(red: 31 / 255, green: 34 / 255, blue: 42 / 255),
                    Color(red: 57 / 255, green: 63 / 255, blue: 78 / 255),
                    Color(red: 28 / 255, green: 30 / 255, blue: 37 / 255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private func closeButton(topInset: CGFloat) -> some View {
        Button {
            dismiss()
        } label: {
            Circle()
                .fill(Color.white.opacity(0.76))
                .frame(width: 30, height: 30)
                .overlay {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(red: 168 / 255, green: 175 / 255, blue: 184 / 255))
                }
        }
        .buttonStyle(.plain)
        .padding(.top, topInset + 10)
        .padding(.trailing, 20)
        .frame(maxWidth: .infinity, alignment: .topTrailing)
    }

    private func handle(
        for handle: ProtractorHandle,
        angleDegrees: Double,
        layout: ProtractorLayout
    ) -> some View {
        let endpoint = ProtractorGeometry.endpoint(
            for: angleDegrees,
            center: layout.center,
            radius: layout.handleRadius
        )

        return ZStack {
            Circle()
                .fill(Color.white.opacity(0.001))
                .frame(width: 72, height: 72)

            Circle()
                .fill(Color.white.opacity(0.94))
                .frame(width: 18, height: 18)
                .overlay {
                    Circle()
                        .stroke(Color.black.opacity(0.85), lineWidth: 2)
                }
                .shadow(color: Color.black.opacity(0.16), radius: 6, y: 3)
        }
        .position(endpoint)
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .named(coordinateSpaceName))
                .onChanged { value in
                    viewModel.updateMeasurement(
                        ProtractorGeometry.updating(
                            viewModel.measurementState,
                            handle: handle,
                            location: value.location,
                            center: layout.center
                        )
                    )
                }
        )
    }
}

@MainActor
enum ProtractorCaptureServiceProvider {
    static let shared = CameraCaptureService(mode: .previewOnly)

    static func prewarmIfAuthorized() async {
        await shared.prewarmSessionIfAuthorized()
    }
}

@MainActor
private final class ProtractorViewModel: ObservableObject {
    @Published var measurementState = ProtractorMeasurementState.initial

    let captureService: CameraCaptureService

    private var cancellables: Set<AnyCancellable> = []

    init() {
        self.captureService = ProtractorCaptureServiceProvider.shared
        captureService.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    init(captureService: CameraCaptureService) {
        self.captureService = captureService
        captureService.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    var formattedMeasurement: String {
        ProtractorGeometry.formattedMeasurement(
            ProtractorGeometry.measurementDegrees(for: measurementState)
        )
    }

    var cameraNotice: String? {
        switch captureService.authorizationState {
        case .authorized:
            return nil
        case .unknown:
            return "正在准备相机..."
        case .unavailable:
            return "当前环境没有可用相机，请在真机上使用量角器测量。"
        case .denied:
            return "相机权限已关闭，打开设置后即可使用量角器测量。"
        case .restricted:
            return "当前设备限制了相机访问，暂时无法开启测量预览。"
        }
    }

    var showsSettingsAction: Bool {
        captureService.authorizationState == .denied
    }

    func handleAppear() async {
        if captureService.authorizationState == .authorized, captureService.isSessionConfigured {
            captureService.startSession()
            return
        }

        await captureService.prepareSession()
        captureService.startSession()
    }

    func handleSceneActive() async {
        captureService.startSession()
    }

    func handleDisappear() {
        captureService.stopSession()
    }

    func updateMeasurement(_ measurementState: ProtractorMeasurementState) {
        self.measurementState = measurementState
    }

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        UIApplication.shared.open(url)
    }
}

private struct ProtractorLayout {
    let viewportSize: CGSize
    let safeTopInset: CGFloat
    let safeBottomInset: CGFloat

    var radius: CGFloat {
        min(viewportSize.width * 0.815, viewportSize.height * 0.39)
    }

    var center: CGPoint {
        CGPoint(x: 0, y: safeTopInset + 46 + radius)
    }

    var handleRadius: CGFloat {
        radius - 18
    }

    var outerLabelRadius: CGFloat {
        radius - 30
    }

    var innerScaleArcRadius: CGFloat {
        max(radius - 48, radius * 0.67)
    }

    var innerLabelRadius: CGFloat {
        innerScaleArcRadius - ProtractorGeometry.innerLabelInset
    }

    var readoutPosition: CGPoint {
        CGPoint(
            x: viewportSize.width - 96,
            y: min(viewportSize.height - safeBottomInset - 140, center.y + radius * 0.74)
        )
    }
}

private struct ProtractorOverlay: View {
    let layout: ProtractorLayout
    let measurementState: ProtractorMeasurementState

        var body: some View {
            ZStack {
                Canvas { context, _ in
                    drawArcs(in: &context)
                    drawOuterTicks(in: &context)
                    drawInnerScale(in: &context)
                    drawRay(
                        angleDegrees: measurementState.leadingRayAngleDegrees,
                        in: &context
                    )
                    drawRay(
                        angleDegrees: measurementState.trailingRayAngleDegrees,
                        in: &context
                    )
                    drawCenterMarker(in: &context)
                }

                ForEach(0...ProtractorGeometry.majorStepCount, id: \.self) { step in
                    labelView(
                        for: step,
                        reversed: false,
                        radius: layout.outerLabelRadius,
                        fontSize: 11
                    )
                }

                ForEach(0...ProtractorGeometry.majorStepCount, id: \.self) { step in
                    labelView(
                        for: step,
                        reversed: true,
                        radius: layout.innerLabelRadius,
                        fontSize: 10
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }

    @ViewBuilder
    private func labelView(
        for step: Int,
        reversed: Bool,
        radius: CGFloat,
        fontSize: CGFloat
    ) -> some View {
        let angleDegrees = Double(step * 10) - 90
        let labelPoint = ProtractorGeometry.endpoint(
            for: angleDegrees,
            center: layout.center,
            radius: radius
        )
        let labelValue = ProtractorGeometry.majorLabelValue(for: step, reversed: reversed)

        Text("\(labelValue)")
            .font(.system(size: fontSize, weight: reversed ? .regular : .medium, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(Color.black.opacity(reversed ? 0.82 : 0.8))
            .rotationEffect(.degrees(angleDegrees + 90))
            .position(labelPoint)
    }

    private func drawArcs(in context: inout GraphicsContext) {
        var outerPath = Path()
        outerPath.addArc(
            center: layout.center,
            radius: layout.radius,
            startAngle: .degrees(-90),
            endAngle: .degrees(90),
            clockwise: false
        )
        context.stroke(outerPath, with: .color(Color.black.opacity(0.72)), lineWidth: 1.3)

        var innerPath = Path()
        innerPath.addArc(
            center: layout.center,
            radius: layout.innerScaleArcRadius,
            startAngle: .degrees(-90),
            endAngle: .degrees(90),
            clockwise: false
        )
        context.stroke(innerPath, with: .color(Color.black.opacity(0.56)), lineWidth: 1)
    }

    private func drawOuterTicks(in context: inout GraphicsContext) {
        for degree in 0...180 {
            let angleDegrees = Double(degree) - 90
            let outerPoint = ProtractorGeometry.endpoint(
                for: angleDegrees,
                center: layout.center,
                radius: layout.radius
            )
            let tickLength: CGFloat

            if degree.isMultiple(of: 10) {
                tickLength = 24
            } else if degree.isMultiple(of: 5) {
                tickLength = 16
            } else {
                tickLength = 10
            }

            let innerPoint = ProtractorGeometry.endpoint(
                for: angleDegrees,
                center: layout.center,
                radius: layout.radius - tickLength
            )

            var tick = Path()
            tick.move(to: outerPoint)
            tick.addLine(to: innerPoint)
            context.stroke(tick, with: .color(Color.black.opacity(0.68)), lineWidth: degree.isMultiple(of: 10) ? 1.3 : 1)
        }
    }

    private func drawInnerScale(in context: inout GraphicsContext) {
        for degree in 0...180 {
            let angleDegrees = Double(degree) - 90
            let outerPoint = ProtractorGeometry.endpoint(
                for: angleDegrees,
                center: layout.center,
                radius: layout.innerScaleArcRadius
            )
            let innerPoint = ProtractorGeometry.endpoint(
                for: angleDegrees,
                center: layout.center,
                radius: layout.innerScaleArcRadius - ProtractorGeometry.innerTickLength(for: degree)
            )

            var tick = Path()
            tick.move(to: outerPoint)
            tick.addLine(to: innerPoint)
            context.stroke(
                tick,
                with: .color(Color.black.opacity(degree.isMultiple(of: 10) ? 0.72 : (degree.isMultiple(of: 5) ? 0.52 : 0.42))),
                style: StrokeStyle(
                    lineWidth: degree.isMultiple(of: 10) ? 1.15 : (degree.isMultiple(of: 5) ? 0.92 : 0.72),
                    lineCap: .round
                )
            )
        }
    }

    private func drawRay(
        angleDegrees: Double,
        in context: inout GraphicsContext
    ) {
        let endPoint = ProtractorGeometry.endpoint(
            for: angleDegrees,
            center: layout.center,
            radius: layout.handleRadius
        )

        var path = Path()
        path.move(to: layout.center)
        path.addLine(to: endPoint)

        context.stroke(
            path,
            with: .color(Color.black.opacity(0.78)),
            style: StrokeStyle(lineWidth: 2.2, lineCap: .round)
        )
    }

    private func drawCenterMarker(in context: inout GraphicsContext) {
        let centerRect = CGRect(
            x: layout.center.x - 4,
            y: layout.center.y - 4,
            width: 8,
            height: 8
        )

        context.fill(
            Path(ellipseIn: centerRect),
            with: .color(Color.white.opacity(0.96))
        )
        context.stroke(
            Path(ellipseIn: centerRect.insetBy(dx: -2, dy: -2)),
            with: .color(Color.black.opacity(0.82)),
            lineWidth: 1.4
        )
    }
}

private struct ProtractorNoticeCard: View {
    let message: String
    let showsSettingsAction: Bool
    let onOpenSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            if showsSettingsAction {
                Button("打开设置", action: onOpenSettings)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(red: 28 / 255, green: 58 / 255, blue: 123 / 255))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white, in: Capsule())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.56), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        ProtractorScreen()
    }
}
