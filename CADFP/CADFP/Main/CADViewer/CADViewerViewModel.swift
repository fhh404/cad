import Foundation
import Combine

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
    @Published var isExtractingTexts = false
    @Published var isMarkupHidden = false
    @Published var activeMarkup: MarkupOption?
    @Published var alertMessage: AlertMessage?

    weak var controller: CADBaseViewController?

    init(title: String) {
        self.title = title
    }

    var isMarkupSubpanelPresented: Bool {
        isMarkupTextInputPresented || activeMarkupStylePanel != nil
    }

    func showLayers() {
        dismissMarkupChrome()
        controller?.requestLayerSnapshot()
        isLayerSheetPresented = true
    }

    func showMarkupPanel() {
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

    func showMeasurementPlaceholder() {
        alertMessage = AlertMessage(title: "测量", message: "第一版先把图层、批注、隐藏批注和文字提取接通，测量能力会在下一阶段补上。")
    }

    func toggleMarkupsHidden() {
        isMarkupHidden.toggle()
        controller?.setMarkupsHidden(isMarkupHidden)
    }

    func showExtractedTexts() {
        dismissMarkupChrome()
        isLayerSheetPresented = false
        extractedTexts = []
        isExtractingTexts = true
        isTextSheetPresented = true
        controller?.requestExtractedTexts()
    }

    func resetView() {
        controller?.resetView()
    }

    func showSettingsPlaceholder() {
        alertMessage = AlertMessage(title: "设置", message: "图纸设置功能会在下一阶段接入。")
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
}

struct CADHotspotAnnotation: Identifiable, Equatable {
    let id = UUID()
    let text: String
}

struct CADMarkupRGB: Equatable {
    let red: Int
    let green: Int
    let blue: Int
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
        max(0.25, fontSize / 49.0)
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
