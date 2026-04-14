import Combine
import CoreGraphics
import Foundation
import UIKit

@MainActor
final class CADViewerViewModel: ObservableObject {
    struct AlertMessage: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }

    enum MarkupOption: String, CaseIterable, Identifiable {
        case rectangle = "矩形"
        case circle = "圆形"
        case cloud = "云线"
        case text = "文字"
        case handDraw = "手绘"

        var id: String { rawValue }

        var bridgeValue: CADMarkupTool {
            switch self {
            case .rectangle:
                return CADMarkupTool(rawValue: 0)!
            case .circle:
                return CADMarkupTool(rawValue: 1)!
            case .cloud:
                return CADMarkupTool(rawValue: 2)!
            case .text:
                return CADMarkupTool(rawValue: 3)!
            case .handDraw:
                return CADMarkupTool(rawValue: 4)!
            }
        }
    }

    enum MarkupStylePanel: Equatable {
        case text
        case handDraw
    }

    let title: String

    @Published var layers: [CADLayerItem] = []
    @Published var extractedTexts: [String] = []
    @Published var isLayerSheetPresented = false
    @Published var isMarkupToolbarPresented = false
    @Published var isMeasurementToolbarPresented = false
    @Published var selectedMeasurementMode = CADMeasurementMode.length
    @Published var measurementSamples: [CADMeasurementSample] = []
    @Published var isMarkupTextInputPresented = false
    @Published var selectedMarkupToolbarItem: CADMarkupToolbarItemKind?
    @Published var activeMarkupStylePanel: MarkupStylePanel?
    @Published var markupTextDraft = ""
    @Published var hotspotTextDraft = ""
    @Published var isHotspotInputPresented = false
    @Published var hotspotAnnotations: [CADHotspotAnnotation] = []
    @Published var markupFontSize = 49.0
    @Published var selectedTextColorIndex = 1
    @Published var selectedHandDrawColorIndex = 1
    @Published var selectedLineWidthIndex = 0
    @Published var isTextSheetPresented = false
    @Published var isTextExtractionOverlayPresented = false
    @Published var textExtractionSelectionRect = CADTextExtractionSelectionGeometry.normalized(
        CADTextExtractionSelectionGeometry.initialDesignRect,
        in: CADTextExtractionSelectionGeometry.designCanvasSize
    )
    @Published var hasTextExtractionAttempted = false
    @Published var isExtractingTexts = false
    @Published var isMarkupHidden = false
    @Published var isSettingsPanelPresented = false
    @Published var selectedSettingsBackground = CADViewerSettingsBackgroundOption.defaultOption
    @Published var settingsRotationDegrees = 0
    @Published var activeMarkup: MarkupOption?
    @Published var alertMessage: AlertMessage?

    weak var controller: CADBaseViewController? {
        didSet {
            oldValue?.isMeasurementModeEnabled = false
            controller?.isMeasurementModeEnabled = isMeasurementToolbarPresented
            applySettingsBackground()
            applySettingsRotation()
        }
    }

    init(title: String) {
        self.title = title
    }

    var isMarkupSubpanelPresented: Bool {
        isMarkupTextInputPresented || activeMarkupStylePanel != nil
    }

    var measurementLengthText: String? {
        guard selectedMeasurementMode == .length, measurementSamples.count >= 2 else {
            return nil
        }

        return CADMeasurementCalculator.formattedLength(
            CADMeasurementCalculator.length(from: measurementSamples.map(\.worldPoint))
        )
    }

    var measurementAreaText: String? {
        guard selectedMeasurementMode == .area, measurementSamples.count >= 3 else {
            return nil
        }

        return CADMeasurementCalculator.formattedArea(
            CADMeasurementCalculator.area(from: measurementSamples.map(\.worldPoint))
        )
    }

    var measurementCoordinateText: String? {
        guard selectedMeasurementMode == .coordinate, let worldPoint = measurementSamples.last?.worldPoint else {
            return nil
        }

        return CADMeasurementCalculator.formattedCoordinate(worldPoint)
    }

    func showLayers() {
        dismissMarkupChrome()
        dismissMeasurementChrome()
        dismissTextExtractionChrome()
        dismissSettingsChrome()
        controller?.requestLayerSnapshot()
        isLayerSheetPresented = true
    }

    func showMarkupPanel() {
        dismissMeasurementChrome()
        dismissTextExtractionChrome()
        dismissSettingsChrome()
        isLayerSheetPresented = false
        isMarkupToolbarPresented = true
        isMarkupTextInputPresented = false
        isHotspotInputPresented = false
        activeMarkupStylePanel = nil
        selectedMarkupToolbarItem = nil
    }

    func selectMarkupToolbarItem(_ item: CADMarkupToolbarItemKind) {
        switch item {
        case .back:
            dismissMarkupChrome()
        case .text:
            finishActiveMarkupTool()
            selectedMarkupToolbarItem = .text
            activeMarkupStylePanel = nil
            isHotspotInputPresented = false
            isMarkupTextInputPresented = true
        case .handDraw:
            selectedMarkupToolbarItem = .handDraw
            activeMarkup = .handDraw
            isMarkupTextInputPresented = false
            isHotspotInputPresented = false
            activeMarkupStylePanel = .handDraw
            applyHandDrawMarkupStyle()
            controller?.activate(MarkupOption.handDraw.bridgeValue)
        case .hotspot:
            finishActiveMarkupTool()
            selectedMarkupToolbarItem = .hotspot
            activeMarkupStylePanel = nil
            isMarkupTextInputPresented = false
            hotspotTextDraft = ""
            isHotspotInputPresented = true
        }
    }

    func showMarkupTextStylePanel() {
        selectedMarkupToolbarItem = .text
        isMarkupTextInputPresented = false
        isHotspotInputPresented = false
        activeMarkupStylePanel = .text
    }

    func dismissMarkupStylePanel() {
        let currentPanel = activeMarkupStylePanel
        activeMarkupStylePanel = nil
        isMarkupTextInputPresented = currentPanel == .text
    }

    func dismissMarkupSubpanel() {
        let wasTextPanel = isMarkupTextInputPresented || activeMarkupStylePanel == .text
        isMarkupTextInputPresented = false
        activeMarkupStylePanel = nil

        if wasTextPanel {
            selectedMarkupToolbarItem = nil
        }
    }

    func selectMarkupColor(_ option: CADMarkupColorOption, for stylePanel: MarkupStylePanel) {
        switch stylePanel {
        case .text:
            selectedTextColorIndex = option.rawValue
        case .handDraw:
            selectedHandDrawColorIndex = option.rawValue
            restartHandDrawToolIfNeeded()
        }
    }

    func selectHandDrawLineWeight(_ option: CADMarkupLineWeightOption) {
        selectedLineWidthIndex = option.rawValue
        restartHandDrawToolIfNeeded()
    }

    func confirmMarkupText() {
        let text = markupTextDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            alertMessage = AlertMessage(title: "文字批注", message: "请输入文字内容。")
            return
        }

        activeMarkup = .text
        isMarkupTextInputPresented = false
        activeMarkupStylePanel = nil
        applyTextMarkupStyle()
        controller?.activateTextMarkup(withText: text, textSize: CADMarkupFontSizeMapper.textScale(for: markupFontSize))
    }

    func cancelHotspotText() {
        hotspotTextDraft = ""
        isHotspotInputPresented = false
    }

    func confirmHotspotText() {
        let text = hotspotTextDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            alertMessage = AlertMessage(title: "热点", message: "请输入热点文本。")
            return
        }

        isHotspotInputPresented = false
        hotspotAnnotations.append(CADHotspotAnnotation(text: text))
        hotspotTextDraft = ""
    }

    func showMeasurementPanel() {
        dismissMarkupChrome()
        dismissTextExtractionChrome()
        dismissSettingsChrome()
        isLayerSheetPresented = false
        isTextSheetPresented = false
        isHotspotInputPresented = false
        isMeasurementToolbarPresented = true
        selectedMeasurementMode = .length
        measurementSamples = []
        controller?.isMeasurementModeEnabled = true
    }

    func dismissMeasurementPanel() {
        dismissMeasurementChrome()
    }

    func selectMeasurementMode(_ mode: CADMeasurementMode) {
        selectedMeasurementMode = mode
        measurementSamples = []
        isMeasurementToolbarPresented = true
        controller?.isMeasurementModeEnabled = true
    }

    func handleMeasuredPoint(screenPoint: CGPoint, worldCoordinate: CADMeasurementCoordinate) {
        let sample = CADMeasurementSample(
            screenPoint: screenPoint,
            worldPoint: CADMeasurementWorldPoint(
                x: worldCoordinate.x,
                y: worldCoordinate.y,
                z: worldCoordinate.z
            )
        )

        switch selectedMeasurementMode {
        case .length:
            if measurementSamples.count >= 2 {
                measurementSamples = [sample]
            } else {
                measurementSamples.append(sample)
            }
        case .area:
            measurementSamples.append(sample)
        case .coordinate:
            measurementSamples = [sample]
        }
    }

    func toggleMarkupsHidden() {
        isMarkupHidden.toggle()
        controller?.setMarkupsHidden(isMarkupHidden)
    }

    func showExtractedTexts() {
        dismissMarkupChrome()
        dismissMeasurementChrome()
        dismissSettingsChrome()
        isLayerSheetPresented = false
        extractedTexts = []
        isExtractingTexts = false
        hasTextExtractionAttempted = false
        isTextSheetPresented = false
        isTextExtractionOverlayPresented = true
        textExtractionSelectionRect = CADTextExtractionSelectionGeometry.normalized(
            CADTextExtractionSelectionGeometry.initialDesignRect,
            in: CADTextExtractionSelectionGeometry.designCanvasSize
        )
    }

    func cancelTextExtraction() {
        dismissTextExtractionChrome()
    }

    func confirmTextExtraction(in canvasSize: CGSize) {
        let selectionRect = CADTextExtractionSelectionGeometry.denormalized(
            textExtractionSelectionRect,
            in: canvasSize
        )
        extractedTexts = []
        isExtractingTexts = true
        hasTextExtractionAttempted = true
        controller?.requestExtractedTexts(inViewRect: selectionRect)
    }

    func updateTextExtractionSelection(_ rect: CGRect, in canvasSize: CGSize) {
        let clampedRect = CADTextExtractionSelectionGeometry.clamped(rect, in: canvasSize)
        textExtractionSelectionRect = CADTextExtractionSelectionGeometry.normalized(clampedRect, in: canvasSize)
    }

    func copyExtractedTexts() {
        let content = extractedTexts.joined(separator: "\n")
        guard !content.isEmpty else {
            alertMessage = AlertMessage(title: "文字提取", message: "当前没有可复制的文字。")
            return
        }

        UIPasteboard.general.string = content
        alertMessage = AlertMessage(title: "文字提取", message: "已复制提取结果。")
    }

    func resetView() {
        controller?.resetView()
    }

    func showSettingsPanel() {
        dismissMarkupChrome()
        dismissMeasurementChrome()
        dismissTextExtractionChrome()
        isLayerSheetPresented = false
        isTextSheetPresented = false
        isHotspotInputPresented = false
        isSettingsPanelPresented = true
        applySettingsBackground()
        applySettingsRotation()
    }

    func dismissSettingsPanel() {
        dismissSettingsChrome()
    }

    func rotateSettingsViewCounterclockwise() {
        settingsRotationDegrees = CADViewerSettingsRotation.normalizedDegrees(settingsRotationDegrees - 90)
        applySettingsRotation()
    }

    func rotateSettingsViewClockwise() {
        settingsRotationDegrees = CADViewerSettingsRotation.normalizedDegrees(settingsRotationDegrees + 90)
        applySettingsRotation()
    }

    func selectSettingsBackground(_ option: CADViewerSettingsBackgroundOption) {
        selectedSettingsBackground = option
        applySettingsBackground()
    }

    func toggleLayer(_ item: CADLayerItem) {
        controller?.setLayerHidden(!item.isHidden, at: item.index)
    }

    func updateLayers(_ layerItems: [CADLayerItem]) {
        layers = layerItems
    }

    func updateTextItems(_ items: [String]) {
        extractedTexts = items
        isExtractingTexts = false
    }

    func receiveMessage(title: String, message: String) {
        alertMessage = AlertMessage(title: title, message: message)
    }

    private func dismissMarkupChrome() {
        isMarkupToolbarPresented = false
        isMarkupTextInputPresented = false
        activeMarkupStylePanel = nil
        isHotspotInputPresented = false
        finishActiveMarkupTool()
    }

    private func dismissMeasurementChrome() {
        isMeasurementToolbarPresented = false
        measurementSamples = []
        controller?.isMeasurementModeEnabled = false
    }

    private func dismissTextExtractionChrome() {
        isTextExtractionOverlayPresented = false
        isTextSheetPresented = false
        isExtractingTexts = false
        hasTextExtractionAttempted = false
        extractedTexts = []
    }

    private func dismissSettingsChrome() {
        isSettingsPanelPresented = false
    }

    private func finishActiveMarkupTool() {
        activeMarkup = nil
        controller?.finishActiveMarkup()
    }

    private func applyTextMarkupStyle() {
        let color = colorOption(for: selectedTextColorIndex).rgb
        controller?.setMarkupColorWithRed(color.red, green: color.green, blue: color.blue)
    }

    private func applyHandDrawMarkupStyle() {
        let color = colorOption(for: selectedHandDrawColorIndex).rgb
        controller?.setMarkupColorWithRed(color.red, green: color.green, blue: color.blue)
        controller?.setMarkupLineWeight(lineWeightOption(for: selectedLineWidthIndex).bridgeWeight)
    }

    private func restartHandDrawToolIfNeeded() {
        guard activeMarkup == .handDraw else {
            return
        }

        controller?.finishActiveMarkup()
        applyHandDrawMarkupStyle()
        controller?.activate(MarkupOption.handDraw.bridgeValue)
    }

    private func colorOption(for index: Int) -> CADMarkupColorOption {
        CADMarkupColorOption(rawValue: index) ?? .cyan
    }

    private func lineWeightOption(for index: Int) -> CADMarkupLineWeightOption {
        CADMarkupLineWeightOption(rawValue: index) ?? .thin
    }

    private func applySettingsBackground() {
        let color = selectedSettingsBackground.rgb
        controller?.setDrawingBackground(red: color.red, green: color.green, blue: color.blue)
    }

    private func applySettingsRotation() {
        controller?.setViewRotation(degrees: settingsRotationDegrees)
    }
}

struct CADHotspotAnnotation: Identifiable, Equatable {
    let id = UUID()
    let text: String
}

enum CADMeasurementMode: String, CaseIterable, Identifiable {
    case length
    case area
    case coordinate

    var id: String { rawValue }
}

struct CADMeasurementWorldPoint: Equatable {
    let x: Double
    let y: Double
    let z: Double
}

struct CADMeasurementSample: Identifiable, Equatable {
    let id = UUID()
    let screenPoint: CGPoint
    let worldPoint: CADMeasurementWorldPoint
}

enum CADMeasurementCalculator {
    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.roundingMode = .halfUp
        return formatter
    }()

    static func length(from points: [CADMeasurementWorldPoint]) -> Double {
        guard points.count >= 2, let first = points.first, let second = points.dropFirst().first else {
            return 0
        }

        let dx = second.x - first.x
        let dy = second.y - first.y
        let dz = second.z - first.z
        return sqrt(dx * dx + dy * dy + dz * dz)
    }

    static func area(from points: [CADMeasurementWorldPoint]) -> Double {
        guard points.count >= 3 else {
            return 0
        }

        var sum = 0.0
        for index in points.indices {
            let current = points[index]
            let next = points[index == points.index(before: points.endIndex) ? points.startIndex : points.index(after: index)]
            sum += current.x * next.y - next.x * current.y
        }
        return abs(sum) / 2
    }

    static func formattedLength(_ value: Double) -> String {
        formattedScalar(value)
    }

    static func formattedArea(_ value: Double) -> String {
        "\(formattedScalar(value))㎡"
    }

    static func formattedCoordinate(_ point: CADMeasurementWorldPoint) -> String {
        "X:\(formattedScalar(point.x))\nY:\(formattedScalar(point.y))"
    }

    private static func formattedScalar(_ value: Double) -> String {
        formatter.string(from: NSNumber(value: value)) ?? "0"
    }
}

enum CADTextExtractionSelectionHandle: CaseIterable, Identifiable {
    case topLeading
    case top
    case topTrailing
    case leading
    case trailing
    case bottomLeading
    case bottom
    case bottomTrailing

    var id: String {
        switch self {
        case .topLeading:
            return "topLeading"
        case .top:
            return "top"
        case .topTrailing:
            return "topTrailing"
        case .leading:
            return "leading"
        case .trailing:
            return "trailing"
        case .bottomLeading:
            return "bottomLeading"
        case .bottom:
            return "bottom"
        case .bottomTrailing:
            return "bottomTrailing"
        }
    }
}

enum CADTextExtractionSelectionGeometry {
    static let designCanvasSize = CGSize(width: 393, height: 852)
    static let initialDesignRect = CGRect(x: 56, y: 322, width: 220, height: 180)
    static let minimumSize = CGSize(width: 64, height: 64)

    static func normalized(_ rect: CGRect, in bounds: CGSize) -> CGRect {
        guard bounds.width > 0, bounds.height > 0 else {
            return .zero
        }

        let clampedRect = clamped(rect, in: bounds)
        return CGRect(
            x: clampedRect.minX / bounds.width,
            y: clampedRect.minY / bounds.height,
            width: clampedRect.width / bounds.width,
            height: clampedRect.height / bounds.height
        )
    }

    static func denormalized(_ rect: CGRect, in bounds: CGSize) -> CGRect {
        guard bounds.width > 0, bounds.height > 0 else {
            return .zero
        }

        return clamped(
            CGRect(
                x: rect.minX * bounds.width,
                y: rect.minY * bounds.height,
                width: rect.width * bounds.width,
                height: rect.height * bounds.height
            ),
            in: bounds
        )
    }

    static func moved(_ rect: CGRect, by translation: CGSize, in bounds: CGSize) -> CGRect {
        clamped(rect.offsetBy(dx: translation.width, dy: translation.height), in: bounds)
    }

    static func resized(
        _ rect: CGRect,
        handle: CADTextExtractionSelectionHandle,
        by translation: CGSize,
        in bounds: CGSize
    ) -> CGRect {
        guard bounds.width > 0, bounds.height > 0 else {
            return .zero
        }

        var minX = rect.minX
        var maxX = rect.maxX
        var minY = rect.minY
        var maxY = rect.maxY

        switch handle {
        case .topLeading:
            minX += translation.width
            minY += translation.height
        case .top:
            minY += translation.height
        case .topTrailing:
            maxX += translation.width
            minY += translation.height
        case .leading:
            minX += translation.width
        case .trailing:
            maxX += translation.width
        case .bottomLeading:
            minX += translation.width
            maxY += translation.height
        case .bottom:
            maxY += translation.height
        case .bottomTrailing:
            maxX += translation.width
            maxY += translation.height
        }

        if maxX - minX < minimumSize.width {
            if handle.resizesLeadingEdge {
                minX = maxX - minimumSize.width
            } else {
                maxX = minX + minimumSize.width
            }
        }

        if maxY - minY < minimumSize.height {
            if handle.resizesTopEdge {
                minY = maxY - minimumSize.height
            } else {
                maxY = minY + minimumSize.height
            }
        }

        if minX < 0 {
            if handle.resizesLeadingEdge {
                minX = 0
            } else {
                maxX -= minX
                minX = 0
            }
        }
        if maxX > bounds.width {
            if handle.resizesTrailingEdge {
                maxX = bounds.width
            } else {
                minX -= maxX - bounds.width
                maxX = bounds.width
            }
        }
        if minY < 0 {
            if handle.resizesTopEdge {
                minY = 0
            } else {
                maxY -= minY
                minY = 0
            }
        }
        if maxY > bounds.height {
            if handle.resizesBottomEdge {
                maxY = bounds.height
            } else {
                minY -= maxY - bounds.height
                maxY = bounds.height
            }
        }

        return clamped(CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY), in: bounds)
    }

    static func clamped(_ rect: CGRect, in bounds: CGSize) -> CGRect {
        guard bounds.width > 0, bounds.height > 0 else {
            return .zero
        }

        let width = min(max(rect.width, minimumSize.width), bounds.width)
        let height = min(max(rect.height, minimumSize.height), bounds.height)
        let originX = min(max(rect.minX, 0), max(bounds.width - width, 0))
        let originY = min(max(rect.minY, 0), max(bounds.height - height, 0))
        return CGRect(x: originX, y: originY, width: width, height: height)
    }
}

private extension CADTextExtractionSelectionHandle {
    var resizesLeadingEdge: Bool {
        self == .topLeading || self == .leading || self == .bottomLeading
    }

    var resizesTrailingEdge: Bool {
        self == .topTrailing || self == .trailing || self == .bottomTrailing
    }

    var resizesTopEdge: Bool {
        self == .topLeading || self == .top || self == .topTrailing
    }

    var resizesBottomEdge: Bool {
        self == .bottomLeading || self == .bottom || self == .bottomTrailing
    }
}

struct CADMarkupRGB: Equatable {
    let red: Int
    let green: Int
    let blue: Int
}

enum CADViewerSettingsBackgroundOption: Int, CaseIterable, Identifiable {
    case white
    case gray
    case black

    static let defaultOption = CADViewerSettingsBackgroundOption.black

    var id: Int { rawValue }

    var rgb: CADMarkupRGB {
        switch self {
        case .white:
            return CADMarkupRGB(red: 255, green: 255, blue: 255)
        case .gray:
            return CADMarkupRGB(red: 151, green: 154, blue: 153)
        case .black:
            return CADMarkupRGB(red: 0, green: 0, blue: 0)
        }
    }
}

enum CADViewerSettingsRotation {
    static func normalizedDegrees(_ degrees: Int) -> Int {
        let normalized = degrees % 360
        return normalized >= 0 ? normalized : normalized + 360
    }
}

enum CADMarkupColorOption: Int, CaseIterable, Identifiable {
    case magenta
    case cyan
    case red
    case yellow
    case green
    case purple

    var id: Int { rawValue }

    var rgb: CADMarkupRGB {
        switch self {
        case .magenta:
            return CADMarkupRGB(red: 217, green: 50, blue: 202)
        case .cyan:
            return CADMarkupRGB(red: 35, green: 196, blue: 254)
        case .red:
            return CADMarkupRGB(red: 240, green: 59, blue: 53)
        case .yellow:
            return CADMarkupRGB(red: 239, green: 205, blue: 48)
        case .green:
            return CADMarkupRGB(red: 56, green: 221, blue: 102)
        case .purple:
            return CADMarkupRGB(red: 155, green: 70, blue: 221)
        }
    }
}

enum CADMarkupLineWeightOption: Int, CaseIterable, Identifiable {
    case thin
    case regular
    case thick

    var id: Int { rawValue }

    var bridgeWeight: Int {
        switch self {
        case .thin:
            return 2
        case .regular:
            return 4
        case .thick:
            return 6
        }
    }
}

enum CADMarkupFontSizeMapper {
    static func textScale(for fontSize: Double) -> Double {
        guard abs(fontSize - 49) > 0.001 else {
            return 0.0
        }

        return max(0.25, fontSize / 49.0)
    }
}

enum CADViewerToolbarItemKind: String, CaseIterable, Identifiable {
    case layers
    case markup
    case measurement
    case hideMarkup
    case textExtraction
    case reset
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .layers:
            return "图层"
        case .markup:
            return "批注"
        case .measurement:
            return "测量"
        case .hideMarkup:
            return "隐藏批注"
        case .textExtraction:
            return "文字提取"
        case .reset:
            return "重置"
        case .settings:
            return "设置"
        }
    }

    var inactiveIconName: String {
        switch self {
        case .layers:
            return "图层-L 1"
        case .markup:
            return "批注 1"
        case .measurement:
            return "测量 1"
        case .hideMarkup:
            return "隐藏批注 1"
        case .textExtraction:
            return "文字提取 1"
        case .reset:
            return "重置筛选 1"
        case .settings:
            return "设置 (2) 1"
        }
    }

    var activeIconName: String {
        switch self {
        case .layers:
            return "图层-L 2"
        case .markup:
            return "批注 2"
        case .measurement:
            return "测量 2"
        case .hideMarkup:
            return "隐藏批注 2"
        case .textExtraction:
            return "文字提取 2"
        case .reset:
            return "重置筛选 2"
        case .settings:
            return "设置 (2) 2"
        }
    }

    func iconName(isActive: Bool) -> String {
        isActive ? activeIconName : inactiveIconName
    }
}

enum CADMeasurementToolbarItemKind: String, CaseIterable, Identifiable {
    case back
    case length
    case area
    case coordinate

    var id: String { rawValue }

    var title: String {
        switch self {
        case .back:
            return ""
        case .length:
            return "测长度"
        case .area:
            return "测面积"
        case .coordinate:
            return "测坐标"
        }
    }

    var mode: CADMeasurementMode? {
        switch self {
        case .back:
            return nil
        case .length:
            return .length
        case .area:
            return .area
        case .coordinate:
            return .coordinate
        }
    }

    var inactiveIconName: String {
        switch self {
        case .back:
            return "返回 (2) 1"
        case .length:
            return "长度测量 1-1"
        case .area:
            return "面积 1"
        case .coordinate:
            return "坐标 1"
        }
    }

    var activeIconName: String {
        switch self {
        case .back:
            return "返回 (2) 1"
        case .length:
            return "长度测量 1"
        case .area:
            return "面积 2"
        case .coordinate:
            return "坐标 1-1"
        }
    }

    func iconName(isActive: Bool) -> String {
        isActive ? activeIconName : inactiveIconName
    }
}

enum CADMarkupToolbarItemKind: String, CaseIterable, Identifiable {
    case back
    case text
    case handDraw
    case hotspot

    var id: String { rawValue }

    var title: String {
        switch self {
        case .back:
            return ""
        case .text:
            return "文字"
        case .handDraw:
            return "手绘"
        case .hotspot:
            return "热点"
        }
    }

    var inactiveIconName: String {
        switch self {
        case .back:
            return "返回 (2) 1"
        case .text:
            return "文字 (2) 1"
        case .handDraw:
            return "手写体 2"
        case .hotspot:
            return "定位 (1) 1"
        }
    }

    var activeIconName: String {
        switch self {
        case .back:
            return "返回 (2) 1"
        case .text:
            return "文字 (2) 2"
        case .handDraw:
            return "手写体 3"
        case .hotspot:
            return "定位 (1) 2"
        }
    }

    func iconName(isActive: Bool) -> String {
        isActive ? activeIconName : inactiveIconName
    }
}
