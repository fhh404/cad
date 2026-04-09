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

        var id: String { rawValue }

        var symbolName: String {
            switch self {
            case .rectangle:
                return "rectangle"
            case .circle:
                return "circle"
            case .cloud:
                return "scribble.variable"
            case .text:
                return "textformat"
            }
        }

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
            }
        }
    }

    let title: String

    @Published var layers: [CADLayerItem] = []
    @Published var extractedTexts: [String] = []
    @Published var isLayerSheetPresented = false
    @Published var isMarkupPanelPresented = false
    @Published var isTextSheetPresented = false
    @Published var isExtractingTexts = false
    @Published var isMarkupHidden = false
    @Published var activeMarkup: MarkupOption?
    @Published var alertMessage: AlertMessage?

    weak var controller: CADBaseViewController?

    init(title: String) {
        self.title = title
    }

    func showLayers() {
        controller?.requestLayerSnapshot()
        isLayerSheetPresented = true
    }

    func showMarkupPanel() {
        isMarkupPanelPresented = true
    }

    func selectMarkup(_ option: MarkupOption) {
        activeMarkup = option
        isMarkupPanelPresented = false
        controller?.activate(option.bridgeValue)
    }

    func showMeasurementPlaceholder() {
        alertMessage = AlertMessage(title: "测量", message: "第一版先把图层、批注、隐藏批注和文字提取接通，测量能力会在下一阶段补上。")
    }

    func toggleMarkupsHidden() {
        isMarkupHidden.toggle()
        controller?.setMarkupsHidden(isMarkupHidden)
    }

    func showExtractedTexts() {
        extractedTexts = []
        isExtractingTexts = true
        isTextSheetPresented = true
        controller?.requestExtractedTexts()
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
}
